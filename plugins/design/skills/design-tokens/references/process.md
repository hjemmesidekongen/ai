# Design Tokens — Detailed Process

## Input: tokens.yml

Read `.ai/design/{name}/tokens.yml` and extract:
- `primitives.color` — all palette scales (primary, secondary, accent, neutral, red, amber, green)
- `semantic.color` — intent mappings (primary, success, warning, error, info, surfaces, text, border)
- `semantic.dark` — dark mode overrides
- `typography` — families, scale, weights
- `spacing` — base unit and scale
- `radius` — named sizes
- `shadow` — elevation levels

If tokens.yml is missing, stop and report: "Run visual-identity first."

## Step 1: Generate tailwind.json

Tailwind theme extension format:

```json
{
  "theme": {
    "extend": {
      "colors": {
        "primary": { "50": "#hex", "100": "#hex", ..., "950": "#hex", "DEFAULT": "#hex" },
        "secondary": { ... },
        "accent": { ... },
        "neutral": { ... },
        "success": "#hex",
        "warning": "#hex",
        "error": "#hex",
        "info": "#hex"
      },
      "fontFamily": {
        "heading": ["Font Name", "sans-serif"],
        "body": ["Font Name", "sans-serif"],
        "mono": ["Font Name", "monospace"]
      },
      "fontSize": {
        "display": ["3.5rem", { "lineHeight": "1.1", "fontWeight": "700" }],
        "h1": ["2.5rem", { "lineHeight": "1.2", "fontWeight": "700" }],
        "h2": ["2rem", { "lineHeight": "1.25", "fontWeight": "600" }],
        "h3": ["1.5rem", { "lineHeight": "1.3", "fontWeight": "600" }],
        "h4": ["1.25rem", { "lineHeight": "1.4", "fontWeight": "500" }],
        "body": ["1rem", { "lineHeight": "1.6", "fontWeight": "400" }],
        "body-sm": ["0.875rem", { "lineHeight": "1.5", "fontWeight": "400" }],
        "caption": ["0.75rem", { "lineHeight": "1.4", "fontWeight": "500" }]
      },
      "spacing": { "1": "0.25rem", "2": "0.5rem", ... },
      "borderRadius": { "sm": "0.25rem", "md": "0.375rem", ... },
      "boxShadow": { "sm": "...", "md": "...", "lg": "..." }
    }
  },
  "darkMode": "class"
}
```

Rules:
- DEFAULT on each palette = the semantic reference stop (typically 500-600)
- Map actual font names from tokens.yml
- Include all spacing steps from tokens.yml
- `darkMode: "class"` always

## Step 2: Generate variables.css

```css
/* Design Tokens — {name}
   Generated from tokens.yml by design-tokens skill */

:root {
  /* --- Colors: Primary --- */
  --color-primary-50: #hex;
  --color-primary-100: #hex;
  /* ... through 950 */
  --color-primary: var(--color-primary-600);

  /* --- Colors: Secondary --- */
  /* ... same pattern ... */

  /* --- Colors: Semantic --- */
  --color-success: #hex;
  --color-warning: #hex;
  --color-error: #hex;
  --color-info: #hex;

  /* --- Surfaces --- */
  --color-background: #hex;
  --color-surface: #hex;
  --color-surface-elevated: #hex;

  /* --- Text --- */
  --color-foreground: #hex;
  --color-foreground-secondary: #hex;
  --color-foreground-muted: #hex;

  /* --- Border --- */
  --color-border: #hex;
  --color-border-strong: #hex;
  --color-ring: #hex;

  /* --- Typography --- */
  --font-heading: "Font Name", sans-serif;
  --font-body: "Font Name", sans-serif;
  --font-mono: "Font Name", monospace;

  --text-display: 3.5rem;
  --text-h1: 2.5rem;
  /* ... through caption */

  /* --- Spacing --- */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  /* ... all steps */

  /* --- Radius --- */
  --radius-sm: 0.25rem;
  /* ... all sizes */

  /* --- Shadow --- */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  /* ... all levels */
}

.dark {
  --color-background: #hex;
  --color-surface: #hex;
  --color-surface-elevated: #hex;
  --color-foreground: #hex;
  --color-foreground-secondary: #hex;
  --color-foreground-muted: #hex;
  --color-primary: var(--color-primary-400);
  --color-accent: var(--color-accent-400);
  --color-border: #hex;
  --color-border-strong: #hex;
}
```

