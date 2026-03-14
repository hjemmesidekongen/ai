---
name: root-cause-debugging
description: >
  4-phase mandatory investigation protocol before any fix is attempted:
  Investigate → Pattern Analysis → Hypothesis → Implement. Prevents band-aid
  fixes by requiring evidence gathering, pattern identification, and a testable
  hypothesis before touching code. Includes escalation tree, anti-patterns
  (shotgun debugging, fix-and-pray, symptom fixation), symptom-to-tool mapping,
  and framework-aware debugging references. If 3+ fixes fail, escalate to
  architecture review. Use when diagnosing a bug or unexpected behavior, when
  a quick fix isn't working and the problem keeps returning, when a test is
  failing and the cause isn't immediately obvious, when a system behaves
  differently than expected, or when debugging any framework-specific issue
  (load the relevant tech skill's references/debugging.md for framework detail).
user_invocable: false
interactive: false
depends_on: [verification-gate]
triggers:
  - "root cause analysis"
  - "bug keeps returning"
  - "investigate failure"
  - "band-aid fix failing"
  - "unexpected behavior"
  - "debug"
  - "investigate bug"
  - "systematic debugging"
reads:
  - "logs, stack traces, error output (context-dependent)"
writes: []
checkpoint:
  type: code_validation
  required_checks:
    - name: "evidence_gathered"
      verify: "All available evidence collected before hypothesis formed (logs, traces, recent changes)"
      fail_action: "Gather more evidence — do not hypothesize from incomplete data"
    - name: "hypothesis_stated"
      verify: "A specific, testable hypothesis was stated: 'The cause is X, therefore Y will happen'"
      fail_action: "Restate hypothesis with a concrete prediction that can be verified"
    - name: "fix_verified"
      verify: "Fix was verified with verification-gate protocol (proof command run, output read)"
      fail_action: "Run verification-gate before claiming fixed"
    - name: "not_band_aid"
      verify: "Fix addresses the root cause, not just the symptom"
      fail_action: "Trace from symptom to root cause before implementing"
  on_fail: "Return to investigation phase. Do not implement until hypothesis is solid."
  on_pass: "Root cause identified, fix verified. Document what was found and why."
model_tier: senior
_source:
  origin: "kronen"
  inspired_by: "superpowers repo — root-cause-first debugging pattern"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Adapted 4-phase protocol + supporting techniques to kronen skill format"
---

# root-cause-debugging

No fix before understanding. Symptoms are not root causes.

## 4-Phase Protocol

```
Phase 1: INVESTIGATE  — gather all evidence before forming opinions
Phase 2: PATTERN      — find what the evidence has in common
Phase 3: HYPOTHESIS   — state a specific, testable cause + prediction
Phase 4: IMPLEMENT    — fix the root cause, verify with verification-gate
```

## Escalation Rule

If 3 or more fixes fail to resolve the problem: **stop**. The architecture
may be wrong. Surface the pattern to the user before attempting more fixes.

## Process

See `references/process.md` for the full investigation methodology,
root-cause tracing technique, defense-in-depth layers, and
condition-based waiting pattern.
