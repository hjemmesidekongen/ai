---
name: package-audit
description: >
  npm audit workflow, outdated dependency triage, license compliance checking,
  and update strategies for patch, minor, and major version bumps. Covers
  Renovate/Dependabot config and monorepo update coordination.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "package audit"
  - "npm audit"
  - "outdated deps"
  - "dependency update"
reads:
  - "package.json"
  - "package-lock.json / yarn.lock / pnpm-lock.yaml"
  - ".npmrc"
writes:
  - ".ai/reviews/package-audit-<timestamp>.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "audit_run"
      verify: "npm audit (or equivalent) executed — output captured with vulnerability counts"
      fail_action: "Run the audit command before assessing — do not guess CVE status"
    - name: "outdated_triaged"
      verify: "All outdated packages assessed with update strategy (patch/minor/major/hold)"
      fail_action: "Run npm outdated and assign a strategy to each package"
    - name: "licenses_checked"
      verify: "License compliance verified — no prohibited licenses in production deps"
      fail_action: "Run license-checker and compare against allowed/denied lists"
    - name: "critical_vulns_addressed"
      verify: "All critical and high CVEs have a resolution path documented"
      fail_action: "Document fix, workaround, or accepted risk for every critical/high finding"
  on_fail: "Package audit incomplete — all checks required before reporting"
  on_pass: "Audit complete — update plan and license report ready for review"
_source:
  origin: "smedjen"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Built for smedjen covering npm audit, license compliance, and update triage"
---

# package-audit

Structured dependency audit: security vulnerabilities, outdated packages, license
compliance, and update planning. Produces a triage report with per-package decisions.

## Audit Scope

| Area | What gets checked |
|------|------------------|
| CVEs | npm audit / Snyk / Socket — vulnerability counts by severity |
| Outdated packages | npm outdated — current vs wanted vs latest |
| License compliance | license-checker — compare against allowed/denied list |
| Lock file integrity | Committed lock file matches package.json ranges |
| Automation config | Renovate / Dependabot configured and scoped correctly |

## Update Strategies

| Strategy | When to use |
|----------|------------|
| patch | Apply immediately — bug fixes, no API change |
| minor | Test in branch — new features, backward compatible |
| major | Assess breaking changes, plan migration, test thoroughly |
| hold | Pin with documented reason — incompatible, high-risk, awaiting upstream |

## Rules

- Never run `npm audit fix --force` without reviewing what it changes first.
- Pin major version bumps behind a branch — do not update directly on main.
- A held package requires a documented reason and a revisit date.
- License violations in production deps are blockers — dev dep violations are warnings.

See `references/process.md` for audit commands, semver decision rules, license lists,
Renovate/Dependabot config templates, and report schema.
