# web-security-owasp — Process Reference

## XSS — Full Prevention

### Reflected XSS
- Encode all request-derived values before inserting into HTML response
- Use framework-provided template auto-escaping (React JSX, Vue templates, Django, Rails — all escape by default)
- Never disable auto-escape in templates without explicit review

### Stored XSS
- Sanitize on output, not just on input — stored data can be used in multiple contexts
- Use a proven sanitization library (DOMPurify for client-side, sanitize-html for server-side)
- Define an allowlist of permitted tags/attributes — blocklist approaches always miss something

### DOM-based XSS
- Never write to `innerHTML`, `document.write`, `eval`, `setTimeout(string)`, or `location.href` with user data
- Use `textContent` for text insertion; use DOM APIs for element creation
- Treat URL fragment (`location.hash`) as untrusted input

### Content Security Policy
```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{random}';
  style-src 'self' 'nonce-{random}';
  img-src 'self' data: https:;
  font-src 'self';
  connect-src 'self';
  frame-ancestors 'none';
  base-uri 'self';
  form-action 'self';
```
- Generate nonce per response, not per session
- Avoid `unsafe-inline` and `unsafe-eval` — these defeat CSP
- Use `report-uri` or `report-to` in report-only mode first to catch violations before enforcing

---

## CSRF — Defense Patterns

### Synchronizer Token (stateful)
1. Server generates random token, stores in session
2. Embed token in every state-mutating form (`<input type="hidden">`)
3. Server validates token before processing; reject on mismatch or absence
4. Token is per-session minimum; per-request tokens are stronger

### Double-Submit Cookie (stateless)
1. Server sets a random value in a non-HttpOnly cookie
2. Client reads cookie and sends the same value in a custom header or request body
3. Server compares cookie value vs header value — CSRF cannot read the cookie cross-origin

### SameSite Cookies
- `SameSite=Strict` — cookie not sent on any cross-site request (breaks OAuth flows)
- `SameSite=Lax` — cookie not sent on cross-site POST, but sent on top-level GET navigations (good default)
- `SameSite=None; Secure` — required for intentional cross-site embedding (iframes, third-party widgets)

### Origin/Referer Validation
- Reject requests where `Origin` header does not match server origin
- `Referer` can be stripped by privacy tools — use as supplementary check, not sole defense

---

## SQL Injection

### Parameterized Queries (safe)
```sql
-- PostgreSQL (node-postgres)
const result = await client.query(
  'SELECT * FROM users WHERE id = $1 AND status = $2',
  [userId, status]
);
```

### ORM Safety
- Prisma: query builder is safe by default; `$queryRaw` requires `Prisma.sql` tagged template
- TypeORM: use `createQueryBuilder` with parameters; `query()` with raw strings is not safe
- Sequelize: parameterize `where` clauses; avoid `literal()` with user input

### Stored Procedures
- Parameterized stored procedures are safe; dynamic SQL inside procedures is not

---

## NoSQL Injection

### MongoDB
- Never pass user-controlled objects directly to query operators
- `$where` executes JavaScript — disable it or sanitize strictly
- Validate and type-check fields before passing to query: `typeof userId === 'string'`
- Use `mongoose` schema typing to reject unexpected operator fields

```js
// Vulnerable
User.findOne({ username: req.body.username })  // username: { $gt: '' } bypasses auth

// Safe
const username = String(req.body.username)  // coerce to string, eliminates operator injection
User.findOne({ username })
```

---

## SSRF — Allowlist Pattern

```js
const ALLOWED_HOSTS = new Set(['api.example.com', 'cdn.example.com'])
const PRIVATE_RANGES = [
  /^10\./,
  /^172\.(1[6-9]|2\d|3[01])\./,
  /^192\.168\./,
  /^127\./,
  /^169\.254\./,   // cloud metadata
  /^::1$/,         // IPv6 loopback
  /^fc00:/,        // IPv6 ULA
]

async function safeServerFetch(url) {
  const parsed = new URL(url)
  if (!ALLOWED_HOSTS.has(parsed.hostname)) throw new Error('Host not allowed')

  // Resolve DNS and re-check (prevent DNS rebinding)
  const { address } = await dns.lookup(parsed.hostname)
  if (PRIVATE_RANGES.some(r => r.test(address))) throw new Error('Private IP blocked')

  return fetch(url)
}
```

---

## Security Headers — Full Stack

| Header | Recommended Value | Purpose |
|--------|-------------------|---------|
| `Content-Security-Policy` | See CSP section above | XSS mitigation |
| `X-Frame-Options` | `DENY` | Clickjacking (legacy) |
| `X-Content-Type-Options` | `nosniff` | MIME sniffing attacks |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload` | HTTPS enforcement |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Limit referrer leakage |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=()` | Disable unused APIs |
| `Cross-Origin-Opener-Policy` | `same-origin` | Isolate browsing context |
| `Cross-Origin-Embedder-Policy` | `require-corp` | Enable SharedArrayBuffer safely |
| `Cross-Origin-Resource-Policy` | `same-origin` | Prevent cross-origin reads |

Remove: `X-Powered-By`, `Server` (information disclosure).

---

## Cookie Security Flags

```
Set-Cookie: session=<token>; HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=86400
```

| Flag | Effect |
|------|--------|
| `HttpOnly` | Blocks JavaScript access — prevents XSS-based session theft |
| `Secure` | HTTPS only — prevents transmission over HTTP |
| `SameSite=Lax` | Blocks CSRF on cross-site POST; allows top-level navigations |
| `Path=/` | Scope to full application |
| `Max-Age` | Explicit expiry — prefer over `Expires` (uses client clock) |
| `__Secure-` prefix | Browser enforces Secure flag |
| `__Host-` prefix | Browser enforces Secure + Path=/ + no Domain attribute |

---

## Subresource Integrity (SRI)

Apply to all externally loaded scripts and stylesheets:
```html
<script
  src="https://cdn.example.com/lib.js"
  integrity="sha384-<base64-hash>"
  crossorigin="anonymous"
></script>
```

Generate hash: `openssl dgst -sha384 -binary lib.js | openssl base64 -A`

---

## HTTPS and HSTS

- Redirect all HTTP to HTTPS at the load balancer, not the application
- Set HSTS `max-age` to at least 1 year (31536000 seconds)
- Include `includeSubDomains` if all subdomains are HTTPS-ready
- Submit to HSTS preload list only after confirming all subdomains support HTTPS permanently

---

## Anti-Patterns

- Sanitizing input instead of encoding output — different contexts need different encoding
- Using blocklists for XSS filtering — always incomplete; use allowlists
- Storing session tokens in `localStorage` — XSS can read it; use `HttpOnly` cookies
- Validating `Referer` as sole CSRF defense — stripped by privacy tools and proxies
- Building SQL queries with template literals or string concatenation
- Trusting `X-Forwarded-For` without knowing your proxy topology
- Setting CSP to `unsafe-inline` "for now" — it never gets tightened later
- Using `eval()` anywhere in production code
- Disabling certificate verification in server-side HTTP clients (dev habit that ships to prod)
- CORS `Access-Control-Allow-Origin: *` on endpoints that use cookies or auth headers
