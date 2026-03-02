---
origin: "obra/superpowers"
origin_skill: "test-driven-development"
origin_version: "1.0.0"
forked_date: "2026-03-02"
sections_kept: "Iron Law, Red-Green-Refactor cycle, verification checklist, red flags list, Why Order Matters, Common Rationalizations table, When Stuck table"
sections_removed: "Philosophical rationale sections (duplicated across multiple Why Order Matters subsections) — trimmed repetitive argumentative content per findings.md"
---

# Test-Driven Development (TDD)

## Core Principle

Write the test first. Watch it fail. Write minimal code to pass.

**If you didn't watch the test fail, you don't know if it tests the right thing.**

> See also: `javascript-testing-patterns.md` for Vitest setup, mocking patterns, RTL component testing, and test fixtures (mechanics). This skill covers methodology.

## When to Use

**Always:** new features, bug fixes, refactoring, behavior changes.

**Exceptions (ask your human partner first):** throwaway prototypes, generated code, configuration files.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over.

- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Delete means delete

## Red-Green-Refactor

### RED — Write Failing Test

Write one minimal test showing what should happen.

```typescript
// ✅ Good: clear name, tests real behavior, one thing
test('retries failed operations 3 times', async () => {
  let attempts = 0
  const operation = () => {
    attempts++
    if (attempts < 3) throw new Error('fail')
    return 'success'
  }
  const result = await retryOperation(operation)
  expect(result).toBe('success')
  expect(attempts).toBe(3)
})

// ❌ Bad: vague name, tests mock not code
test('retry works', async () => {
  const mock = vi.fn()
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success')
  await retryOperation(mock)
  expect(mock).toHaveBeenCalledTimes(2)
})
```

Requirements: one behavior, clear name, real code (no mocks unless unavoidable).

### Verify RED — Watch It Fail (MANDATORY. Never skip.)

```bash
npm test path/to/test.test.ts
```

Confirm: test fails (not errors), failure message is expected, fails because feature is missing.

- **Test passes?** You're testing existing behavior. Fix the test.
- **Test errors?** Fix the error, re-run until it fails correctly.

### GREEN — Minimal Code

Write simplest code to pass the test. No features, no refactoring beyond the test.

```typescript
// ✅ Just enough to pass
async function retryOperation<T>(fn: () => Promise<T>): Promise<T> {
  for (let i = 0; i < 3; i++) {
    try { return await fn() }
    catch (e) { if (i === 2) throw e }
  }
  throw new Error('unreachable')
}

// ❌ Over-engineered YAGNI
async function retryOperation<T>(fn: () => Promise<T>, options?: {
  maxRetries?: number
  backoff?: 'linear' | 'exponential'
  onRetry?: (attempt: number) => void
}): Promise<T> { ... }
```

### Verify GREEN (MANDATORY.)

```bash
npm test path/to/test.test.ts
```

Confirm: test passes, other tests still pass, output is pristine.

- **Test fails?** Fix code, not test.
- **Other tests fail?** Fix now.

### REFACTOR — Clean Up

After green only: remove duplication, improve names, extract helpers. Keep tests green. Don't add behavior.

## Good Tests

| Quality | Good | Bad |
|---------|------|-----|
| Minimal | One thing. "and" in name? Split it. | `test('validates email and domain and whitespace')` |
| Clear | Name describes behavior | `test('test1')` |
| Shows intent | Demonstrates desired API | Obscures what code should do |

## Why Order Matters

Tests written after code pass immediately. Passing immediately proves nothing:
- Might test wrong thing
- Might test implementation, not behavior
- You never saw it catch the bug

Test-first forces you to see the test fail — proving it actually tests something.

**"Tests after achieve the same goals"** — No. Tests-after answer "What does this do?" Tests-first answer "What should this do?" Tests-after are biased by your implementation.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Already manually tested" | Ad-hoc ≠ systematic. No record, can't re-run. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. Unverified code is technical debt. |
| "Keep as reference, write tests first" | You'll adapt it. That's testing after. Delete means delete. |
| "TDD will slow me down" | TDD is faster than debugging. |

## Red Flags — STOP and Start Over

- Code before test
- Test passes immediately without implementation
- Can't explain why test failed
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "Already spent X hours, deleting is wasteful"
- "TDD is dogmatic, I'm being pragmatic"
- "This is different because..."

**All of these mean: Delete code. Start over with TDD.**

## Verification Checklist

Before marking work complete:

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered

Can't check all boxes? You skipped TDD. Start over.

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API. Write assertion first. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup huge | Extract helpers. Still complex? Simplify design. |

## Bug Fix Example

```typescript
// 1. RED — write failing test
test('rejects empty email', async () => {
  const result = await submitForm({ email: '' })
  expect(result.error).toBe('Email required')
})

// 2. Verify RED — confirm it fails
// $ npm test → FAIL: expected 'Email required', got undefined

// 3. GREEN — minimal fix
function submitForm(data: FormData) {
  if (!data.email?.trim()) {
    return { error: 'Email required' }
  }
  // ...
}

// 4. Verify GREEN — all pass
// 5. REFACTOR if needed
```

## Final Rule

```
Production code → test exists and failed first
Otherwise → not TDD
```
