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

## Dispatch Mode

In **subagent mode** (default), both stages dispatch via `Task()`:

- **Stage 1:** Fill `resources/prompts/spec-review-dispatch.md` template with
  task definitions, implementer reports, and base_sha..commit_sha. Dispatch as
  Haiku subagent. Collect `spec_compliance` YAML report.
- **Stage 2:** Fill `resources/prompts/quality-review-dispatch.md` template with
  wave summary, commit range, and Stage 1 report. Dispatch as Opus subagent.
  Collect `qa_report` YAML report.

In **inline mode**, both stages run in the current session (legacy behavior).

## Process Summary

1. **Receive input** — verification type, check strings, wave context,
   task_complete reports (subagent mode), commit range
2. **Stage 1** — dispatch `spec-compliance-reviewer` via Task() (haiku) with
   task reports and git SHAs. If fail → stop, log `failed_spec`
3. **Stage 2 gate** — check if quality review is required (wave.qa_review,
   qa_frequency, or final wave). If not required → mark complete, return pass
4. **Stage 2** — dispatch `qa-agent` via Task() (opus) with commit range and
   Stage 1 report
5. **Produce verdict** — `pass` / `pass_with_warnings` / `fail`
6. **Log failures** — append to state.yml `errors` array; deduplicate;
   mark resolved on re-pass
7. **Handle re-runs** — max 3 rounds before escalating to `manual_approval`

## Execution

Read `references/process.md` for the complete dispatch table, per-method
procedures, output format, verdict rules, error-logging schema, and edge
cases (unknown types, unavailable tools, re-run logic).
