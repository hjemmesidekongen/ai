# Design Tokens — Detailed Process

Full instructions for the design-tokens skill (Phase 2). Referenced by SKILL.md.

---

## Before You Start

Read `brand-summary.yml` and extract:

- `colors` — primary, secondary, accent (each with hex and scale 50–900), neutrals,
  semantic colors (success, warning, error, info)
- `typography` — primary font family + weights, secondary font family + weights,
  type scale (H1–H6, Body, Body Small, Caption) with size/weight/line-height
- `spacing` — base unit and scale
- `border_radius` — named sizes (sm, md, lg, full)
- `shadows` — named elevation levels if present

If `brand-summary.yml` is missing or its `colors` section is empty, STOP and report:

```
Cannot start design-tokens phase. Missing prerequisite:
  - brand-summary.yml (run brand-loader first)
  - colors section must be populated
```

---

## Step 1: Generate Tailwind Config

Write `tailwind.config.json`. This is the Tailwind v3 theme configuration.

**Structure:**

```json
{
  "theme": {
    "extend": {
      "colors": {
        "primary": {
          "50": "#eff6ff",
          "100": "#dbeafe",
          "200": "#bfdbfe",
          "300": "#93c5fd",
          "400": "#60a5fa",
          "500": "#3b82f6",
          "600": "#2563eb",
          "700": "#1d4ed8",
          "800": "#1e40af",
          "900": "#1e3a8a",
          "DEFAULT": "#2563eb"
        },
        "secondary": { "...scale..." },
        "accent": { "...scale..." },
        "neutral": {
          "50": "#f8fafc",
          "100": "#f1f5f9",
          "300": "#cbd5e1",
          "500": "#64748b",
          "700": "#334155",
          "900": "#0f172a"
        },
        "success": "#16a34a",
        "warning": "#f59e0b",
        "error": "#dc2626",
        "info": "#2563eb"
      },
      "fontFamily": {
        "primary": ["Inter", "sans-serif"],
        "secondary": ["Georgia", "serif"]
      },
      "fontSize": {
        "xs": ["0.75rem", { "lineHeight": "1.4" }],
        "sm": ["0.875rem", { "lineHeight": "1.5" }],
        "base": ["1rem", { "lineHeight": "1.6" }],
        "lg": ["1.125rem", { "lineHeight": "1.4" }],
        "xl": ["1.25rem", { "lineHeight": "1.4" }],
        "2xl": ["1.5rem", { "lineHeight": "1.3" }],
        "3xl": ["1.75rem", { "lineHeight": "1.3" }],
        "4xl": ["2.25rem", { "lineHeight": "1.2" }],
        "5xl": ["3rem", { "lineHeight": "1.1" }]
      },
      "spacing": {
        "1": "0.25rem",
        "2": "0.5rem",
        "3": "0.75rem",
        "4": "1rem",
        "6": "1.5rem",
        "8": "2rem",
        "12": "3rem",
        "16": "4rem",
        "24": "6rem"
      },
      "borderRadius": {
        "sm": "0.25rem",
        "DEFAULT": "0.375rem",
        "md": "0.5rem",
        "lg": "0.75rem",
        "xl": "1rem",
        "full": "9999px"
      }
    }
  },
  "darkMode": "class",
  "content": ["./src/**/*.{js,ts,jsx,tsx}"]
}
```

**Rules:**
- Include only scale steps present in brand-summary.yml
- Set `DEFAULT` on primary, secondary, accent to the brand's main shade (typically 600)
- Map type scale from brand-summary.yml — use brand's actual font families, not defaults
- `darkMode: "class"` always — enables `.dark` class strategy
- Map border radius names directly from brand-summary.yml

**Save to findings.md after this step (2-Action Rule checkpoint).**

---

## Step 2: Generate CSS Custom Properties

Write `variables.css` with a `:root` block. Organize by token category with comments.

**Structure:**

