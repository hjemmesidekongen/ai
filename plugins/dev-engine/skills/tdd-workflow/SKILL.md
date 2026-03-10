---
name: tdd-workflow
description: >
  Red-green-refactor cycle enforcement for test-driven development. Guides writing
  failing tests first, making them pass with minimal code, then refactoring.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "tdd"
  - "test driven"
  - "red green refactor"
  - "write test first"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "test_exists_before_code"
      verify: "A failing test was written before implementation"
      fail_action: "Write the failing test first"
    - name: "minimal_pass"
      verify: "Implementation is the simplest code that passes"
      fail_action: "Simplify — no speculative features"
    - name: "refactor_preserves_behavior"
      verify: "All tests still pass after refactoring"
      fail_action: "Revert refactor and try smaller steps"
  on_fail: "TDD cycle incomplete — follow the discipline"
  on_pass: "TDD cycle complete — tests green, code clean"
_source:
  origin: "dev-engine"
  inspired_by: "superpowers-main + claude-core tdd-gate patterns"
  ported_date: "2026-03-10"
  iteration: 2
  changes: "Replaced tutorial content with expert TDD patterns and framework-specific guidance"
---

# TDD Workflow

## When to Break the Cycle

TDD is not universal. Know when to exit:

- **Spikes**: Exploring an unfamiliar API or library. Write throwaway code, learn the shape, then restart with tests. Never TDD a spike — you'll test the wrong abstractions.
- **Integration wiring**: Connecting existing tested modules (routes → controllers → services). The test would mirror the implementation. Write an integration test after wiring instead.
- **Throwaway prototypes**: If the code will be discarded within days, skip TDD. If it survives past the prototype, stop and add tests before extending.
- **UI layout**: Visual positioning, CSS, animations. Snapshot tests add friction without catching real regressions. Use visual regression tools (Chromatic, Percy) instead.

## Framework-Specific TDD Patterns

**React (Testing Library)**: Test user behavior, not component internals. `getByRole` over `getByTestId`. Fire real events (`userEvent.click`) not synthetic ones. Never assert on component state — assert on what the user sees. For hooks: `renderHook` + `act()`, test the contract not the implementation.

**Next.js**: Server components can't use Testing Library — test the data layer directly. For API routes, call the handler function with mocked `NextRequest`. For server actions, test the function, mock `redirect`/`revalidatePath`. Client components test normally.

**NestJS**: Use `Test.createTestingModule` to bootstrap isolated modules. Override providers with `.overrideProvider(Service).useValue(mock)`. Test guards and interceptors in isolation from controllers.

**Prisma**: Never mock Prisma Client method-by-method — use a test database or `@prisma/client/runtime` for unit tests. For integration tests, use a seeded test DB with transaction rollback (`$transaction` + throw to rollback).

## Test Double Decision Tree

Pick the lightest double that serves the test:

| Need | Use | Not |
|------|-----|-----|
| Provide canned data to the subject | **Stub** | Mock — you don't need call verification |
| Verify the subject called a dependency | **Spy** | Mock — spy preserves real behavior |
| Replace a slow/flaky dependency entirely | **Fake** (in-memory DB, local server) | Mock — fakes catch more integration bugs |
| Enforce exact call sequence and arguments | **Mock** | Use sparingly — brittle to refactoring |

Rule of thumb: if your test breaks when you refactor internals but behavior is unchanged, you over-mocked.

## Property-Based Testing as TDD Extension

When a function has a contract expressible as invariants (sorting, encoding/decoding, serialization roundtrips), add property tests alongside example tests. Use `fast-check` for JS/TS. Write the property first (red), implement until it holds (green), refactor.

Properties that always pay off: roundtrip (`decode(encode(x)) === x`), idempotency (`f(f(x)) === f(x)`), commutativity where expected, "no crash" on arbitrary input.

See references/process.md for the step-by-step TDD cycle with cycle gates and anti-patterns.
