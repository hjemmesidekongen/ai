---
name: systematic-debugging
description: >
  4-phase debugging protocol: gather evidence, identify patterns, form hypotheses,
  validate fix. Prevents band-aid fixes by requiring root cause understanding.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "debug"
  - "investigate bug"
  - "root cause"
  - "systematic debugging"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "evidence_gathered"
      verify: "Error logs, stack traces, and reproduction steps documented"
      fail_action: "Gather evidence before forming hypotheses"
    - name: "root_cause_identified"
      verify: "Root cause is stated with supporting evidence"
      fail_action: "Keep investigating — no fix without root cause"
    - name: "fix_validated"
      verify: "Fix addresses root cause and regression test exists"
      fail_action: "Add regression test covering the root cause"
  on_fail: "Debugging incomplete — follow the protocol"
  on_pass: "Root cause found and validated with regression test"
_source:
  origin: "dev-engine"
  inspired_by: "claude-core root-cause-debugging"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Adapted from claude-core 4-phase protocol for general dev use"
---

# systematic-debugging

4-phase protocol for finding and fixing root causes. Do not write a fix until phase 3 is complete.

## Phases

**Phase 1 — Gather Evidence**
Collect logs, stack traces, error messages, and reproduction steps before touching code.
Document exact inputs, environment, and the observed vs. expected behavior.

**Phase 2 — Identify Patterns**
Look for what changed, what correlates, and what scope is affected.
Use binary search (git bisect, commenting out code) to narrow the blast radius.
Ask: is this deterministic or intermittent? Specific input or general?

**Phase 3 — Form and Test Hypotheses**
State the root cause as a falsifiable claim. Generate 2–3 competing hypotheses.
Test the cheapest hypothesis first. Eliminate before you commit.

**Phase 4 — Validate the Fix**
The fix must address the root cause — not just suppress the symptom.
Write a regression test that reproduces the original failure before patching.
Verify the test passes with the fix and fails without it.

## Escalation Decision Tree

- Cannot reproduce → document conditions, add logging, revisit with more data
- Reproduced but cause unclear → go deeper in phase 2 (binary search, isolate subsystem)
- Root cause found but fix is high-risk → flag for review before shipping
- Recurring bug class → promote to architectural fix, not point patch

## Common Traps

- **Confirmation bias**: testing only the hypothesis you already believe
- **Shotgun debugging**: changing multiple things at once — makes causality impossible to determine
- **Fix-and-pray**: shipping a change without a regression test
- **Symptom fixation**: silencing the error log instead of fixing the cause
- **Premature escalation**: asking for help before exhausting phase 1 evidence

See `references/process.md` for detailed phase walkthroughs, tooling guidance, and anti-pattern examples.
