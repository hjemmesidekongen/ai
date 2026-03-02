---
name: qa-validation
user-invocable: false
description: >
  Phase 4b of /dev:build — QA Expert validates build against original spec,
  PO checks end-goal alignment, calculates spec alignment score (0-100),
  and generates the build report. Use when running /dev:build phase 4b,
  validating build completeness, checking spec alignment, generating build
  reports, or performing PO sign-off assessment.
phase: 4
depends_on: [code-review]
writes:
  - ".ai/dev/[project-name]/team-state.yml (review.qa_validation section)"
  - ".ai/dev/[project-name]/build-report.md"
reads:
  - ".ai/dev/[project-name]/team-state.yml (decomposition, execution, review.code_review)"
  - ".ai/dev/[project-name]/dev-config.yml"
  - "plugins/dev/resources/templates/build-report-template.md"
model_tier: principal
interactive: false
checkpoint:
  type: data_validation
  required_checks:
    - name: "spec_alignment_score"
      verify: "review.qa_validation.spec_alignment is a number 0-100"
      fail_action: "Calculate score from components implemented vs specified"
    - name: "po_signoff"
      verify: "review.qa_validation.po_signoff is approved or revisions_needed"
      fail_action: "Run PO assessment against original feature description"
    - name: "build_report"
      verify: "build-report.md exists with at least 8 sections"
      fail_action: "Generate build report from build-report-template.md"
    - name: "low_alignment_fails"
      verify: "If spec_alignment < 70, status is failed with gaps listed in notes"
      fail_action: "Set status to failed and list specific unimplemented components"
    - name: "timestamp_set"
      verify: "review.qa_validation.completed_at is set"
      fail_action: "Write current timestamp to completed_at"
  on_fail: "Fix issues and re-run checkpoint. Low alignment blocks build completion."
  on_pass: "Update team-state.yml review section. Build is complete."
---

# QA Validation

Phase 4b of /dev:build. QA Expert validates the build against the original spec, PO assesses end-goal alignment, and a comprehensive build report is generated.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | team-state.yml decomposition + execution + code_review, build-report-template.md |
| **Writes** | team-state.yml review.qa_validation, build-report.md |
| **Checkpoint** | data_validation: spec alignment score, PO sign-off, build report, low alignment fails, timestamp |
| **Dependencies** | code-review (must pass first — no criticals) |

## QA Flow Summary

1. Read `decomposition` from team-state.yml — the original spec (components, boundaries, files)
2. Read `execution.dispatched_tasks` — all subagent reports (files_changed, gate results)
3. Read `review.code_review` — findings and status from Phase 4a
4. Read `build.feature_description` — user's original intent
5. QA Assessment — per component: task exists? files match? gates pass? criticals?
6. Calculate spec alignment: `(implemented / total) × quality_factor`
7. PO Assessment — dispatch PO subagent: goal achieved? scope deviations? sign-off
8. Generate build report from `build-report-template.md`
9. Write `review.qa_validation` to team-state.yml

## Findings Persistence

Write QA findings to `.ai/dev/[project-name]/findings.md`.
**2-Action Rule:** After every 2 component assessments, save findings to findings.md immediately.

## Error Logging — Log errors to state.yml errors array. Check errors before retrying.

## Execution — [references/process.md](references/process.md)
