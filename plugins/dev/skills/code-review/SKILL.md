---
name: code-review
description: >
  Phase 4a of /dev:build — audit the full wave diff for code quality, pattern
  adherence, convention compliance, security (OWASP top 10), and performance.
  Rate findings by severity, block merge on critical issues, and write review
  report to team-state.yml. Use when reviewing agent output, running /dev:build
  phase 4, auditing wave diffs, checking code quality, or validating security.
phase: 4
depends_on: [completion-gate]
writes:
  - "~/.claude/dev/[project-name]/team-state.yml (review.code_review section)"
reads:
  - "~/.claude/dev/[project-name]/team-state.yml (execution.commit_range)"
  - "~/.claude/dev/[project-name]/dev-config.yml (conventions section)"
  - "~/.claude/dev/[project-name]/knowledge/conventions.yml"
model_tier: senior
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
  on_fail: "Fix issues and re-run checkpoint. Critical findings block qa-validation."
  on_pass: "Update team-state.yml review section. Hand off to qa-validation."
---

# Code Review

Phase 4a of /dev:build. Audits the full wave diff for quality, patterns, security, and convention compliance. Critical findings block QA until remediated.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | team-state.yml execution.commit_range, dev-config.yml conventions, knowledge/conventions.yml |
| **Writes** | team-state.yml review.code_review (status, findings, completed_at) |
| **Checkpoint** | data_validation: review status, files covered, finding structure, critical blocks, timestamp |
| **Dependencies** | completion-gate (build/lint/test must pass first) |

## Review Flow Summary

1. Read `execution.commit_range` from team-state.yml — get base_sha and head_sha
2. Run `git diff [base_sha]..[head_sha]` — get the full wave diff
3. Read `dev-config.yml` conventions + `knowledge/conventions.yml` for project rules
4. For each changed file, review 5 dimensions: quality, patterns, conventions, security, performance
5. Rate each finding: critical (must fix), warning (should fix), info (suggestion)
6. Write `review.code_review` to team-state.yml — if criticals exist, status = "failed"

## Findings Persistence

Write review findings to `~/.claude/dev/[project-name]/findings.md`.
**2-Action Rule:** After every 2 files reviewed, save findings to findings.md immediately.

## Error Logging — Log errors to state.yml errors array. Check errors before retrying.

## Execution — [references/process.md](references/process.md)
