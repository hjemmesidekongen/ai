---
name: verification-runner
description: >
  Dispatches verification checks for completed waves and returns a structured
  verdict. Use when running wave verification, dispatching checkpoint checks,
  validating completed waves, or re-checking after QA fixes.
---

# Verification Runner

> checkpoint: none (utility skill — called by other skills/commands, not executed standalone)

Dispatches verification checks for completed waves. Takes a verification type
and a list of checks from the plan, runs each check using the appropriate
method, and returns a structured verdict.

## Context

- Reads: wave `verification` block from plan (type + checks), task list, verification_profile, working directory
- Writes: `verification_result` returned to caller; failed checks logged to `state.yml errors`
- Checkpoint: none (utility skill)
- Dependencies: none

## Process Summary

1. **Receive input** — verification type, check strings, wave context
2. **Dispatch** — look up type in `resources/verification-registry.yml` and route to the matching method
3. **Execute checks** — run each check per method: `data_validation` (read + inspect YAML), `file_validation` (Glob + Bash), `schema_validation` (parse + cross-reference), `accessibility_validation` (contrast ratios + WCAG), `manual_approval` (present to user), or domain stubs (`web_lint`, `web_build`, `web_test`, `seo_audit`)
4. **Produce verdict** — `pass` / `pass_with_warnings` / `fail`; `fail` blocks wave advancement
5. **Log failures to state.yml** — append to `errors` array; deduplicate; mark resolved on re-pass
6. **Handle re-runs** — on re-check, only re-run previously failed checks; max 3 rounds before escalating to `manual_approval`

## Execution

Read `references/process.md` for the complete dispatch table, per-method
procedures, output format, verdict rules, error-logging schema, and edge cases
(unknown types, unavailable tools, re-run logic).