```css
/* ============================================================
   Design Tokens — [Brand Name]
   Generated from brand-summary.yml
   ============================================================ */

:root {
  /* --- Colors: Primary --- */
  --color-primary-50: #eff6ff;
  --color-primary-100: #dbeafe;
  --color-primary-200: #bfdbfe;
  --color-primary-300: #93c5fd;
  --color-primary-400: #60a5fa;
  --color-primary-500: #3b82f6;
  --color-primary-600: #2563eb;
  --color-primary-700: #1d4ed8;
  --color-primary-800: #1e40af;
  --color-primary-900: #1e3a8a;
  --color-primary: var(--color-primary-600);

  /* --- Colors: Secondary --- */
  /* ...same pattern... */

  /* --- Colors: Accent --- */
  /* ...same pattern... */

  /* --- Colors: Neutral --- */
  --color-neutral-50: #f8fafc;
  --color-neutral-100: #f1f5f9;
  --color-neutral-300: #cbd5e1;
  --color-neutral-500: #64748b;
  --color-neutral-700: #334155;
  --color-neutral-900: #0f172a;

  /* --- Colors: Semantic --- */
  --color-success: #16a34a;
  --color-warning: #f59e0b;
  --color-error: #dc2626;
  --color-info: #2563eb;

  /* --- Typography: Families --- */
  --font-primary: "Inter", sans-serif;
  --font-secondary: "Georgia", serif;

  /* --- Typography: Scale --- */
  --font-size-xs: 0.75rem;
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  --font-size-2xl: 1.5rem;
  --font-size-3xl: 1.75rem;
  --font-size-4xl: 2.25rem;
  --font-size-5xl: 3rem;

  /* --- Spacing --- */
  --spacing-1: 0.25rem;
  --spacing-2: 0.5rem;
  --spacing-3: 0.75rem;
  --spacing-4: 1rem;
  --spacing-6: 1.5rem;
  --spacing-8: 2rem;
  --spacing-12: 3rem;
  --spacing-16: 4rem;
  --spacing-24: 6rem;

  /* --- Border Radius --- */
  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;
  --radius-xl: 1rem;
  --radius-full: 9999px;

  /* --- Shadows --- */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
}

/* --- Dark Mode Overrides --- */
.dark {
  --color-primary: var(--color-primary-400);  /* lighter on dark bg */
  --color-neutral-50: #0f172a;                /* invert backgrounds */
  --color-neutral-900: #f8fafc;               /* invert text */
  /* ...full dark mode token overrides... */
}
```

**Rules:**
- Every color scale step gets a variable — no gaps
- Semantic colors as single vars, not scales (unless brand-summary.yml has semantic scales)
- Font family vars must quote font names with spaces
- Include `.dark` override block using brand-summary.yml dark mode adjustments
- Dark mode overrides only the tokens that change — not a full duplicate

**Save to findings.md after this step (2-Action Rule checkpoint).**

---

## Step 3: Generate DTCG JSON

Write `tokens.dtcg.json` in Design Tokens Community Group (W3C) format. This enables
interoperability with Figma Tokens, Style Dictionary, Token Pipeline, and similar tools.

**DTCG format rules:**
- Every token has `$value` and `$type`
- Optional: `$description` for usage notes
- Tokens nest into groups using object keys
- No `$` prefix on group names — only on token properties

**Structure:**

