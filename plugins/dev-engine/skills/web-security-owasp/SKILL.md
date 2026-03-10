---
name: web-security-owasp
description: >
  XSS, CSRF, injection attacks, SSRF, security headers, and web application
  security hardening. Covers reflected/stored/DOM-based XSS, token-based CSRF
  defense, parameterized queries, SSRF allowlists, and the full security header
  stack with recommended values.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "web security"
  - "xss"
  - "csrf"
  - "injection"
  - "owasp web"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "output_encoding"
      verify: "All user-supplied data encoded before insertion into HTML, JS, CSS, or URL contexts"
      fail_action: "Apply context-appropriate encoding; do not rely on input sanitization alone"
    - name: "csrf_token_present"
      verify: "State-mutating endpoints validate CSRF token or enforce SameSite=Strict/Lax cookie policy"
      fail_action: "Add synchronizer token pattern or double-submit cookie before shipping"
    - name: "parameterized_queries"
      verify: "Database queries use parameterized statements or prepared queries — no string concatenation"
      fail_action: "Replace interpolated query strings with bound parameters or ORM query builder"
    - name: "security_headers"
      verify: "CSP, X-Frame-Options, X-Content-Type-Options, HSTS present in HTTP responses"
      fail_action: "Add missing headers via server config or middleware; verify with securityheaders.com"
    - name: "ssrf_input_validation"
      verify: "User-controlled URLs validated against allowlist before server-side fetch"
      fail_action: "Enforce allowlist of approved domains/IPs; block private IP ranges at network layer"
  on_fail: "Security check failed — do not merge until resolved"
  on_pass: "OWASP web security checks passed"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Original skill, no port"
---

# web-security-owasp

Security bugs are architecture bugs discovered late. The OWASP Top 10 attacks succeed because input trust assumptions are baked into design — not because developers forgot a sanitization call.

## XSS — Three Surfaces

**Reflected**: payload in request, echoed in response. User must click a crafted URL. Stored: payload persisted to DB, served to every visitor. **DOM-based**: payload lives in the URL fragment or JS variable, processed entirely client-side — server logs show nothing.

Prevention: output encoding matched to context (HTML entity, JS escape, CSS escape, URL encode). CSP as a second layer — not a replacement. Never trust `innerHTML`; use `textContent` or DOM APIs.

## CSRF

Forged requests exploit authenticated sessions. Defense: synchronizer token (server-issued, validated per-request) or `SameSite=Strict` cookies. Double-submit cookie pattern works for stateless APIs. Check `Origin`/`Referer` headers as secondary signal.

## SQL and NoSQL Injection

Parameterized queries eliminate SQL injection — string concatenation does not. ORM query builders are safe when used correctly; raw query escape hatches are not. NoSQL injection targets MongoDB `$where` and JSON body operators — validate and type-check inputs before passing to query layer.

## SSRF

Server-side fetch of user-supplied URLs enables internal network scanning. Allowlist approved domains. Resolve DNS before connecting and re-validate the resolved IP — DNS rebinding bypasses hostname checks. Block RFC-1918 ranges (10.x, 172.16.x, 192.168.x) and `169.254.0.0/16` (cloud metadata).

## Clickjacking

Embed the target in an iframe, render transparent overlay, capture clicks. Defense: `X-Frame-Options: DENY` or `Content-Security-Policy: frame-ancestors 'none'`. `frame-ancestors` is the CSP-native replacement; use both for older browser coverage.

See `references/process.md` for security header values, cookie flag reference, SRI, HTTPS/HSTS setup, and anti-patterns.
