---
name: plan-engine
description: >
  Converts a flat task list with dependencies into an optimized wave plan.
  Handles dependency resolution via topological sort, file-ownership conflict
  detection, model-tier assignment, and verification setup. Use when organizing
  tasks into parallel-safe execution waves or creating wave-based plans.
user_invocable: false
interactive: false
depends_on: []
reads: []
writes:
  - ".ai/plans/{name}/plan.yml"
  - ".ai/plans/{name}/state.yml"
checkpoint: data_validation
model_tier: principal
_source:
  origin: "claude-core"
  inspired_by: "task-planner/wave-decomposer + file-ownership"
  iteration: 1
  changes: "Merged three skills into one. Simplified conflict resolution. Cleaner model-tier heuristics."
---

# plan-engine

Converts a flat task list with dependencies into an optimized wave plan. Handles dependency resolution, file-ownership conflict detection, model-tier assignment, and verification setup in a single pass.

Use this skill when a set of tasks needs to be organized into parallel-safe execution waves with proper dependency ordering, file isolation, and verification gates.

## When to trigger

- `/plan:create` command is invoked
- A task list with dependencies needs wave decomposition
- Multiple agents will work in parallel and need file-ownership isolation

## What it does

1. **Dependency resolution** — topological sort into waves
2. **File-ownership isolation** — detect and resolve write conflicts within waves
3. **Model-tier assignment** — assign junior/senior/principal based on task complexity
4. **Verification setup** — assign verification type and checks per wave
5. **Emit plan.yml** — conforming to `resources/plan-schema.yml`

## Process

See `references/process.md` for the full algorithm with worked examples.

## Input

A task list (provided inline or as a file) with:
- `id`, `name`, `depends_on`, `files_written`, `files_read`

## Output

- `.ai/plans/{name}/plan.yml` — the wave plan
- `.ai/plans/{name}/state.yml` — execution state (all pending)
