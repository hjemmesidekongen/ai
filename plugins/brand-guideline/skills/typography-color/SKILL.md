---
name: typography-color
description: >
  Guides the user through color palette selection and typography system design.
  Suggests palette directions based on brand personality, generates tint/shade
  scales, computes contrast ratios, validates WCAG AA compliance, produces
  colorblind safety notes, creates dark mode variants, and builds a typographic
  hierarchy. Writes the colors and typography sections to brand-reference.yml.
phase: 4
depends_on: [identity-interview, audience-personas, tone-of-voice]
writes:
  - "brand-reference.yml#colors"
  - "brand-reference.yml#typography"
reads:
  - "brand-reference.yml#meta"
  - "brand-reference.yml#identity"
  - "brand-reference.yml#voice"
checkpoint:
  type: accessibility_validation
  required_checks:
    - name: "contrast_matrix"
      verify: "All foreground/background pairs in brand-reference.yml have contrast_ratio field"
      fail_action: "Compute missing ratios before proceeding"
    - name: "wcag_aa_body"
      verify: "All body-text pairs have wcag_aa_normal: true (≥ 4.5:1)"
      fail_action: "Suggest nearest accessible alternative color from the tint/shade scale"
    - name: "wcag_aa_large"
      verify: "All large-text pairs have wcag_aa_large: true (≥ 3:1)"
      fail_action: "Suggest nearest accessible alternative color from the tint/shade scale"
    - name: "colorblind_notes"
      verify: "All primary and accent colors have colorblind_notes for protanopia, deuteranopia, tritanopia"
      fail_action: "Generate missing notes by analyzing RGB channel contribution"
    - name: "dark_mode"
      verify: "Dark mode section exists with background, text, brand_adjustments, and validated accessible_pairs"
      fail_action: "Generate dark mode variants and validate all pairs"
    - name: "font_weights"
      verify: "Primary font has at least 2 weights in the weights array"
      fail_action: "Ask the user which weights they need (Regular, Semi-Bold, Bold, etc.)"
  on_fail: "Fix issues and re-run checkpoint. Do NOT advance to next phase."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Typography & Color System

Phase 4 of brand generation. Produces a complete, accessibility-first color system and a typographic hierarchy. Both sections are written to `brand-reference.yml` and validated with an `accessibility_validation` checkpoint before advancing.

## Before You Start

Read these sections from brand-reference.yml:

- `meta.brand_name` and `meta.industry` — ground suggestions in the right domain
- `identity.values` — inform color mood (e.g., innovative → blue, energetic → orange)
- `identity.positioning` — category and differentiator shape visual identity
- `voice.personality` — attribute/not pairs drive typography character (formal → serif, modern → sans)
- `voice.spectrum` — formality and enthusiasm scores guide palette energy

If identity or voice sections are missing, STOP and report:

```
Cannot start typography-color phase. Missing prerequisite:
  - identity section (run identity-interview first)
  - voice section (run tone-of-voice first)
```

Reference this data throughout: "Your brand personality is [attributes]. Your formality score is [N]/10. Let's find colors and fonts that match."

## Interview Philosophy

Same rules as previous phases:

- Ask **one question at a time**. Never present a wall of questions.
- **Offer examples** relevant to the user's industry and personality.
- If the user gives a **vague answer**, ask a focused follow-up.
- If the user says **"I don't know"**, suggest 2-3 options based on their brand personality.
- After each answer, briefly reflect back what you understood.

---

## Part 1: Color Palette

### Step 1: Existing Colors Check

**Question:**

"Do you have existing brand colors, or are we starting fresh?"

| Answer | Follow-up |
|--------|-----------|
| Has colors | "Great — share the hex values. Which is primary vs. secondary?" |
| Has a rough idea | "What color family feels right? Blue, green, warm tones?" |
| Starting fresh | Continue to Step 2 — palette directions |

If they have existing colors, skip to Step 3 (generate scales for the provided colors). Still validate accessibility.

### Step 2: Palette Direction Selection

