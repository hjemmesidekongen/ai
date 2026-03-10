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
  iteration: 1
  changes: "Built for dev-engine as discipline skill"
---

# TDD Workflow

Red-green-refactor is a discipline, not a suggestion. Tests define the contract before code exists.

## The Cycle

**Red** — Write a failing test that describes the behavior you want. Run it. It must fail. If it passes without code changes, the test is wrong.

**Green** — Write the minimum code to make the test pass. No extras. Ugly is fine. Speculative features are not.

**Refactor** — Clean the code without changing behavior. Tests must stay green throughout. If a refactor breaks tests, it went too far.

## When to Use TDD

Use TDD for: pure logic, algorithms, data transformations, API contracts, business rules, and anything with clear inputs/outputs.

Skip TDD for: UI layout, exploratory spikes, throwaway prototypes, and infrastructure wiring where the test would just mirror the implementation.

## Rules

- Never write implementation before a failing test exists.
- One test per cycle. Don't batch cycles — keep feedback tight.
- The refactor phase is mandatory. Green + messy is not done.
- A test that never fails has never been validated. Delete or fix it.
- Mock external dependencies in unit tests. Test the integration separately.

## Common Mistakes

- Writing tests after the fact and calling it TDD — it isn't.
- Writing tests that test the implementation instead of the behavior.
- Skipping the refactor phase because "it works."
- Over-mocking until the test no longer reflects real behavior.
- Making multiple changes between red and green — isolate failures.

See `references/process.md` for step-by-step workflow, code examples, test doubles patterns, and anti-patterns.
