---
name: design-tokens
description: "Generate platform tokens — Tailwind, CSS variables, DTCG JSON"
argument-hint: "[NAME]"
---

# Design Tokens

Generates platform-consumable token files from visual identity using the
design-tokens skill.

## Steps

1. **Resolve name** — if argument provided, use it. Otherwise scan `.ai/design/`
   for available designs.

2. **Verify prerequisite** — check `.ai/design/{name}/tokens.yml` exists.
   If missing: "No visual identity found. Run `/design:identity` first."

3. **Check existing tokens** — if `.ai/design/{name}/tokens/` has files:
   - Print what exists
   - Ask: "Platform tokens exist. Regenerate? (y/n)"
   - If `--force` passed, skip confirmation

4. **Invoke design-tokens skill** with resolved name

5. **Report results**:
   - Files generated: tailwind.json, variables.css, tokens.dtcg.json
   - WCAG contrast validation summary (pass/fail counts)
   - Colorblind safety notes summary
   - Path to `.ai/design/{name}/tokens/`
