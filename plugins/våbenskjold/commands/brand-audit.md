---
name: brand-audit
description: "Codify an existing brand from materials and samples"
argument-hint: "[BRAND_NAME]"
---

# /våbenskjold:audit

Extracts and codifies a brand from existing materials into structured guidelines.

## Steps

1. **Resolve brand name** — use the argument if provided, otherwise ask.

2. **Check for existing brand** at `.ai/brand/{name}/`:
   - If exists with complete files → warn: "Brand already codified. Use /våbenskjold:evolve to update."
   - If exists with partial files → offer to continue from existing data
   - If not exists → proceed with fresh audit

3. **Create directory** — `.ai/brand/{name}/`

4. **Invoke brand-audit** skill with the brand name.

5. **On completion** — report files created and suggest next steps.
