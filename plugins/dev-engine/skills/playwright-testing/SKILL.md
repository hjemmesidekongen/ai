---
name: playwright-testing
description: >
  Playwright locators, assertions, fixtures, visual comparison, trace viewer, and CI setup.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "playwright"
  - "playwright testing"
  - "browser testing"
  - "playwright ci"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "no_hard_waits"
      verify: "Tests use Playwright auto-waiting and expect(), not sleep/setTimeout"
      fail_action: "Replace hard waits with locator-based assertions"
    - name: "role_locators_preferred"
      verify: "getByRole/getByLabel used before falling back to getByTestId or CSS"
      fail_action: "Upgrade selectors to role-based locators where possible"
    - name: "test_isolation"
      verify: "Each test is fully isolated — auth and state set up in fixtures, not shared"
      fail_action: "Move shared state into storageState fixtures or beforeEach hooks"
  on_fail: "Playwright tests have structural issues — fix before merging"
  on_pass: "Playwright tests follow best practices"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for dev-engine"
---

# Playwright Testing

Playwright provides auto-waiting, multi-browser support, and a rich toolchain. Use its built-in patterns — don't work around them.

## Locator Strategy (priority order)

1. `getByRole` — semantic, resilient, accessible
2. `getByLabel` — form inputs
3. `getByPlaceholder` — inputs without labels
4. `getByText` — text-only elements (be specific, not partial)
5. `getByTestId` — fallback when semantics aren't enough
6. CSS/XPath — last resort only

Chain locators to narrow scope: `page.getByRole('dialog').getByRole('button', { name: 'Submit' })`.

## Assertions

Use `expect(locator)` — all Playwright assertions auto-wait. Never assert on `.textContent()` values directly.

Key assertions: `toBeVisible`, `toHaveText`, `toHaveValue`, `toHaveURL`, `toHaveCount`, `toBeChecked`.

Soft assertions let a test continue after failure: `expect.soft(locator).toBeVisible()`. Check `expect(page).toHaveURL()` for navigation confirmation.

## Fixture Model

Extend `test` with `test.extend<{}>()` to inject reusable page wrappers and auth state. Keep fixtures in `fixtures/` and re-export a custom `test` object. Auth state goes in `storageState` — run auth once, reuse across tests.

## CI Considerations

Run with `--workers=4` or `--shard=1/4` for parallel execution. Retry flaky tests with `retries: 2` in `playwright.config.ts`. Always store traces and screenshots as artifacts on failure. Use `reporter: [['html'], ['github']]` for GitHub Actions native annotations.

See `references/process.md` for full implementation detail: locators, assertions, fixtures, visual comparison, network mocking, API testing, trace viewer, sharding, debugging, and anti-patterns.
