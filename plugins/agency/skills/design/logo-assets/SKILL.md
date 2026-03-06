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
      verify: "4 brand icon SVGs exist in design/logos/ (brand-icon.svg, brand-icon-light.svg, brand-icon-dark.svg, brand-icon-mono.svg)"
      fail_action: "Generate missing icon variants from primary logo"
    - name: "svg_validity"
      verify: "All SVG files are valid XML with proper viewBox and no raster content"
      fail_action: "Fix SVG structure — ensure valid XML, viewBox attribute, no embedded bitmaps"
    - name: "svg_file_size"
      verify: "Each SVG file is under 50KB"
      fail_action: "Optimize paths — simplify geometry, remove unnecessary metadata"
    - name: "preview_html"
      verify: "design/previews/logo-preview.html exists, all <img src> paths use relative refs to ../logos/ (not .ai/brands/), and every referenced file exists"
      fail_action: "Fix paths to use ../logos/ relative refs and verify all referenced SVG files exist"
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

## Process

Structured 5-phase interactive flow with fast-forward detection for existing logos.
Phases: Discovery, Concept Generation (20-25 SVGs), Refinement, Finalization (6 logo + 4 icon + 3 social SVGs), Optional Professional Refinement. See `references/process.md` for full step-by-step instructions.

## Findings & Execution

Write progress to `.ai/projects/[name]/design/findings.md`. **2-Action Rule:** save after every 2 generation actions. Log errors to state.yml errors array.
