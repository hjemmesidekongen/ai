# playwright-testing — Debugging Reference

## Common Debugging Scenarios

### Flaky CI tests
**Symptom:** Tests pass locally but fail intermittently in CI.
**Root cause:** Race conditions from missing `await`, animation timing, or network latency differences between local and CI environments.
**Diagnosis:**
- Run with trace enabled: `npx playwright test --trace on`
- Open trace viewer: `npx playwright show-trace trace.zip`
- Look for actions that fire before the previous navigation or network request completes
- Search test code for `page.click()`, `page.fill()`, `page.goto()` without `await`
- Check for `waitForTimeout()` calls — these are almost always the wrong solution
- Run the failing test in a loop to confirm flakiness: `npx playwright test --repeat-each=20 path/to/test.spec.ts`
**Fix pattern:** Add missing `await` keywords. Replace `waitForTimeout()` with `waitForSelector()`, `waitForResponse()`, or `expect().toBeVisible()`. Use `web-first assertions` that auto-retry. For animation-dependent tests, wait for the final state rather than a fixed delay.

### Element not found
**Symptom:** `locator.click: Error: strict mode violation` or `waiting for selector` timeout.
**Root cause:** Selector matches zero elements (DOM not ready, wrong selector) or multiple elements (ambiguous selector).
**Diagnosis:**
- Add `await page.pause()` before the failing line to open Playwright Inspector
- Use the Inspector's "Pick locator" tool to find the correct selector
- Check if the element is inside an iframe: `page.frameLocator('#iframe-id').locator('button')`
- Check if the element is inside a shadow DOM: `page.locator('host-element').locator('button')`
- Verify element visibility: `await expect(page.locator('selector')).toBeVisible()`
- Check for lazy loading or conditional rendering that delays the element
**Fix pattern:** Use Playwright's recommended locator strategies in order: `getByRole()`, `getByText()`, `getByLabel()`, `getByTestId()`. For strict mode violations, narrow the selector with `.first()`, `.nth(n)`, or add a parent scope via `.locator('parent').locator('child')`.

### Test isolation failures
**Symptom:** Tests pass individually but fail when run together. Order-dependent results.
**Root cause:** Shared state leaking between tests — cookies, localStorage, database records, or authenticated sessions persisting across test cases.
**Diagnosis:**
- Run the failing test alone: `npx playwright test --grep "test name"`
- Run with `--workers=1` to check if parallelism is the issue
- Check if tests share a `storageState` file that accumulates state
- Look for `test.describe.configure({ mode: 'serial' })` — serial tests share context by design
- Check `beforeAll` / `afterAll` hooks for shared state setup without matching teardown
**Fix pattern:** Use `test.use({ storageState: undefined })` to reset browser state per test. Move shared setup to `beforeEach` instead of `beforeAll`. Create fresh `storageState` per test file via the global setup project pattern. Use `test.describe.configure({ mode: 'parallel' })` unless serial execution is genuinely required.

### Screenshot diff noise
**Symptom:** Visual comparison tests fail on CI due to minor rendering differences (anti-aliasing, font rendering, subpixel shifts).
**Root cause:** Different OS, GPU, or font rendering pipelines between local machine and CI runner.
**Diagnosis:**
- Compare the diff image in `test-results/` — check if differences are subpixel noise vs. real regressions
- Check if the CI runner OS matches local: `uname -a` in CI logs
- Look at font rendering: system fonts render differently across platforms
- Check for dynamic content (timestamps, avatars, random data) in screenshots
**Fix pattern:** Set `maxDiffPixelRatio: 0.01` or `maxDiffPixels: 100` in `expect(page).toHaveScreenshot()` for acceptable tolerance. Run CI tests inside the official Playwright Docker container (`mcr.microsoft.com/playwright:v1.x-jammy`) for consistent rendering. Update snapshots from CI, not locally: `npx playwright test --update-snapshots` inside the same Docker image. Mask dynamic content with `mask: [page.locator('.timestamp')]`.

### Network interception not working
**Symptom:** `page.route()` handler never fires. Requests bypass mocking and hit the real API.
**Root cause:** Route registered after the request fires, wrong URL pattern, or request initiated by a service worker.
**Diagnosis:**
- Add request logging to see what URLs are actually being requested:
  ```
  page.on('request', req => console.log('REQ:', req.method(), req.url()));
  page.on('response', res => console.log('RES:', res.status(), res.url()));
  ```
- Check if the URL pattern in `page.route()` matches the actual request URL exactly (including query params)
- Check if the request is made by a service worker — `page.route()` does not intercept service worker requests by default
- Verify route is registered before the action that triggers the request
**Fix pattern:** Register routes before `page.goto()`. Use glob patterns for flexible matching: `page.route('**/api/users*', handler)`. For service worker requests, use `browserContext.route()` instead of `page.route()`. For GraphQL, match on the POST body using `route.fetch()` to inspect and modify.

## Debugging Tools

| Tool | When to use | Command |
|------|------------|---------|
| Trace Viewer | Post-mortem analysis of test failures | `npx playwright show-trace trace.zip` |
| Playwright Inspector | Live interactive debugging | `await page.pause()` or `PWDEBUG=1 npx playwright test` |
| UI Mode | Explore tests with time-travel debugging | `npx playwright test --ui` |
| Code Generator | Generate selectors by clicking in a browser | `npx playwright codegen https://example.com` |
| HTML Report | Review test results with screenshots and traces | `npx playwright show-report` |
| VS Code Extension | Run/debug individual tests from editor | Install `ms-playwright.playwright` |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
