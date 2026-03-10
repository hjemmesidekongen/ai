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
  iteration: 2
  changes: "Replaced generic patterns with error architecture, structured logging, and retry strategies"
---

# Error Handling Patterns

## Custom Error Class Hierarchy

Base `AppError` with fields: `message`, `code`, `statusCode`, `isOperational`. All domain errors extend it. This lets catch blocks discriminate by type and middleware map errors to HTTP responses automatically.

Subclasses: `ValidationError` (400, fields map), `AuthError` (401/403), `NotFoundError` (404, resource + id), `ConflictError` (409), `ExternalServiceError` (502, service name + original error), `RateLimitError` (429, retryAfter).

Mark `isOperational: true` for expected errors (bad input, missing resource). Non-operational errors (null deref, OOM) should crash — they're bugs, not user problems.

## Structured Error Logging

Every logged error must include: `error_code` (machine-readable, e.g. `AUTH_TOKEN_EXPIRED`), `message`, `stack` (dev/staging only — strip in prod), `context` (request ID, user ID, route, input summary), `severity` (error/warn/info), `timestamp` (ISO 8601 UTC), `service` (originating module).

Never log raw `error.message` from external services — may contain PII or credentials. Sanitize first.

## Retry Strategy Decision Tree

1. **Is the operation idempotent?** (GET, PUT with same payload, read query) → safe to retry.
2. **Is the failure transient?** (network timeout, 429, 503) → retry with exponential backoff. Cap at 3 attempts. Base delay 1s, multiplier 2x, add jitter (random 0-500ms).
3. **Is it a mutation?** (POST creating a resource, payment, email send) → do NOT auto-retry. Surface to user with a "retry" action. If you must retry, ensure idempotency keys.
4. **Is it a client error?** (400, 401, 403, 404, 422) → never retry. The request is wrong; retrying won't fix it.

## Error Boundary Placement Strategy

Place boundaries at **feature boundaries**, not per-component or root-only:

- **Root boundary**: Catches catastrophic failures. Shows "something went wrong" + reload button. This is the last resort — if only this catches errors, placement is wrong.
- **Feature boundary**: Wraps each independent feature (dashboard widget, comment section, settings panel). One feature crashing doesn't take down the page.
- **Data boundary**: Wraps components that fetch data. Shows feature-specific loading/error states.
- **Never per-component**: Too granular. Creates noisy fallback UI and makes error recovery harder.

## Error Monitoring Integration

Configure Sentry (or equivalent) with: environment tags, release version, user context (anonymized), breadcrumbs for last 10 actions. Filter out: `isOperational` errors that are expected (4xx from valid user actions). Alert on: unhandled rejections, error rate spikes, new error types not seen before.
