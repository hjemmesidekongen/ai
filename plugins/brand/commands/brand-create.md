---
name: brand-create
description: "Create a new brand from scratch through research and sparring"
argument-hint: "[BRAND_NAME]"
---

# /brand:create

Creates a new brand through market research and interactive sparring.

## Steps

1. **Resolve brand name** — use the argument if provided, otherwise ask.

2. **Check for existing brand** at `.ai/brand/{name}/`:
   - If exists and has complete files → warn: "Brand already exists. Use /brand:evolve to update."
   - If exists with partial files → offer to resume: "Found partial brand. Continue from where you left off?"
   - If not exists → proceed with creation

3. **Create directory** — `.ai/brand/{name}/`

4. **Invoke brand-strategy** skill with the brand name.

5. **On completion** — report files created and suggest next steps:
   - "Use /brand:apply to wire this brand into a project"
   - "Use /brand:status to see what was created"
