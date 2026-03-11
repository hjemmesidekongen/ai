---
name: http-protocols
description: >
  HTTP/1.1 vs 2 vs 3, TCP handshake, cookies, sessions, CORS, caching headers,
  and protocol fundamentals. Covers multiplexing, QUIC, Set-Cookie attributes,
  JWT vs server sessions, preflight mechanics, Cache-Control directives, and
  content negotiation.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "http protocols"
  - "http headers"
  - "caching headers"
  - "cors headers"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "cache_control_explicit"
      verify: "All responses include explicit Cache-Control directive — no reliance on heuristic caching"
      fail_action: "Set Cache-Control per resource type; add no-store for sensitive responses"
    - name: "cors_allowlist"
      verify: "CORS origin is explicit allowlist, not wildcard, when credentials are involved"
      fail_action: "Replace Access-Control-Allow-Origin: * with per-request origin validation against allowlist"
    - name: "cookie_attributes"
      verify: "Session cookies have HttpOnly, Secure, SameSite, and explicit Max-Age or Expires"
      fail_action: "Add missing cookie flags; review SameSite value against CSRF requirements"
    - name: "https_enforced"
      verify: "HSTS header present; no mixed content; HTTP redirects to HTTPS at edge"
      fail_action: "Configure HSTS with min 1-year max-age; fix mixed content warnings"
    - name: "compression_enabled"
      verify: "Text responses (HTML, JSON, CSS, JS) served with gzip or brotli encoding"
      fail_action: "Enable compression at server or CDN layer; verify Content-Encoding header in response"
  on_fail: "HTTP protocol check failed — resolve before shipping"
  on_pass: "HTTP protocol checks passed"
_source:
  origin: "smedjen"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 2
  changes: "Replaced protocol fundamentals with CDN strategy, rate limiting, and HTTP/3 adoption guidance"
---

# http-protocols

Operational HTTP patterns beyond protocol fundamentals — CDN strategy, rate limiting, versioning, and cache optimization.

## CDN Cache Invalidation

**Versioned URLs** (default): Hash in filename (`app.a1b2c3.js`), `Cache-Control: public, max-age=31536000, immutable`. New deploy = new URL = instant invalidation. Index HTML uses `no-cache`.

**Tag-based purge**: Surrogate keys (`Surrogate-Key: product-123 category-shoes`), purge by tag on data change. Fastly native, Cloudflare Enterprise. Better than full purge for dynamic content.

**SWR tuning**: `Cache-Control: max-age=60, stale-while-revalidate=3600` — serve stale while fetching fresh. `max-age` = acceptable staleness, `swr` = maximum tolerance.

## HTTP/3 Adoption Decision

Enable when: CDN supports it (Cloudflare/Fastly/CloudFront), browser clients, latency > throughput. Deploy at CDN layer with `Alt-Svc: h3=":443"; ma=86400`. No app code changes.
Hold off when: corporate proxies block UDP/443, server-to-server traffic, APM tools lack QUIC support.

## Rate Limiting Patterns

**Token bucket**: Fixed replenish rate, burst up to bucket size. Redis + Lua for distributed — `EVALSHA` atomically checks and decrements.
**Sliding window**: Rolling time window, no burst spikes at boundaries. Redis sorted sets: `ZADD`/`ZRANGEBYSCORE`/`ZREMRANGEBYSCORE`.
**Headers**: Always return `X-RateLimit-Limit`, `Remaining`, `Reset` (Unix). `Retry-After` on 429.

## API Versioning

**URL path** (`/v2/users`): Simple, visible in logs, recommended for public APIs.
**Accept header** (`application/vnd.api+json;version=2`): Clean URLs, better for internal APIs.
**Never query param** (`?v=2`): Breaks caching, no standard.

## Conditional Request Optimization

**ETag generation**: Hash body for static assets. For DB responses, composite `updated_at` + ID. Weak ETags (`W/"abc"`) match semantically equivalent responses.
**304 savings**: Saves bandwidth, not compute. Cache server-side too for expensive queries.
See `references/process.md` for TCP/TLS handshakes, status codes, cookie attributes, CORS headers, and compression.
