---
name: logo-assets
user-invocable: false
description: >
  Runs a 5-phase logo design process producing all logo SVG variants, brand
  icon variants, social templates, and an interactive HTML preview. Use when
  designing a project logo, generating logo concepts, or creating the full
  logo system for an agency project. Produces 6 logo variants, 4 brand icon
  variants, 3 social templates (OG image, Twitter card, LinkedIn banner), and
  registers all assets in asset-registry.yml.
phase: design
depends_on: [brand-loader, design-tokens]
writes:
  - ".ai/projects/[name]/design/logos/*.svg"
  - ".ai/projects/[name]/design/logos/brand-icon/*.svg"
  - ".ai/projects/[name]/design/logos/social-templates/*.svg"
  - ".ai/projects/[name]/design/previews/logo-preview.html"
  - ".ai/projects/[name]/asset-registry.yml"
reads:
  - ".ai/projects/[name]/brand/brand-summary.yml"
  - ".ai/projects/[name]/brand/brand-reference.yml"
checkpoint:
  type: file_validation
  required_checks:
    - name: "logo_svg_variants"
    - name: "brand_icon_variants"
    - name: "svg_validity"
    - name: "svg_file_size"
    - name: "preview_html"
    - name: "assets_registered"
  on_fail: "Fix issues and re-run checkpoint. Advance only after all checks pass."
  on_pass: "Update state.yml, write recovery_notes, register assets, advance."
model_tier: principal
---

# Logo Assets

Design phase skill. Takes project brand data and produces a complete logo
system through a structured 5-phase process. Produces 6 logo SVG variants,
4 brand icon variants, 3 social template SVGs, an HTML preview page, and
registers all assets in asset-registry.yml.

## Context

**Reads:** brand-summary.yml — brand name, colors, typography, shape language,
mood; brand-reference.yml — full visual specification
**Writes:** logos/*.svg, brand-icon/*.svg, social-templates/*.svg,
previews/logo-preview.html, asset-registry.yml
**Checkpoint:** file_validation — 6 checks (logo_svg_variants, brand_icon_variants,
svg_validity, svg_file_size, preview_html, assets_registered)

## Process Summary

1. Read brand-summary.yml and brand-reference.yml — name, colors, typography, visual
2. **Phase 1 — Discovery:** Reflect brand context → logo type preference
   (wordmark/lettermark/abstract/combination/emblem) → reference logos → what
   to avoid → design brief summary; wait for user confirmation
3. **Phase 2 — Concept Generation:** 20-25 SVG concepts via 4 parallel sub-agents
   (wordmarks, abstract, combination, wildcard); HTML preview at
   design/previews/logo-preview.html; user picks 3-5 favorites
4. **Phase 3 — Refinement:** 3-4 variations per pick (weight/spacing/proportion/
   detail/color); multi-size testing (200px, 80px, 40px, 16px); background
   testing (white, dark, brand color, photography, light gray); final selection
5. **Phase 4 — Finalization:** 6 logo SVG variants → 4 brand icon variants →
   clear space + minimum size → misuse rules → update preview → confirm before
   writing all files
6. **Phase 4b — Social Templates:** OG image (1200x630), Twitter card (1200x628),
   LinkedIn banner (1584x396); each embeds final logo + brand colors; written
   to social-templates/
7. **Phase 5 — Optional refinement:** Figma/Illustrator import, CMYK/Pantone for
   print, trademark search guidance; noted in project state
8. Register all SVG outputs in asset-registry.yml (logos, icons, social templates)
9. Run file_validation checkpoint (6 checks); fix failures; advance only
   after all checks pass
10. Write recovery notes to state.yml
## Findings Persistence
Write progress to `.ai/projects/[name]/design/findings.md`. **2-Action Rule:** save after every 2 generation actions. Log errors to state.yml errors array.
## Execution

Before executing, read `references/process.md` for detailed instructions.
