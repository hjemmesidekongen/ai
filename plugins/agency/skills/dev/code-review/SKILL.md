---
name: code-review
user-invocable: false
description: >
  Phase 4a of /agency:build — audit the full wave diff for code quality, pattern
  adherence, convention compliance, security (OWASP top 10), performance, and
  design token compliance. Rate findings by severity, block merge on critical
  issues, and write review report to project-state.yml. Use when reviewing agent
  output, running /agency:build phase 4, auditing wave diffs, checking code
  quality, validating security, or verifying design token usage in UI code.
phase: 4
depends_on: [completion-gate]
writes:
  - ".ai/projects/[name]/project-state.yml (review.code_review section)"
reads:
  - ".ai/projects/[name]/project-state.yml (execution.commit_range)"
  - ".ai/projects/[name]/dev/dev-config.yml (conventions section)"
  - ".ai/projects/[name]/knowledge/conventions.yml"
  - ".ai/projects/[name]/design/tokens/ (design token files)"
model_tier: senior
model: sonnet
interactive: false
checkpoint:
  type: data_validation
  required_checks:
    - name: "review_status"
      verify: "review.code_review.status is pending, passed, or failed"
      fail_action: "Set status based on findings — failed if criticals exist"
    - name: "files_covered"
      verify: "All changed files from the wave diff are covered in the review"
      fail_action: "Review uncovered files and add findings"
    - name: "finding_structure"
      verify: "Each finding has file (string), severity (critical/warning/info), message (non-empty)"
      fail_action: "Fix malformed findings — add missing fields"
    - name: "critical_blocks"
      verify: "If critical findings exist, status is failed (blocks QA)"
      fail_action: "Update status to failed when criticals present"
    - name: "timestamp_set"
      verify: "review.code_review.completed_at is set"
      fail_action: "Write current timestamp to completed_at"
    - name: "design_token_compliance"
      verify: "Changed UI files reference design tokens, no hardcoded color/spacing/font values"
      fail_action: "Flag hardcoded values as warning-level findings"
  on_fail: "Fix issues and re-run checkpoint. Critical findings block qa-validation."
  on_pass: "Update project-state.yml review section. Hand off to qa-validation."
---

# Code Review

Phase 4a of /agency:build. Audits the full wave diff for quality, patterns, security, convention compliance, and design token usage. Critical findings block QA until remediated.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | project-state.yml execution.commit_range, dev-config.yml conventions, knowledge/conventions.yml, design/tokens/ |
| **Writes** | project-state.yml review.code_review (status, findings, completed_at) |
| **Checkpoint** | data_validation: review status, files covered, finding structure, critical blocks, timestamp, design token compliance |
| **Dependencies** | completion-gate (build/lint/test must pass first) |

## Review Flow Summary

1. Read `execution.commit_range` from project-state.yml — get base_sha and head_sha
2. Run `git diff [base_sha]..[head_sha]` — get the full wave diff
3. Read `dev-config.yml` conventions + `knowledge/conventions.yml` for project rules
4. Load design tokens from `.ai/projects/[name]/design/tokens/` for token compliance checks
5. For each changed file, review 6 dimensions: quality, patterns, conventions, security, performance, design token compliance — see [references/review-dimensions.md](references/review-dimensions.md) for checklists
6. Rate each finding: critical (must fix), warning (should fix), info (suggestion)
7. Write `review.code_review` to project-state.yml — if criticals exist, status = "failed"

## Findings Persistence

Write review findings to `.ai/projects/[name]/findings.md`.
**2-Action Rule:** After every 2 files reviewed, save findings to findings.md immediately.

## Error Logging — Log errors to project-state.yml errors array. Check errors before retrying.

## Execution — [references/process.md](references/process.md)
