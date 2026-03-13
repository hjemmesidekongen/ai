# Opportunities

Systemic improvements surfaced during sessions. Claude adds entries here when
errors reveal fragility or refactors are out of scope for the current task.

Reviewed at the start of each planning wave.

## Format

Each entry: what was observed, why it matters, and where to look.

```
### [short title]
- **Observed:** what happened
- **Impact:** why it matters
- **Location:** file or component affected
- **Added:** date
```

## Entries

### context-manager plan-dispatch mode
- **Observed:** context-manager's context_package format doesn't align with plan-engine Build phase expectations
- **Impact:** Plan-dispatched agents may receive mismatched context packages
- **Location:** plugins/kronen/agents/context-manager.md
- **Added:** 2026-03-13

### plan-verification-gate YAML parsing robustness
- **Observed:** Hook uses sed/awk for YAML parsing — fragile with complex plan.yml structures
- **Impact:** Edge cases with inline arrays, quoted values, or nested structures may bypass the gate
- **Location:** plugins/kronen/scripts/plan-verification-gate.sh
- **Added:** 2026-03-13

### Command frontmatter convention drift
- **Observed:** Some commands use `argument-hint`, others use `usage` in frontmatter
- **Impact:** Inconsistent schema across commands
- **Location:** plugins/kronen/commands/
- **Added:** 2026-03-13

### Agent schema: explicit no-tools marker
- **Observed:** `tools: []` is ambiguous — reviewers flag it as both "no tools" and "wildcard access"
- **Impact:** Zero-tool agents (plan-verifier, plan-classifier) trigger false positives in reviews
- **Location:** Agent frontmatter schema
- **Added:** 2026-03-13
