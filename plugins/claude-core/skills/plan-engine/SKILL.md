---
name: plan-engine
description: >
  Converts a flat task list with dependencies into an optimized wave plan.
  Handles dependency resolution via topological sort, file-ownership conflict
  detection, model-tier assignment, and verification setup. Use when organizing
  tasks into parallel-safe execution waves, creating wave-based plans, resolving
  file-ownership conflicts between parallel agents, or assigning model tiers
  to tasks based on complexity.
user_invocable: false
interactive: false
depends_on: []
triggers:
  - "create plan"
  - "wave plan"
  - "task dependencies"
  - "parallel execution waves"
  - "file-ownership conflicts"
  - "break down work"
  - "organize tasks"
  - "dependency order"
  - "what can run in parallel"
reads: []
writes:
  - ".ai/plans/{name}/plan.yml"
  - ".ai/plans/{name}/plan.md"
  - ".ai/plans/{name}/state.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "plan_emitted"
      verify: "plan.yml written with at least 1 wave containing tasks"
      fail_action: "Re-run dependency resolution and wave assignment"
    - name: "no_file_conflicts"
      verify: "No two tasks in the same wave write to the same file"
      fail_action: "Re-run file-ownership conflict resolution"
    - name: "state_initialized"
      verify: "state.yml created with all tasks set to pending"
      fail_action: "Generate state.yml from plan.yml"
  on_fail: "Fix issues and re-run checkpoint"
  on_pass: "Report wave count, task count, and any resolved conflicts."
model_tier: principal
_source:
  origin: "claude-core"
  inspired_by: "task-planner/wave-decomposer + file-ownership"
  ported_date: "2026-03-08"
  iteration: 1
  changes: "Merged three skills into one. Simplified conflict resolution. Cleaner model-tier heuristics."
---

# plan-engine

Converts a flat task list with dependencies into an optimized wave plan.

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

## Input

Task list with: `id`, `name`, `depends_on`, `files_written`, `files_read`. Full algorithm: `references/process.md`.

## Output

Emits `.ai/plans/{name}/`: plan.yml (wave plan), plan.md (contract), state.yml (all pending).

## NEVER
- Put tasks with write-conflicts in the same wave
- Skip file-ownership check for parallel tasks
- Assign model_tier values outside junior/senior/principal
