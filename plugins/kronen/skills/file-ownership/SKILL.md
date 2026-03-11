---
name: file-ownership
description: >
  Decompose a feature into parallel development streams with strict file boundary
  ownership. Each stream owns specific files exclusively; interface contracts are
  defined at boundaries before implementation begins. Prevents merge conflicts
  structurally. Use when decomposing a feature for parallel agent execution,
  when planning a wave where multiple agents will work simultaneously, when a
  previous parallel attempt produced merge conflicts, or when a multi-stream
  plan needs explicit ownership assignments to prevent write contention.
user_invocable: false
interactive: false
depends_on: [plan-engine]
triggers:
  - "parallel agents"
  - "file ownership"
  - "merge conflicts"
  - "stream decomposition"
  - "parallel development"
  - "concurrent streams"
reads:
  - ".ai/plans/*/state.yml"
writes:
  - ".ai/plans/*/ownership.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "ownership_complete"
      verify: "Every file in the plan assigned to exactly one stream — no overlaps"
      fail_action: "Resolve any files appearing in multiple stream ownership lists"
    - name: "interfaces_defined"
      verify: "Interface contracts written for all stream boundaries before implementation"
      fail_action: "Write interface contracts at all cross-stream boundaries"
    - name: "no_shared_files"
      verify: "No file is in more than one stream's ownership list"
      fail_action: "Split the shared file's responsibilities or assign to one stream"
    - name: "ownership_file_written"
      verify: ".ai/plans/<plan>/ownership.yml written with stream assignments"
      fail_action: "Write ownership.yml before dispatching parallel agents"
  on_fail: "Resolve ownership conflicts before dispatching. Ambiguous ownership = merge conflict."
  on_pass: "Ownership clean. Safe to dispatch parallel streams."
model_tier: senior
_source:
  origin: "kronen"
  inspired_by: "agents-main/plugins/agent-teams/skills/parallel-feature-development/references/file-ownership.md"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Adapted file-boundary decomposition methodology to kronen plan-engine integration. Added ownership.yml schema and interface contract pattern."
---

# file-ownership

Assign strict file ownership before parallel dispatch. No shared files.
Interface contracts at boundaries. Prevents merge conflicts structurally.

## Core Rule

**One stream, one file. No file owned by two streams.**

If two streams both need to write the same file, either:
1. Assign it to one stream and expose the result as a read-only interface
2. Split the file into two files owned by separate streams
3. Make it a third stream that both depend on (sequential dependency)

## Decomposition Steps

```
1. List all files that will be created or modified
2. Identify natural boundaries (module, layer, feature slice)
3. Assign each file to exactly one stream
4. For each cross-stream dependency: write the interface contract
5. Write ownership.yml
6. Dispatch streams with their ownership list in the prompt
```

## Full Process

See `references/process.md` for ownership.yml schema, interface contract
format, boundary detection heuristics, and conflict resolution rules.
