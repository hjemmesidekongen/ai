---
name: e2e-testing-patterns
description: >
  End-to-end testing patterns with Playwright and Cypress. Page object model,
  test fixtures, assertions, waiting strategies, and CI integration.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "e2e testing"
  - "playwright patterns"
  - "end to end"
  - "cypress patterns"
  - "integration testing"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "no_hard_waits"
      verify: "Tests use smart waits (waitFor, expect), not sleep/setTimeout"
      fail_action: "Replace hard waits with condition-based waits"
    - name: "page_objects_used"
      verify: "Selectors are encapsulated in page objects, not scattered in tests"
      fail_action: "Extract selectors to page object classes"
    - name: "test_isolation"
      verify: "Each test can run independently without depending on other test state"
      fail_action: "Add proper setup/teardown for test isolation"
  on_fail: "E2E tests have structural issues — fix before merging"
  on_pass: "E2E tests follow best practices"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for dev-engine"
---

# E2E Testing Patterns

E2E tests validate real user flows against a running application. They're slow and brittle by nature — structure them to minimize both.

## Testing Pyramid Placement

Unit tests: fast, isolated, many. Integration tests: verify service boundaries. E2E tests: validate critical user journeys only. E2E is the top of the pyramid — thin, not comprehensive.

Use E2E for: checkout flows, auth flows, multi-step forms, cross-service workflows, and anything a broken unit test wouldn't catch.

Skip E2E for: input validation, error messages, component rendering, business logic — those belong in unit or integration tests.

## Playwright vs Cypress

**Playwright**: multi-browser (Chromium/Firefox/WebKit), supports multiple tabs and origins, better for complex SPAs, preferred for greenfield. Built-in auto-waiting. Native TypeScript.

**Cypress**: single origin per test (historically), excellent DX for debugging, strong community plugins, good for simpler apps. Real-time reload during dev.

Default to Playwright for new projects unless the team already has Cypress investment.

## Core Principles

- One test, one user journey. Don't combine flows to save setup time.
- Tests must pass in any order. Shared state between tests causes cascading failures.
- Never test what unit tests already cover. E2E cost is high — spend it on integration value.
- Stable selectors only. `data-testid` attributes over CSS classes or text content.
- Smart waits always. The app is async; your tests must be too.

See `references/process.md` for page object implementation, fixture patterns, selector strategies, waiting, visual testing, API mocking, CI setup, and anti-patterns.