Based on the brand personality and voice spectrum, present **exactly 3 palette directions** with rationale. Each direction should feel distinct.

**How to derive directions from brand data:**

| Brand Signal | Color Direction |
|-------------|----------------|
| Formality ≥ 7 | Deep navy, charcoal, burgundy — "Authoritative & Refined" |
| Formality ≤ 3 | Bright primaries, warm tones, coral — "Energetic & Approachable" |
| Enthusiasm ≥ 7 | Saturated hues, warm accents, vibrant — "Bold & Dynamic" |
| Enthusiasm ≤ 3 | Muted tones, pastels, earth tones — "Calm & Considered" |
| Technicality ≥ 7 | Cool grays, electric blue, cyan — "Precise & Technical" |
| Values include trust/reliability | Blue family — universally trusted |
| Values include growth/nature | Green family — organic, sustainable |
| Values include warmth/community | Amber/orange family — welcoming |

**Present to the user:**

```
Based on your brand personality ([attributes]) and spectrum (formality: [N], enthusiasm: [N]):

Direction 1: [Name] — [Primary color family]
  [Rationale tied to brand values/personality]
  Primary: [color], Secondary: [color], Accent: [color]

Direction 2: [Name] — [Primary color family]
  [Rationale tied to brand values/personality]
  Primary: [color], Secondary: [color], Accent: [color]

Direction 3: [Name] — [Primary color family]
  [Rationale tied to brand values/personality]
  Primary: [color], Secondary: [color], Accent: [color]

Which direction feels right? Or describe your own.
```

**Follow-up:**

"What colors should we absolutely avoid? Think about competitor colors or cultural sensitivities in your industry."

### Step 3: Generate Tint/Shade Scales

For each color (primary, secondary, accent), generate a 10-step scale from lightest (50) to darkest (900).

**Scale generation method:**

1. Start with the chosen base hex
2. Convert to HSL
3. For lighter shades (50–400): increase lightness, slightly decrease saturation
4. For darker shades (700–900): decrease lightness, slightly adjust hue for richness
5. The 500 step should be close to the base color
6. Ensure perceptual evenness — each step should feel like an equal jump

```yaml
scale:
  50:  "#EFF6FF"   # Lightest — backgrounds, hover states
  100: "#DBEAFE"   # Light — subtle backgrounds, selected states
  200: "#BFDBFE"   # Light — borders, dividers
  300: "#93C5FD"   # Medium light — icons, decorative
  400: "#60A5FA"   # Medium — less prominent UI
  500: "#3B82F6"   # Base — the "default" shade
  600: "#2563EB"   # Primary brand shade
  700: "#1D4ED8"   # Dark — hover states for buttons
  800: "#1E40AF"   # Darker — active states, emphasis
  900: "#1E3A8A"   # Darkest — text on light backgrounds
```

**Also generate scales for semantic colors:**

- **Success** (green family) — with scale
- **Warning** (amber family) — with scale
- **Error** (red family) — with scale
- **Info** (blue family, may share with primary) — with scale

Semantic colors must be distinguishable from each other AND from brand colors.

### Step 4: Generate Neutral Scale

Create 5–7 neutral shades from near-white to near-black:

```yaml
neutrals:
  - name: "White"
    hex: "#FFFFFF"
    use: "Page backgrounds"
  - name: "Gray 50"
    hex: "#F8FAFC"
    use: "Subtle backgrounds, alternating rows"
  - name: "Gray 100"
    hex: "#F1F5F9"
    use: "Card backgrounds, input fields"
  - name: "Gray 300"
    hex: "#CBD5E1"
    use: "Borders, dividers"
  - name: "Gray 500"
    hex: "#64748B"
    use: "Muted text, placeholders"
  - name: "Gray 700"
    hex: "#334155"
    use: "Secondary text"
  - name: "Gray 900"
    hex: "#0F172A"
    use: "Primary text, headings"
```

### Step 5: Compute Contrast Ratios

For EVERY intended foreground/background pair, compute the WCAG contrast ratio.

