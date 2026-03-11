---
name: design-tokens
user_invocable: false
interactive: false
description: >
  Transforms visual identity tokens.yml into platform-consumable formats:
  Tailwind theme JSON, CSS custom properties, and DTCG JSON. Generates WCAG
  contrast matrix with colorblind safety notes. Use when generating platform
  tokens from visual identity, creating Tailwind theme, building CSS variables,
  or running /design:tokens.
depends_on: [visual-identity]
writes:
  - ".ai/design/{name}/tokens/tailwind.json"
  - ".ai/design/{name}/tokens/variables.css"
  - ".ai/design/{name}/tokens/tokens.dtcg.json"
  - ".ai/design/{name}/tokens/contrast-matrix.md"
reads:
  - ".ai/design/{name}/tokens.yml"
  - "plugins/design/resources/token-schema.yml"
model_tier: senior
model: sonnet
checkpoint:
  type: token_validation
  required_checks:
    - name: "tailwind_valid"
      verify: "tailwind.json is valid JSON with colors, fontFamily, spacing, borderRadius"
      fail_action: "Fix JSON structure or add missing keys"
    - name: "css_valid"
      verify: "variables.css has :root with --color-*, --font-*, --spacing-* and .dark block"
      fail_action: "Add missing variable categories or dark mode block"
    - name: "dtcg_valid"
      verify: "tokens.dtcg.json has $value and $type on every leaf token"
      fail_action: "Add missing $value/$type fields"
    - name: "wcag_body_text"
      verify: "All body text foreground/background pairs meet 4.5:1"
      fail_action: "Flag failures, suggest nearest passing shade from scale"
    - name: "contrast_matrix"
      verify: "contrast-matrix.md has light mode, dark mode, and colorblind tables"
      fail_action: "Generate missing sections"
  on_fail: "Fix and re-run checkpoint"
  on_pass: "Platform tokens ready for dev-engine consumption"
_source:
  origin: original
  ported_date: "2026-03-10"
  iteration: 1
  changes: ["initial creation"]
---

# Design Tokens

Transforms visual identity tokens.yml into platform-consumable formats and
validates accessibility compliance.

## Context

| Aspect | Details |
|--------|---------|
| **Input** | .ai/design/{name}/tokens.yml (from visual-identity) |
| **Outputs** | tailwind.json, variables.css, tokens.dtcg.json, contrast-matrix.md |
| **Location** | .ai/design/{name}/tokens/ |
| **Checkpoint** | 5 checks: tailwind, css, dtcg, wcag, contrast matrix |

## Context Resolution

1. Check `.ai/design/{name}/tokens.yml` — if missing, run visual-identity first
2. Read token-schema.yml for output format requirements

## Process

1. Read tokens.yml — extract primitives, semantic, typography, spacing, shadow
2. Generate tailwind.json — full color scales, fontFamily, fontSize, spacing, radius
3. Generate variables.css — :root organized by category + .dark override block
4. Generate tokens.dtcg.json — W3C format with $value, $type, $description
5. Compute WCAG contrast ratios for all foreground/background pairs
6. Generate contrast-matrix.md — EightShapes-style grid + colorblind notes
7. Run checkpoint — all 5 checks must pass

**Findings:** `.ai/design/{name}/findings.md` (2-action rule). Errors → findings.md.

## Execution

Read `references/process.md` for output templates, WCAG formula, and DTCG rules.
