# Verification Before Completion — Process Reference

Detailed checklists, command references, and anti-patterns for the
verification-before-completion skill.

---

## Checklist by Task Type

### Feature implementation
- [ ] Unit tests for new logic pass
- [ ] Integration tests (if applicable) pass
- [ ] Edge cases: empty input, max input, invalid input
- [ ] Error paths return correct status/message
- [ ] Acceptance criteria from the original task re-read and matched
- [ ] No regressions in existing tests

### Bug fix
- [ ] Reproduce the original bug before the fix (confirm the failure)
- [ ] Apply fix, confirm the reproduction case now passes
- [ ] Related tests added or updated
- [ ] Sibling code paths checked for the same root cause
- [ ] Regression test added for the exact scenario

### Refactor
- [ ] All existing tests pass unchanged
- [ ] Build produces no new warnings
- [ ] Behavior is identical from a caller's perspective (diff the public API)
- [ ] Performance not regressed (benchmark if the path is hot)

### UI / visual change
- [ ] Browser loaded, layout confirmed at target viewport
- [ ] Screenshot taken and compared to spec or Figma
- [ ] Interaction states tested: hover, focus, disabled, loading, error
- [ ] Responsive breakpoints spot-checked
- [ ] No console errors during render

### Config / infra change
- [ ] Deployment dry-run or plan reviewed
- [ ] Rollback path identified
- [ ] Dependent services not broken (check health endpoints)
- [ ] Secrets not leaked into output or logs

### Documentation
- [ ] Links resolve
- [ ] Code examples run as written
- [ ] Content matches the current behavior (not the old behavior)

---

## Verification Commands by Stack

### JavaScript / TypeScript
```bash
npm test                        # or yarn test / pnpm test
npm run build
npx tsc --noEmit               # type check only
npx eslint . --max-warnings 0
```

### Node / backend
```bash
npm test
node -e "require('./dist/index.js')"   # smoke test the build artifact
curl -s http://localhost:PORT/health   # health check after starting
```

### Python
```bash
pytest -x                      # stop on first failure
python -m mypy .
ruff check .
python -c "import app; print('ok')"   # smoke test
```

### Go
```bash
go test ./...
go build ./...
go vet ./...
staticcheck ./...
```

### Rust
```bash
cargo test
cargo build --release
cargo clippy -- -D warnings
```

### CSS / design tokens
```bash
npm run storybook:build        # catches broken component stories
npx stylelint "**/*.css"
```

### CI equivalent (run locally before pushing)
```bash
# Mirrors what CI will run — adjust to your pipeline
npm ci && npm run lint && npm test && npm run build
```

---

## CI Integration

When a CI pipeline is available, treat a passing pipeline as the minimum bar —
not the ceiling. CI often runs on a clean environment and catches env-specific
assumptions that pass locally.

- If CI is green but local output has warnings, address the warnings.
- If CI is pending, do not mark the task done — wait for results.
- If CI is not configured, note that explicitly in the verification summary.

For PR-based workflows: verification happens before the PR is opened, not after.
Opening a PR and waiting for CI is not a substitute for local verification.

---

## Screenshot Verification for UI Work

1. Take a screenshot after the change is applied.
2. Compare against the spec (Figma, mockup, or issue description).
3. Check at minimum: desktop (1280px+) and mobile (375px).
4. Look for: overflow, clipping, misaligned elements, wrong colors/fonts.
5. Check interaction states that are not visible in a static screenshot by
   clicking through them manually.

If a visual diff tool is available (Chromatic, Percy, Playwright screenshots),
run it. Do not rely on "it looks right" without a concrete comparison.

---

## Anti-Patterns

### Green-path-only testing
Running only the happy path and calling it verified. Real failures live in
empty states, error conditions, boundary values, and concurrent access.
Fix: for every feature, name two things that could go wrong and test them.

### Self-grading
"I'm confident the logic is correct" is not a verification step. Confidence
is not evidence. Run the thing.

### Partial output reading
Stopping at the first success line and not reading the rest. Errors often
appear after an apparent success (post-build steps, teardown failures, warnings
promoted to errors). Read to the end.

### Stale test results
Citing a previous test run after making additional code changes. The run must
be after the last edit. Re-run after every change, no matter how small.

### Assuming the editor caught it
Type errors, lint issues, and broken imports are not always visible in the
editor in real time. The tool chain is the authority. Run it.

### Deferred verification
"I'll check this once the PR is open." Verification is a prerequisite to
claiming done, not a follow-up step.

### Testing the wrong thing
Writing a test that passes trivially (e.g., asserting `true === true`) or
that tests framework behavior rather than your logic. Verify the test actually
fails when the behavior is broken.
