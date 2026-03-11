---
name: smedjen-orchestrator
description: >
  Top-level pipeline orchestration for smedjen. Chains project-mapper,
  taskflow-bridge, task-decomposer, context-assembler, tier-assignment,
  agent-dispatcher, and completion-gate in sequence with skip conditions,
  dry-run mode, and per-stage error handling.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "orchestrate"
  - "full pipeline"
  - "run dev engine"
  - "execute task"
reads:
  - ".ai/tasks/active.yml"
  - ".ai/project-map.yml"
writes:
  - ".ai/tasks/pipeline-state.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "pipeline_state_written"
      verify: "pipeline-state.yml exists with status for every stage"
      fail_action: "Write pipeline state before reporting"
    - name: "no_skipped_required_stages"
      verify: "No required stage was skipped without a recorded skip reason"
      fail_action: "Record skip reason or re-run the stage"
    - name: "completion_gate_passed"
      verify: "completion-gate stage status is passed, not partial or failed"
      fail_action: "Do not mark pipeline done until gate passes"
  on_fail: "Pipeline incomplete — resolve stage failures before reporting done"
  on_pass: "Pipeline complete — all stages passed or legitimately skipped"
_source:
  origin: "smedjen"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Original skill, no port"
---

# Smedjen Orchestrator

Runs the full smedjen pipeline from task intake to verified completion. Each stage is independently tracked so the pipeline can resume after failure without re-running completed stages.

## Pipeline Sequence

| Stage | Skill | Skip condition |
|-------|-------|---------------|
| 1 | project-mapper | Scan cache exists and is < 24 hours old |
| 2 | taskflow-bridge | Always runs (fast detection; standalone if no taskflow) |
| 3 | task-decomposer | Decomposition already exists for this task revision |
| 4 | context-assembler | Assembled context exists for the same task-id |
| 5 | tier-assignment | Tier assignments exist for current decomposition |
| 6 | agent-dispatcher | All subtasks already dispatched and reported |
| 7 | completion-gate | Never skipped — must always run |

## Dry-Run Mode

Pass `--dry-run` to preview the pipeline plan without executing agents:

- Outputs which stages will run vs. skip and why.
- Shows the decomposition and tier assignments that would be used.
- Does not write to `.ai/tasks/dispatched/` or trigger any agent.

## Error Handling

- If any stage fails, write `status: failed` and `error:` to `pipeline-state.yml`.
- Do not proceed to the next stage on failure.
- Surface the blocker with a clear next step — never silently skip a failed stage.
- On resume, re-run from the failed stage (completed stages are not re-run).

See `references/process.md` for full stage specs, skip condition logic, dry-run output format, resume protocol, and pipeline configuration options.