Rules:
- Every primitive scale step gets a variable
- Semantic colors as shorthand vars
- .dark block only overrides tokens that change
- Font family vars must quote names with spaces

## Step 3: Generate tokens.dtcg.json

W3C Design Tokens Community Group format:

```json
{
  "color": {
    "primary": {
      "50": { "$value": "#hex", "$type": "color", "$description": "Lightest — backgrounds" },
      "100": { "$value": "#hex", "$type": "color", "$description": "Light — subtle backgrounds" },
      ...
    },
    "semantic": {
      "success": { "$value": "#hex", "$type": "color", "$description": "Success feedback" },
      ...
    }
  },
  "font": {
    "family": {
      "heading": { "$value": "Font Name, sans-serif", "$type": "fontFamily" },
      "body": { "$value": "Font Name, sans-serif", "$type": "fontFamily" },
      "mono": { "$value": "Font Name, monospace", "$type": "fontFamily" }
    },
    "size": {
      "display": { "$value": "3.5rem", "$type": "dimension" },
      ...
    },
    "weight": {
      "regular": { "$value": 400, "$type": "fontWeight" },
      ...
    }
  },
  "spacing": {
    "1": { "$value": "0.25rem", "$type": "dimension" },
    ...
  },
  "radius": {
    "sm": { "$value": "0.25rem", "$type": "dimension" },
    ...
  },
  "shadow": {
    "sm": { "$value": { "offsetX": "0", "offsetY": "1px", "blur": "2px", "spread": "0", "color": "rgb(0 0 0 / 0.05)" }, "$type": "shadow" },
    ...
  }
}
```

Rules:
- Every leaf token must have $value and $type
- $description on every color token (describe intended use)
- Valid $type values: color, dimension, fontFamily, fontWeight, duration, cubicBezier, shadow
- Max 3 levels of nesting

## Step 4: WCAG Contrast Validation

### Formula
```
Relative luminance per channel:
  sRGB = channel / 255
  linear = sRGB <= 0.04045 ? sRGB/12.92 : ((sRGB+0.055)/1.055)^2.4
  L = 0.2126*R + 0.7152*G + 0.0722*B

Contrast ratio = (L_lighter + 0.05) / (L_darker + 0.05)
```

### Required pairs

Light mode:
| Foreground | Background | Threshold |
|------------|------------|-----------|
| foreground | background | 4.5:1 |
| foreground-secondary | background | 4.5:1 |
| foreground-muted | background | 3:1 |
| primary | background | 3:1 |
| white | primary | 4.5:1 |
| success | background | 3:1 |
| error | background | 4.5:1 |

Dark mode:
| Foreground | Background | Threshold |
|------------|------------|-----------|
| dark.foreground | dark.background | 4.5:1 |
| dark.foreground-secondary | dark.background | 4.5:1 |
| dark.primary | dark.background | 4.5:1 |

### Failure handling
For failing pairs: scan the palette scale for nearest passing shade.
Flag decorative-only colors (e.g., warning yellow on white).

### Colorblind assessment
For each primary/accent/semantic color, note risk under:
- Protanopia (red-blind, ~1% male): high R + low G → flag
- Deuteranopia (green-blind, ~5% male): similar R/G → flag
- Tritanopia (blue-blind, ~0.01%): high B similar to yellow → flag

Rule: never rely on color alone — always pair with icon/label.

## Step 5: Generate contrast-matrix.md

EightShapes-style grid format:

```markdown
# Contrast Matrix — {name}

## Light Mode

| | background | surface | surface-elevated |
|---|---|---|---|
| foreground | 15.4:1 pass | 15.4:1 pass | 15.4:1 pass |
| foreground-secondary | 7.2:1 pass | ... | ... |
| primary | 4.8:1 pass | ... | ... |

## Dark Mode

| | background | surface | surface-elevated |
|---|---|---|---|
| ... | ... | ... | ... |

## Colorblind Safety

| Color | Protanopia | Deuteranopia | Tritanopia |
|---|---|---|---|
| primary | safe | safe | pair with icon |
| ... | ... | ... | ... |

## Validation Tools
- WebAIM Contrast Checker
- EightShapes Contrast Grid
- Accessible Palette
```
