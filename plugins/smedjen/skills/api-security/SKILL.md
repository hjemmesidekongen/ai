---
name: api-security
description: >
  Rate limiting, input validation, CORS, security headers, API keys, and
  request sanitization.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "api security"
  - "rate limiting"
  - "cors"
  - "input validation"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "rate_limiting_present"
      verify: "All public endpoints have rate limiting — per-IP and per-user where applicable"
      fail_action: "Add rate limiting middleware — unbounded endpoints are trivially DoS'd"
    - name: "input_validated_at_boundary"
      verify: "All incoming data is validated at the API boundary before touching business logic"
      fail_action: "Add schema validation (zod/joi) before processing — never trust raw input"
    - name: "cors_not_wildcard_with_credentials"
      verify: "CORS does not combine Access-Control-Allow-Origin: * with credentials: true"
      fail_action: "Restrict allowed origins to an explicit allowlist when credentials are involved"
    - name: "security_headers_set"
      verify: "Responses include Helmet defaults: CSP, HSTS, X-Frame-Options, X-Content-Type-Options"
      fail_action: "Add Helmet.js middleware or equivalent header configuration"
  on_fail: "API has unresolved security gaps — address before deploying to production"
  on_pass: "API security posture is sound"
_source:
  origin: "smedjen"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for smedjen"
---

# API Security

Defense-in-depth: rate limiting stops abuse, validation stops bad data, headers stop browser-based attacks, sanitization stops injection.

## Rate Limiting

**Token bucket** — users accumulate tokens over time. Good for bursty traffic. **Sliding window** — rolling time window, Redis-backed with `ZADD`/`ZCOUNT`. More uniform enforcement.

Apply at multiple levels: per-IP (unauthenticated), per-user (authenticated), per-endpoint (login, OTP, password reset). Return `429` with `Retry-After` header.

## Input Validation

Validate at the API boundary before touching business logic. **zod** (TypeScript): type-safe schemas, infers TS types, preferred. **joi** (JS): runtime-only, battle-tested. **class-validator** (NestJS): decorator-based DTOs with class-transformer.

Validate: shape, types, string formats, numeric ranges, enum membership, array length. Reject unknown fields. Return structured `400` with field-level error details.

## CORS

Explicit allowlist only — never `*` with credentials. Match origin against the list; set `Access-Control-Allow-Origin` to the matched origin, not `*`. Set `Access-Control-Max-Age` (e.g., 86400) to reduce preflights. Separate dev/staging/production origins in config, not in code.

## Security Headers — Helmet.js

`helmet()` sets 11 headers by default. Critical: `Content-Security-Policy`, `Strict-Transport-Security` (1yr + includeSubDomains), `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`. CSP requires per-project tuning — start with `default-src 'self'`.

## Sanitization

**SQL injection** — parameterized queries or ORM always. **XSS** — sanitize HTML with `sanitize-html` (server) or `DOMPurify` (client) when storing user HTML. **Path traversal** — normalize paths, never build file paths from raw user input. **NoSQL injection** — strip MongoDB operators from user input (`$where`, `$gt`).

## Additional Controls

Body size limits (tune from Express's 100kb default). HTTPS enforced at the load balancer. IP allowlisting for admin/internal routes. Structured logging on all 4xx/5xx; alert on anomalous error rates.

## Anti-Patterns

No rate limiting on auth endpoints, wildcard CORS with credentials, raw SQL concatenation, logging request bodies with credentials, HTTP in production, missing body size limits.

See `references/process.md` for Redis rate limiter, zod middleware, Helmet config, CORS setup, sanitization helpers, API key management, and NestJS guard patterns.
