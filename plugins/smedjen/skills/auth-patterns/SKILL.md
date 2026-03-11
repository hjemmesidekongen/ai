---
name: auth-patterns
description: >
  OAuth 2.0, JWT, sessions, RBAC, refresh tokens, PKCE, and authentication
  architecture.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "auth patterns"
  - "oauth"
  - "jwt"
  - "authentication"
  - "authorization"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "no_jwt_in_localstorage"
      verify: "JWTs are stored in httpOnly cookies, not localStorage or sessionStorage"
      fail_action: "Move token storage to httpOnly cookie — localStorage is XSS-accessible"
    - name: "tokens_have_expiry"
      verify: "All JWTs include exp claim and refresh tokens have explicit TTLs"
      fail_action: "Add exp to JWT payload and set explicit TTL on refresh tokens"
    - name: "asymmetric_signing_in_distributed"
      verify: "Distributed systems use RS256/ES256, not HS256"
      fail_action: "Switch to RS256/ES256 — symmetric secrets cannot be safely shared across services"
    - name: "pkce_for_public_clients"
      verify: "Authorization code flow for SPAs and mobile apps uses PKCE"
      fail_action: "Add code_challenge/code_verifier — public clients cannot securely store client_secret"
  on_fail: "Auth implementation has structural security issues — fix before merging"
  on_pass: "Auth patterns are sound"
_source:
  origin: "smedjen"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for smedjen"
---

# Auth Patterns

Auth is where structural mistakes matter more than implementation bugs. Wrong token storage, no rotation, or missing expiry creates permanent exposure.

## OAuth 2.0 Flow Selection

**Authorization Code + PKCE** — SPAs, mobile apps. No client secret. PKCE replaces it with a one-time code verifier. Default choice for anything running in a browser.

**Authorization Code (confidential)** — server-side apps with a securely stored client secret. Secret never leaves the server.

**Client Credentials** — machine-to-machine, no user. Short-lived tokens rotated by infra.

**Device Flow** — TVs, CLIs, limited-input devices. User completes auth on a secondary device.

## JWT Essentials

Signed (not encrypted) — the payload is readable. Required claims: `iss`, `sub`, `aud`, `exp`, `iat`, `jti`. Validation must verify signature, `exp`, `iss`, and `aud` — libraries skip `aud` by default, configure it explicitly.

Signing: use RS256 or ES256 for distributed systems. HS256 requires all services to share the secret — rotation becomes an operational risk.

## Refresh Token Rotation

Short-lived access tokens (15m) + longer-lived refresh tokens (7–30d). On refresh: invalidate the old token, issue a new one. Reuse of an invalidated token signals theft — invalidate the entire token family. Store refresh tokens as hashed values, not plaintext.

## Session-Based Auth

httpOnly, Secure, SameSite cookie with a session ID. Session data server-side — Redis as the backing store. Prefer this over JWT when instant revocation is required (ban, logout-all-devices). Session IDs: 128-bit random, never derived from user data.

## RBAC and ABAC

**RBAC**: roles → permissions. Works well up to ~20 permission types. Define roles in code unless dynamic creation is a product requirement. Encode roles in the JWT `roles` claim for stateless checks.

**ABAC**: policies evaluate attributes (user, resource, context). Use for complex multi-tenant or enterprise access models.

## Anti-Patterns and Reference

JWT in localStorage, missing `exp`, HS256 in microservices, rolling your own crypto, plaintext passwords, trusting `alg: none`.
See `references/process.md` for PKCE flow, JWT validation middleware, NextAuth config, RBAC middleware, argon2id hashing, and TOTP setup.
