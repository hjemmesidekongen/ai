---
name: "tdd"
description: "Enforces pure Red/Green/Refactor test-driven development cycle during implementation"
phase: "dev"
depends_on: ["project-scanner"]
reads:
  - ".ai/projects/{project}/state.yml"
  - ".ai/profiles/{profile}.yml"
writes:
  - "src/**/*.test.tsx"
  - "src/**/*.test.ts"
model_tier: "senior"
checkpoint:
  type: code_quality_gate
  required_checks:
    - name: "all_tests_passing"
      verify: "vitest run exits with 0 failures"
      fail_action: "Fix failing tests using RED/GREEN cycle"
    - name: "coverage_threshold_met"
      verify: "Line coverage >= 80% on new code"
      fail_action: "Add missing test cases for uncovered branches"
  on_fail: "Log error to state.yml, re-run failed checks"
  on_pass: "Update state.yml, mark TDD cycle completed"
---

# TDD

Enforces pure Red/Green/Refactor during implementation. One failing test, minimal implementation, next assertion.

## Activation

Profile-controlled:
- `tdd: true` -- always active
- `tdd: false` -- disabled
- `tdd: "detect"` -- check for vitest config + existing test files; enable if found, disable + flag if not

## Cycle

1. **RED** -- Write ONE failing test. One assertion only. Run `vitest --watch`. Confirm failure.
2. **GREEN** -- Write the minimum code to pass. No more. Run tests. Confirm green.
3. **REFACTOR** -- Improve code while tests stay green. Extract, rename, simplify. Run tests.
4. **REPEAT** -- Next assertion. Back to RED.

## Rules

- Never write implementation before a failing test
- Never write multiple assertions before seeing them fail
- Test files adjacent to source: `Button.test.tsx` next to `Button.tsx`
- vitest as default runner with `--watch` during active development
- Coverage target: 80%+ line coverage on new code

## Runner

```
vitest --watch --reporter=verbose
```
