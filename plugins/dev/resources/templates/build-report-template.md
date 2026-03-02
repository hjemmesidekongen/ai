# Build Report: {{feature_name}}

## Build Summary

| Field | Value |
|-------|-------|
| **Feature** | {{feature_description}} |
| **Status** | {{status}} |
| **Build ID** | {{build_id}} |
| **Started** | {{started_at}} |
| **Completed** | {{completed_at}} |
| **Duration** | {{duration}} |

## Components Built

{{#each components}}
- **{{name}}** ({{type}}) — {{description}}
  - Files: {{files_affected}}
{{/each}}

## Agent Assignments

| Task | Agent | Tier | Status | Commit |
|------|-------|------|--------|--------|
{{#each tasks}}
| {{id}}: {{description}} | {{assigned_agent}} | {{model_tier}} | {{status}} | {{commit_sha}} |
{{/each}}

## Test Results

| Check | Result |
|-------|--------|
| **Build** | {{build_passed}} |
| **Lint** | {{lint_passed}} |
| **Tests** | {{tests_passed}} |
| **Type Check** | {{typecheck_passed}} |

## Code Review Findings

| File | Severity | Message |
|------|----------|---------|
{{#each findings}}
| {{file}}:{{line}} | {{severity}} | {{message}} |
{{/each}}

**Review Status:** {{code_review_status}} ({{reviewer_tier}})

## QA Validation

| Metric | Value |
|--------|-------|
| **Spec Alignment** | {{spec_alignment}}% |
| **PO Sign-off** | {{po_signoff}} |
| **Notes** | {{qa_notes}} |

## Blockers Encountered

{{#if blockers}}
{{#each blockers}}
- **{{task_id}}:** {{reason}} — {{resolution}}
{{/each}}
{{else}}
No blockers encountered.
{{/if}}

## Commit Range

- **Base SHA:** {{base_sha}}
- **Head SHA:** {{head_sha}}
- **Total Commits:** {{commit_count}}
