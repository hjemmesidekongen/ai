# e2e-testing-patterns — Debugging Reference

## Common Debugging Scenarios

### Test environment data inconsistency
**Symptom:** Tests pass on first run but fail on subsequent runs against the same environment. Assertions fail because expected data was modified or deleted by a previous test.
**Root cause:** Tests mutate shared database state without cleanup. Test B depends on data that Test A created or deleted.
**Diagnosis:**
- Run the failing test in isolation — if it passes alone, it's a data dependency issue
- Check test setup: does `beforeEach` create its own data or rely on pre-existing records?
- Query the test database directly to verify expected records exist before the test runs
- Review test teardown: is `afterEach` cleaning up created records?
- Check for hardcoded IDs that collide across tests
**Fix pattern:** Wrap each test in a database transaction and roll back after completion. If the framework doesn't support test transactions natively, use factory functions that create unique data per test with generated IDs (e.g., `createUser({ email: \`test-${uuid}@example.com\` })`). Seed the database in `beforeEach`, not `beforeAll`. Use API calls to create test data rather than sharing a fixture dump — this makes each test self-contained.

### CI-only failures
**Symptom:** Tests pass locally on every run but fail consistently or intermittently in CI.
**Root cause:** Environment differences — OS, browser version, screen resolution, timezone, locale, network latency, available memory, or missing system dependencies.
**Diagnosis:**
- Compare CI runner environment with local:
  - Node version: `node -v`
  - OS: `uname -a` (CI logs)
  - Browser version: check CI output for browser binary version
  - Timezone: `echo $TZ` or `date`
  - Locale: `echo $LANG`
- Run tests locally inside the same Docker image CI uses:
  ```
  docker run -it -v $(pwd):/app -w /app <ci-image> bash
  npm ci && npx playwright test
  ```
- Check CI resource limits — memory-constrained runners cause timeout failures
- Look for viewport-dependent assertions — CI may run headless with a different default viewport
- Check for hardcoded `localhost` URLs that should use environment variables in CI
**Fix pattern:** Pin browser versions in CI config. Set explicit timezone and locale in test config. Use the same Docker image locally and in CI. Set explicit viewport sizes in test configuration rather than relying on defaults. Replace `localhost` references with configurable base URLs (`process.env.BASE_URL`). Add `--retries=1` in CI to distinguish flaky from genuine failures.

### Test ordering dependency
**Symptom:** Tests fail when run in a different order, or when a specific test is skipped, or when running a subset of tests.
**Root cause:** Tests implicitly depend on side effects from earlier tests — login state, created records, global variable mutations, or module-level state that persists across test files.
**Diagnosis:**
- Run tests with randomized order: `--randomize` (Playwright), `--randomize` (Jest), or `--order=random` (Vitest)
- If randomization causes failures, the suite has ordering dependencies
- Identify the dependency chain:
  - Run the failing test alone — does it pass?
  - Run the failing test after each other test file individually to find which predecessor it depends on
- Check for module-level side effects: global variable assignments, singleton mutations, `jest.mock()` without `jest.restoreAllMocks()`
- Check `beforeAll` hooks that set state consumed by tests in other describe blocks
**Fix pattern:** Make each test self-sufficient. Move all precondition setup into `beforeEach`. If login state is needed, create it per test (or per file via a setup fixture), not per suite. Reset global state in `afterEach`. Use `test.describe` to scope shared state to a single block. Run with `--randomize` in CI as a regression guard against future ordering dependencies.

## Debugging Tools

| Tool | When to use | Command |
|------|------------|---------|
| Randomized ordering | Detect hidden test dependencies | `npx playwright test --randomize` or `npx vitest --order=random` |
| Single test isolation | Verify a test works independently | `npx playwright test --grep "test name"` |
| CI Docker image locally | Reproduce CI-only failures | `docker run -it -v $(pwd):/app -w /app <image> bash` |
| Database query tool | Verify test data state before/after tests | `psql`, `mysql`, or ORM CLI (`npx prisma studio`) |
| Test reporter (verbose) | See execution order and timing | `npx playwright test --reporter=list` |
| Trace/video recording | Capture CI test execution for review | `use: { trace: 'retain-on-failure', video: 'retain-on-failure' }` |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
