---
name: "test-utilities"
description: "Shared test infrastructure — render wrappers, factories, MSW handlers, Playwright fixtures"
phase: "dev"
depends_on: ["scaffold"]
reads:
  - ".ai/projects/{project}/dev/stack.yml"
writes:
  - "src/test/utils.ts"
  - "src/test/factories/"
  - "src/test/msw/"
  - "e2e/fixtures/"
model_tier: "senior"
checkpoint:
  type: code_quality_gate
  required_checks:
    - name: "render_wrapper_exists"
      verify: "src/test/utils.ts exports renderWithProviders()"
      fail_action: "Create render wrapper with all required providers"
    - name: "factories_created"
      verify: "At least one factory function exists in src/test/factories/"
      fail_action: "Generate factory functions from project data models"
    - name: "msw_handlers_configured"
      verify: "Default MSW handlers exist in src/test/msw/handlers.ts"
      fail_action: "Create default API mock handlers from stack.yml endpoints"
  on_fail: "Log error to state.yml, re-run failed checks"
  on_pass: "Update state.yml, mark test utilities available"
---

# Test Utilities

Shared test infrastructure. Mocks are shared, not per-test throwaway.

## Core Utilities

- **renderWithProviders()** — in `src/test/utils.ts`. Wraps component with all required providers (theme, router, query client). Every test imports from here, never creates its own wrapper.
- **Factory functions** — `createMockUser()`, `createMockProject()`, etc. in `src/test/factories/`. Accept spread overrides for customization. Return fully typed objects.
- **MSW handlers** — Default API handlers in `src/test/msw/handlers.ts`. Shared across all tests. Override per-test only when needed.
- **Playwright fixtures** — Shared fixtures in `e2e/fixtures/`. Auth states, seeded data, common page objects.

## Discipline Rules

1. Before creating a mock: search for existing one in `src/test/` and `e2e/fixtures/`
2. Never define provider wrappers in test files — always import from `src/test/utils.ts`
3. New factories go in `src/test/factories/`, not inline in tests
4. MSW handler overrides use `server.use()` in individual tests, never modify default handlers
