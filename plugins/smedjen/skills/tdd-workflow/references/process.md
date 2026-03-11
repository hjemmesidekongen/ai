# TDD Workflow — Process Reference

## Step-by-Step Cycle

### 1. Identify the next behavior
Pick the smallest unit of behavior that moves the implementation forward. If the requirement is large, decompose it into independent behaviors and TDD each one.

### 2. Write a failing test (Red)
Write a test that:
- Describes the behavior in plain language (test name)
- Sets up the minimal state needed
- Calls the unit under test
- Asserts a single outcome

Run the test suite. The new test must fail. If it passes, either the behavior already exists or the assertion is wrong. Fix the test before continuing.

### 3. Make it pass (Green)
Write the simplest code that makes the failing test pass. "Simplest" means:
- No branching unless the test requires it
- No error handling unless the test requires it
- No abstractions unless an existing test requires them

Ugly implementation is acceptable. The refactor phase exists to fix it.

Run the full suite. All tests — not just the new one — must pass.

### 4. Refactor (Refactor)
With all tests green, clean the code:
- Extract duplication
- Rename for clarity
- Simplify control flow
- Apply design patterns where they reduce complexity

Run the suite after each refactor step. If anything goes red, undo the last change. Refactor in small steps.

### 5. Repeat
Return to step 1. Pick the next behavior.

---

## Code Examples (Pseudocode)

### Simple unit — string validation

```
// Red: write failing test
test("rejects empty username") {
  result = validateUsername("")
  assert result.valid == false
  assert result.error == "Username cannot be empty"
}

// Green: minimal implementation
function validateUsername(username) {
  if username == "" {
    return { valid: false, error: "Username cannot be empty" }
  }
  return { valid: true }
}

// Next cycle — Red
test("rejects username shorter than 3 characters") {
  result = validateUsername("ab")
  assert result.valid == false
  assert result.error == "Username must be at least 3 characters"
}

// Green: extend, don't over-engineer
function validateUsername(username) {
  if username == "" {
    return { valid: false, error: "Username cannot be empty" }
  }
  if username.length < 3 {
    return { valid: false, error: "Username must be at least 3 characters" }
  }
  return { valid: true }
}

// Refactor: extract min-length constant, unify guard structure
```

### Stateful behavior — shopping cart

```
// Red
test("cart starts empty") {
  cart = Cart.new()
  assert cart.itemCount == 0
}

// Green
class Cart {
  constructor() { this.items = [] }
  get itemCount() { return this.items.length }
}

// Red — next behavior
test("adding an item increases count") {
  cart = Cart.new()
  cart.add({ id: "sku-1", qty: 1 })
  assert cart.itemCount == 1
}

// Green — add minimal add() method
// Refactor — if items structure repeated, extract Item class
```

---

## When TDD Doesn't Apply

| Situation | Why TDD breaks down | Alternative |
|-----------|-------------------|-------------|
| Exploratory spikes | You don't know the API yet — tests would be wrong | Spike first, delete output, TDD the real implementation |
| UI layout and visual correctness | Assertions can't verify pixel-level accuracy | Visual verification tools, screenshot diffing |
| Infrastructure wiring (DB connections, env setup) | Tests mirror implementation too closely | Integration tests after wiring, not before |
| Generated code | Testing generated output, not logic | Test the generator config / template |
| Throwaway prototypes | TDD investment doesn't pay off | If the prototype survives, rewrite with TDD |

---

## Integration with CI

TDD produces a test suite that doubles as a CI quality gate. To close the loop:

1. All TDD tests run on every PR — no exceptions for "obviously fine" changes.
2. Coverage is a by-product, not a target. Don't add tests to hit a coverage number.
3. Flaky tests get fixed immediately — a non-deterministic suite erodes trust in the whole gate.
4. Failing tests block merge. The suite must be green in CI before review.
5. Slow tests (>10s per unit) get profiled and optimized. A slow suite stops being run.

CI config should separate unit (fast, run always) from integration (slower, run on merge). TDD tests belong in the unit bucket.

---

## Test Doubles Patterns

Use the right double for the job. Overusing mocks is a common TDD failure mode.

| Double | What it does | When to use |
|--------|------------|------------|
| **Stub** | Returns hardcoded values | Isolate from external data sources |
| **Mock** | Records calls, asserts interactions | Verify collaboration between units |
| **Fake** | Lightweight working implementation (e.g. in-memory DB) | Integration paths where real infra is too slow |
| **Spy** | Wraps real object, records calls | When you need real behavior + interaction verification |
| **Dummy** | Placeholder passed but never used | Satisfy required parameters |

Rules for doubles:
- Don't mock what you don't own. Wrap third-party APIs before testing them.
- Mocks that mimic implementation details will break on every refactor. Test behavior, not implementation.
- One mock per test. Multiple mocks signal the unit under test has too many dependencies.
- Fakes should live in `test/helpers/` or `__test__/fakes/` — not inline in tests.

---

## Anti-Patterns

### Test-after disguised as TDD
Writing implementation first, then tests that match it. The tests will always pass — they were designed to. You get coverage without specification.

Detection: if writing the test feels trivial and obvious, the implementation came first.

### Brittle tests
Tests that break when internals change but behavior doesn't. Caused by testing implementation details instead of observable behavior.

Fix: test inputs and outputs, not the path the code takes to get there.

### Overmocking
So many mocks that the unit under test is effectively isolated from everything real. Passes in tests, fails in production.

Fix: integration tests at key boundaries. Mocks for speed, fakes for fidelity.

### Skipping the refactor phase
Green means done. Tech debt accumulates. Future cycles get slower.

Fix: refactor is part of the cycle contract, not optional cleanup.

### Giant tests
One test that sets up complex state, exercises multiple behaviors, and asserts many things. When it fails, you don't know why.

Fix: one behavior per test. Setup and assertion should fit in a screen.

### Testing trivial code
Testing getters, setters, framework boilerplate. Zero value, maintenance burden.

Fix: test behavior that could plausibly be wrong. Skip the obvious.
