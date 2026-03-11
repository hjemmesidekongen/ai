---
name: brand-evolve
description: "Refresh or reinvent an existing brand"
argument-hint: "[BRAND_NAME]"
---

# /våbenskjold:evolve

Guided reinvention of an existing brand guideline.

## Steps

1. **Resolve brand name** — use the argument if provided. If not, scan `.ai/brand/` and let the user pick.

2. **Verify brand exists** at `.ai/brand/{name}/`:
   - If exists → load and proceed
   - If not exists → "No brand found. Run /våbenskjold:create or /våbenskjold:audit first."

3. **Invoke brand-evolve** skill with the brand name.

4. **On completion** — report what changed and suggest reviewing with `/våbenskjold:status`.
