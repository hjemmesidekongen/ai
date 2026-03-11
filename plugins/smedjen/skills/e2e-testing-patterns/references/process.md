# E2E Testing Patterns — Process Reference

## Page Object Model

Encapsulate all selectors and page interactions in a class. Tests call methods, never raw selectors.

```ts
// pages/checkout.page.ts
export class CheckoutPage {
  constructor(private page: Page) {}

  async fillShipping(address: Address) {
    await this.page.getByTestId('shipping-name').fill(address.name);
    await this.page.getByTestId('shipping-address').fill(address.street);
  }

  async submitOrder() {
    await this.page.getByRole('button', { name: 'Place Order' }).click();
    await this.page.waitForURL('/confirmation');
  }

  get orderConfirmation() {
    return this.page.getByTestId('confirmation-number');
  }
}

// tests/checkout.spec.ts
test('completes order with valid address', async ({ page }) => {
  const checkout = new CheckoutPage(page);
  await checkout.fillShipping(testAddress);
  await checkout.submitOrder();
  await expect(checkout.orderConfirmation).toBeVisible();
});
```

When a selector changes, update one file — not every test that uses it.

## Test Fixture Patterns

Fixtures provide shared setup without test interdependence.

```ts
// fixtures/auth.fixture.ts (Playwright)
export const test = base.extend<{ authenticatedPage: Page }>({
  authenticatedPage: async ({ page }, use) => {
    await page.goto('/login');
    await page.getByTestId('email').fill('test@example.com');
    await page.getByTestId('password').fill(process.env.TEST_PASSWORD!);
    await page.getByRole('button', { name: 'Sign in' }).click();
    await page.waitForURL('/dashboard');
    await use(page);
  },
});

test('views account settings', async ({ authenticatedPage }) => {
  // already logged in — no auth setup in the test body
});
```

Use fixtures for: authentication state, seeded database records, API stubs, and feature flags.

## Selector Strategies

Priority order — most stable to least:

1. `data-testid` — explicit, immune to copy and style changes
2. ARIA role + name — `getByRole('button', { name: 'Submit' })` — accessible and semantic
3. Label text — `getByLabel('Email address')` — good for forms
4. Placeholder — `getByPlaceholder('Search...')` — use only when label isn't available
5. Text content — `getByText('Confirm')` — fragile, avoid for interactive elements
6. CSS selectors — last resort, breaks with refactors

Add `data-testid` to elements that tests need to target. This is not test debt — it's a stable contract.

```html
<!-- good -->
<button data-testid="submit-order">Place Order</button>

<!-- fragile -->
<button class="btn btn-primary checkout-submit">Place Order</button>
```

## Waiting Strategies

Never use `sleep` or `setTimeout`. The app signals readiness — wait for the signal.

```ts
// wait for element to appear
await expect(page.getByTestId('success-banner')).toBeVisible();

// wait for network request
await page.waitForResponse(resp => resp.url().includes('/api/orders'));

// wait for URL change after navigation
await page.waitForURL('/confirmation/**');

// wait for element state
await expect(page.getByRole('button', { name: 'Submit' })).toBeEnabled();

// wait for text content
await expect(page.getByTestId('status')).toHaveText('Processing');
```

Playwright auto-waits on most actions. Override timeout only when the app genuinely takes longer: `{ timeout: 10000 }`.

## Visual Comparison Testing

Catch unintended UI regressions with screenshot comparisons.

```ts
// Playwright
await expect(page).toHaveScreenshot('checkout-form.png', {
  maxDiffPixelRatio: 0.02,  // allow 2% pixel difference
});

// Component-level snapshot
await expect(page.getByTestId('product-card')).toHaveScreenshot();
```

Update snapshots intentionally: `npx playwright test --update-snapshots`. Commit snapshots to version control. Review diffs in PR like any other change.

Don't use visual tests for dynamic content (dates, user-specific data). Mask dynamic regions:

```ts
await expect(page).toHaveScreenshot({ mask: [page.getByTestId('timestamp')] });
```

## API Mocking in E2E

Mock external APIs or slow services without removing test value.

```ts
// Playwright route interception
await page.route('**/api/payment', route => {
  route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ status: 'approved', transactionId: 'txn_123' }),
  });
});

// Simulate error states
await page.route('**/api/inventory', route => {
  route.fulfill({ status: 503 });
});
```

Mock when: the dependency is a third-party service, the real call has side effects (email, payment), or you need to test error states reliably.

Don't mock your own API unless absolutely necessary — those calls are part of what E2E validates.

## CI Configuration

### Playwright (playwright.config.ts)

```ts
export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 4 : undefined,
  reporter: [['html'], ['junit', { outputFile: 'results.xml' }]],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    headless: true,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
  ],
});
```

### GitHub Actions

```yaml
- name: Run E2E tests
  run: npx playwright test
  env:
    BASE_URL: ${{ env.STAGING_URL }}
    TEST_PASSWORD: ${{ secrets.TEST_PASSWORD }}

- uses: actions/upload-artifact@v3
  if: failure()
  with:
    name: playwright-report
    path: playwright-report/
    retention-days: 7
```

Run E2E against a deployed staging environment, not localhost in CI. Local E2E are for development iteration only.

## Debugging Failed Tests

1. **Check the trace first** — Playwright traces capture DOM snapshots, network, and console at each step. Run `npx playwright show-trace trace.zip`.
2. **Reproduce locally in headed mode** — `npx playwright test --headed --debug` opens the browser and pauses at each step.
3. **Check for timing issues** — if a test is flaky, add explicit waits for the condition rather than increasing timeouts.
4. **Inspect network tab** — unexpected 4xx/5xx often reveals the real failure before the assertion.
5. **Check test isolation** — run the test alone with `--grep`. If it passes in isolation, the failure is state leaking from another test.

```bash
# Run single test in debug mode
npx playwright test checkout.spec.ts --debug

# Run with trace always on (useful for flaky investigation)
npx playwright test --trace on

# Cypress equivalent
npx cypress open --spec "cypress/e2e/checkout.cy.ts"
```

## Anti-Patterns

**Brittle selectors** — CSS classes, XPath, or DOM structure selectors break on any refactor. Use `data-testid` or ARIA roles.

**Test interdependence** — Test B assumes Test A ran first. Add fixture setup to each test that needs it. If setup is slow, use `beforeAll` with teardown, not cross-test state.

**Hard waits** — `await page.waitForTimeout(3000)` is a symptom of not knowing when the app is ready. Find the signal and wait for that instead.

**Testing implementation details** — asserting that a specific function was called, or that an internal class was applied, means the test breaks when you refactor without changing behavior. Test what the user sees.

**Too many E2E tests** — if you have 200 E2E tests, most of them are probably unit test territory. E2E suites above ~50 tests become maintenance burdens. Push coverage down the pyramid.

**Shared test accounts** — parallel tests using the same user account create race conditions. Use per-test or per-worker accounts seeded via API, not shared fixture accounts.

**Asserting exact text** — copy changes break tests. Assert that confirmation text exists, not the exact wording, unless wording is a product requirement.
