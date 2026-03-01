---
name: verification-runner
description: >
  Orchestrates two-stage verification for completed waves. Stage 1 dispatches
  spec-compliance-reviewer (junior) for mechanical checks. Stage 2 dispatches
  qa-agent (principal) for quality review — only if Stage 1 passes. Use when
  running wave verification, dispatching checkpoint checks, validating completed
  waves, or re-checking after fixes.
model_tier: senior
---

# Verification Runner

> checkpoint: none (utility skill — called by plan-execute, not standalone)

Orchestrates two-stage verification for completed waves. Dispatches Stage 1
(spec compliance) first; only proceeds to Stage 2 (quality review) on pass.

## Context

- Reads: wave `verification` block from plan, task list, verification_profile,
  working directory, target skill SKILL.md frontmatter
- Writes: `verification_result` returned to caller; failed checks logged to
  `state.yml errors` with status `failed_spec` or `failed_quality`
- Checkpoint: none (utility skill)
- Dependencies: spec-compliance-reviewer (Stage 1), qa-agent (Stage 2)

## Two-Stage Flow

```
Stage 1: spec-compliance-reviewer (junior/Haiku)
  → FAIL → mark failed_spec, skip Stage 2, return fail
  → PASS → proceed to Stage 2 (if required)

Stage 2: qa-agent (principal/Opus)
  → FAIL → mark failed_quality, return fail
  → PASS_WITH_NOTES → mark passed_with_notes, return pass_with_warnings
  → PASS → mark complete, return pass
```

## Process Summary

1. **Receive input** — verification type, check strings, wave context
2. **Stage 1** — dispatch `spec-compliance-reviewer` with target skill's
   `writes` and `checkpoint` frontmatter. If fail → stop, log `failed_spec`
3. **Stage 2 gate** — check if quality review is required (wave.qa_review,
   qa_frequency, or final wave). If not required → mark complete, return pass
4. **Stage 2** — dispatch `qa-agent` with output files and plan context
5. **Produce verdict** — `pass` / `pass_with_warnings` / `fail`
6. **Log failures** — append to state.yml `errors` array; deduplicate;
   mark resolved on re-pass
7. **Handle re-runs** — max 3 rounds before escalating to `manual_approval`

## Execution

Read `references/process.md` for the complete dispatch table, per-method
procedures, output format, verdict rules, error-logging schema, and edge
cases (unknown types, unavailable tools, re-run logic).
