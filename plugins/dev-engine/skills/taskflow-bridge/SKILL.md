---
name: taskflow-bridge
description: >
  Bridge between dev-engine and taskflow. Uses active task context to enrich
  completion gate checks and map acceptance criteria to verifiable checks.
  If taskflow plugin is not installed, dev-engine operates standalone without
  task context.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "task context"
  - "taskflow integration"
  - "active task"
  - "bridge"
reads:
  - ".ai/tasks/active.yml"
  - "plugins/taskflow/.claude-plugin/plugin.json"
writes:
  - ".ai/tasks/bridge-context.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "taskflow_detection"
      verify: "taskflow install status resolved (installed or standalone mode recorded)"
      fail_action: "Re-run detection before proceeding"
    - name: "acceptance_criteria_mapped"
      verify: "Each acceptance criterion from active task maps to a completion gate check (or standalone noted)"
      fail_action: "Map all criteria before dispatching completion gate"
    - name: "bridge_context_written"
      verify: ".ai/tasks/bridge-context.yml written with task_id, criteria, and mode"
      fail_action: "Write bridge context file before handoff to completion gate"
  on_fail: "Bridge incomplete — resolve detection or mapping failures"
  on_pass: "Bridge context ready — completion gate can consume task criteria"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Original skill, no port"
---

# Taskflow Bridge

Connects dev-engine's execution pipeline to taskflow's task context. When taskflow is installed, active task acceptance criteria drive the completion gate. When it is not, dev-engine runs in standalone mode using only the agent-provided criteria.

## Detection

On each pipeline run, check whether taskflow is installed:

1. Look for `plugins/taskflow/.claude-plugin/plugin.json`.
2. If found: load `.ai/tasks/active.yml` and extract acceptance criteria.
3. If not found: log `mode: standalone` in bridge context and continue.

**If taskflow plugin is not installed, dev-engine operates standalone without task context.**

## Acceptance Criteria Mapping

When taskflow is active, each acceptance criterion becomes a typed completion check:

| Criterion type | Maps to completion gate check |
|---------------|-------------------------------|
| Functional | `verify: <behavior>` |
| Test coverage | `verify: test suite passes` |
| Output file | `verify: file exists at <path>` |
| No regressions | `verify: existing tests green` |

See `references/process.md` for detection logic, schema for bridge-context.yml, criteria mapping rules, and handling of partial task context.
