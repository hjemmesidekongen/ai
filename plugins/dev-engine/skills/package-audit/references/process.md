# package-audit: Process Reference

## npm audit Workflow

```bash
# Run full audit, capture output
npm audit

# JSON output for programmatic processing
npm audit --json > audit-report.json

# Audit only production dependencies
npm audit --omit=dev

# Safe auto-fix (patch-level only, no breaking changes)
npm audit fix

# Preview what --force would change before applying
npm audit fix --force --dry-run
```

**Never run `npm audit fix --force` blindly** — it can bump major versions and introduce breaking changes. Always review the dry-run output first.

### Equivalents for other package managers
```bash
# yarn
yarn audit
yarn audit --json

# pnpm
pnpm audit
pnpm audit --fix
```

---

## Snyk Integration

```bash
npm install -g snyk && snyk auth

# One-time test
snyk test

# Test with a blocking severity threshold (CI use)
snyk test --severity-threshold=high

# Monitor project continuously (uploads snapshot to Snyk dashboard)
snyk monitor

# Fix known vulnerabilities
snyk fix
```

### Snyk in CI (GitHub Actions)
```yaml
- name: Snyk security scan
  uses: snyk/actions/node@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  with:
    args: --severity-threshold=high
```

---

## Socket Integration

Socket detects malicious behavior, not just known CVEs.

```bash
npm install -g @socketsecurity/cli
socket scan .
```

Use Socket for new dependency additions — it flags typosquatting, install scripts that
exfiltrate data, and packages with sudden maintainer changes. Complement, not replace, npm audit.

---

## Outdated Dependency Triage

```bash
# Show all outdated packages
npm outdated

# Check a specific package
npm view <package> versions --json
```

### Output interpretation
- **Current**: installed version
- **Wanted**: latest version satisfying package.json range
- **Latest**: latest published version

### Triage decision tree

```
Is there a known CVE? → Yes → Patch/update immediately regardless of semver
Is it a patch bump (x.y.Z)? → Yes → Update immediately, low risk
Is it a minor bump (x.Y.z)? → Yes → Update in branch, run tests
Is it a major bump (X.y.z)? → Yes → Read CHANGELOG, assess breaking changes, plan migration
Is the package abandoned (>2 years no update)? → Find replacement or fork
Is it an internal/tooling dep (eslint, jest, etc.)? → Lower priority, update in batches
```

---

## Update Strategies

### Patch updates
Apply immediately. These are bug and security fixes. Semver guarantees no API change.
```bash
npm update  # updates all packages to wanted (within package.json ranges)
```

### Minor updates
Test in a branch. New features but backward compatible per semver. In practice, check
the CHANGELOG for any unintentional breaking changes.
```bash
npm install <package>@<minor-version>
```

