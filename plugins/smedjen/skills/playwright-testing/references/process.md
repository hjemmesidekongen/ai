# Playwright Testing — Process Reference

## Locators

### Role-based (preferred)
```ts
page.getByRole('button', { name: 'Submit' })
page.getByRole('textbox', { name: 'Email' })
page.getByRole('heading', { level: 2 })
page.getByLabel('Password')
page.getByPlaceholder('Search...')
```

### Text-based
```ts
page.getByText('Sign in')                          // partial match by default
page.getByText('Sign in', { exact: true })         // exact match
```

### Test ID (fallback)
```ts
page.getByTestId('submit-btn')                     // data-testid attribute
```
Configure the attribute name in `playwright.config.ts`: `testIdAttribute: 'data-testid'`.

### Chaining and filtering
```ts
page.getByRole('dialog').getByRole('button', { name: 'Confirm' })
page.getByRole('listitem').filter({ hasText: 'Product A' }).getByRole('button')
page.locator('li').nth(2)
page.locator('li').last()
```

### CSS / XPath (last resort)
```ts
page.locator('.my-class > button')
page.locator('xpath=//button[@type="submit"]')
```

---

## Assertions

All `expect(locator)` calls auto-wait up to the configured timeout. Never assert on raw DOM values.

### Visibility and state
```ts
await expect(locator).toBeVisible()
await expect(locator).toBeHidden()
await expect(locator).toBeEnabled()
await expect(locator).toBeDisabled()
await expect(locator).toBeChecked()
await expect(locator).toBeFocused()
```

### Content
```ts
await expect(locator).toHaveText('Expected text')
await expect(locator).toContainText('partial')
await expect(locator).toHaveValue('input value')
await expect(locator).toHaveAttribute('href', '/home')
await expect(locator).toHaveCount(3)
```

### Page-level
```ts
await expect(page).toHaveURL('/dashboard')
await expect(page).toHaveTitle('My App')
```

### Soft assertions
```ts
await expect.soft(locator).toBeVisible()
await expect.soft(locator).toHaveText('Label')
// Test continues — all soft failures reported at the end
```

---

## Fixtures

### Extending test
```ts
// fixtures/index.ts
import { test as base } from '@playwright/test'
import { LoginPage } from './pages/LoginPage'

type Fixtures = { loginPage: LoginPage }

export const test = base.extend<Fixtures>({
  loginPage: async ({ page }, use) => {
    await use(new LoginPage(page))
  },
})
export { expect } from '@playwright/test'
```

### Auth state fixture
```ts
// global-setup.ts
import { chromium } from '@playwright/test'

async function globalSetup() {
  const browser = await chromium.launch()
  const page = await browser.newPage()
  await page.goto('/login')
  await page.getByLabel('Email').fill('user@example.com')
  await page.getByLabel('Password').fill('password')
  await page.getByRole('button', { name: 'Sign in' }).click()
  await page.context().storageState({ path: 'playwright/.auth/user.json' })
  await browser.close()
}
export default globalSetup
```

```ts
// playwright.config.ts
export default defineConfig({
  globalSetup: './global-setup.ts',
  use: { storageState: 'playwright/.auth/user.json' },
})
```

### Page Object Model
```ts
export class LoginPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/login')
  }

  async login(email: string, password: string) {
    await this.page.getByLabel('Email').fill(email)
    await this.page.getByLabel('Password').fill(password)
    await this.page.getByRole('button', { name: 'Sign in' }).click()
  }
}
```

---

## Visual Comparison

```ts
await expect(page).toHaveScreenshot('homepage.png')
await expect(locator).toHaveScreenshot('component.png', { threshold: 0.2 })
```

Update snapshots: `npx playwright test --update-snapshots`.

### Config
```ts
expect: {
  toHaveScreenshot: {
    maxDiffPixelRatio: 0.02,
    threshold: 0.2,
  },
}
```

Snapshots are stored per platform in `__snapshots__/`. Commit baseline snapshots. Run visual tests in Docker for consistency across machines.

---

## Trace Viewer

### Capture traces
```ts
// playwright.config.ts
use: {
  trace: 'on-first-retry',     // or 'on', 'off', 'retain-on-failure'
  screenshot: 'only-on-failure',
  video: 'retain-on-failure',
}
```

### Open trace
```bash
npx playwright show-trace trace.zip
```

Traces include DOM snapshots, network requests, console logs, and action timeline. Use trace viewer before adding `console.log` to tests — the answer is usually already there.

---

## Network Mocking

