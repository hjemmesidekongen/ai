# parallel-reviewer — Process

## Step 1: Collect Scope

Before dispatching reviewers, identify:
- List of modified files (from git diff or task context)
- Language(s) in use
- Known constraints (e.g., "no DB changes", "public API endpoint")

Pass this scope to each reviewer in their dispatch prompt.

---

## Step 2: Reviewer Prompt Templates

Dispatch all 4 in parallel. Each reviewer writes an artifact file.

### Security Reviewer Prompt

```
You are a security reviewer. Analyze the following files for security issues:

Files: [list of modified files]
Language: [language]

Check for:
- Authentication and authorization gaps
- Input validation missing or incomplete
- Secrets or credentials in code (hardcoded or logged)
- Injection vulnerabilities (SQL, command, XSS, SSTI)
- OWASP Top 10 issues relevant to this code
- Unsafe deserialization, path traversal, SSRF

Write your findings to: .ai/plans/<plan>/artifacts/security-review.md

Format each finding as:
  Severity: CRITICAL | HIGH | MEDIUM | LOW
  File: <path>:<line>
  Issue: <description>
  Fix: <concrete remediation>

End with: SECURITY_REVIEW_COMPLETE
```

### Performance Reviewer Prompt

```
You are a performance reviewer. Analyze the following files for performance issues:

Files: [list of modified files]
Language: [language]

Check for:
- N+1 query patterns or missing bulk operations
- Synchronous blocking calls in async contexts
- Unnecessary memory allocation in hot paths
- O(n²) or worse loops without justification
- Missing pagination or unbounded result sets
- Repeated computation that could be cached

Write your findings to: .ai/plans/<plan>/artifacts/performance-review.md

Format each finding as:
  Severity: HIGH | MEDIUM | LOW
  File: <path>:<line>
  Issue: <description>
  Fix: <concrete remediation>

End with: PERFORMANCE_REVIEW_COMPLETE
```

### Architecture Reviewer Prompt

```
You are an architecture reviewer. Analyze the following files for architecture issues:

Files: [list of modified files]
Codebase context: [brief description of module boundaries]

Check for:
- Tight coupling between modules that should be independent
- Missing or violated abstraction boundaries
- Responsibility leakage (logic in wrong layer)
- Inconsistent patterns vs the rest of the codebase
- Missing dependency inversion where it would help
- Breaking changes to public interfaces without versioning

Write your findings to: .ai/plans/<plan>/artifacts/architecture-review.md

Format each finding as:
  Severity: HIGH | MEDIUM | LOW
  File: <path>:<line or class>
  Issue: <description>
  Fix: <concrete remediation>

End with: ARCHITECTURE_REVIEW_COMPLETE
```

### Testing Reviewer Prompt

```
You are a testing reviewer. Analyze the following files for test quality issues:

Files: [list of modified files]
Test files: [list of test files]

Check for:
- Missing test cases for new logic branches
- Edge cases not covered (null, empty, boundary values)
- Tests that only verify happy path
- Overly broad mocks that hide real behavior
- Test assertions too weak to catch regressions
- Missing integration tests for cross-boundary logic

Write your findings to: .ai/plans/<plan>/artifacts/testing-review.md

Format each finding as:
  Severity: HIGH | MEDIUM | LOW
  File: <path>:<line>
  Issue: <description>
  Fix: <concrete remediation>

End with: TESTING_REVIEW_COMPLETE
```

---

## Step 3: Collect Artifacts

After all 4 reviewers complete, **read artifact files directly**:

```
Read: .ai/plans/<plan>/artifacts/security-review.md
Read: .ai/plans/<plan>/artifacts/performance-review.md
Read: .ai/plans/<plan>/artifacts/architecture-review.md
Read: .ai/plans/<plan>/artifacts/testing-review.md
```

Do not paraphrase reviewer responses. Findings lose fidelity through synthesis.

---

## Step 4: Deduplication Rules

1. If two reviewers flag the same line for related reasons, merge into one finding
2. The merged finding inherits the higher severity
3. Reference both reviewers: "Flagged by: security, architecture"
4. Keep distinct if the issues are different even at the same location

---

## Step 5: Consolidation Format

Write final report to `.ai/plans/<plan>/artifacts/review-report.md`:

```markdown
# Review Report

**Files reviewed**: [count]
**Total findings**: [count] ([X] critical, [Y] high, [Z] medium, [W] low)
**Review streams**: security | performance | architecture | testing

## Critical Issues (must fix before merge)

### [Issue title] — CRITICAL
**File**: path/to/file.ts:42
**Flagged by**: security
**Issue**: Description of the problem.
**Fix**: Concrete remediation steps.

---

## High Issues (should fix)
...

## Medium Issues (consider fixing)
...

## Low / Informational
...

## Summary

[2-3 sentences: overall code quality, primary concerns, recommendation]
```

---

## Severity Ranking Criteria

| Severity | Criteria |
|----------|---------|
| CRITICAL | Security vulnerability exploitable in production, data loss risk, auth bypass |
| HIGH | Correctness bug under common conditions, significant performance regression |
| MEDIUM | Maintainability issue, missing coverage on important path, minor performance |
| LOW | Style, naming, optional improvement with no correctness impact |

---

## Fallback: Sequential Mode

If parallel dispatch is not available, run reviewers sequentially in this order:
1. Security (highest risk first)
2. Architecture (shapes other findings)
3. Performance
4. Testing (last — benefits from seeing other findings)
