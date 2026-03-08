---
name: plan-verifier
description: >
  Two-stage verification for completed plan waves. Stage 1 runs fast
  mechanical checks (file existence, schema, ownership). Stage 2 runs
  quality review. Logs failures to state.yml. Use when verifying completed
  waves before advancing to the next wave.
user_invocable: false
interactive: false
depends_on: []
reads:
  - ".ai/plans/{name}/plan.yml"
  - ".ai/plans/{name}/state.yml"
writes:
  - ".ai/plans/{name}/state.yml"
checkpoint: data_validation
model_tier: principal
_source:
  origin: "claude-core"
  inspired_by: "task-planner/verification-runner + spec-compliance-reviewer + qa-agent"
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
