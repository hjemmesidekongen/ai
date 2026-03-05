# Code Review — Dimension Checklists & Reference

On-demand reference for the code-review skill. Loaded when detailed checklists, severity examples, verification protocol, error handling, or commit protocol are needed.

---

## Dimension Checklists

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

### f. Design Token Compliance (UI files only)

Apply to files under `src/components/`, `src/styles/`, `src/pages/`, or any `.css`, `.scss`, `.tsx`, `.jsx` file. Skip if `.ai/projects/[name]/design/tokens/` does not exist.

- **Hardcoded colors:** No hex values (`#3B82F6`), rgb/rgba literals, or named CSS colors (`color: blue`). All colors must reference a design token variable.
- **Hardcoded spacing:** No raw pixel/rem values for margin, padding, gap, or width that should come from a spacing scale (`margin: 16px` → `margin: var(--spacing-4)`).
- **Hardcoded typography:** No hardcoded font-family, font-size, font-weight, or line-height that should use a typography token (`font-size: 14px` → `font-size: var(--text-sm)`).

**Token reference format:** Load token names from `design/tokens/` files. Flag any UI value that matches a token's raw value but is written as a literal instead of a token reference.

**Severity:** Hardcoded design values are always `warning` — they degrade brand consistency but do not block merge. Never escalate to `critical` for token violations alone.

---

## Severity Examples

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
- Hardcoded color, spacing, or typography value (should use design token)

**Info finding examples:**
- Opportunity to extract a reusable helper
- Minor naming improvement suggestion
- Alternative algorithm with better time complexity

---

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- project-state.yml `review.code_review` section exists and is non-empty
- `review.code_review.status` is one of: pending, passed, failed
- `files_reviewed` array is non-empty and matches changed files count
- Every finding has non-empty: file, severity, message
- severity values are one of: critical, warning, info
- If any finding has severity "critical": status must be "failed"
- `completed_at` is set to a valid timestamp

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Review is thorough — security dimension was checked (not just style issues)
- Design token compliance was checked for all UI files
- Severity ratings are appropriate (not inflated or under-rated)
- Findings are actionable (specific file, line, and recommendation)
- Critical findings have clear remediation paths
- Pattern adherence was checked against actual project conventions

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.

---

## Error Handling

1. **Git diff failure:** If `git diff` fails (bad SHA, missing commits), log to project-state.yml errors array. Verify SHAs exist with `git cat-file -t [sha]`. If SHAs are valid but diff fails, try `git diff --no-renames` as fallback.

2. **File not accessible:** If a reviewed file has been deleted or moved since the diff, note it as "file removed post-diff" and skip. Do not fail the entire review for one missing file.

3. **Large diffs:** If the diff exceeds 500 changed files, split into batches of 50 files. Review each batch and save findings incrementally.

4. **Missing design tokens:** If `.ai/projects/[name]/design/tokens/` does not exist, skip dimension f entirely. Log a single info-level finding noting token directory is absent — do not fail the review.

5. **Before retrying:** Always check project-state.yml errors array for previous failed attempts. Never repeat the same approach.

---

## Commit Protocol

**Subagent mode** (dispatched via Task()):
1. Stage only project-state.yml and findings.md updates
2. Commit: `[plan_name]: code-review [task_id]`
3. Report commit SHA in task_complete

**Inline mode:** Commit after verification passes with descriptive message.
