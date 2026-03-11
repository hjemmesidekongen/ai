# Code Review — Process Reference

## Review Workflow

### Phase 1: Gather Context

1. Get the diff: `git diff <base>..<head>` or `git diff --staged`
2. Identify changed files and categorize: source, test, config, generated, docs
3. Read surrounding context for each changed file (function scope, module purpose)
4. Check for related changes that should have been included but weren't

### Phase 2: Review Each File

Walk through every changed file. For each file, evaluate all five dimensions.

### Phase 3: Write Report

Structure findings into the review YAML. Set overall verdict based on findings.

### Phase 4: Checkpoint

Verify all files covered, all findings well-formed, severity assignments consistent.

---

## Review Checklist

### 1. Correctness

- Does the code do what the commit message / task description says?
- Are edge cases handled (null, empty, boundary values, concurrent access)?
- Are error paths correct — do they clean up state, propagate errors, avoid swallowing exceptions?
- Do conditional branches cover all cases? Any unreachable code?
- Are data transformations correct — off-by-one, type coercion, encoding?
- Do loops terminate? Are recursion base cases present?

### 2. Security

- Input validation: is all external input sanitized before use?
- Authentication/authorization: are access checks present where needed?
- Secrets: are credentials, tokens, or keys hardcoded or logged?
- Injection: SQL, command, template, path traversal — is interpolation safe?
- Dependencies: any known CVEs in added or updated packages?
- Data exposure: are error messages or logs leaking internal state?

### 3. Performance

- Are there N+1 queries, unnecessary loops, or redundant computations?
- Is there unbounded growth (arrays, caches, listeners that never clean up)?
- Are expensive operations (network, disk, crypto) in hot paths?
- Could any operation block the event loop or main thread?
- Are there missing indexes for new query patterns?
- Is pagination or streaming needed for large data sets?

### 4. Readability

- Are names descriptive? Do they match domain language?
- Is the code structured so the reader can follow the logic top-to-bottom?
- Are complex sections commented with "why", not "what"?
- Are magic numbers extracted into named constants?
- Is the abstraction level consistent within each function?
- Are there dead code paths, commented-out code, or TODO items without tracking?

### 5. Testing

- Do new code paths have corresponding test cases?
- Are edge cases and error paths tested, not just the happy path?
- Are tests isolated — no shared mutable state between tests?
- Do tests assert behavior, not implementation details?
- Are test names descriptive enough to serve as documentation?
- For bug fixes: is there a regression test that would have caught the original bug?

---

## Severity Definitions

### Critical

Production impact: high. The change introduces a defect or vulnerability that will affect users or system integrity.

Examples:
- SQL injection via unsanitized user input
- Race condition that corrupts shared state
- Missing null check that causes a crash on a common code path
- Authentication bypass on a protected endpoint
- Data loss — delete without confirmation, missing transaction rollback

### Important

Production impact: moderate. The change works but has problems that should be fixed before or shortly after merge.

Examples:
- Missing error handling that silently swallows failures
- N+1 query in a list endpoint that will degrade at scale
- Test only covers happy path, missing edge cases
- Function does too many things — should be split for maintainability
- Missing input validation that could cause confusing errors downstream

### Minor

Production impact: low. Style, naming, or structural suggestions that improve code quality but don't affect behavior.

Examples:
- Variable name could be more descriptive
- Duplicated logic that could be extracted into a helper
- Inconsistent formatting with the rest of the codebase
- TODO comment without a tracking reference
- Import ordering doesn't follow project convention

---

## Review Report Schema

```yaml
# .ai/reviews/<review-id>.yml
review_id: "rev-<timestamp>-<short-hash>"
created_at: "<ISO 8601>"
scope:
  base_ref: "<base commit or branch>"
  head_ref: "<head commit or branch>"
  files_changed: <count>
  lines_added: <count>
  lines_removed: <count>

verdict: "approved" | "changes_requested" | "blocked"
# approved: no critical or important findings
# changes_requested: important findings present, no criticals
# blocked: critical findings present

summary: "<1-2 sentence overall assessment>"

findings:
  - file: "<path>"
    line: <number>          # line in the diff, not the file
    severity: "critical" | "important" | "minor"
    category: "correctness" | "security" | "performance" | "readability" | "testing"
    message: "<what's wrong>"
    suggestion: "<how to fix it>"  # optional but preferred

stats:
  critical: <count>
  important: <count>
  minor: <count>
  files_reviewed: <count>
  files_changed: <count>
```

### Verdict Rules

- **blocked**: any critical finding present
- **changes_requested**: no criticals, but one or more important findings
- **approved**: only minor findings (or no findings at all)

---

## Requesting a Review

When preparing a review request, provide:

1. **Diff** — the actual code changes (via `git diff` or PR link)
2. **Scope description** — what the change is supposed to do, in one paragraph
3. **Constraints** — any relevant constraints (backwards compat, performance targets, security requirements)
4. **Related context** — links to specs, issues, or prior discussions that inform the change
5. **Known risks** — anything you're already uncertain about

Template:
```
## Review Request

**Scope:** <what this change does>
**Diff:** <git diff base..head or PR URL>
**Constraints:** <any constraints>
**Related:** <specs, issues, prior discussion>
**Known risks:** <things you want extra scrutiny on>
```

Do not expect the reviewer to guess intent. If the scope isn't clear from the diff alone, write it down.

---

## Receiving a Review

### Processing findings by severity

**Critical** — Stop other work. Fix immediately. These block merge.

**Important** — Create a task for each. Fix before merge if time allows. If deferring, document the reason in the review reply and create a tracked follow-up.

**Minor** — Fix in the same PR if trivial. Otherwise, note acknowledgment and move on. Don't create follow-up tasks for minor items unless they reveal a pattern.

### Responding to findings

- For each finding: fix, or explain why you disagree. "Will fix" or "Disagree because X" — nothing else needed.
- If you disagree with a severity rating, say so and explain. Severity is negotiable, the finding itself usually isn't.
- Don't argue about minor findings. Fix them or skip them.
- If a finding reveals a gap you hadn't considered, say so. Reviewers learn from honest responses.

---

## Edge Cases

### Large diffs (>500 lines changed)

Split the review by module or logical boundary. Review each segment independently. Note in the summary that the review was segmented.

Large diffs lose review quality. If you're producing a large diff, consider whether it should have been multiple PRs.

### Generated code

Don't review generated output line-by-line. Instead:
- Review the generator configuration or template
- Spot-check a sample of the output for obvious issues
- Flag if the generator itself should have guardrails it's missing

### Dependency updates

- Check the changelog for breaking changes
- Search for known CVEs in the new version
- Verify lock file is consistent with manifest
- For major version bumps, check migration guides

### Config-only changes

- Validate against the schema if one exists
- Check for environment-specific values that shouldn't be in the commit
- Verify no secrets or credentials are included

### Test-only changes

- Verify tests actually assert something meaningful
- Check that new tests don't duplicate existing coverage
- Ensure test data is realistic, not just `foo`/`bar`/`baz`
