---
name: plan-verifier
description: >
  Two-stage verification for completed plan waves. Stage 1 runs fast
  mechanical checks (file existence, schema, ownership). Stage 2 runs
  quality review. Logs failures to state.yml. Use when verifying completed
  waves before advancing to the next wave, checking if a wave passed spec
  compliance, running quality review on completed work, or diagnosing why
  a wave verification failed.
user_invocable: false
interactive: false
depends_on: []
triggers:
  - "verify wave"
  - "check wave complete"
  - "plan verification"
  - "spec compliance check"
  - "wave quality review"
reads:
  - ".ai/plans/{name}/plan.yml"
  - ".ai/plans/{name}/state.yml"
writes:
  - ".ai/plans/{name}/state.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "stage1_complete"
      verify: "Spec compliance checks all passed (file existence, schema, ownership)"
      fail_action: "Fix structural issues before proceeding to Stage 2"
    - name: "verdict_recorded"
      verify: "Verification result written to state.yml wave checkpoint"
      fail_action: "Write checkpoint result to state.yml"
  on_fail: "Fix issues and re-run checkpoint"
  on_pass: "Report stage 1/2 results and any warnings."
model_tier: principal
_source:
  origin: "claude-core"
  inspired_by: "task-planner/verification-runner + spec-compliance-reviewer + qa-agent"
  ported_date: "2026-03-08"
  iteration: 1
  changes: "Merged three components into one skill with two internal phases. Cleaner error logging."
---

# plan-verifier

Two-stage verification for completed plan waves. Stage 1 runs fast mechanical checks (spec compliance). Stage 2 runs quality review (only if Stage 1 passes). Logs all failures to state.yml for persistence across session breaks.

Use this skill when a wave has been completed and needs verification before the next wave can start. Called internally by `/plan:execute`.

## Two-stage flow

```
Stage 1: Spec Compliance (fast, mechanical)
  ├─ FAIL → log errors, skip Stage 2, return fail
  └─ PASS → proceed to Stage 2 (if qa_review flag is set)

Stage 2: Quality Review (slow, judgment-based)
  ├─ FAIL → log errors, return fail
  ├─ PASS_WITH_NOTES → log notes, return pass_with_warnings
  └─ PASS → return pass
```

## Process

See `references/process.md` for the full verification procedure.

## Output

Updates `state.yml`:
- Wave checkpoint with pass/fail and details
- Error entries for any failures (persistent, survives /compact)
