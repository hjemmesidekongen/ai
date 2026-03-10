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
  iteration: 2
  changes: "Replaced tutorial content with E2E architecture patterns and flaky test diagnosis"
---

# E2E Testing Patterns

## When E2E Adds Value vs Wasted Effort

**Worth the cost**: cross-service workflows, auth flows spanning redirects/OAuth, payment/checkout (real payment gateway integration), multi-step wizards with server-side validation, features where the integration surface *is* the risk.

**Wasted effort**: CRUD forms with client-only validation, component rendering (use component tests), business logic testable in isolation, anything where test setup exceeds 3x the test body.
## Test Data Management

**Seeded database**: snapshot a known-good DB state, restore before each suite. Fast but brittle when schema changes. **API-driven setup**: create test data via API calls in `beforeAll`. Slower but always matches current schema. **Factory pattern**: test-scoped data factories that create minimal required state — each test owns its data. Never share mutable data across tests. If two tests need the same user, create two users.

## Parallel Execution

Shard by file, not by test — file-level sharding avoids shared-state conflicts. Playwright: `--shard=1/4`. CI: run shards as parallel jobs, merge reports with `merge-reports`. Each worker gets its own DB schema or tenant via `WORKER_INDEX` env var.

## Visual Regression Testing

Snapshot comparison catches CSS regressions unit tests miss. Use `toHaveScreenshot()` with `maxDiffPixelRatio: 0.01`. Store baselines in git. Update with `--update-snapshots` only on intentional changes.

Mask dynamic content (timestamps, avatars, ads) with `mask: [locator]` to prevent false positives. Run visual tests in a single browser (Chromium) — cross-browser rendering diffs create noise.

## Network Interception Decision

**Mock API** (`route.fulfill`): deterministic, fast, no backend dependency. Use for: error state testing, edge cases, offline behavior, rate limiting simulation.

**Real backend**: catches integration bugs mocks hide. Use for: critical happy paths, data integrity flows, auth token lifecycle.

**Hybrid**: mock third-party APIs, use real internal APIs. Best balance for most teams.

## Flaky Test Diagnosis

1. **Timing?** → Add explicit `waitFor` conditions, never arbitrary delays
2. **Data dependency?** → Test creates its own data, doesn't rely on seed state
3. **Animation/transition?** → Disable CSS animations in test config
4. **Network race?** → Wait for specific network response before asserting
5. **Viewport-dependent?** → Set explicit viewport size in test config
6. **Third-party widget?** → Mock the external script entirely

If a test fails >2% of runs after fixing, delete it. A flaky E2E test has negative value.

See `references/process.md` for page object implementation, fixture patterns, CI setup, and anti-patterns.
