---
name: file-ownership
description: >
  Assigns exclusive file ownership to each agent before parallel dispatch.
  Detects conflicts where two subtasks need the same file and serializes them.
  Produces an ownership manifest consumed by agent-dispatcher.
user_invocable: false
interactive: false
model_tier: senior
depends_on:
  - task-decomposer
triggers:
  - "file ownership"
  - "parallel ownership"
  - "assign files"
reads:
  - ".ai/tasks/decomposed/*.yml"
writes:
  - ".ai/tasks/ownership/<task-id>.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "no_overlaps"
      verify: "No file appears in more than one agent's write list"
      fail_action: "Serialize conflicting subtasks or split the shared file"
    - name: "full_coverage"
      verify: "Every file in the decomposition is assigned to exactly one agent"
      fail_action: "Assign unowned files to the appropriate subtask"
    - name: "manifest_written"
      verify: "Ownership manifest exists at .ai/tasks/ownership/<task-id>.yml"
      fail_action: "Write the ownership manifest before dispatch"
  on_fail: "Ownership conflicts detected — resolve before dispatch"
  on_pass: "Clean ownership — safe to dispatch parallel agents"
_source:
  origin: "smedjen"
  inspired_by: "kronen/skills/file-ownership/SKILL.md"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Adapted for smedjen dispatch pipeline with ownership manifest output"
---

# File Ownership

One agent, one file. No file written by two agents in the same dispatch wave.

## Core Rule

If two subtasks both need to write the same file:
1. Assign the file to one subtask; the other reads the result
2. Split the file so each subtask owns a separate piece
3. Serialize the subtasks (run sequentially instead of parallel)

## Assignment Steps

1. Collect all `file_scope` entries from decomposed subtasks.
2. Build a file → subtask mapping.
3. Flag any file appearing in multiple subtask write lists.
4. Resolve conflicts using the three strategies above.
5. Write the ownership manifest to `.ai/tasks/ownership/<task-id>.yml`.
6. Pass the manifest to agent-dispatcher for enforcement.

## Manifest Schema

```yaml
task_id: "<id>"
agents:
  - subtask: "st-1"
    writes: ["src/auth/service.ts", "src/auth/controller.ts"]
    reads: ["src/shared/types.ts"]
  - subtask: "st-2"
    writes: ["src/users/service.ts"]
    reads: ["src/auth/service.ts"]
conflicts_resolved:
  - file: "src/shared/types.ts"
    resolution: "assigned to st-1, st-2 reads only"
```

## Conflict Detection Heuristic

Files most likely to conflict: shared types, config files, barrel exports, CSS/theme files, test fixtures. Flag these proactively during decomposition.