```json
{
  "color": {
    "primary": {
      "50":  { "$value": "#eff6ff", "$type": "color", "$description": "Lightest primary — backgrounds, hover states" },
      "100": { "$value": "#dbeafe", "$type": "color", "$description": "Light primary — subtle backgrounds" },
      "200": { "$value": "#bfdbfe", "$type": "color", "$description": "Light primary — borders, dividers" },
      "300": { "$value": "#93c5fd", "$type": "color", "$description": "Medium light — icons, decorative" },
      "400": { "$value": "#60a5fa", "$type": "color", "$description": "Medium — less prominent UI" },
      "500": { "$value": "#3b82f6", "$type": "color", "$description": "Base primary" },
      "600": { "$value": "#2563eb", "$type": "color", "$description": "Brand primary — main CTA shade" },
      "700": { "$value": "#1d4ed8", "$type": "color", "$description": "Dark — button hover states" },
      "800": { "$value": "#1e40af", "$type": "color", "$description": "Darker — active states" },
      "900": { "$value": "#1e3a8a", "$type": "color", "$description": "Darkest — text on light backgrounds" }
    },
    "secondary": { "...same pattern..." },
    "accent": { "...same pattern..." },
    "neutral": { "...same pattern with only included steps..." },
    "semantic": {
      "success": { "$value": "#16a34a", "$type": "color", "$description": "Success states" },
      "warning": { "$value": "#f59e0b", "$type": "color", "$description": "Warning states — decorative only on white" },
      "error":   { "$value": "#dc2626", "$type": "color", "$description": "Error and destructive states" },
      "info":    { "$value": "#2563eb", "$type": "color", "$description": "Informational states" }
    }
  },
  "font": {
    "family": {
      "primary":   { "$value": "Inter, sans-serif",  "$type": "fontFamily", "$description": "Headings, UI" },
      "secondary": { "$value": "Georgia, serif",      "$type": "fontFamily", "$description": "Body text" }
    },
    "size": {
      "xs":   { "$value": "0.75rem",  "$type": "dimension" },
      "sm":   { "$value": "0.875rem", "$type": "dimension" },
      "base": { "$value": "1rem",     "$type": "dimension" },
      "lg":   { "$value": "1.125rem", "$type": "dimension" },
      "xl":   { "$value": "1.25rem",  "$type": "dimension" },
      "2xl":  { "$value": "1.5rem",   "$type": "dimension" },
      "3xl":  { "$value": "1.75rem",  "$type": "dimension" },
      "4xl":  { "$value": "2.25rem",  "$type": "dimension" },
      "5xl":  { "$value": "3rem",     "$type": "dimension" }
    }
  },
  "spacing": {
    "1":  { "$value": "0.25rem", "$type": "dimension" },
    "2":  { "$value": "0.5rem",  "$type": "dimension" },
    "4":  { "$value": "1rem",    "$type": "dimension" },
    "8":  { "$value": "2rem",    "$type": "dimension" },
    "16": { "$value": "4rem",    "$type": "dimension" }
  },
  "border-radius": {
    "sm":   { "$value": "0.25rem", "$type": "dimension" },
    "md":   { "$value": "0.5rem",  "$type": "dimension" },
    "lg":   { "$value": "0.75rem", "$type": "dimension" },
    "full": { "$value": "9999px",  "$type": "dimension" }
  }
}
```

**Rules:**
- Include `$description` on every token — describe intended use, not just the value
- Use DTCG-defined `$type` values: `color`, `dimension`, `fontFamily`, `fontWeight`,
  `duration`, `cubicBezier`, `shadow`
- Do not use custom `$type` values
- Token group nesting maximum 3 levels deep

**Save to findings.md after this step (2-Action Rule checkpoint).**

---

## Step 4: WCAG Validation

**Ported from brand-guideline typography-color skill.** Run full validation on all
color pairs from brand-summary.yml.

### 4a: Compute Contrast Ratios

For every intended foreground/background pair, compute WCAG contrast ratio.

**Formula:**

```
contrast_ratio = (L1 + 0.05) / (L2 + 0.05)

Where L1 = relative luminance of the lighter color, L2 = the darker.

Relative luminance per channel:
  sRGB = channel_value / 255
  if sRGB <= 0.04045: linear = sRGB / 12.92
  else: linear = ((sRGB + 0.055) / 1.055) ^ 2.4

L = 0.2126 * R_linear + 0.7152 * G_linear + 0.0722 * B_linear
```

**Required pairs to compute for each primary/secondary/accent color:**

