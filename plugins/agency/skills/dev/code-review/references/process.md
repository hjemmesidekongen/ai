# Code Review — Detailed Process

Phase 4a of /agency:build. Audits the full wave diff for quality, patterns, security, convention compliance, and design token usage. Critical findings block QA until fixed.

## Step 1: Load Review Context

```
Read project-state.yml → execution.commit_range (base_sha, head_sha)
Read dev-config.yml → conventions (naming, imports, file organization)
Read knowledge/conventions.yml → project-specific patterns (if exists)
Read design/tokens/ → token files (if exists) — used for dimension f checks

Run: git diff [base_sha]..[head_sha] --name-only → list of changed files
Run: git diff [base_sha]..[head_sha] → full diff content
```

**Save file list and context summary to findings.md (2-Action Rule checkpoint).**

## Step 2: Review Each Changed File

For each changed file, assess 6 dimensions:

| # | Dimension | Scope |
|---|-----------|-------|
| a | Code Quality | readability, function size <50 lines, nesting <4, file size <800, dead code |
| b | Pattern Adherence | conventions.yml, repository pattern, service layer, error handling, API format |
| c | Convention Compliance | naming, import order, file org, no console.log, no hardcoded values |
| d | Security (OWASP Top 10) | SQL injection, XSS, auth bypass, hardcoded secrets, CSRF, input validation, error leaking |
| e | Performance | N+1 queries, unnecessary re-renders, missing indexes, large payloads, sync blocking |
| f | Design Token Compliance | UI files only — no hardcoded colors/spacing/typography; skip if tokens dir absent |

**Save findings after every 2 files reviewed (2-Action Rule checkpoint).**

## Step 3: Rate and Classify Findings

| Severity | Meaning | Action |
|----------|---------|--------|
| **critical** | Must fix before merge | Blocks QA — returned to producing agent for fix |
| **warning** | Should fix — degrades quality | Logged for attention, does not block merge |
| **info** | Suggestion for improvement | Optional — noted for learning |

## Step 4: Write Review Report

Write `review.code_review` to project-state.yml:

```yaml
review:
  code_review:
    status: "passed | failed"  # failed if any critical findings
    reviewer_tier: "senior"
    files_reviewed:
      - "path/to/file.ts"
    findings:
      - file: "src/api/auth.ts"
        severity: "critical"
        message: "SQL injection: user input concatenated into query on line 42"
        line: 42
    summary:
      total_files: 12
      total_findings: 6
      critical: 1
      warnings: 3
      info: 2
      design_token_violations: 1
    completed_at: "2025-01-15T10:30:00Z"
```

**Decision logic:** critical > 0 → status "failed" (blocks qa-validation), else "passed".
Also update: `build.current_phase` → 4, `meta.updated_at` → current timestamp.
**Save final report to findings.md (2-Action Rule checkpoint).**

## Step 5: Handle Critical Findings

1. Set `review.code_review.status = "failed"`
2. For each critical finding: identify producing agent from `execution.dispatched_tasks`, create remediation task (`FIX-[task_id]`), re-dispatch via agent-dispatcher
3. After fix: re-run review on fixed files only — if no criticals, update to "passed"; if still critical, escalate tier or present to user

---

> **Extended reference:** See [references/review-dimensions.md](review-dimensions.md) for dimension checklists, severity examples, two-stage verification protocol, error scenarios, and commit protocol.

---

## Trace Protocol

If `state.yml` has `trace.enabled: true`, follow the
[trace protocol](../../../../resources/trace-protocol.md) to write a structured
trace file to `.ai/projects/[name]/traces/`.
