---
name: reasoning-trace-optimizer
description: >
  Analyzes agent reasoning patterns in trace-light.log to detect context
  degradation, tool confusion, instruction drift, goal abandonment, circular
  reasoning, and premature conclusions. Produces a diagnosis with specific
  patterns found and a fix recommendation. Use when an agent session is
  underperforming, when repeated tool calls aren't making progress, when an
  agent seems to have lost track of its goal, when debugging why a plan
  stalled or looped, or when reviewing a completed session for quality issues.
user_invocable: false
interactive: false
depends_on: []
triggers:
  - "context degradation"
  - "tool confusion"
  - "reasoning quality"
  - "agent drift"
  - "circular reasoning"
  - "session analysis"
reads:
  - ".ai/traces/trace-light.log"
writes:
  - ".ai/traces/reasoning-diagnosis.md"
checkpoint:
  type: data_validation
  required_checks:
    - name: "patterns_identified"
      verify: "At least one pattern category was checked (even if none found)"
      fail_action: "Run through all 6 pattern checks before reporting"
    - name: "diagnosis_written"
      verify: "reasoning-diagnosis.md written with findings and recommendations"
      fail_action: "Write diagnosis file before reporting complete"
    - name: "actionable_output"
      verify: "Each finding includes a specific fix recommendation"
      fail_action: "Add concrete fix for every pattern found — no bare problem reports"
  on_fail: "Complete all pattern checks and write diagnosis file before finishing."
  on_pass: "Diagnosis complete. Findings written to .ai/traces/reasoning-diagnosis.md."
model_tier: senior
_source:
  origin: "kronen"
  inspired_by: "Agent-Skills-for-Context-Engineering-main — interleaved-thinking skill"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Adapted pattern detection methodology to trace-light.log format. Added 6-category degradation taxonomy and fix recommendations."
---

# reasoning-trace-optimizer

Diagnoses agent reasoning quality by scanning trace-light.log for structural
failure patterns. Surfaces what went wrong and how to fix it.

## When to run

- After a session that didn't complete its goal
- When a plan stalled and the cause is unclear
- When reviewing a session to extract improvement patterns
- Before running instinct-extractor on a suspicious session

## 6 Pattern Categories

See `references/process.md` for full detection criteria and fix recommendations.

| Pattern | Signal | Severity |
|---------|--------|---------|
| Context degradation | Repeated reads of same files, increasing error rate | high |
| Tool confusion | Wrong tool for task, tool retries without adaptation | medium |
| Instruction drift | Actions diverging from original task description | high |
| Goal abandonment | Task incomplete, agent stops without explicit block | critical |
| Circular reasoning | Same investigation steps repeated 2+ times | medium |
| Premature conclusion | Claimed done before verification-gate ran | high |

## Output

Writes `references/process.md`-defined diagnosis to `.ai/traces/reasoning-diagnosis.md`.
