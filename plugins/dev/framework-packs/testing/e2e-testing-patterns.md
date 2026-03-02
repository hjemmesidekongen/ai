---
origin: "wshobson/agents"
origin_skill: "e2e-testing-patterns"
origin_version: "1.0.0"
forked_date: "2026-03-02"
sections_kept: "Playwright patterns: Page Object Model, Fixtures for Test Data, Waiting Strategies (no fixed timeouts), Network Mocking and Interception, Accessibility testing with axe-core, Parallel sharding, Playwright config, Best Practices, Common Pitfalls, Debugging"
sections_removed: "Cypress section (we use Playwright per project standards), Visual Regression Testing (specialized — not core patterns)"
---

# E2E Testing Patterns (Playwright)

Reliable, maintainable Playwright test suites. Page Object Model, fixtures, intelligent waiting, and network mocking.

> See also: `webapp-testing-notes.md` for the reconnaissance-then-action pattern (explore before interacting) and static vs dynamic app detection. `javascript-testing-patterns.md` for unit and component testing with Vitest and RTL.

## Playwright Configuration

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  timeout: 30000,
  expect: { timeout: 5000 },
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [['html'], ['junit', { outputFile: 'results.xml' }]],
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    { name: 'mobile', use: { ...devices['iPhone 13'] } },
  ],
})
```

## Pattern 1: Page Object Model

Encapsulate page logic — tests should describe user behavior, not DOM structure.

```typescript
// pages/LoginPage.ts
import { Page, Locator } from '@playwright/test'

export class LoginPage {
  readonly emailInput: Locator
  readonly passwordInput: Locator
  readonly loginButton: Locator
  readonly errorMessage: Locator

  constructor(readonly page: Page) {
    this.emailInput = page.getByLabel('Email')
    this.passwordInput = page.getByLabel('Password')
    this.loginButton = page.getByRole('button', { name: 'Login' })
    this.errorMessage = page.getByRole('alert')
  }

  async goto() { await this.page.goto('/login') }

  async login(email: string, password: string) {
    await this.emailInput.fill(email)
    await this.passwordInput.fill(password)
    await this.loginButton.click()
  }
}

// e2e/login.test.ts
import { test, expect } from '@playwright/test'
import { LoginPage } from './pages/LoginPage'

test('successful login', async ({ page }) => {
  const loginPage = new LoginPage(page)
  await loginPage.goto()
  await loginPage.login('user@example.com', 'password123')
  await expect(page).toHaveURL('/dashboard')
})

test('failed login shows error', async ({ page }) => {
  const loginPage = new LoginPage(page)
  await loginPage.goto()
  await loginPage.login('wrong@example.com', 'badpassword')
  await expect(loginPage.errorMessage).toContainText('Invalid credentials')
})
```

## Pattern 2: Fixtures for Test Data

Create and clean up test data per test — never depend on shared state.

```typescript
// fixtures/test-data.ts
import { test as base } from '@playwright/test'

type TestData = {
  testUser: { email: string; password: string; name: string }
}

export const test = base.extend<TestData>({
  testUser: async ({}, use) => {
    const user = {
      email: `test-${Date.now()}@example.com`,
      password: 'Test123!@#',
      name: 'Test User',
    }
    await createTestUser(user)      // Setup
    await use(user)                 // Test runs here
    await deleteTestUser(user.email) // Teardown (always runs)
  },
})

// Usage
import { test } from './fixtures/test-data'
import { expect } from '@playwright/test'

test('user can update profile', async ({ page, testUser }) => {
  await page.goto('/login')
  await page.getByLabel('Email').fill(testUser.email)
  await page.getByLabel('Password').fill(testUser.password)
  await page.getByRole('button', { name: 'Login' }).click()

  await page.goto('/profile')
  await page.getByLabel('Name').fill('Updated Name')
  await page.getByRole('button', { name: 'Save' }).click()

  await expect(page.getByText('Profile updated')).toBeVisible()
})
```

## Pattern 3: Waiting Strategies

**Never use fixed timeouts.** Use condition-based waiting.

```typescript
// ❌ Flaky — arbitrary wait
await page.waitForTimeout(3000)

// ✅ Wait for specific network state
await page.waitForLoadState('networkidle')

// ✅ Wait for URL change
await page.waitForURL('/dashboard')

// ✅ Auto-waiting assertions (Playwright retries until timeout)
await expect(page.getByText('Welcome')).toBeVisible()
await expect(page.getByRole('button', { name: 'Submit' })).toBeEnabled()

// ✅ Wait for API response
const responsePromise = page.waitForResponse(
  (response) => response.url().includes('/api/users') && response.status() === 200
)
await page.getByRole('button', { name: 'Load Users' }).click()
const response = await responsePromise
const data = await response.json()
expect(data.users).toHaveLength(10)