### Major updates
Treat as a migration. Steps:
1. Read the CHANGELOG / migration guide
2. Identify breaking changes that affect your usage
3. Create a dedicated branch
4. Update one major version at a time (don't skip versions for large libraries)
5. Run full test suite + manual smoke test
6. Review TypeScript type errors — they reveal API shape changes

### Holding a package
Document the hold in a comment in package.json or a `deps-hold.md` file:
```json
// package.json — add a comment convention or use .npmrc notes
"some-lib": "2.3.1"  // HOLD: v3 drops Node 18 support, revisit 2026-Q3
```

---

## Semver Understanding

```
MAJOR.MINOR.PATCH  →  2.4.1

MAJOR: breaking changes — requires migration
MINOR: new features, backward compatible
PATCH: bug fixes, backward compatible

Ranges in package.json:
  "^2.4.1"  → accepts 2.x.x (>=2.4.1 <3.0.0) — most common
  "~2.4.1"  → accepts 2.4.x (>=2.4.1 <2.5.0) — conservative
  "2.4.1"   → exact pin — maximum control, highest maintenance
  "*"        → any version — never use in production deps
```

Note: semver is a contract, not a guarantee. High-traffic packages sometimes ship
breaking changes in minor versions. Always read the CHANGELOG for major dependencies.

---

## License Compliance

### Allowed / denied lists (typical policy)
```
Allowed (production deps):
  MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause, ISC, 0BSD, CC0-1.0

Caution (legal review required):
  LGPL-2.0, LGPL-2.1, LGPL-3.0, MPL-2.0, CDDL-1.0

Denied (production deps):
  GPL-2.0, GPL-3.0, AGPL-3.0, SSPL-1.0, Commons Clause
  Unlicensed / UNLICENSED (no explicit permission)
```

LGPL libraries can be used without copyleft obligations if linked dynamically (standard
npm usage), but confirm with legal for commercial products.

### license-checker
```bash
npm install -g license-checker

# List all licenses
license-checker --production --json > licenses.json

# Fail on specific licenses
license-checker --production --failOn 'GPL-3.0;AGPL-3.0'

# Exclude packages matching a pattern
license-checker --production --excludePackages 'your-internal-package'
```

### FOSSA / automated compliance
For teams with strict compliance requirements, FOSSA integrates into CI and maintains
a policy file that blocks PRs introducing non-compliant licenses.

---

## Renovate Configuration

```json
// renovate.json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "schedule": ["before 6am on Monday"],
  "automerge": true,
  "automergeType": "pr",
  "packageRules": [
    {
      "matchUpdateTypes": ["patch"],
      "automerge": true
    },
    {
      "matchUpdateTypes": ["minor"],
      "automerge": false,
      "addLabels": ["dependencies"]
    },
    {
      "matchUpdateTypes": ["major"],
      "automerge": false,
      "addLabels": ["dependencies", "breaking-change"]
    }
  ]
}
```

---

## Dependabot Configuration

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
    ignore:
      - dependency-name: "some-legacy-lib"
        versions: [">=3.0.0"]
```

---

## Monorepo Update Strategy

1. Update shared deps at workspace root — propagates to all packages via hoisting.
2. For package-specific overrides, document the reason; overrides are technical debt.
3. Run `npm audit` at root — it covers the entire dependency tree.
4. Use Renovate's `groupName` to batch related package updates into a single PR:
   ```json
   { "groupName": "react", "matchPackagePatterns": ["^react", "^@types/react"] }
   ```
5. Test affected packages after any shared dep update — hoisting means one package's
   update can break another's assumptions.

---

## Breaking Change Assessment Checklist

Before merging a major version update:
- [ ] CHANGELOG reviewed — all breaking changes identified
- [ ] Breaking changes that affect this codebase documented
- [ ] TypeScript errors resolved (type changes reveal API shape changes)
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] No peer dependency conflicts (`npm install` output clean)
- [ ] Bundle size impact checked for frontend deps (use `bundlephobia.com`)
- [ ] Runtime behavior verified in dev environment

---

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|-------------|---------|-----|
| `npm audit fix --force` without review | Can introduce breaking major version bumps | Always dry-run first, review changes |
| Ignoring all audit warnings | CVEs accumulate silently | Triage each finding; document deferred ones |
| `"*"` or `"latest"` in package.json | Non-reproducible builds | Pin to semver ranges; commit lock file |
| Not committing lock file | Builds are not reproducible across environments | Always commit package-lock.json |
| Batching many major bumps together | Impossible to isolate which change broke something | One major version bump per branch |
| No license check in CI | Non-compliant license enters codebase undetected | Run license-checker as a CI gate |
| Holding packages indefinitely with no revisit date | Security debt compounds | Set a revisit date when holding |
| Updating deps immediately before a release | No time to catch regressions | Update deps at start of sprint, not end |

---

## Report Schema

```yaml
# .ai/reviews/package-audit-<timestamp>.yml
audit_date: ""
project: ""
package_manager: npm  # npm | yarn | pnpm
summary:
  critical_vulns: 0
  high_vulns: 0
  moderate_vulns: 0
  low_vulns: 0
  outdated_packages: 0
  license_violations: 0
vulnerabilities:
  - package: ""
    installed_version: ""
    patched_version: ""
    severity: critical  # critical | high | moderate | low
    cve: ""
    resolution: update  # update | workaround | accepted-risk
outdated:
  - package: ""
    current: ""
    wanted: ""
    latest: ""
    strategy: patch  # patch | minor | major | hold
    hold_reason: ""  # required if strategy is hold
    hold_revisit: ""
licenses:
  compliant: true
  violations:
    - package: ""
      license: ""
      status: denied  # denied | review-required
```
