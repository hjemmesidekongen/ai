---
name: spec-compliance-reviewer
user-invocable: false
description: >
  Runs mechanical verification checks after a skill completes. Validates file
  existence, YAML schema presence, required fields, file-ownership compliance,
  and state.yml updates. Use as Stage 1 of two-stage verification before
  quality review. Triggers on checkpoint execution, verification step, spec
  compliance check, structural validation, or pre-QA gate.
model_tier: junior
writes:
  - "spec-compliance-report.yml"
reads:
  - "SKILL.md (target skill's frontmatter — outputs.writes, checkpoint)"
  - "state.yml"
  - "file-ownership map (from plan)"
checkpoint:
  type: none
  note: "Utility skill — produces reports consumed by verification-runner"
---

# Spec Compliance Reviewer

Stage 1 of two-stage verification. Runs fast, mechanical checks requiring only technical validation. If any check fails, Stage 2 (quality review) is skipped
and the skill is marked `failed_spec`.

## Context

- **Reads:** target skill's SKILL.md frontmatter (`writes`, `checkpoint`),
  output files on disk, state.yml, file-ownership map from plan
- **Writes:** structured compliance report (YAML) returned to caller
- **Checkpoint:** none (utility skill — called by verification-runner)
- **Model tier:** junior (Haiku) — all checks are mechanical

## Process Summary

1. Read the target skill's `writes` list from its SKILL.md frontmatter
2. Run 5 mechanical checks: file existence, schema presence, non-empty,
   file ownership, state consistency
3. Produce a structured report with per-check pass/fail and summary
4. Return report to caller — `pass` means Stage 2 can proceed;
   `fail` means skill is marked `failed_spec` immediately

## Output Format

```yaml
spec_compliance:
  skill: [skill-name]
  status: pass | fail
  checks:
    file_existence: { status: pass|fail, expected: [...], missing: [...] }
    schema_presence: { status: pass|fail, sections: {...} }
    non_empty: { status: pass|fail, empty_files: [...] }
    file_ownership: { status: pass|fail, violations: [...] }
    state_consistency: { status: pass|fail, current_state: "..." }
  summary: "All 5 checks passed" | "2 of 5 checks failed: ..."
```

## Execution

Before executing, read `references/process.md` for the detailed check
procedures and `references/check-templates.md` for per-checkpoint-type
checklists.
