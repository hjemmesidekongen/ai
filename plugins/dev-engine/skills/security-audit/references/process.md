# security-audit: Process Reference

## OWASP Top 10 (2021) Checklist

Assess each category. Every item requires an explicit finding or "pass" in the report.

| # | Category | What to check | Mitigation |
|---|----------|--------------|------------|
| A01 | Broken Access Control | Missing auth checks, IDOR, path traversal, CORS misconfiguration | Enforce deny-by-default, validate ownership on every resource request |
| A02 | Cryptographic Failures | HTTP instead of HTTPS, weak ciphers, unencrypted PII at rest, MD5/SHA1 | Enforce TLS 1.2+, use AES-256 at rest, bcrypt/argon2 for passwords |
| A03 | Injection | SQL, NoSQL, LDAP, OS command injection, template injection | Parameterized queries, input validation, escape output, avoid eval/exec |
| A04 | Insecure Design | Missing threat modeling, no rate limiting, unsafe defaults | Threat model before build, apply least-privilege by default |
| A05 | Security Misconfiguration | Debug mode in prod, default credentials, verbose error messages, open S3 buckets | Harden configs per environment, disable unused features, rotate defaults |
| A06 | Vulnerable Components | Outdated deps with known CVEs, unmaintained packages | Run npm audit + Snyk regularly, pin versions, remove unused deps |
| A07 | Auth & Session Failures | Weak passwords, no MFA, session fixation, JWT alg:none | Enforce strong password policy, rotate session tokens, validate JWT claims |
| A08 | Software Integrity Failures | Unverified npm packages, unsigned artifacts, no SBOM | Use lock files, verify checksums, enable npm provenance |
| A09 | Logging & Monitoring Failures | No audit log, logging PII, no alerting on suspicious activity | Log security events, avoid logging sensitive fields, set up anomaly alerts |
| A10 | SSRF | User-controlled URLs fetched server-side, open redirects | Whitelist allowed hosts, block internal IP ranges, validate redirect targets |

---

## Dependency Scanning

### npm audit
```bash
# Full audit with JSON output
npm audit --json > audit-output.json

# Fix safe (patch-level) vulnerabilities automatically
npm audit fix

# Review before applying force fixes — never run blindly
npm audit fix --force --dry-run
```

### Snyk
```bash
# Install once
npm install -g snyk && snyk auth

# Test current project
snyk test

# Monitor continuously (sends to Snyk dashboard)
snyk monitor

# Test specific severity threshold
snyk test --severity-threshold=high
```

### Socket
```bash
# Install
npm install -g @socketsecurity/cli

# Scan package.json
socket scan .

# Check a specific package before installing
socket npm install <package-name>
```

**Triage priority:** CVSS 9.0+ = critical (block), 7.0-8.9 = high (fix this sprint), 4.0-6.9 = medium (schedule), <4.0 = low (backlog).

---

## Secret Detection

### gitleaks
```bash
# Scan the entire repo history
gitleaks detect --source . --report-format json --report-path gitleaks-report.json

# Scan only staged changes (pre-commit)
gitleaks protect --staged

# Scan a specific commit range
gitleaks detect --source . --log-opts="HEAD~10..HEAD"
```

### trufflehog
```bash
# Scan git history
trufflehog git file://. --json

# Scan a specific branch
trufflehog git file://. --branch main --json

# Scan filesystem (no git history)
trufflehog filesystem . --json
```

### Pre-commit hook setup
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
```

**Secret categories to check:** API keys, OAuth tokens, database URLs with credentials, private keys (RSA/EC), JWT secrets, webhook secrets, cloud provider credentials (AWS, GCP, Azure).

---

## CSP and Security Headers

### Required headers

| Header | Recommended value | Purpose |
|--------|------------------|---------|
| `Content-Security-Policy` | `default-src 'self'; script-src 'self'; object-src 'none'` | XSS mitigation |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload` | Force HTTPS |
| `X-Frame-Options` | `DENY` or `SAMEORIGIN` | Clickjacking protection |
| `X-Content-Type-Options` | `nosniff` | MIME sniffing prevention |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Referrer leakage control |
| `Permissions-Policy` | Restrict camera, mic, geolocation as needed | Feature access control |

