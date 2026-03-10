---
name: brand-status
description: "Show brand status and guideline summary"
argument-hint: "[BRAND_NAME]"
---

# /brand:status

Shows the current state of a brand's guidelines.

## Steps

1. **Resolve brand** — if name provided, check that brand. If not, scan `.ai/brand/` for all brands.

2. **For each brand found**, report:
   - Brand name and tagline (from guideline.yml)
   - Completeness: which files exist (guideline.yml, voice.yml, values.yml, dos-and-donts.md)
   - Voice archetype and key scales (from voice.yml)
   - Number of core values (from values.yml)
   - Content pillars count (from guideline.yml)

3. **If no brands found** — "No brands defined yet. Run /brand:create to get started."

4. **Format as table** for multiple brands, detailed view for single brand.