| Foreground | Background | Intent |
|-----------|-----------|--------|
| Brand color (600) | White (#FFFFFF) | Buttons, links on white |
| White (#FFFFFF) | Brand color (600) | White text on colored bg |
| Brand color (600) | Near-white (#F8FAFC) | Links on subtle background |
| Brand 900 | Brand 50 | Dark-on-light within family |
| Brand color (600) | Neutral 900 | Colored text on dark bg |

For each neutral shade, compute against white and against Neutral 900.

**Semantic color pairs (mandatory):**

| Foreground | Background | Intent |
|-----------|-----------|--------|
| Success color | White | Success message text |
| Warning color | White | Warning banner text |
| Error color | White | Error message text |
| White | Error color | Error button text |

### 4b: Validate WCAG AA Compliance

| Element | Minimum Ratio | Required |
|---------|--------------|----------|
| Body text on background | 4.5:1 AA | Yes |
| Large text (18px+ or 14px bold) | 3:1 AA | Yes |
| UI components, icons, borders | 3:1 AA | Yes |
| Body text (enhanced) | 7:1 AAA | Recommended |

**For any pair that fails AA:**

1. Flag clearly:
   ```
   FAIL: Warning (#F59E0B) on White (#FFFFFF)
     Contrast ratio: 2.02:1
     Required: 4.5:1 for body text
   ```
2. Suggest nearest accessible alternative:
   - Scan the color's shade scale for the nearest step that passes
   - Example: "Darken Warning from #F59E0B (500) to #B45309 (700) — ratio 4.7:1"
   - Or suggest using on a dark background

3. If keeping a failing pair for decorative use:
   ```
   Note: Warning Yellow is decorative only on white. Never use for text.
   ```

### 4c: Generate Colorblind Safety Notes

For each primary, secondary, accent, and semantic color, assess visibility under
three types of color vision deficiency.

**Assessment method:**

| Deficiency | Prevalence | What's Affected | How to Assess |
|-----------|------------|----------------|---------------|
| Protanopia (red-blind) | ~1% male | Reds appear dark brown/green | High R + low G channel → flag |
| Deuteranopia (green-blind) | ~5% male | Reds and greens appear similar | Similar R/G values → flag |
| Tritanopia (blue-blind) | ~0.01% | Blues and yellows appear similar | High B + similar to yellow → flag |

**Output per color:**

```yaml
colorblind_notes:
  protanopia: "Distinguishable — no significant red component"
  deuteranopia: "Distinguishable — no significant red component"
  tritanopia: "May appear similar to purple — pair with shape/icon cues"
```

**Rules:**
- Never rely on color alone to convey meaning — always pair with icons, labels, or patterns
- Every semantic color must have an icon alternative (success ✓, warning ⚠, error ✕, info ℹ)
- Flag problematic combinations: red/green, yellow/white, light gray/white
- If a primary color is difficult for any deficiency, note the secondary cue to use

### 4d: Generate Dark Mode Token Variants

Produce the `.dark` override values (already included in variables.css Step 2) and
document the validated dark mode pairs.

**Principles:**
1. Backgrounds invert: White → Neutral 900 (#0F172A or #1E293B)
2. Text inverts: Dark gray → White or Neutral 50
3. Brand colors shift lighter: Use 400 instead of 600 on dark backgrounds
4. Reduce saturation slightly — full saturation on dark causes eye strain
5. Surface layers: base, surface (+1 step), elevated (+2 steps)

**Required dark mode pairs (all must pass WCAG AA):**

| Foreground | Background | Ratio Target |
|-----------|-----------|-------------|
| Neutral 50 | Neutral 900 | ≥ 15:1 (primary text) |
| Neutral 300 | Neutral 900 | ≥ 7:1 (secondary text) |
| Primary 400 | Neutral 900 | ≥ 4.5:1 (links, CTA text) |
| White | Primary 600 | ≥ 4.5:1 (button text) |

### 4e: Output Contrast Matrix

Write `contrast-matrix.md` as an EightShapes-style grid.

**Format:**

```markdown
# Contrast Matrix — [Brand Name]

Generated: [date]

## Light Mode Pairs

|                 | White     | Gray 50   | Gray 100  | Gray 900  | Dark BG   |
|-----------------|-----------|-----------|-----------|-----------|-----------|
| Primary 600     | 4.56 ✓    | 4.32 ✓    | 4.10 ✗    | 1.67 ✗    | 6.20 ✓    |
| Primary 900     | 10.30 ✓   | 9.74 ✓    | 9.21 ✓    | 1.24 ✗    | 3.82 ✓    |
| Warning 500     | 2.02 ✗    | 1.91 ✗    | 1.81 ✗    | 8.04 ✓    | 10.28 ✓   |
| Neutral 900     | 15.39 ✓   | 14.54 ✓   | 13.75 ✓   | —         | 1.12 ✗    |

✓ = passes WCAG AA (≥ 4.5:1 body, ≥ 3:1 large)   ✗ = fails

## Dark Mode Pairs

| ...same grid for dark mode pairs... |

## Colorblind Notes

| Color | Protanopia | Deuteranopia | Tritanopia |
|-------|-----------|-------------|-----------|
| Primary | Safe | Safe | Pair with icon |
| ...   | ...       | ...         | ...       |

## External Validation Tools

- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/) — quick ratio check
- [EightShapes Contrast Grid](https://contrast-grid.eightshapes.com/) — full matrix
- [Adobe Color Contrast Analyzer](https://color.adobe.com/create/color-contrast-analyzer)
- [Accessible Palette](https://accessiblepalette.com/) — CIELAB-based scale builder
```

**Save to findings.md after this step (2-Action Rule checkpoint).**

---

## Step 5: Register Assets

Add all generated files to `asset-registry.yml` under the project's design section.

**Entry format per file:**

```yaml
design_tokens:
  - path: ".ai/projects/[name]/design/tokens/tailwind.config.json"
    type: tailwind_config
    description: "Tailwind v3 theme with brand colors, fonts, spacing, border-radius"
    generated: "[ISO timestamp]"
    wcag_validated: true

  - path: ".ai/projects/[name]/design/tokens/variables.css"
    type: css_custom_properties
    description: "CSS custom properties for all design tokens, includes dark mode overrides"
    generated: "[ISO timestamp]"
    wcag_validated: true

  - path: ".ai/projects/[name]/design/tokens/tokens.dtcg.json"
    type: dtcg_tokens
    description: "W3C Design Tokens Community Group format — Figma Tokens, Style Dictionary compatible"
    generated: "[ISO timestamp]"
    wcag_validated: true

  - path: ".ai/projects/[name]/design/tokens/contrast-matrix.md"
    type: contrast_matrix
    description: "EightShapes-style contrast grid with WCAG pass/fail for all color pairs"
    generated: "[ISO timestamp]"
```

If `asset-registry.yml` doesn't exist yet, create it with a `_meta` block first.

---

## Checkpoint: accessibility_validation

After writing all files, run all 7 checks sequentially.

### Check 1: tailwind_config_valid

**Verify:** `tailwind.config.json` is valid JSON and contains `theme.extend.colors`,
`theme.extend.fontFamily`, `theme.extend.spacing`.

**How:** Parse the file as JSON. Check for required keys at `theme.extend`.

**Fail action:** Identify the missing key or JSON syntax error. Fix and re-write.

### Check 2: css_variables_valid

**Verify:** `variables.css` has a `:root` block containing at least one `--color-*`,
one `--font-*`, and one `--spacing-*` variable.

**How:** Read the file. Check for `:root {` block. Scan for the three variable prefixes.

**Fail action:** Identify missing categories. Add the missing variables to the `:root` block.

### Check 3: dtcg_valid

**Verify:** `tokens.dtcg.json` is valid JSON and every leaf token object has both
`$value` and `$type` fields.

**How:** Parse as JSON. Walk every leaf object (no nested object children). Confirm
presence of `$value` and `$type` on each.

**Fail action:** Identify tokens missing required fields. Add `$value`/`$type` and re-write.

### Check 4: wcag_aa_body

**Verify:** Every pair in the contrast matrix intended for body text has a ratio ≥ 4.5:1.

**How:** Read `contrast-matrix.md`. Identify all pairs marked ✗ that apply to body text.

**Fail action:** For each failing pair, apply the fix from Step 4b (darken shade or
restrict to decorative-only). Re-compute and re-write the matrix.

### Check 5: wcag_aa_large

**Verify:** Every pair intended for headings or large text has a ratio ≥ 3:1.

**How:** Same as Check 4, but with the 3.0 threshold.

**Fail action:** Same approach — scan shade scale for nearest passing step.

### Check 6: colorblind_notes

**Verify:** `contrast-matrix.md` colorblind notes table has entries for every primary,
secondary, accent, and semantic color. Each entry must have protanopia, deuteranopia,
and tritanopia assessments.

**How:** Read the colorblind notes section of the matrix. Verify all colors are listed.

**Fail action:** Generate missing entries using the channel-analysis method from Step 4c.

### Check 7: assets_registered

**Verify:** `asset-registry.yml` contains entries for all 4 output files (tailwind.config.json,
variables.css, tokens.dtcg.json, contrast-matrix.md).

**How:** Read asset-registry.yml. Check for paths matching all 4 files.

**Fail action:** Add the missing entries and re-write asset-registry.yml.

### On Checkpoint Failure

If ANY check fails:
1. Report all failures with specific fix instructions
2. Apply the fixes
3. Re-run only the failing checks
4. Maximum 3 rounds before escalating to the user
5. Do NOT advance to component-specs until all 7 checks pass

### On Checkpoint Pass

1. Update `state.yml`:
   - Phase 2 (design-tokens) status → `completed`
   - Checkpoint passed → `true`
   - Details → counts of tokens generated and pairs validated

2. Write recovery notes:
   ```
   Project: [name]
   Tailwind config: [N] color scales, [M] font families, spacing + radius included.
   CSS variables: [N] vars total across [M] categories, dark mode overrides included.
   DTCG JSON: [N] tokens in W3C format.
   WCAG: [N] pairs computed. All body-text pairs pass AA. Dark mode: validated.
   Colorblind notes: all primary/accent/semantic colors assessed.
   Assets registered: 4 files in asset-registry.yml.
   ```

3. Advance to component-specs phase

---

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- tailwind_config_valid: tailwind.config.json is valid JSON with colors, fontFamily, spacing keys
- css_variables_valid: variables.css has :root block with --color-*, --font-*, --spacing-* vars
- dtcg_valid: tokens.dtcg.json follows DTCG format with $value, $type fields
- wcag_aa_body: all body text pairs meet 4.5:1 contrast ratio
- wcag_aa_large: all large text pairs meet 3:1 contrast ratio
- colorblind_notes: colorblind safety notes exist for primary and semantic colors
- assets_registered: all 3 token files registered in asset-registry.yml

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Token scales are complete and consistent (no missing shade steps)
- Color values match brand-summary.yml exactly — no arbitrary substitutions
- Dark mode overrides are sufficient and all pairs pass WCAG AA
- DTCG descriptions convey intended use, not just values
- Contrast matrix includes all required foreground/background pairs

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.

---

## External Validation References

Provide these links in the contrast-matrix.md for independent verification:

| Tool | Purpose |
|------|---------|
| WebAIM Contrast Checker | Quick ratio check for any two colors |
| EightShapes Contrast Grid | Full color-vs-color matrix |
| Accessible Palette | CIELAB-based scale builder with guaranteed contrast |
| Adobe Color Contrast Analyzer | Check ratios + colorblind simulation |
| Stark (Figma plugin) | In-Figma contrast checking and colorblind simulation |
| Style Dictionary | Transform DTCG tokens to any platform format |
| Theo (Salesforce) | Token transformation pipeline |