**Contrast ratio formula (relative luminance):**

```
L1 = relative luminance of lighter color
L2 = relative luminance of darker color

contrast_ratio = (L1 + 0.05) / (L2 + 0.05)

Where relative luminance for a color:
  1. Convert hex to linear RGB:
     sRGB = value / 255
     if sRGB <= 0.04045: linear = sRGB / 12.92
     else: linear = ((sRGB + 0.055) / 1.055) ^ 2.4
  2. L = 0.2126 * R_linear + 0.7152 * G_linear + 0.0722 * B_linear
```

**Required pairs to compute for each primary/secondary/accent color:**

| Foreground | Background | Intent |
|-----------|-----------|--------|
| Brand color | White (#FFFFFF) | Buttons, links on white |
| White | Brand color | White text on colored bg |
| Brand color | Near-white (#F8FAFC) | Links on subtle bg |
| Brand 900 | Brand 50 | Dark-on-light within same family |
| Brand color | Gray 900 (#0F172A) | Colored text on dark bg |
| Brand color | Each other brand color | Decorative pairings |

For each neutral, compute against white, near-white, and dark backgrounds.

**Output per pair:**

```yaml
accessible_pairs:
  - foreground: "#2563EB"
    background: "#FFFFFF"
    contrast_ratio: 4.56
    wcag_aa_normal: true       # ≥ 4.5:1 (body text under 18px)
    wcag_aa_large: true        # ≥ 3:1 (text 18px+ or 14px bold)
    wcag_aaa_normal: false     # ≥ 7:1
    wcag_aaa_large: true       # ≥ 4.5:1
    use: "Blue buttons on white, blue links on white"
```

### Step 6: Validate WCAG AA Compliance

After computing all pairs, enforce these rules:

| Element | Minimum Ratio | WCAG Level | Required |
|---------|--------------|------------|----------|
| Body text on background | 4.5:1 | AA | **Yes** |
| Large text (18px+ or 14px bold) | 3:1 | AA | **Yes** |
| UI components & graphical objects | 3:1 | AA | **Yes** |
| Body text (enhanced) | 7:1 | AAA | Recommended |
| Large text (enhanced) | 4.5:1 | AAA | Recommended |

**For any pair that fails AA:**

1. Flag it clearly:
   ```
   FAIL: Amber (#F59E0B) on White (#FFFFFF)
     Contrast ratio: 2.02:1
     Required: 4.5:1 for body text
   ```

2. Suggest the nearest accessible alternative:
   - Scan the color's tint/shade scale for the closest step that passes
   - Example: "Darken Amber from #F59E0B (500) to #B45309 (700) — ratio 4.7:1"
   - Or suggest using it on a dark background instead

3. If the user wants to keep a failing pair for decorative use only:
   ```yaml
   - foreground: "#F59E0B"
     background: "#FFFFFF"
     contrast_ratio: 2.02
     wcag_aa_normal: false
     wcag_aa_large: false
     use: "Decorative only — NEVER for text"
     warning: "Does not meet AA. Use only for non-text decorative elements."
   ```

**Never allow a failing pair to be used for text without an explicit decorative-only marker.**

### Step 7: Generate Colorblind Safety Notes

For each primary and accent color, assess visibility under the three main types of color vision deficiency:

**How to assess:**

1. **Protanopia** (red-blind, ~1% of males): Reds appear as dark browns/greens. High red channel + low green → flag.
2. **Deuteranopia** (green-blind, ~5% of males): Greens and reds appear similar as browns/yellows. Red/green channel balance is key.
3. **Tritanopia** (blue-blind, ~0.01%): Blues and yellows appear similar. Blue/yellow channel balance is key.

**Output per color:**

```yaml
colorblind_notes:
  protanopia: "Distinguishable — no significant red component"
  deuteranopia: "Distinguishable — no significant red component"
  tritanopia: "May appear similar to purple — pair with shape/icon cues"
```

**Rules:**

- Never rely on color alone to convey meaning — always pair with icons, labels, or patterns
- Flag problematic combinations: red/green, yellow/white, light gray/white
- Every semantic color (success/warning/error/info) must have an icon alternative
- If a primary color is difficult under any deficiency, note what secondary cue to use

### Step 8: Generate Dark Mode Variants

**Question:**

"Do you need a dark mode version of your color system?"

Default: yes. Only skip if the user explicitly declines.

**Dark mode principles:**

1. Backgrounds go dark: White → #0F172A or #1E293B
2. Text goes light: Dark text → white or light gray
3. Brand colors adjust: May need a lighter shade for readability on dark backgrounds
4. Reduce saturation slightly: Full-saturation on dark backgrounds causes eye strain
5. Surfaces layer up: Slightly lighter shades for cards/elevated surfaces

**Required output:**

```yaml
dark_mode:
  background:
    base: "#0F172A"
    surface: "#1E293B"
    elevated: "#334155"
  text:
    primary: "#F8FAFC"
    secondary: "#CBD5E1"
    muted: "#64748B"
  brand_adjustments:
    - original: "#2563EB"
      dark_mode: "#60A5FA"
      reason: "Lighter shade for readability on dark background"
  accessible_pairs:
    - foreground: "#F8FAFC"
      background: "#0F172A"
      contrast_ratio: 17.4
      wcag_aa_normal: true
      wcag_aa_large: true
      use: "Primary text on dark background"
    # ... all dark mode pairs
```

**Every dark mode pair must also pass WCAG AA.** Run the same validation from Step 6.

### Step 9: Output Contrast Matrix

Before writing to disk, present a contrast matrix showing all color pairs at a glance. Format like EightShapes Contrast Grid:

```
              White    Gray 50   Gray 100  Gray 900  Blue 600  Dark BG
Blue 600      4.56     4.32      4.10      1.67      —         6.20
Blue 900     10.30     9.74      9.21      1.24      2.26      3.82
Amber 600     2.02     1.91      1.81      8.04      1.75     10.28
Gray 900     15.39    14.54     13.75      —         1.67      1.12
White         —        1.06      1.12     15.39      4.56     17.40
```

Mark failing pairs (below 4.5:1 for body text) clearly.

### Step 10: Color Usage Proportions

Define how colors should be balanced:

```yaml
proportions:
  rule: "60/30/10"
  dominant: "White / Light Gray (60%)"
  secondary: "Brand primary + neutrals (30%)"
  accent: "Accent color (10%)"
```

---

## Part 2: Typography System

### Step 11: Font Selection

Select fonts that match the brand personality from the voice section.

**Personality-to-font mapping:**

| Brand Personality | Primary Font Style | Examples |
|------------------|-------------------|----------|
| Confident + Modern | Geometric sans-serif | Inter, Poppins, Plus Jakarta Sans |
| Warm + Approachable | Rounded sans-serif / humanist | Nunito, Quicksand, Lato, Open Sans |
| Authoritative + Traditional | Serif | Merriweather, Lora, Playfair Display |
| Technical + Precise | Grotesque sans / monospace | IBM Plex Sans, JetBrains Mono, Space Grotesk |
| Playful + Creative | Display / handwritten (headings only) | Outfit, Sora, Fraunces |

**Questions (one at a time):**

1. "Do you have existing brand fonts?"
   - If yes: use them, verify availability and licensing
   - If no: present 2-3 pairings matched to personality

2. "Where will the brand appear most? Web, print, or both?"
   - Web-first: prioritize Google Fonts for easy loading
   - Print-first: wider selection, consider licensing costs
   - Both: find fonts available in both Google Fonts and desktop formats

3. Present the pairing options:
   ```
   Based on your brand personality ([attributes]):

   Pairing 1: [Primary] + [Secondary]
     [Why this works for your brand]
     Source: [Google Fonts / Adobe / System]

   Pairing 2: [Primary] + [Secondary]
     [Why this works for your brand]
     Source: [Google Fonts / Adobe / System]

   Pairing 3: [Primary] + [Secondary]
     [Why this works for your brand]
     Source: [Google Fonts / Adobe / System]

   Which pairing feels right?
   ```

**Font sources and licensing:**

| Source | Cost | Best For |
|--------|------|----------|
| Google Fonts | Free | Web-first, easy embedding |
| Adobe Fonts | Creative Cloud subscription | Wide selection, premium quality |
| Fontshare | Free for commercial use | Curated quality, unique options |
| System fonts | Zero loading cost | Performance-critical sites |

### Step 12: Define Type Scale

Build a consistent typographic hierarchy with 8 levels (H1 through H6, Body, Small, Caption):

**Scale principles:**

- Use a consistent ratio between levels (1.25 minor third or 1.333 perfect fourth)
- Line height decreases as size increases (large text needs tighter leading)
- Letter spacing: negative for large text, neutral or positive for small text
- Every level specifies both px and rem
- Minimum body text: 16px (never smaller for primary reading)

```yaml
scale:
  - level: "H1 / Display"
    size: "48px / 3rem"
    weight: "Bold"
    line_height: "1.1"
    use: "Page titles, hero sections"

  - level: "H2"
    size: "36px / 2.25rem"
    weight: "Semi-Bold"
    line_height: "1.2"
    use: "Section headings"

  - level: "H3"
    size: "28px / 1.75rem"
    weight: "Semi-Bold"
    line_height: "1.3"
    use: "Subsections, card titles"

  - level: "H4"
    size: "24px / 1.5rem"
    weight: "Semi-Bold"
    line_height: "1.3"
    use: "Card headings, sidebar titles"

  - level: "H5"
    size: "20px / 1.25rem"
    weight: "Medium"
    line_height: "1.4"
    use: "Widget titles, form section headings"

  - level: "H6"
    size: "18px / 1.125rem"
    weight: "Medium"
    line_height: "1.4"
    use: "Small section labels, overlines"

  - level: "Body"
    size: "16px / 1rem"
    weight: "Regular"
    line_height: "1.6"
    use: "Paragraphs, descriptions"

  - level: "Body Small"
    size: "14px / 0.875rem"
    weight: "Regular"
    line_height: "1.5"
    use: "Secondary text, metadata"

  - level: "Caption"
    size: "12px / 0.75rem"
    weight: "Medium"
    line_height: "1.4"
    use: "Labels, footnotes, timestamps"
```

### Step 13: Define Font Weights

For each font family, specify which weights are used and where:

```yaml
primary:
  family: "Inter"
  use: "Headings, hero text, UI elements"
  weights: ["Bold 700", "Semi-Bold 600", "Medium 500"]
  source: "Google Fonts"
secondary:
  family: "Georgia"
  use: "Body text, long-form content"
  weights: ["Regular 400", "Italic 400"]
  source: "System font"
```

**Rules:**

- Limit to 3-4 weights per family (performance and consistency)
- Always include Regular (400) for at least one family
- Bold (700) for emphasis, Semi-Bold (600) for headings
- Italic for inline emphasis, not as a display style
- At least 2 weights for the primary font (checkpoint enforces this)

**Confirm licensing:**

"Your fonts are sourced from [Google Fonts / Adobe / etc.]. [Google Fonts = free for web and commercial use. / Adobe Fonts = requires Creative Cloud subscription. / Licensed font = verify license covers web embedding.]"

---

## Part 3: Write to brand-reference.yml

### Summary Before Writing

Before writing to disk, present the full summary for approval:

```
Here's the color and typography system I built:

COLOR PALETTE
  Primary: [Name] — [hex] (scale: 50–900)
  Secondary: [Name] — [hex] (scale: 50–900)
  Accent: [Name] — [hex] (scale: 50–900)
  Neutrals: [count] shades from [lightest] to [darkest]
  Semantic: success [hex], warning [hex], error [hex], info [hex]
  Proportions: [rule]

ACCESSIBILITY
  [N] contrast pairs computed
  All body-text pairs pass WCAG AA (4.5:1): [yes/no — list failures]
  All large-text pairs pass WCAG AA (3:1): [yes/no — list failures]
  Colorblind notes: all primary/accent colors assessed
  Dark mode: [included/not included] with [N] validated pairs

TYPOGRAPHY
  Primary: [family] — [weights] (source: [source])
  Secondary: [family] — [weights] (source: [source])
  Scale: [N] levels from [largest] to [smallest]

[Contrast matrix table from Step 9]

Does this look right? I can adjust anything before we save.
```

Only write to disk after the user confirms.

### Write Colors Section

Write the complete `colors` section to `brand-reference.yml#colors`:

```yaml
colors:
  primary:
    - name: "Brand Blue"
      hex: "#2563EB"
      rgb: "37, 99, 235"
      hsl: "217, 91%, 60%"
      use: "Primary CTA, links, key UI elements"
      scale:
        50: "#EFF6FF"
        # ... all 10 steps
        900: "#1E3A8A"
      accessible_pairs:
        - foreground: "#2563EB"
          background: "#FFFFFF"
          contrast_ratio: 4.56
          wcag_aa_normal: true
          wcag_aa_large: true
          wcag_aaa_normal: false
          wcag_aaa_large: true
          use: "Blue buttons on white, blue links on white"
        # ... all computed pairs for this color
      colorblind_notes:
        protanopia: "Distinguishable — no red component"
        deuteranopia: "Distinguishable — no red component"
        tritanopia: "May appear similar to purple — pair with shape/icon cues"
  secondary:
    # ... same structure
  accent:
    # ... same structure
  neutrals:
    - name: "White"
      hex: "#FFFFFF"
      use: "Page backgrounds"
    # ... all neutral shades
  semantic:
    success: "#16A34A"
    warning: "#F59E0B"
    error: "#DC2626"
    info: "#2563EB"
  accessibility:
    - pair: "Brand Blue on White"
      contrast_ratio: "4.56:1"
      wcag_aa: true
      wcag_aaa: false
    # ... summary of all key pairs for quick reference
  proportions:
    rule: "60/30/10"
    dominant: "White / Light Gray (60%)"
    secondary: "Brand primary + neutrals (30%)"
    accent: "Accent color (10%)"
  dark_mode:
    background:
      base: "#0F172A"
      surface: "#1E293B"
      elevated: "#334155"
    text:
      primary: "#F8FAFC"
      secondary: "#CBD5E1"
      muted: "#64748B"
    brand_adjustments:
      - original: "#2563EB"
        dark_mode: "#60A5FA"
        reason: "Lighter shade for readability on dark background"
    accessible_pairs:
      - foreground: "#F8FAFC"
        background: "#0F172A"
        contrast_ratio: 17.4
        wcag_aa_normal: true
        wcag_aa_large: true
        use: "Primary text on dark background"
      # ... all dark mode pairs validated
```

### Write Typography Section

Write the complete `typography` section to `brand-reference.yml#typography`:

```yaml
typography:
  primary:
    family: "Inter"
    use: "Headings, hero text, UI elements"
    weights: ["Bold 700", "Semi-Bold 600", "Medium 500"]
    source: "Google Fonts"
  secondary:
    family: "Georgia"
    use: "Body text, long-form content"
    weights: ["Regular 400", "Italic 400"]
    source: "System font"
  scale:
    - level: "H1 / Display"
      size: "48px / 3rem"
      weight: "Bold"
      line_height: "1.1"
      use: "Page titles, hero sections"
    # ... all 9 levels (H1–H6, Body, Body Small, Caption)
```

---

## Checkpoint: accessibility_validation

After writing, run ALL of these checks:

### Check 1: contrast_matrix

**Verify:** Every foreground/background pair in `colors` has a `contrast_ratio` field.

**How:** Read the colors section. For each entry in `accessible_pairs` (in every color group AND in `dark_mode.accessible_pairs`), verify `contrast_ratio` is present and is a number > 0.

**Fail action:** Compute missing ratios using the formula from Step 5.

### Check 2: wcag_aa_body

**Verify:** All pairs intended for body text have `wcag_aa_normal: true`.

**How:** For each pair where `use` suggests text usage (not "decorative only"), verify `wcag_aa_normal` is `true` (contrast_ratio ≥ 4.5).

**Fail action:** For each failing pair:
1. Scan the color's tint/shade scale for the nearest step that passes
2. Suggest: "Darken [color name] from [hex] to [suggested hex] (ratio [new ratio]:1)"
3. Present the fix to the user

### Check 3: wcag_aa_large

**Verify:** All pairs intended for large text (H1–H4, 18px+ or 14px bold) have `wcag_aa_large: true`.

**How:** For each pair where `use` suggests heading or large text usage, verify `wcag_aa_large` is `true` (contrast_ratio ≥ 3.0).

**Fail action:** Same approach as Check 2, but with the 3.0:1 threshold.

### Check 4: colorblind_notes

**Verify:** All primary and accent colors have `colorblind_notes` with entries for `protanopia`, `deuteranopia`, and `tritanopia`.

**How:** Read each primary and accent color. Verify `colorblind_notes` object exists with all three keys, each containing a non-empty string.

**Fail action:** Generate the missing notes by analyzing the color's RGB channels:
- High red + low green → flag for protanopia/deuteranopia
- High blue + low yellow → flag for tritanopia
- Suggest pairing strategies (icons, patterns, labels)

### Check 5: dark_mode

**Verify:** The `dark_mode` section exists under `colors` with validated accessible pairs.

**How:**
1. Check `colors.dark_mode` exists
2. Check it has `background`, `text`, `brand_adjustments`, and `accessible_pairs`
3. For each pair in `dark_mode.accessible_pairs`, verify `wcag_aa_normal: true` for text pairs

**Fail action:** Generate the dark mode section:
1. Create dark background values (base, surface, elevated)
2. Map brand colors to lighter variants for dark backgrounds
3. Compute and validate all pairs
4. Re-run this check

### Check 6: font_weights

**Verify:** `typography.primary.weights` array has at least 2 items.

**How:** Read `typography.primary.weights` and count items.

**Fail action:** Ask the user which weights they need. Suggest: "Most brands need at least Regular (400) and Bold (700). Semi-Bold (600) is common for headings."

### On Checkpoint Failure

If ANY check fails:
1. Report all failures with suggested fixes
2. Apply fixes (adjust colors, compute missing data)
3. Re-run the failing checks only
4. Maximum 3 rounds before escalating to the user
5. Do NOT advance to the next phase until ALL checks pass

### On Checkpoint Pass

1. Update `state.yml`:
   - Phase 4 status → `completed`
   - Checkpoint passed → `true`
   - Details → summary of what was validated
2. Write recovery notes:
   ```
   Brand: [name] ([industry])
   Primary palette: [primary hex] + [secondary hex] + [accent hex]
   [N] tint/shade scales generated. [M] contrast pairs computed.
   All pairs pass WCAG AA. Dark mode: [validated/skipped].
   Colorblind notes: present for all primary/accent colors.
   Typography: [primary font] + [secondary font], [N]-level scale.
   Font source: [Google Fonts / Adobe / etc.]
   ```
3. Advance to phase 5 (visual-identity)

## External Validation References

After generating the color system, include these tools in the brand manual for the user to verify independently:

| Tool | Purpose |
|------|---------|
| WebAIM Contrast Checker | Quick ratio check for any two colors |
| EightShapes Contrast Grid | Matrix of all color-vs-color combinations |
| Accessible Palette | Build CIELAB-based scales with guaranteed contrast |
| Adobe Color Contrast Checker | Check ratios + colorblind simulation |
| Stark (Figma plugin) | In-Figma contrast checking and colorblind sim |
| Color Safe | Generate accessible text colors for any background |
| InclusiveColors | Full palette builder with live WCAG validation |