### Helmet.js (Node/Express)
```js
import helmet from 'helmet'

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      objectSrc: ["'none'"],
      upgradeInsecureRequests: [],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
}))
```

### CSP gotchas
- `unsafe-inline` and `unsafe-eval` defeat CSP — use nonces or hashes instead.
- Third-party CDN scripts require their origin in `script-src`.
- CSP Report-Only mode for testing without breaking: `Content-Security-Policy-Report-Only`.
- Validate with [https://csp-evaluator.withgoogle.com](https://csp-evaluator.withgoogle.com).

---

## SAST / DAST Basics

### SAST (static analysis)
- **ESLint security plugins**: `eslint-plugin-security`, `eslint-plugin-no-unsanitized`
- **Semgrep**: Rule-based pattern matching. Run `semgrep --config=p/owasp-top-ten .`
- **CodeQL**: GitHub-native, deep data-flow analysis. Enable via Actions workflow.
- Focus on: injection sinks (`eval`, `exec`, `innerHTML`, `dangerouslySetInnerHTML`), unsafe deserialization, prototype pollution (`__proto__`, `constructor`).

### DAST (dynamic analysis)
- **OWASP ZAP**: Proxy-based scanner. Run against a staging environment, never production.
- **Burp Suite**: Manual + automated web app testing. Community edition for basic scans.
- DAST requires a running application — not applicable to pre-deployment static review.

---

## Supply Chain Security

- **Lock files are required.** No lock file = unpinned transitive deps = reproducibility risk.
- **Check for typosquatting**: Verify package names against intended names before installing.
- **npm provenance**: Packages published with `--provenance` have cryptographic build attestation — prefer these for critical deps.
- **SBOM generation**: `npm sbom --sbom-format cyclonedx` produces a software bill of materials.
- **Audit new deps before adding**: Run `socket npm install <pkg>` or `snyk test` before committing.
- **Remove unused deps**: `depcheck` identifies packages in package.json not used in code.

---

## Code Review Security Checklist

Before approving a PR, verify:

- [ ] No credentials, tokens, or secrets in diff
- [ ] User input validated and sanitized before use in queries, commands, or templates
- [ ] Auth checks present on all new routes/endpoints
- [ ] No new use of `eval`, `exec`, `innerHTML`, or `dangerouslySetInnerHTML` without justification
- [ ] Error messages do not leak stack traces or internal paths to users
- [ ] New dependencies scanned for CVEs and license compliance
- [ ] File upload paths validated (type, size, name sanitization)
- [ ] Redirect targets validated against whitelist
- [ ] Rate limiting in place for auth endpoints and expensive operations
- [ ] Sensitive data not logged (passwords, tokens, PII)

---

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|-------------|---------|-----|
| `eval(userInput)` | Remote code execution | Parse data with JSON.parse or a schema validator |
| Concatenating SQL strings | SQL injection | Use parameterized queries or ORM |
| `res.send(req.query.msg)` | Reflected XSS | Escape output; use CSP |
| Storing passwords in plaintext | Credential exposure | Use bcrypt/argon2 with appropriate work factor |
| `jwt.verify(token, secret, { algorithms: ['none'] })` | JWT bypass | Always specify allowed algorithms explicitly |
| `npm install <pkg>` without review | Supply chain risk | Audit with Socket or Snyk before committing |
| Debug endpoints in production | Information disclosure | Guard with env check; disable in prod build |
| Catching all errors and returning 200 | Masking failures | Return appropriate status codes; log internally |

---

## Report Schema

```yaml
# .ai/reviews/security-<timestamp>.yml
audit_date: ""
project: ""
auditor: ""
summary:
  critical: 0
  high: 0
  medium: 0
  low: 0
findings:
  - id: "SEC-001"
    category: "A03 Injection"
    severity: critical
    location: "src/api/users.ts:42"
    description: ""
    reproduction: ""
    mitigation: ""
    status: open  # open | acknowledged | resolved
owasp_checklist:
  A01_access_control: pass  # pass | finding
  A02_crypto: pass
  A03_injection: finding
  A04_insecure_design: pass
  A05_misconfiguration: pass
  A06_vulnerable_components: finding
  A07_auth_failures: pass
  A08_integrity_failures: pass
  A09_logging: pass
  A10_ssrf: pass
```