// ✅ Wait for multiple conditions in parallel
await Promise.all([
  page.waitForURL('/success'),
  expect(page.getByText('Payment successful')).toBeVisible(),
])
```

## Pattern 4: Network Mocking and Interception

```typescript
// Mock API failures
test('displays error when API fails', async ({ page }) => {
  await page.route('**/api/users', (route) => {
    route.fulfill({
      status: 500,
      contentType: 'application/json',
      body: JSON.stringify({ error: 'Internal Server Error' }),
    })
  })
  await page.goto('/users')
  await expect(page.getByText('Failed to load users')).toBeVisible()
})

// Intercept and modify requests
test('adds auth header', async ({ page }) => {
  await page.route('**/api/**', async (route) => {
    await route.continue({
      headers: {
        ...route.request().headers(),
        'Authorization': `Bearer ${TEST_TOKEN}`,
      },
    })
  })
  await page.goto('/protected')
})

// Mock third-party services
test('payment flow with mocked Stripe', async ({ page }) => {
  await page.route('**/stripe.com/**', (route) => {
    route.fulfill({
      status: 200,
      body: JSON.stringify({ id: 'mock_payment_id', status: 'succeeded' }),
    })
  })
  // Test continues normally...
})

// Spy on requests without modifying
test('tracks analytics calls', async ({ page }) => {
  const analyticsCalls: string[] = []
  page.on('request', (req) => {
    if (req.url().includes('/analytics')) {
      analyticsCalls.push(req.url())
    }
  })
  await page.goto('/')
  await page.getByRole('button', { name: 'Buy' }).click()
  expect(analyticsCalls.some(url => url.includes('purchase'))).toBe(true)
})
```

## Pattern 5: Accessibility Testing

```bash
npm install @axe-core/playwright
```

```typescript
import AxeBuilder from '@axe-core/playwright'

test('homepage has no accessibility violations', async ({ page }) => {
  await page.goto('/')
  const results = await new AxeBuilder({ page })
    .exclude('#third-party-widget')  // Exclude widgets you can't control
    .analyze()
  expect(results.violations).toEqual([])
})

test('form is accessible', async ({ page }) => {
  await page.goto('/signup')
  const results = await new AxeBuilder({ page })
    .include('form')
    .analyze()
  expect(results.violations).toEqual([])
})
```

## Parallel Sharding (CI)

```typescript
// playwright.config.ts — for large test suites in CI
export default defineConfig({
  // Enable sharding per CI job
  // Run: npx playwright test --shard=1/4
})
```

```yaml
# .github/workflows/e2e.yml
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: npx playwright test --shard=${{ matrix.shard }}/4
```

## Best Practices

1. **Use semantic locators** — `getByRole`, `getByLabel`, `getByText` before `getByTestId`
2. **Page Object Model** — encapsulate all page interactions in POM classes
3. **Fixtures for test data** — create fresh data per test, clean up in teardown
4. **Never `waitForTimeout`** — always wait for conditions
5. **Keep tests independent** — no shared state between tests
6. **Test user behavior** — click, type, see — not implementation details
7. **Mock external services** — Stripe, email, analytics, etc.
8. **Run in parallel** — `fullyParallel: true` in config

```typescript
// ❌ Brittle selectors
page.locator('.btn.btn-primary.submit-button')
page.locator('div > form > div:nth-child(2) > input')

// ✅ Semantic selectors
page.getByRole('button', { name: 'Submit' })
page.getByLabel('Email address')
page.getByTestId('submit-button')  // Last resort
```

## Common Pitfalls

- **Flaky tests:** Use proper waits, not `waitForTimeout`
- **Coupled tests:** Each test must be fully independent
- **Over-testing:** Use E2E only for critical user journeys; use unit tests for logic
- **No cleanup:** Always clean up test data in fixture teardown
- **Missing `baseURL`:** Set in config so tests work across environments

## Debugging

```bash
# Run in headed mode
npx playwright test --headed

# Open Playwright inspector (step through)
npx playwright test --debug

# Run specific test file
npx playwright test e2e/login.test.ts
```

```typescript
// Add steps for better test reports
test('checkout flow', async ({ page }) => {
  await test.step('Add item to cart', async () => {
    await page.goto('/products')
    await page.getByRole('button', { name: 'Add to Cart' }).click()
  })

  await test.step('Proceed to checkout', async () => {
    await page.goto('/cart')
    await page.getByRole('button', { name: 'Checkout' }).click()
  })
})

// Pause execution (opens inspector)
await page.pause()
```
