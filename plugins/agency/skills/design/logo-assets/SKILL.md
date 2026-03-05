---
name: logo-assets
user-invocable: false
description: >
  Designs a complete logo system: 6 logo SVG variants, 4 brand icon variants,
  3 social templates (OG image, Twitter card, LinkedIn banner), and an
  interactive HTML preview. Use when designing a project logo, creating logo
  concepts, generating logo variants for light/dark backgrounds, building a
  responsive logo system, or running /agency:design logo phase. Produces
  production-ready SVGs and registers all assets in asset-registry.yml.
phase: 2
depends_on: [brand-loader]
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
      verify: "6 logo SVGs exist in design/logos/ (primary, reversed, monochrome, icon, horizontal, stacked)"
      fail_action: "Generate missing variants using brand data"
    - name: "brand_icon_variants"
      verify: "4 brand icon SVGs exist in design/logos/brand-icon/ (default, monochrome, small, favicon)"
      fail_action: "Generate missing icon variants from primary logo"
    - name: "svg_validity"
      verify: "All SVG files are valid XML with proper viewBox and no raster content"
      fail_action: "Fix SVG structure — ensure valid XML, viewBox attribute, no embedded bitmaps"
    - name: "svg_file_size"
      verify: "Each SVG file is under 50KB"
      fail_action: "Optimize paths — simplify geometry, remove unnecessary metadata"
    - name: "preview_html"
      verify: "design/previews/logo-preview.html exists and embeds all logo variants"
      fail_action: "Generate preview HTML with all variants on light/dark backgrounds"
    - name: "assets_registered"
      verify: "All logo and icon SVGs are registered in asset-registry.yml with correct paths"
      fail_action: "Register missing assets in asset-registry.yml"
  on_fail: "Fix issues and re-run checkpoint. Advance only after all checks pass."
  on_pass: "Update state.yml, write recovery_notes, register assets, advance."
model_tier: principal
model: opus
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

### Pre-check: Fast-forward detection

Before starting the interactive flow, check if production logos already exist
(e.g. from /brand:generate):

```
existing_logos = glob(.ai/projects/[name]/design/logos/*.svg)
  OR glob(.ai/projects/[name]/brand/logos/*.svg)
  OR glob(.ai/projects/[name]/brand/brand-package/logos/*.svg)

if existing_logos.count >= 4:
  Report existing assets found:
    "Found {count} existing logo SVGs. These appear to be from a prior
     brand generation run."
    List files found.
  Ask user:
    "[1] Fast-forward — validate existing logos, copy to design/logos/,
         generate any missing variants, and run checkpoint
     [2] Start fresh — run the full 5-phase interactive logo design process"

  if user picks [1] (fast-forward):
    - Validate existing SVGs (valid XML, viewBox, no raster, <50KB)
    - Copy to design/logos/ if not already there
    - Identify missing variants from the 6 required (primary, reversed,
      monochrome, icon, horizontal, stacked) and 4 brand icons
    - Generate only missing variants
    - Generate logo-preview.html
    - Generate social templates if missing
    - Skip to step 8 (register + checkpoint)

  if user picks [2]:
    Proceed with full interactive flow below
```

### Full interactive flow

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
9. Run file_validation checkpoint (6 checks); fix failures; advance only after all checks pass
10. Write recovery notes to state.yml

## Findings & Execution

Write progress to `.ai/projects/[name]/design/findings.md`. **2-Action Rule:** save after every 2 generation actions. Log errors to state.yml errors array. Before executing, read `references/process.md` for detailed instructions.