### Route interception
```ts
await page.route('/api/users', (route) => {
  route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify([{ id: 1, name: 'Alice' }]),
  })
})
```

### Modify responses
```ts
await page.route('/api/data', async (route) => {
  const response = await route.fetch()
  const json = await response.json()
  json.items.push({ id: 999, name: 'Injected' })
  await route.fulfill({ response, json })
})
```

### Block requests
```ts
await page.route('**/*.png', (route) => route.abort())
```

### Wait for requests
```ts
const [request] = await Promise.all([
  page.waitForRequest('/api/submit'),
  page.getByRole('button', { name: 'Submit' }).click(),
])
```

---

## API Testing

Playwright can test APIs directly without a browser using `request` context.

```ts
import { test, expect } from '@playwright/test'

test('GET /api/users returns list', async ({ request }) => {
  const response = await request.get('/api/users')
  expect(response.status()).toBe(200)
  const body = await response.json()
  expect(body).toHaveLength(3)
})

test('POST /api/users creates user', async ({ request }) => {
  const response = await request.post('/api/users', {
    data: { name: 'Bob', email: 'bob@example.com' },
  })
  expect(response.status()).toBe(201)
})
```

Reuse auth state: `APIRequestContext` accepts `storageState` just like browser contexts.

---

## Parallel Execution

### Worker config
```ts
// playwright.config.ts
workers: process.env.CI ? 4 : undefined,   // auto-detect locally
fullyParallel: true,
```

Tests within a file run sequentially by default. Set `fullyParallel: true` for intra-file parallelism (ensure each test is truly isolated).

### Sharding (CI matrix)
```bash
# Run shard 1 of 4
npx playwright test --shard=1/4
```

```yaml
# GitHub Actions matrix
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: npx playwright test --shard=${{ matrix.shard }}/4
```

Merge shard reports: `npx playwright merge-reports ./blob-report --reporter=html`.

---

## Retries

```ts
// playwright.config.ts
retries: process.env.CI ? 2 : 0,
```

Retries are for legitimately flaky tests (animations, external services). If a test fails consistently, fix it — don't raise the retry count.

---

## Reporter Config

```ts
reporter: [
  ['html', { open: 'never' }],
  ['github'],      // GitHub Actions annotations
  ['list'],        // console output
  ['blob', { outputDir: './blob-report' }],  // for shard merging
],
```

---

## CI Setup

### GitHub Actions
```yaml
name: Playwright Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: mcr.microsoft.com/playwright:v1.44.0-jammy
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci
      - run: npx playwright test
        env:
          BASE_URL: http://localhost:3000
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 7
```

### Docker (local consistency)
Use the official Playwright image for visual tests to ensure pixel-identical snapshots:
```bash
docker run --rm -v $(pwd):/work -w /work mcr.microsoft.com/playwright:v1.44.0-jammy \
  npx playwright test --update-snapshots
```

---

## Debugging

### Headed mode
```bash
npx playwright test --headed
npx playwright test --headed --slowMo=500   # slow motion
```

### Debug mode (step through)
```bash
npx playwright test --debug
```

Opens Playwright Inspector. Use `page.pause()` in test code to pause at a specific point.

### UI mode
```bash
npx playwright test --ui
```

Interactive watch mode with test picker, timeline, and trace viewer side by side.

### Codegen (record interactions)
```bash
npx playwright codegen https://example.com
```

Generates test code from browser interactions. Use as a starting point, not as final test code.

---

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| `page.waitForTimeout(2000)` | Hard wait — always too long or too short | Use `expect(locator).toBeVisible()` |
| `page.locator('.btn-primary')` | CSS class selectors break on style changes | Use `getByRole('button', { name: '...' })` |
| Shared state between tests | Cascading failures, order-dependent | Isolate via fixtures and storageState |
| `page.$eval('.text', el => el.textContent)` | Raw DOM extraction, no auto-wait | `expect(locator).toHaveText(...)` |
| Testing implementation details | Tests break on refactors | Test user-visible behavior only |
| No `data-testid` fallback | Brittle tests on dynamic UI | Add `data-testid` to unstable elements |
| `test.only` committed | Skips entire test suite in CI | Enforce with `forbidOnly: true` in CI config |
| Visual tests without Docker | Snapshot diff on every machine | Run snapshot updates in a fixed Docker image |
| Ignoring `expect.soft` failures | Hides partial failures | Review soft assertion results before marking pass |
| Over-mocking network | Tests don't catch real API issues | Mock only when necessary (external services, slow endpoints) |
