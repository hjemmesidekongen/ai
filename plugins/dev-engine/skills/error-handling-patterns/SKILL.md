---
name: error-handling-patterns
description: >
  Consistent error handling across codebases. Error boundaries, try-catch patterns,
  custom error types, logging strategies, and graceful degradation.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "error handling"
  - "exception handling"
  - "error patterns"
  - "error boundaries"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "error_types_defined"
      verify: "Custom error types exist for domain-specific failures"
      fail_action: "Define error types instead of using generic Error"
    - name: "catch_specificity"
      verify: "Catch blocks handle specific errors, not catch-all"
      fail_action: "Narrow catch scope to specific error types"
    - name: "user_facing_messages"
      verify: "Error messages shown to users are helpful, not stack traces"
      fail_action: "Separate user-facing messages from developer logs"
  on_fail: "Error handling incomplete — follow the patterns"
  on_pass: "Error handling is consistent and specific"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for dev-engine"
---

# Error Handling Patterns

## Philosophy

Errors are first-class citizens. Handle them at the right layer, with the right specificity. Generic catches and silent failures mask bugs — they don't prevent them.

Three principles:
- **Fail visibly in dev, gracefully in prod.** Development should surface every error; production should degrade without crashing.
- **Handle errors where you have context.** Don't bubble a DB error to the UI layer; translate it before it crosses a boundary.
- **Separate concerns.** User-facing messages, developer logs, and retry logic are three different responsibilities.

## The Error Pyramid

From most preferred to least:

1. **Recover** — handle locally, continue execution (e.g., use a default, skip the item)
2. **Retry** — transient failures (network, rate limits); use exponential backoff with a limit
3. **Report** — log structured context, propagate a typed error to the caller
4. **Crash** — unrecoverable state; fail fast, let a supervisor restart

Most application errors should resolve at level 1 or 2. Reaching level 4 is a signal the system hit an unexpected state — not a normal path.

## Boundaries

**React**: Use `ErrorBoundary` components to isolate subtree failures. Place them at feature boundaries, not just the root. Pair with a fallback UI that gives the user a recovery action.

**Node.js**: Use domain-level error handlers (`process.on('unhandledRejection')`) as a last resort, not primary handling. Structure async routes with `try/catch` or an error-handling middleware that maps typed errors to HTTP status codes.

Full patterns, code examples, and anti-patterns: `references/process.md`
