---
name: wave-decomposer
description: >
  Converts a flat task list with dependencies into an optimized wave plan.
  Use when creating wave plans, decomposing tasks into waves, running
  /plan:create, or optimizing task parallelism.
---

# Wave Decomposer

Takes a flat list of tasks with dependencies and produces an optimized wave
plan that maximizes parallelism while respecting dependency ordering and
file-ownership constraints.

## Context

- Reads: task list provided by the consuming plugin (ids, depends_on, files_written, files_read)
- Writes: wave plan conforming to `resources/plan-schema.yml`
- Checkpoint: none (utility skill — called by /plan:create, not standalone)
- Dependencies: none

## Process Summary

1. **Dependency resolution** — topological sort assigns tasks to waves; detect cycles
2. **File-ownership conflict check** — find overlapping `files_written` within each wave; move conflicting tasks to the next wave
3. **Set parallel flag** — `parallel: true` when wave has multiple conflict-free tasks
4. **Compute wave dependencies** — `depends_on_waves` derived from task dependency graph
5. **Assign verification** — pick type from profile or infer from `files_written` patterns; generate concrete checks
6. **Assign model tier** — `junior` / `senior` / `principal` / `self` per task based on difficulty, risk, domain-specialist signals, and name heuristics
7. **Set QA review flag** — final wave always `qa_review: true`; profile may enable every-wave QA
8. **Emit plan** — output full plan in `plan-schema.yml` format; all statuses `pending`

## Execution

Read `references/process.md` for the complete algorithm, overlap detection
rules, model-tier assignment heuristics, output format, worked examples, and
error cases.
