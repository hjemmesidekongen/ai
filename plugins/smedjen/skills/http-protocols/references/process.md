# http-protocols — Process Reference

## TCP Handshake and TLS

### TCP (3-way handshake)
```
Client → SYN            → Server
Client ← SYN-ACK        ← Server
Client → ACK            → Server
// connection established — 1 RTT
```

### TLS 1.3 (on top of TCP)
```
Client → ClientHello (key share) → Server
Client ← ServerHello + Certificate + Finished ← Server
Client → Finished + HTTP Request → Server
// 1 RTT total (0-RTT available on session resumption)
```

TLS 1.2 required 2 RTTs. TLS 1.3 cut that to 1. HTTP/3 + QUIC eliminates the separate TCP handshake entirely — TLS and transport negotiate in parallel.

---

## HTTP/1.1

- Persistent connections: `Connection: keep-alive` reuses TCP sockets across requests
- Requests are serialized per connection — response must arrive before next request starts
- Pipelining: multiple requests without waiting for responses — broken in practice (proxies, servers don't implement it correctly)
- Browser workaround: 6 parallel connections per origin
- Performance techniques needed: asset bundling, spriting, domain sharding — all workarounds for 1.1 limits

---

## HTTP/2

- Single TCP connection per origin, full request multiplexing
- Streams: each request/response is a stream; streams are independent and interleaved
- HPACK: header compression with a shared dynamic table — reduces repetitive headers (cookies, user-agent) to a few bytes
- Server push: server sends resources before client requests them — effectively deprecated; browsers removed support
- Binary framing layer — not human-readable like HTTP/1.1 text

**Still has TCP head-of-line blocking**: a lost TCP packet stalls all streams until retransmit completes.

---

## HTTP/3 and QUIC

- Transport: UDP, not TCP — eliminates kernel-level head-of-line blocking
- QUIC implements reliable delivery per stream — a lost packet only stalls the affected stream
- TLS 1.3 is built into QUIC — cannot be disabled or downgraded
- 0-RTT connection resumption: client can send data with the first packet on a resumed session
- Connection migration: QUIC connections survive IP changes (phone switching from WiFi to LTE)
- Connection IDs: not tied to 4-tuple (src IP, src port, dst IP, dst port) — enables migration

---

## HTTP Status Code Reference

| Range | Meaning | Key codes |
|-------|---------|-----------|
| 1xx | Informational | 100 Continue, 101 Switching Protocols |
| 2xx | Success | 200 OK, 201 Created, 204 No Content, 206 Partial Content |
| 3xx | Redirect | 301 Moved Permanently, 302 Found, 304 Not Modified, 307 Temporary Redirect, 308 Permanent Redirect |
| 4xx | Client error | 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 409 Conflict, 422 Unprocessable Entity, 429 Too Many Requests |
| 5xx | Server error | 500 Internal Server Error, 502 Bad Gateway, 503 Service Unavailable, 504 Gateway Timeout |

301 vs 308: 301 allows method change on redirect (POST → GET); 308 preserves method.
307 vs 302: same distinction for temporary redirects.
401 vs 403: 401 = not authenticated (send credentials); 403 = authenticated but not authorized.

---

## Cookies — Set-Cookie Attributes

```
Set-Cookie: session=<token>; HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=86400; Domain=example.com
```

| Attribute | Effect |
|-----------|--------|
| `HttpOnly` | JS cannot access via `document.cookie` — prevents XSS session theft |
| `Secure` | HTTPS only — never sent over plaintext HTTP |
| `SameSite=Strict` | Not sent on any cross-site request (breaks OAuth, payment flows) |
| `SameSite=Lax` | Sent on top-level GET navigations; blocked on cross-site POST (good default) |
| `SameSite=None; Secure` | Sent cross-site — required for embedded widgets, iframes |
| `Max-Age=N` | Expiry in seconds from now (preferred over `Expires`) |
| `Expires=<date>` | Absolute expiry — uses client clock, can be wrong |
| `Domain=example.com` | Sent to subdomains; omit to restrict to exact host |
| `Path=/` | Scope to full site; narrow for sensitive cookies |
| `__Secure-` prefix | Browser enforces Secure flag regardless of Set-Cookie value |
| `__Host-` prefix | Browser enforces Secure + Path=/ + no Domain |

Cookies are sent with every request to the matching origin — keep them small. Aim for <4KB total; browsers reject cookies over 4096 bytes.

---

## Sessions: Server-Side vs JWT

### Server-Side Sessions
- Session ID stored in cookie (opaque, random, unpredictable)
- Server stores session data (Redis, DB, memory)
- Revocation: delete session record — instant effect
- Scaling: requires shared session store across instances

### JWT (JSON Web Tokens)
- Structure: `header.payload.signature` — all data in the token
- Server is stateless — no session store needed
- Revocation: token is valid until expiry — requires blocklist for immediate revocation
- Use short expiry (15 min access token) + refresh token pattern
- Store in `HttpOnly` cookie — not `localStorage` (XSS readable)
- Validate: signature, `alg` (reject `none`), `exp`, `iss`, `aud`

```js
// Reject "alg: none" explicitly
jwt.verify(token, secret, { algorithms: ['HS256'] })
```

---

## CORS — Full Mechanics

### Simple Requests (no preflight)
Methods: GET, HEAD, POST. Headers: only safe headers (Accept, Content-Type with limited values). No preflight — browser sends request, checks response headers before exposing to JS.

### Preflight (`OPTIONS`)
Triggered by: non-safe methods (PUT, DELETE, PATCH), custom headers, Content-Type: application/json.

```
OPTIONS /api/data HTTP/1.1
Origin: https://app.example.com
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Content-Type, Authorization
```

Server response:
```
Access-Control-Allow-Origin: https://app.example.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Max-Age: 86400      // cache preflight for 24 hours
Access-Control-Allow-Credentials: true  // only if cookies/auth needed
```

### Header Reference

| Header | Direction | Purpose |
|--------|-----------|---------|
| `Origin` | Request | Sent by browser automatically on cross-origin requests |
| `Access-Control-Allow-Origin` | Response | Which origin can access the response |
| `Access-Control-Allow-Methods` | Response | Allowed HTTP methods |
| `Access-Control-Allow-Headers` | Response | Allowed request headers |
| `Access-Control-Allow-Credentials` | Response | Whether cookies/auth headers are allowed |
| `Access-Control-Max-Age` | Response | How long preflight result can be cached |
| `Access-Control-Expose-Headers` | Response | Which response headers JS can read |

`Access-Control-Allow-Origin: *` cannot be combined with `Access-Control-Allow-Credentials: true` — browsers reject this combination.

---

## Caching — Cache-Control Directives

| Directive | Meaning |
|-----------|---------|
| `no-store` | Never cache — sensitive data |
| `no-cache` | Cache but must revalidate before use |
| `private` | Browser can cache; CDN/shared caches cannot |
| `public` | Any cache (browser, CDN, proxy) can store |
| `max-age=N` | Fresh for N seconds |
| `s-maxage=N` | Override max-age for shared caches (CDN) |
| `must-revalidate` | Expired cache must not be served stale |
| `stale-while-revalidate=N` | Serve stale while fetching fresh in background |
| `stale-if-error=N` | Serve stale if origin returns 5xx |
| `immutable` | Content at this URL will never change (use with content hash in filename) |

### Recommended by Resource Type

| Resource | Cache-Control | Notes |
|----------|--------------|-------|
| HTML | `no-cache` | Revalidate every time; CDN stores but checks |
| JS/CSS with content hash | `public, max-age=31536000, immutable` | Never changes at this URL |
| JS/CSS without hash | `public, max-age=600` | Short TTL; update on deploy |
| API responses | `private, no-cache` or `no-store` | Depends on sensitivity |
| Images (static) | `public, max-age=86400` | 1 day; hash in filename for longer |
| Fonts | `public, max-age=31536000, immutable` | Stable, hash in filename |

### Conditional Requests

```
// First response
ETag: "abc123"
Last-Modified: Mon, 10 Mar 2026 12:00:00 GMT

// Subsequent request
If-None-Match: "abc123"
If-Modified-Since: Mon, 10 Mar 2026 12:00:00 GMT

// Server response if unchanged
304 Not Modified  // no body — saves bandwidth
```

---

## Content Negotiation

Client signals preference via `Accept` headers; server responds with matching representation:

```
Accept: text/html, application/json;q=0.9, */*;q=0.8
Accept-Language: en-US,en;q=0.9,fr;q=0.5
Accept-Encoding: gzip, deflate, br
```

Server responds with `Content-Type`, `Content-Language`, `Content-Encoding` and should include `Vary` to tell caches which request headers affect the response:

```
Vary: Accept-Encoding, Accept-Language
```

Missing `Vary` causes caches to serve the wrong variant to different clients.

---

## Compression

Enable at the server or CDN layer — never in application code for large responses.

| Algorithm | Ratio | Speed | Notes |
|-----------|-------|-------|-------|
| gzip | Good | Fast | Universal browser support; use for compatibility |
| brotli | Better (~20%) | Slower to compress | Supported in all modern browsers; HTTPS only |
| zstd | Best | Fastest | Limited browser support as of 2026 |

Set threshold: compress responses >1KB. Compressing small responses costs more CPU than it saves in bandwidth.

```nginx
# nginx
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml;
gzip_min_length 1024;

brotli on;
brotli_types text/plain text/css application/json application/javascript;
```

---

## Anti-Patterns

- Sending `Cache-Control: no-cache` when you mean `no-store` — they are different
- Using `Expires` header — client clock can be wrong; use `max-age` instead
- Setting `Access-Control-Allow-Origin: *` on credentialed endpoints
- Not caching static assets with content hashes — wastes CDN and browser cache
- Using `Vary: *` — tells every cache the response is uncacheable
- Storing JWTs in `localStorage` — XSS accessible; use `HttpOnly` cookies
- Long-lived JWTs without refresh token rotation — compromise window equals token lifetime
- Forgetting `Vary: Accept-Encoding` when serving compressed responses — CDN serves gzip to clients that don't support it
- Using HTTP/1.1 domain sharding with HTTP/2 — HTTP/2 is hurt by extra connections, not helped
- Not setting `SameSite` on cookies — browsers apply their own default (usually Lax) but explicit is better
- Relying on HTTP/3 without fallback — QUIC is blocked by some corporate firewalls; alt-svc header handles graceful downgrade
