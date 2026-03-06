---
name: "e2e-testing"
description: "Playwright E2E testing conventions — page objects, fixtures, breakpoint screenshots"
phase: "dev"
depends_on: ["scaffold"]
reads:
  - ".ai/projects/{project}/state.yml"
  - ".ai/profiles/{profile}.yml"
writes:
  - "e2e/"
  - "playwright.config.ts"
model_tier: "senior"
checkpoint:
  type: code_quality_gate
  required_checks:
    - name: "playwright_config_exists"
      verify: "playwright.config.ts exists with 3 breakpoints configured"
      fail_action: "Create playwright config with mobile/tablet/desktop viewports"
    - name: "page_objects_created"
      verify: "At least one page object class exists in e2e/pages/"
      fail_action: "Generate page objects from application routes"
    - name: "e2e_tests_green"
      verify: "playwright test exits with 0 failures"
      fail_action: "Fix failing specs, check selectors use data-testid"
  on_fail: "Log error to state.yml, re-run failed checks"
  on_pass: "Update state.yml, mark E2E testing completed"
---

# E2E Testing

Playwright conventions for end-to-end testing. Tests live in `/e2e/` at project root — outside the application.

## Activation

Profile-controlled:
- `e2e: true` — always active
- `e2e: false` — disabled
- `e2e: "detect"` — check for `/e2e/` directory + `playwright.config.ts`; enable if found

## Structure

```
e2e/
  fixtures/       # Shared auth states, seeded data, page objects
  pages/          # Page object classes
  specs/          # Test files (*.spec.ts)
  playwright.config.ts
```

## Rules

- Page Object Pattern: every page gets a class in `e2e/pages/` encapsulating selectors and actions
- Shared fixtures in `e2e/fixtures/` — auth states, seeded test data
- Chromium default, test at: mobile (375px), tablet (768px), desktop (1280px)
- Tests are independent — no test depends on another test's state
- Use data-testid for selectors, never CSS classes or DOM structure

## Visual Verification Integration

At section milestones, Playwright captures screenshots across breakpoints. These screenshots feed into the visual verification loop (LLM vision check against Pencil design reference).
