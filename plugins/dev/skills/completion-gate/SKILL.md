---
name: completion-gate
description: >
  Phase 3 quality gate for /dev:build — run build, lint, and related tests per
  completed task, return failures to agents while context is fresh, retry up to
  2 times with escalation, and record gate results in team-state.yml. Use when
  running post-agent quality checks, gating wave completion, verifying build
  integrity after agent dispatch, or checking lint and test status per task.
phase: 3
depends_on: [agent-dispatcher]
writes:
  - ".ai/dev/[project-name]/team-state.yml (execution.dispatched_tasks[].report)"
reads:
  - ".ai/dev/[project-name]/team-state.yml (execution.dispatched_tasks)"
  - ".ai/dev/[project-name]/dev-config.yml (commands section)"
model_tier: junior
interactive: false
checkpoint:
  type: code_quality_gate
  required_checks:
    - name: "build_passes"
      verify: "Build command exits with code 0 for all passed tasks"
      fail_action: "Return build errors to agent, re-dispatch for fix"
    - name: "lint_passes"
      verify: "Lint command exits with code 0 for all passed tasks"
      fail_action: "Return lint errors to agent, re-dispatch for fix"
    - name: "tests_pass"
      verify: "Related tests exit with code 0 for all passed tasks"
      fail_action: "Return test failures to agent, re-dispatch for fix"
    - name: "failures_logged"
      verify: "Any failed gates are logged to team-state.yml errors array"
      fail_action: "Write missing error entries to state.yml errors"
  on_fail: "Return failure to producing agent (max 2 retries). If still failing, log and escalate to code-review."
  on_pass: "Update team-state.yml report fields. At wave boundary, run full test suite."
---

# Completion Gate

Phase 3 quality gate for /dev:build. Runs build, lint, and related tests per completed task. Returns failures to agents while their context is fresh — catching errors here costs one fix instead of an investigation later.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | team-state.yml execution.dispatched_tasks, dev-config.yml commands |
| **Writes** | team-state.yml execution.dispatched_tasks[].report (build_passed, lint_passed, tests_passed) |
| **Checkpoint** | code_quality_gate: build passes, lint passes, tests pass, failures logged |
| **Dependencies** | agent-dispatcher (tasks must be dispatched and completed) |

## Gate Flow

1. Read `dev-config.yml` `commands` section — get `build`, `lint`, `test_related`, `test`
2. Read `team-state.yml` `execution.dispatched_tasks` — get completed tasks with `files_changed`
3. For each completed task:
   a. Run `commands.build` → record exit code
   b. Run `commands.lint` → record exit code
   c. Run `commands.test_related [files_changed]` → record exit code
   d. All pass (exit 0) → mark gate `passed`
   e. Any fail → return failure to producing agent (re-dispatch at same tier with error context)
   f. Agent fixes → re-run gate (max 2 retries)
   g. Still failing → mark `failed`, log to `team-state.yml` errors array
4. At wave boundary: run full test suite via `commands.test`
5. Update `team-state.yml` `execution.dispatched_tasks[].report` with gate booleans

## Findings Persistence

Write gate results to `.ai/dev/[project-name]/findings.md`.
**2-Action Rule:** After every 2 gate check runs, save results to findings.md immediately.

## Error Logging

When gate commands fail unexpectedly (command not found, timeout, permission denied):
1. Log to state.yml errors array: `{ timestamp, skill: "completion-gate", error, attempted_fix, result, next_approach }`
2. Check errors before retrying — never repeat a failed approach
3. The verification-runner logs checkpoint failures automatically
