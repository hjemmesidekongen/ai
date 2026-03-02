# Code Review — Detailed Process

## Overview

The code reviewer is Phase 4a of /dev:build. It audits the full wave diff —
every file changed by every agent in the wave — for quality, patterns, security,
and convention compliance. Critical findings block QA until fixed.

## Prerequisites

Before starting, verify:
1. `~/.claude/dev/[project-name]/team-state.yml` has `execution.commit_range` with both `base_sha` and `head_sha`
2. All tasks in the wave have completion-gate status `passed` (build/lint/test passed)
3. `dev-config.yml` exists with a conventions section
4. If commit_range is missing, report error and suggest running agent-dispatcher first

## Step 1: Load Review Context

```
Read team-state.yml → execution.commit_range (base_sha, head_sha)
Read dev-config.yml → conventions (naming, imports, file organization)
Read knowledge/conventions.yml → project-specific patterns (if exists)

Run: git diff [base_sha]..[head_sha] --name-only → list of changed files
Run: git diff [base_sha]..[head_sha] → full diff content
```

**Save file list and context summary to findings.md (2-Action Rule checkpoint).**

## Step 2: Review Each Changed File

For each changed file in the diff, assess 5 dimensions:

### a. Code Quality
- **Readability:** Clear variable/function names, no cryptic abbreviations
- **Function size:** Functions should be < 50 lines
- **Nesting depth:** No more than 4 levels of nesting
- **File size:** Files should be < 800 lines (< 400 preferred)
- **Dead code:** No commented-out code blocks, unused imports, or unreachable branches

### b. Pattern Adherence
- Does the code follow patterns documented in `knowledge/conventions.yml`?
- Repository pattern: data access uses the repository interface (`findAll`, `findById`, etc.)
- Service layer: business logic in services, not in controllers/handlers
- Error handling: follows project error handling conventions (catch, log context, throw user-friendly)
- API responses: uses the project's standard response format (if defined in dev-config.yml)

### c. Convention Compliance
- **Naming:** camelCase/snake_case/PascalCase per project convention in dev-config.yml
- **Import ordering:** follows project import order (stdlib → deps → internal)
- **File organization:** matches project structure from dev-config.yml key_directories
- **No console.log:** debugging statements removed before commit
- **No hardcoded values:** constants or env vars used instead

### d. Security (OWASP Top 10)
- **SQL Injection:** Are queries parameterized? Any string concatenation in SQL?
- **XSS:** Is HTML output sanitized? Any `dangerouslySetInnerHTML` or unescaped user input?
- **Auth bypass:** Is authentication middleware present on protected routes?
- **Hardcoded secrets:** Any API keys, passwords, tokens in source code?
- **CSRF:** Is CSRF protection enabled on state-changing endpoints?
- **Input validation:** Is user input validated at system boundaries (Zod, joi, etc.)?
- **Error leaking:** Do error messages expose internal paths, stack traces, or DB schemas?

### e. Performance
- **N+1 queries:** Database calls inside loops without batching
- **Unnecessary re-renders:** Missing React.memo/useMemo/useCallback where beneficial
- **Missing indexes:** Queries on non-indexed columns (check if new columns need indexes)
- **Large payloads:** Fetching entire records when only a few fields are needed
- **Synchronous blocking:** CPU-intensive operations on the main thread

**Save findings after every 2 files reviewed (2-Action Rule checkpoint).**

## Step 3: Rate and Classify Findings

Each finding gets a severity level:

| Severity | Meaning | Action |
|----------|---------|--------|
| **critical** | Must fix before merge | Blocks QA — returned to producing agent for fix |
| **warning** | Should fix — degrades quality | Logged for attention, does not block merge |
| **info** | Suggestion for improvement | Optional — noted for learning |

**Critical finding examples:**
- SQL injection vulnerability (unparameterized query)
- Hardcoded API key or secret
- Missing auth on a protected endpoint
- Unhandled null that causes runtime crash

**Warning finding examples:**
- Function exceeds 50 lines
- Missing error handling on external API call
- Inconsistent naming convention
- Missing input validation on user-facing endpoint

**Info finding examples:**
- Opportunity to extract a reusable helper
- Minor naming improvement suggestion
- Alternative algorithm with better time complexity

## Step 4: Write Review Report

Write `review.code_review` to team-state.yml:

```yaml
review:
  code_review:
    status: "passed | failed"  # failed if any critical findings
    reviewer_tier: "senior"    # actual tier used
    files_reviewed:
      - "path/to/file.ts"
    findings:
      - file: "src/api/auth.ts"
        severity: "critical"
        message: "SQL injection: user input concatenated into query on line 42"
        line: 42
      - file: "src/components/Header.tsx"
        severity: "warning"
        message: "Function renderNavItems exceeds 50 lines (67 lines)"
        line: 15
      - file: "src/utils/format.ts"
        severity: "info"
        message: "Consider extracting date formatting into a shared utility"
        line: 8
    summary:
      total_files: 12
      total_findings: 5
      critical: 1
      warnings: 2
      info: 2
    completed_at: "2025-01-15T10:30:00Z"
```

**Decision logic:**
- If `critical > 0`: set status to `"failed"` — this blocks qa-validation
- If `critical == 0`: set status to `"passed"` — proceed to qa-validation

Also update:
- `build.current_phase` → 4 (review phase)
- `meta.updated_at` → current timestamp

**Save final report to findings.md (2-Action Rule checkpoint).**

## Step 5: Handle Critical Findings

When critical findings are found:

```
1. Set review.code_review.status = "failed"
2. For each critical finding:
   a. Identify which agent produced the file (from execution.dispatched_tasks)
   b. Create a remediation task:
      - task_id: "FIX-[original_task_id]"
      - description: "[finding message] in [file]"
      - files_owned: [the affected file]
      - model_tier: same as original agent (or escalated)
   c. Return to agent-dispatcher for re-dispatch
3. After agent fixes:
   a. Re-run code review on the fixed files only
   b. If no more criticals: update status to "passed"
   c. If still critical: escalate tier or present to user
```

## Commit Protocol

**Subagent mode** (dispatched via Task()):
1. Stage only team-state.yml and findings.md updates
2. Commit: `[plan_name]: code-review [task_id]`
3. Report commit SHA in task_complete

**Inline mode:** Commit after verification passes with descriptive message.

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- team-state.yml review.code_review section exists and is non-empty
- review.code_review.status is one of: pending, passed, failed
- files_reviewed array is non-empty and matches changed files count
- Every finding has non-empty: file, severity, message
- severity values are one of: critical, warning, info
- If any finding has severity "critical": status must be "failed"
- completed_at is set to a valid timestamp

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Review is thorough — security dimension was checked (not just style issues)
- Severity ratings are appropriate (not inflated or under-rated)
- Findings are actionable (specific file, line, and recommendation)
- Critical findings have clear remediation paths
- Pattern adherence was checked against actual project conventions

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.

## Error Handling

When errors occur during code review:

1. **Git diff failure:** If `git diff` fails (bad SHA, missing commits), log to
   state.yml errors array. Verify SHAs exist with `git cat-file -t [sha]`. If
   SHAs are valid but diff fails, try `git diff --no-renames` as fallback.

2. **File not accessible:** If a reviewed file has been deleted or moved since
   the diff, note it as "file removed post-diff" and skip. Do not fail the
   entire review for one missing file.

3. **Large diffs:** If the diff exceeds 500 changed files, split into batches
   of 50 files. Review each batch and save findings incrementally.

4. **Before retrying:** Always check state.yml errors array for previous failed
   attempts. Never repeat the same approach.
