---
name: design-tokens
user-invocable: false
description: >
  Transforms brand tokens into consumable design token formats: Tailwind config,
  CSS custom properties, and DTCG JSON. Includes WCAG accessibility validation
  (contrast ratios, colorblind safety, dark mode). Use when generating design
  tokens, creating Tailwind theme, building CSS variables, validating color
  accessibility, or running /agency:design token phase.
phase: 2
depends_on: [brand-loader]
writes:
  - ".ai/projects/[name]/design/tokens/tailwind.config.json"
  - ".ai/projects/[name]/design/tokens/variables.css"
  - ".ai/projects/[name]/design/tokens/tokens.dtcg.json"
  - ".ai/projects/[name]/design/tokens/contrast-matrix.md"
  - ".ai/projects/[name]/asset-registry.yml"
reads:
  - ".ai/projects/[name]/brand/brand-summary.yml"
model_tier: senior
checkpoint:
  type: accessibility_validation
  required_checks:
    - name: "tailwind_config_valid"
      verify: "tailwind.config.json is valid JSON with colors, fontFamily, spacing keys"
    - name: "css_variables_valid"
      verify: "variables.css has :root block with --color-*, --font-*, --spacing-* vars"
    - name: "dtcg_valid"
      verify: "tokens.dtcg.json follows DTCG format with $value, $type fields"
    - name: "wcag_aa_body"
      verify: "All body text pairs meet 4.5:1 contrast ratio"
    - name: "wcag_aa_large"
      verify: "All large text pairs meet 3:1 contrast ratio"
    - name: "colorblind_notes"
      verify: "Colorblind safety notes exist for primary and semantic colors"
    - name: "assets_registered"
      verify: "All 3 token files registered in asset-registry.yml"
  on_fail: "Fix and re-run"
  on_pass: "Update state.yml, advance to component-specs"
---

# Design Tokens

Phase 2 of agency design. Transforms brand-summary.yml tokens into consumable
formats for developers and design tools, then validates all color pairs against
WCAG accessibility standards.

## Context

**Reads:** `.ai/projects/[name]/brand/brand-summary.yml`
**Writes:** `tailwind.config.json`, `variables.css`, `tokens.dtcg.json`,
`contrast-matrix.md`, `asset-registry.yml`
**Checkpoint:** accessibility_validation — 7 checks
**Depends on:** brand-loader must be complete

## Process Summary

1. Read brand-summary.yml — extract colors (with scales), typography, spacing,
   border-radius; stop if brand-loader hasn't run
2. **Generate Tailwind config** — tailwind.config.json with full color scales,
   fontFamily, fontSize scale, spacing, borderRadius, dark mode class strategy
3. **Generate CSS custom properties** — variables.css with :root block organized
   by category (color, font, spacing, radius, shadow)
4. **Generate DTCG JSON** — tokens.dtcg.json in Design Tokens Community Group format
   with $value, $type, $description per token
5. **WCAG validation** (ported from brand-guideline typography-color):
   - Compute contrast ratios for all foreground/background pairs (WCAG formula)
   - Validate WCAG AA compliance — flag failures, suggest nearest passing shade
   - Generate colorblind safety notes (protanopia, deuteranopia, tritanopia)
   - Generate dark mode token variants with validated pairs
   - Output contrast matrix (EightShapes-style grid)
6. **Register assets** in asset-registry.yml (3 token files + contrast-matrix.md)
7. Run checkpoint — all 7 checks must pass before advancing

## Findings Persistence

Write intermediate results to `.ai/projects/[name]/design/findings.md`. **2-Action Rule:** after every 2 research/generation actions, IMMEDIATELY save progress to findings.md. Log all errors to state.yml errors array — never repeat a failed approach.
## Execution

Before executing, read `references/process.md` for detailed instructions.
