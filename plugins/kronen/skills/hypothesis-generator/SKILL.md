---
name: hypothesis-generator
description: >
  Generate three competing hypotheses for a debugging problem, then investigate
  each in parallel and synthesize evidence to identify the root cause. Extends
  root-cause-debugging with structured hypothesis management. Use when a bug's
  root cause is unclear after initial evidence gathering, when a previous fix
  failed and the cause is still unknown, when multiple subsystems could plausibly
  be at fault, or when confirmation bias in investigation needs to be avoided.
user_invocable: false
interactive: false
depends_on: [root-cause-debugging]
triggers:
  - "hypothesis"
  - "parallel investigation"
  - "3 hypotheses"
  - "competing theories"
  - "confirmation bias"
reads:
  - "logs, error output, stack traces (context-dependent)"
writes: []
checkpoint:
  type: code_validation
  required_checks:
    - name: "three_hypotheses_stated"
      verify: "Exactly three distinct hypotheses stated, each with cause/mechanism/prediction/test"
      fail_action: "Generate all three before investigating any single one"
    - name: "hypotheses_distinct"
      verify: "Each hypothesis has a different root cause — not just different symptoms"
      fail_action: "Revise so hypotheses target different causal mechanisms"
    - name: "evidence_synthesized"
      verify: "All three investigations complete before selecting root cause"
      fail_action: "Complete all three investigations before committing to a fix"
    - name: "confirmed_hypothesis"
      verify: "One hypothesis scored CONFIRMED before entering Phase 4"
      fail_action: "If none confirmed, return to Phase 1 for more evidence"
  on_fail: "Do not proceed to Phase 4 until synthesis is complete."
  on_pass: "Root cause confirmed by hypothesis elimination. Proceed to fix."
model_tier: senior
_source:
  origin: "kronen"
  inspired_by: "agents-main + superpowers-main systematic-debugging"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "3-hypothesis parallel investigation methodology. Structured extension to root-cause-debugging's 4-phase protocol. Evidence synthesis with scoring (CONFIRMED/POSSIBLE/REFUTED)."
---

# hypothesis-generator

Generate three competing hypotheses, investigate each, synthesize — then fix.
Eliminates confirmation bias by forcing investigation of alternative causes.

## When to use

After Phase 1 of root-cause-debugging when evidence doesn't clearly point to
one cause. Do NOT use for obvious bugs — only when genuinely uncertain.

## 3-Hypothesis Protocol

```
After evidence gathering:

  Hypothesis A: most obvious explanation
  Hypothesis B: different mechanism, same symptom
  Hypothesis C: deeper/systemic cause (the non-obvious one)

  Each needs: Cause | Mechanism | Prediction | Test

Investigate all three (parallel if possible)
Score each: CONFIRMED / POSSIBLE / REFUTED
Synthesize → select confirmed hypothesis → enter Phase 4
```

## Synthesis Rules

One confirmed → Phase 3 hypothesis. Two confirmed → find unifying root cause.
All refuted → return to Phase 1. All possible → run most discriminating test.

Full process: `root-cause-debugging/references/process.md` — Hypothesis-Driven Extension.
