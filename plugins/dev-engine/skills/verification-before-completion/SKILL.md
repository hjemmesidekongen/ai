---
name: verification-before-completion
description: >
  Mandatory verification protocol before claiming any task is done. Run tests,
  check output, verify edge cases, and confirm acceptance criteria are met.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "verify"
  - "check work"
  - "before done"
  - "verification checklist"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "proof_command_run"
      verify: "A concrete verification command was executed (test, build, lint)"
      fail_action: "Run the proof command — no claiming done without evidence"
    - name: "output_checked"
      verify: "Command output was read and confirms success"
      fail_action: "Read the full output — do not assume success"
    - name: "edge_cases_considered"
      verify: "At least 2 edge cases or error paths were verified"
      fail_action: "Test edge cases before marking complete"
  on_fail: "Verification incomplete — run the checks"
  on_pass: "Verified — task is genuinely complete"
_source:
  origin: "dev-engine"
  inspired_by: "claude-core verification-gate + superpowers verification"
  ported_date: "2026-03-10"
  iteration: 2
  changes: "Refocused from generic advice to stack-specific verification commands and decision matrix"
---

# Verification Before Completion

## Verification Commands by Stack

| Stack | Tests | Build | Types | Lint |
|-------|-------|-------|-------|------|
| React (Vite) | `npx vitest run` | `npx vite build` | `npx tsc --noEmit` | `npx eslint .` |
| Next.js | `npx jest` or `npx vitest run` | `npx next build` | `npx tsc --noEmit` | `npx next lint` |
| Node/Express | `npx jest` or `npx vitest run` | `npx tsc` (if TS) | `npx tsc --noEmit` | `npx eslint .` |
| Expo | `npx jest` | `npx expo export` | `npx tsc --noEmit` | `npx eslint .` |
| Prisma | `npx jest` (with test DB) | `npx prisma generate` | `npx tsc --noEmit` | `npx prisma validate` |
| Monorepo (Turbo) | `npx turbo test` | `npx turbo build` | `npx turbo typecheck` | `npx turbo lint` |

Always run `npx tsc --noEmit` separately from the build — some build tools (Vite, esbuild) strip types without checking them.

## Verification Matrix

| Check type | What it catches | Automated? |
|------------|----------------|------------|
| Type check | Interface mismatches, null safety, wrong argument types | Yes |
| Unit tests | Logic regressions, broken contracts | Yes |
| Build | Import errors, missing exports, dead code tree-shaking issues | Yes |
| Lint | Style violations, unused vars, accessibility issues (eslint-plugin-jsx-a11y) | Yes |
| Integration test | Cross-module wiring, API contract breaks | Yes |
| Visual review | Layout regressions, responsive breakpoints, animation glitches | Manual |
| Runtime behavior | Memory leaks, race conditions, hydration errors | Manual |
| Env-specific | Missing env vars, wrong API URLs, CORS in production | Manual |

## What Verification Catches That Self-Review Misses

- **Runtime behavior**: Code that reads correctly but fails at runtime (circular deps, import order, async timing).
- **Env-specific failures**: Works locally, breaks in CI/staging (missing env vars, different Node version, OS-specific path handling).
- **Dependency conflicts**: New package introduces a peer dependency conflict. Build succeeds but runtime throws.
- **Type narrowing gaps**: TypeScript compiles but a runtime `undefined` slips through a type assertion or `as` cast.
- **Stale build cache**: Previous build artifacts mask a real error. `rm -rf .next` or `rm -rf dist` before building.

## When Manual Verification Is Required

Automated is sufficient when: pure logic, data transformations, API endpoints with test coverage, config changes with type checking.

Manual is required when: visual UI changes (layout, animations, responsive), user flows spanning multiple pages, third-party integration behavior (OAuth, payment, email), performance characteristics (load time, bundle size), accessibility (screen reader testing, keyboard navigation).
