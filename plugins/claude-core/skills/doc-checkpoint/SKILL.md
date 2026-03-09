---
name: doc-checkpoint
description: >
  Evaluate documentation state after task completion. Compares changed files against
  CLAUDE.md, MEMORY.md, roadmap.yml, and ecosystem.json to produce a structured
  checklist of needed updates. Use after multi-file tasks, roadmap deliveries, or
  when adding new capabilities.
user_invocable: false
interactive: false
depends_on: []
reads:
  - "~/CLAUDE.md"
  - "CLAUDE.md"
  - ".ai/roadmap.yml"
  - "plugins/*/.claude-plugin/ecosystem.json"
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "diff_analyzed"
      verify: "Git diff was read and change categories identified"
      fail_action: "Run git diff --name-only HEAD to identify changed files"
    - name: "checklist_produced"
      verify: "YAML checklist output generated with priority-tagged items"
      fail_action: "Apply routing table from references/process.md to categorize updates"
    - name: "no_false_negatives"
      verify: "New skills/commands verified against ecosystem.json registration"
      fail_action: "Cross-check skill directories against ecosystem.json entries"
model_tier: junior
_source:
  origin: "claude-core"
  inspired_by: "RL-019"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "New skill implementing documentation governance."
---

# Doc Checkpoint

Evaluates documentation state after task completion. Produces a prioritized checklist
of documentation updates needed based on what files changed.

## When to Use

- After multi-file tasks (3+ files changed)
- After delivering a roadmap item
- After adding/removing skills, commands, hooks, or agents
- When the `doc-stale-check` Stop hook fires a warning

## When NOT to Use

- Mid-task (wait until verification passes)
- Typo fixes, formatting-only changes
- Single-file refactors that don't change capabilities

## Quick Reference — Routing Table

| What changed | Update target |
|---|---|
| Skill/command/hook/agent added or removed | Project CLAUDE.md (tree + counts) |
| New behavioral rule | ~/CLAUDE.md |
| Architecture or plugin structure | Project CLAUDE.md |
| Factual state change | MEMORY.md |
| Roadmap item delivered | .ai/roadmap.yml |
| User-facing capability change | Plugin README.md |

## Output Format

YAML checklist with `required` / `recommended` / `optional` priority levels.
Each item has: target file, action, detail, priority.

## Execution — [references/process.md](references/process.md)
