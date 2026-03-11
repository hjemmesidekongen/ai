# Design Plugin Architecture

## Pipeline

```
brand guideline (.ai/brand/{name}/)
  → visual-identity → tokens.yml + identity.yml
    → design-tokens → tailwind.json, variables.css, tokens.dtcg.json, contrast-matrix.md
```

## Components

- **3 skills**: visual-identity, design-tokens, design-loader
- **3 commands**: /segl:identity, /segl:tokens, /segl:status
- **0 agents, 0 hooks**

## Output Paths

All design artifacts live under `.ai/design/{name}/`:

```
.ai/design/{name}/
  tokens.yml              # Source of truth (OKLCH color, typography, spacing)
  identity.yml            # Design rationale
  tokens/
    tailwind.json          # Tailwind theme config
    variables.css          # CSS custom properties (:root + .dark)
    tokens.dtcg.json       # W3C Design Token Community Group format
    contrast-matrix.md     # WCAG contrast audit
```

## Token Schema

Defined in `resources/token-schema.yml`. All generated token files must conform to this schema.

## Key Design Decision

OKLCH color space for all palette generation. OKLCH provides perceptual uniformity — equal numeric steps produce equal perceived lightness changes, unlike HSL. This matters for generating consistent 10-stop color scales (50-950) and computing reliable contrast ratios.
