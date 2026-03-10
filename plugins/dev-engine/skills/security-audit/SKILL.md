---
name: security-audit
description: >
  OWASP Top 10 vulnerability assessment, dependency scanning, secret detection,
  CSP and security header review, SAST/DAST guidance, and supply chain security.
  Use when hardening a codebase before release, reviewing a PR with auth or input
  handling changes, or responding to a reported vulnerability.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "security audit"
  - "owasp"
  - "security review"
  - "vulnerability scan"
reads:
  - "source files (context-dependent)"
  - "package.json / package-lock.json"
  - ".env.* files (presence check only)"
writes:
  - ".ai/reviews/security-<timestamp>.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "owasp_top10_checked"
      verify: "All 10 OWASP categories assessed with explicit pass or finding per category"
      fail_action: "Work through each OWASP category systematically — do not skip"
    - name: "secrets_scanned"
      verify: "Secret detection run — no hardcoded credentials, tokens, or keys in source"
      fail_action: "Scan all config files, env files, and committed history references"
    - name: "deps_audited"
      verify: "Dependency audit completed — known CVEs identified and severity noted"
      fail_action: "Run npm audit or equivalent before marking audit complete"
    - name: "headers_reviewed"
      verify: "CSP and security headers assessed against OWASP recommendations"
      fail_action: "Check response headers against the security headers checklist"
    - name: "critical_findings_blocked"
      verify: "No critical findings left unaddressed in the report"
      fail_action: "Escalate critical findings — do not proceed until acknowledged"
  on_fail: "Security audit incomplete — all categories must be checked before reporting"
  on_pass: "Audit complete — findings ranked by severity, mitigations documented"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Built for dev-engine covering OWASP, secrets, deps, and headers"
---

# security-audit

Structured security review: OWASP Top 10, dependency CVEs, secrets, HTTP headers.
Produces a severity-ranked findings report.

## Review Scope

| Area | What gets checked |
|------|------------------|
| OWASP Top 10 | All 10 categories, each with explicit pass or finding |
| Dependency CVEs | npm audit, Snyk, or Socket — known vulnerabilities with CVSS scores |
| Secret detection | Hardcoded credentials, tokens, API keys in source and config |
| CSP / headers | Content-Security-Policy, HSTS, X-Frame-Options, referrer policy |
| Supply chain | Lock file integrity, unpinned deps, suspicious package names |

## Rules

- Assess every OWASP category. A "no finding" is still a required entry.
- Any credential in source is critical — never mark as "probably fine".
- Flag missing headers individually — do not bundle them as one finding.
- SAST findings require a reproduction path, not just a pattern match.
- Severity: critical = block release; high = fix this release; medium = schedule; low = backlog.

See `references/process.md` for the full OWASP checklist, scanning commands,
header requirements, and report schema.
