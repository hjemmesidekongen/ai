---
origin: "anthropics/skills"
origin_skill: "webapp-testing"
origin_version: "1.0.0"
forked_date: "2026-03-02"
sections_kept: "Reconnaissance-then-action pattern and static vs dynamic app decision tree only"
sections_removed: "with_server.py helper, full Playwright toolkit documentation — not needed since e2e-testing-patterns.md is the primary E2E reference"
---

# Webapp Testing Notes (Reconnaissance Pattern)

Partial fork — reconnaissance-then-action pattern only. For full Playwright patterns, see `e2e-testing-patterns.md`.

## Reconnaissance-then-Action Pattern

Before interacting with a web app, explore it first to understand the current state.

**Workflow:**
1. **Navigate** to the page
2. **Observe** — take a screenshot or read the DOM to understand current state
3. **Plan** — decide what interaction is needed
4. **Act** — perform the interaction
5. **Verify** — confirm the expected result

```typescript
// ✅ Reconnaissance before action
test('fill checkout form', async ({ page }) => {
  await page.goto('/checkout')

  // Step 1: Observe — screenshot or check page state
  const screenshot = await page.screenshot()
  // Or: const heading = await page.getByRole('heading').textContent()

  // Step 2: Understand the form structure
  const inputs = await page.locator('input').all()
  // const labels = await page.locator('label').allTextContents()

  // Step 3: Act based on observation
  await page.getByLabel('Card number').fill('4242424242424242')
  await page.getByLabel('Expiry').fill('12/26')
  await page.getByRole('button', { name: 'Pay' }).click()

  // Step 4: Verify
  await expect(page.getByText('Payment successful')).toBeVisible()
})
```

**When to use:** Complex pages where the exact structure is unknown, dynamic content that changes based on state, multi-step flows where each step depends on the previous outcome.

## Static vs Dynamic App Decision

Before writing tests, determine how the app renders content:

```
Is the content present in the HTML source (view-source)?
├── Yes → Static app
│   └── Simpler locators work, content is predictable
│   └── Less reliance on waitForLoadState('networkidle')
└── No → Dynamic app (client-side rendering)
    └── Must wait for JavaScript to execute
    └── Use: await expect(element).toBeVisible() (auto-waits)
    └── May need: await page.waitForLoadState('domcontentloaded')
    └── Avoid: checking elements immediately after navigation
```

**Practical check:**
```typescript
// Check if app is static or dynamic
const html = await page.content()
const isDynamic = !html.includes('expected-content-text')
// If dynamic, ensure you're waiting for the correct element before asserting
```

## Server Management Note

When testing locally, start the dev server before tests:

```typescript
// playwright.config.ts
export default defineConfig({
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
  use: { baseURL: 'http://localhost:3000' },
})
```

This ensures the server is running before any test starts and is killed after tests complete.
