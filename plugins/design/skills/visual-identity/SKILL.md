---
name: visual-identity
user_invocable: true
interactive: true
description: >
  Creates a complete visual identity system from brand direction or user input.
  Generates color palettes (OKLCH-based, 10-stop scales), typography pairing,
  spacing system, and foundational design decisions. Outputs tokens.yml as the
  primary design truth file. Use when creating visual identity from brand
  guidelines, building color palettes, selecting typography, or running
  /design:identity.
depends_on: []
writes:
  - ".ai/design/{name}/tokens.yml"
  - ".ai/design/{name}/identity.yml"
reads:
  - ".ai/brand/{name}/guideline.yml"
  - ".ai/brand/{name}/voice.yml"
  - "plugins/design/resources/token-schema.yml"
model_tier: senior
model: sonnet
checkpoint:
  type: design_validation
  required_checks:
    - name: "color_palettes_complete"
      verify: "tokens.yml has primary, secondary, accent palettes with 10-stop scales (50-950)"
      fail_action: "Generate missing color scales using OKLCH interpolation"
    - name: "semantic_colors_mapped"
      verify: "tokens.yml has semantic colors (success, warning, error, info) with dark mode variants"
      fail_action: "Map semantic colors from palette and compute dark mode overrides"
    - name: "typography_defined"
      verify: "tokens.yml has heading, body, mono families with full type scale"
      fail_action: "Select font pairing and generate type scale"
    - name: "spacing_system"
      verify: "tokens.yml has base unit and spacing scale (8+ steps)"
      fail_action: "Generate spacing scale from base unit"
    - name: "wcag_body_text"
      verify: "Primary text on background meets 4.5:1 contrast"
      fail_action: "Adjust text color or background to meet WCAG AA"
    - name: "identity_rationale"
      verify: "identity.yml documents color theory rationale and typography pairing logic"
      fail_action: "Write design rationale for choices made"
  on_fail: "Fix and re-run checkpoint"
  on_pass: "Visual identity complete — ready for design-tokens generation"
_source:
  origin: original
  ported_date: "2026-03-10"
  iteration: 1
  changes: ["initial creation"]
---

# Visual Identity

Creates the foundational visual system: color, typography, spacing. Reads brand
guidelines when available; gathers minimum direction from user when not.

## Context

| Aspect | Details |
|--------|---------|
| **Input** | Brand guideline (if exists) OR user-provided direction |
| **Output** | tokens.yml (design truth), identity.yml (rationale) |
| **Location** | .ai/design/{name}/ |
| **Checkpoint** | 6 checks: palettes, semantic, typography, spacing, WCAG, rationale |

## Context Resolution

1. Check `.ai/brand/{name}/` — if guideline.yml exists, extract color/personality/industry
2. If no brand: ask user for industry, mood (2-3 adjectives), color preferences
3. Proceed with whatever context is available

## Process

1. Context resolution — load brand or gather user input
2. Color palettes — OKLCH-based primary/secondary/accent, 10-stop scales (50-950)
3. Semantic mapping — success/warning/error/info + surface/text/border + dark mode
4. Typography — heading + body + mono families, type scale (display → caption)
5. Spacing — base unit, scale, radius, shadow tokens
6. WCAG validation — all foreground/background pairs against AA thresholds
7. Write tokens.yml + identity.yml

**Findings:** `.ai/design/{name}/findings.md` (2-action rule). Errors → findings.md.

## Execution

Read `references/process.md` for OKLCH generation, typography pairing, and output format.
