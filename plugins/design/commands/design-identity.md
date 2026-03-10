---
name: design-identity
description: "Create visual identity — color palettes, typography, spacing system"
argument-hint: "[NAME] [--from-brand NAME]"
---

# Design Identity

Creates a complete visual identity system using the visual-identity skill.

## Steps

1. **Resolve name** — if argument provided, use as design name. Otherwise:
   - Check if brand exists at `.ai/brand/` — use first brand name found
   - If no brand, ask user for a name

2. **Check existing** — if `.ai/design/{name}/tokens.yml` exists:
   - Print current identity summary
   - Ask: "Visual identity exists. Regenerate? (y/n)"
   - If `--force` passed, skip confirmation and regenerate

3. **Invoke visual-identity skill** with resolved name

4. **Report results**:
   - Color palettes generated (primary, secondary, accent)
   - Typography pairing selected
   - Spacing system defined
   - WCAG validation summary
   - Path to `.ai/design/{name}/tokens.yml`

5. **Suggest next step**: `/design:tokens` to generate platform-consumable formats
