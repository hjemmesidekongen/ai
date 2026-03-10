---
name: completion-gate
description: >
  10-point quality gate run by the code-reviewer agent after implementation.
  Verifies spec compliance, lint, tests, security, and visual output. The
  implementing agent never runs this gate on its own work.
user_invocable: false
interactive: false
model_tier: senior
depends_on:
  - agent-dispatcher
triggers:
  - "completion gate"
  - "quality gate"
  - "verify completion"
  - "done check"
reads:
  - ".ai/tasks/dispatched/*.yml"
  - "project config (package.json, tsconfig, etc.)"
writes:
  - ".ai/tasks/gate-results/<task-id>.yml"
checkpoint:
  type: code_quality_gate
  required_checks:
    - name: "all_criteria_evaluated"
      verify: "All 10 gate criteria have a pass/fail/skip result with evidence"
      fail_action: "Run missing criteria checks"
    - name: "no_critical_failures"
      verify: "No criteria marked critical have failed"
      fail_action: "Return failures to implementing agent for fix"
    - name: "results_recorded"
      verify: "Gate results written to .ai/tasks/gate-results/<task-id>.yml"
      fail_action: "Write gate results file"
  on_fail: "Gate failed — return failures to agent, retry up to 2 times"
  on_pass: "Gate passed — task may be marked done"
_source:
  origin: "dev-engine"
  inspired_by: "agency/skills/dev/completion-gate/SKILL.md + D-020"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Expanded from agency 3-check gate to full 10-point criteria per D-020"
---

# Completion Gate

10-point quality verification. Run by the code-reviewer agent, never by the
implementing agent. A task is not done until all applicable criteria pass.

## The 10 Criteria

| # | Check | When to skip |
|---|-------|-------------|
| 1 | Spec compliance — matches original task description | Never |
| 2 | Lint passes | No linter configured |
| 3 | Type check passes | No type checker |
| 4 | Unit tests pass | No test runner |
| 5 | Integration tests pass | No integration tests |
| 6 | E2E tests pass | No E2E setup |
| 7 | New tests cover new behavior | No testable behavior added |
| 8 | Visual verification passes | Not a UI change |
| 9 | Security check — no new vulnerabilities | N/A |
| 10 | Code-reviewer sign-off | Never |

## Gate Flow

1. Receive completed subtask from agent-dispatcher.
2. Run each applicable criterion, collecting pass/fail + evidence.
3. If any critical criterion fails: return error to implementing agent.
4. Agent fixes, gate re-runs (max 2 retries).
5. If still failing after retries: mark failed, log, escalate.
6. All pass: write results, mark task as gate-passed.

See `references/process.md` for detailed criteria, evidence formats, and retry flow.
