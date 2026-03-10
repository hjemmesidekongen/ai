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
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Original skill, no port"
---

# http-protocols

HTTP is a request-response protocol layered on TCP (or QUIC). Every performance and security decision in a web app is downstream of how well you understand what happens between the browser and the server.

## Protocol Generations

**HTTP/1.1** — persistent connections (keep-alive), but requests are serial per connection. Browsers open 6 connections per origin to work around this. Pipelining exists on paper; nobody uses it in practice.

**HTTP/2** — single TCP connection, full multiplexing: many requests in flight simultaneously. HPACK header compression. Server push (largely deprecated in browsers). Eliminates the need for domain sharding and sprite sheets.

**HTTP/3** — built on QUIC (UDP-based). Removes head-of-line blocking at the transport layer (HTTP/2 still suffers from TCP HOL blocking). 0-RTT connection resumption cuts latency on repeat visits. TLS 1.3 is built in.

## Cookies and Sessions

`Set-Cookie` is how the server establishes state. The browser stores and echoes the cookie on every matching request. Cookie security depends entirely on the flags set at creation time — the value alone is not enough.

Sessions: server stores state, client holds an opaque session ID. JWT: client holds all state, signed by server — stateless but irrevocable without a blocklist. JWTs are not inherently more secure; they shift revocation complexity to the application.

## CORS

CORS is enforced by the browser, not the server. A server without CORS headers does not block cross-origin requests — it blocks cross-origin JavaScript from reading responses. Preflight (`OPTIONS`) fires when the request method or headers fall outside the "simple request" definition.

## Caching

Browser and CDN caching eliminate round trips. The `Cache-Control` header is authoritative. `ETag` and `Last-Modified` enable conditional requests — the server responds 304 when content is unchanged. `stale-while-revalidate` lets browsers serve stale content immediately while fetching fresh in the background.

See `references/process.md` for TCP/TLS handshake detail, status code reference, full cookie attribute table, CORS header breakdown, Cache-Control directive matrix, content negotiation, compression setup, and anti-patterns.
