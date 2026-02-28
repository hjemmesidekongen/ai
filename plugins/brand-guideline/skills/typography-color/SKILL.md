---
name: typography-color
description: >
  Guides the user through color palette selection and typography system design.
  Generates tint/shade scales, computes contrast ratios, validates WCAG AA
  compliance, produces colorblind safety notes, and creates dark mode variants.
  Writes the colors and typography sections to brand-reference.yml.
phase: 4
depends_on: [identity-interview, audience-personas, tone-of-voice]
writes:
  - "brand-reference.yml#colors"
  - "brand-reference.yml#typography"
reads:
  - "brand-reference.yml#identity"
  - "brand-reference.yml#voice"
checkpoint:
  type: accessibility_validation
  required_checks:
    - name: "contrast_matrix"
      verify: "All foreground/background pairs in brand-reference.yml have contrast_ratio field"
      fail_action: "Compute missing ratios before proceeding"
    - name: "wcag_aa_body"
      verify: "All body-text pairs have wcag_aa_normal: true"
      fail_action: "Suggest nearest accessible alternative color"
    - name: "wcag_aa_large"
      verify: "All large-text pairs have wcag_aa_large: true"
      fail_action: "Suggest nearest accessible alternative color"
    - name: "colorblind_notes"
      verify: "All primary colors have colorblind_notes for protanopia, deuteranopia, tritanopia"
      fail_action: "Generate missing notes"
    - name: "dark_mode"
      verify: "Dark mode section exists with validated pairs"
      fail_action: "Generate dark mode variants"
  on_fail: "Fix issues and re-run checkpoint. Do NOT advance to next phase."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Typography & Color System

Phase 4 of brand generation. Produces a complete, accessibility-first color system and a typographic hierarchy. Both sections are written to `brand-reference.yml` and validated with an `accessibility_validation` checkpoint before advancing.

## Prerequisites

Before starting, read these sections from brand-reference.yml:

- **identity** — Brand positioning and values inform color mood (innovative → blue, energetic → orange, etc.)
- **voice** — Brand personality spectrum influences typography character (formal → serif, modern → sans-serif)

If either section is missing, STOP and report:
```
Cannot start typography-color phase. Missing prerequisite:
  - identity section (run identity-interview first)
  - voice section (run tone-of-voice first)
```

## Part 1: Color Palette

### Step 1: Color Discovery Interview

Ask the user focused questions to establish the palette direction. This is interactive — do not skip.

**Questions to ask:**

1. "Do you have existing brand colors, or are we starting fresh?"
   - If existing: ask for hex values, note which are primary vs secondary
   - If fresh: continue to mood-based selection

2. "Based on your brand personality ([list attributes from voice.personality]), which color families feel right?"
   - Present 3-4 mood-matched options with rationale
   - Example: "Your brand is 'confident, warm, clear' — consider deep blues (trust), warm amber (energy), or forest green (growth)"

3. "What colors should we absolutely avoid?"
   - Note competitor colors to differentiate from
   - Note cultural or industry sensitivities

4. "Do you need a dark mode version of your color system?"
   - Default: yes. Only skip if user explicitly declines.

**After the interview, confirm the direction before generating:**

```
Color Direction:
  Primary: Deep blue family (#2563EB range) — trust, professionalism
  Secondary: Slate gray (#475569 range) — readability, neutral base
  Accent: Warm amber (#F59E0B range) — energy, attention, warmth
  Approach: Modern, confident, accessible

Proceed with this palette direction? (User confirms or adjusts)
```

### Step 2: Generate Base Palette

For each color category, select the base color:

**Primary colors** (1-3):
- The hero color. Appears on CTAs, links, key UI elements.
- Must pass WCAG AA on white for body text (4.5:1 minimum).

**Secondary colors** (1-2):
- Supporting color for body text, secondary elements.
- Typically a neutral or muted tone.

**Accent colors** (1-2):
- Highlights, warnings, attention-grabbing elements.
- Used sparingly (10% rule).

**Neutral scale** (5-7 shades):
- From near-white (#F8FAFC) to near-black (#0F172A).
- Used for backgrounds, borders, subtle text.

**Semantic colors** (4):
- success, warning, error, info
- Must be distinguishable from each other AND from brand colors.
- Must each pass accessibility on their intended background.

### Step 3: Generate Tint/Shade Scales

For EVERY primary, secondary, and accent color, generate a 10-step scale from lightest to darkest:

```yaml
scale:
  50:  "#EFF6FF"   # Lightest — backgrounds, hover states
  100: "#DBEAFE"   # Light — subtle backgrounds, selected states
  200: "#BFDBFE"   # Light — borders, dividers
  300: "#93C5FD"   # Medium light — icons, decorative
  400: "#60A5FA"   # Medium — less prominent UI
  500: "#3B82F6"   # Base — the "default" shade
  600: "#2563EB"   # Primary brand shade (if this is the chosen hex)
  700: "#1D4ED8"   # Dark — hover states for buttons
  800: "#1E40AF"   # Darker — active states, emphasis
  900: "#1E3A8A"   # Darkest — text on light backgrounds
```

**How to generate the scale:**

1. Start with the chosen base hex (e.g., #2563EB)
2. Convert to HSL
3. For lighter shades (50-400): increase lightness, slightly decrease saturation
4. For darker shades (700-900): decrease lightness, slightly adjust hue for richness
5. The 500 step should be close to the base color
6. Ensure perceptual evenness — each step should feel like an equal jump

### Step 4: Compute Contrast Ratios

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

**Required pairs to compute:**

For each primary/secondary/accent color, compute against:
- White (#FFFFFF)
- Near-white (#F8FAFC)
- Light gray (#F1F5F9)
- Dark (#0F172A)
- Near-black (#1E293B)
- Each other primary/secondary (for decorative pairings)

For each neutral, compute against:
- White and near-white (for text readability)
- Dark colors (for reversed contexts)

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

### Step 5: Validate WCAG AA Compliance

After computing all pairs, enforce these rules:

| Element | Minimum Ratio | WCAG Level | Required |
|---------|--------------|------------|----------|
| Body text on background | 4.5:1 | AA | **Yes** |
| Large text on background (18px+ or 14px bold) | 3:1 | AA | **Yes** |
| UI components & graphical objects | 3:1 | AA | **Yes** |
| Body text (enhanced) | 7:1 | AAA | Recommended |
| Large text (enhanced) | 4.5:1 | AAA | Recommended |

**For any pair that fails AA:**

1. Flag it clearly:
   ```
   ⚠ FAIL: Amber (#F59E0B) on White (#FFFFFF)
     Contrast ratio: 2.02:1
     Required: 4.5:1 for body text
   ```

2. Suggest the nearest accessible alternative:
   - Darken the foreground until it passes: "#B45309" (ratio 4.7:1)
   - Or lighten the background: use against Dark (#0F172A) instead
   - Present both options to the user

3. If the user wants to keep a failing pair for decorative use only, note it:
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

### Step 6: Generate Colorblind Safety Notes

For each primary and accent color, assess visibility under the three main types of color vision deficiency:

```yaml
colorblind_notes:
  protanopia: "Distinguishable — no red component"
  deuteranopia: "Distinguishable — no red component"
  tritanopia: "May appear similar to purple — pair with shape/icon cues"
```

**How to assess:**

1. **Protanopia** (red-blind, ~1% of males): Reds appear as dark browns/greens. Assess whether the color has significant red channel contribution.
2. **Deuteranopia** (green-blind, ~5% of males): Greens and reds appear similar as browns/yellows. Assess red/green channel balance.
3. **Tritanopia** (blue-blind, ~0.01%): Blues and yellows appear similar. Assess blue/yellow channel balance.

**Rules:**
- Never rely on color alone to convey meaning — always pair with icons, labels, or patterns
- Flag problematic combinations: red/green, yellow/white, light gray/white
- Every semantic color (success/warning/error/info) must have an icon alternative
- If a primary color is difficult under any deficiency, note what secondary cue to use

### Step 7: Generate Dark Mode Variants

Create a dark mode color mapping. Dark mode is NOT just inverted colors — it requires re-mapped values with validated contrast.

**Dark mode principles:**

1. **Backgrounds go dark:** White (#FFFFFF) → Dark (#0F172A or #1E293B)
2. **Text goes light:** Dark text → White or light gray
3. **Brand colors adjust:** Primary may need a lighter shade for readability on dark backgrounds
4. **Reduce saturation slightly:** Full-saturation colors on dark backgrounds cause eye strain
5. **Surfaces layer up:** Use slightly lighter dark shades for cards/elevated surfaces

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
      use: "Primary text on dark background"
    - foreground: "#60A5FA"
      background: "#0F172A"
      contrast_ratio: 6.2
      wcag_aa_normal: true
      use: "Brand blue links/CTAs on dark background"
```

**Every dark mode pair must also pass WCAG AA.** Run the same validation from step 5 on all dark mode pairs.

---

## Part 2: Typography System

### Step 8: Font Selection

Select fonts that match the brand personality from the voice section.

**Primary font** (headings, hero text, UI):
- Match to brand personality:
  - Confident + Modern → Geometric sans-serif (Inter, Poppins, Plus Jakarta Sans)
  - Warm + Approachable → Rounded sans-serif (Nunito, Quicksand) or humanist sans (Lato, Open Sans)
  - Authoritative + Traditional → Serif (Merriweather, Lora, Playfair Display)
  - Technical + Precise → Monospace or grotesque sans (JetBrains Mono, IBM Plex Sans)

**Secondary font** (body text, long-form):
- Must pair well with primary
- Prioritize readability at 16px
- If primary is display/heading-only, secondary carries the reading load

**Questions for the user:**

1. "Do you have existing brand fonts?"
   - If yes: use them, verify they're available (Google Fonts, Adobe, licensed)
   - If no: present 2-3 pairings matched to personality

2. "Where will the brand appear most? (Web, print, both)"
   - Web-first: prioritize Google Fonts for easy loading
   - Print-first: wider font selection, consider licensing

**Font sources and licensing:**
- Google Fonts: free, easy to embed, best for web
- Adobe Fonts: included with Creative Cloud, great selection
- Fontshare: free for commercial use, curated quality
- System fonts: zero loading cost (Inter is now a system font on many platforms)

### Step 9: Define Type Scale

Build a consistent typographic hierarchy with 5-7 levels:

```yaml
scale:
  - level: "H1 / Display"
    size: "48px / 3rem"
    weight: "Bold"
    line_height: "1.1"
    letter_spacing: "-0.02em"
    use: "Page titles, hero sections"

  - level: "H2"
    size: "36px / 2.25rem"
    weight: "Semi-Bold"
    line_height: "1.2"
    letter_spacing: "-0.01em"
    use: "Section headings"

  - level: "H3"
    size: "24px / 1.5rem"
    weight: "Semi-Bold"
    line_height: "1.3"
    use: "Subsections, card titles"

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

**Scale principles:**
- Use a consistent ratio between levels (1.25 or 1.333 are common)
- Line height decreases as size increases (large text needs tighter leading)
- Letter spacing is negative for large text, neutral or positive for small text
- Every level must specify both px and rem
- Minimum body text size: 16px (never smaller for primary reading)

### Step 10: Define Font Weights

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
- Document when to use which weight (don't leave it ambiguous)

---

## Part 3: Write to brand-reference.yml

### Step 11: Write Colors Section

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
        100: "#DBEAFE"
        200: "#BFDBFE"
        300: "#93C5FD"
        400: "#60A5FA"
        500: "#3B82F6"
        600: "#2563EB"
        700: "#1D4ED8"
        800: "#1E40AF"
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
        # ... all computed pairs
      colorblind_notes:
        protanopia: "Distinguishable — no red component"
        deuteranopia: "Distinguishable — no red component"
        tritanopia: "May appear similar to purple — pair with shape/icon cues"
  secondary:
    # ... same structure
  accent:
    # ... same structure
  neutrals:
    # ... hex and use only (scales not needed for neutrals)
  semantic:
    success: "#16A34A"
    warning: "#F59E0B"
    error: "#DC2626"
    info: "#2563EB"
  accessibility:
    # ... summary pairs for quick reference (from brand-reference-schema.yml)
  proportions:
    rule: "60/30/10"
    dominant: "White / Light Gray (60%)"
    secondary: "Slate / Brand Blue (30%)"
    accent: "Amber (10%)"
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
      # ... all dark mode pairs validated
```

### Step 12: Write Typography Section

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
    # ... all levels
```

---

## Checkpoint: accessibility_validation

Before declaring this phase complete, run ALL of these checks:

### Check 1: contrast_matrix

**Verify:** Every foreground/background pair in `brand-reference.yml#colors` has a `contrast_ratio` field.

**How:** Read the colors section. For each entry in `accessible_pairs` (in every color group AND in `dark_mode.accessible_pairs`), verify `contrast_ratio` is present and is a number > 0.

**Fail action:** Compute missing ratios using the formula from step 4.

### Check 2: wcag_aa_body

**Verify:** All pairs intended for body text have `wcag_aa_normal: true`.

**How:** For each pair where `use` suggests text usage (not "decorative only"), verify `wcag_aa_normal` is `true` (meaning contrast_ratio ≥ 4.5).

**Fail action:** For each failing pair:
1. Calculate how much the foreground must darken (or lighten) to reach 4.5:1
2. Find the nearest shade from the color's tint/shade scale that passes
3. Suggest: "Darken [color name] from [hex] to [suggested hex] (ratio [new ratio]:1)"

### Check 3: wcag_aa_large

**Verify:** All pairs intended for large text have `wcag_aa_large: true`.

**How:** For each pair where `use` suggests heading or large text usage, verify `wcag_aa_large` is `true` (meaning contrast_ratio ≥ 3.0).

**Fail action:** Same approach as check 2, but with the 3.0:1 threshold.

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
2. Check it has `background`, `text`, and `accessible_pairs` sub-sections
3. For each pair in `dark_mode.accessible_pairs`, verify `wcag_aa_normal: true` for text pairs

**Fail action:** Generate the dark mode section:
1. Create dark background values
2. Map brand colors to lighter variants for dark backgrounds
3. Compute and validate all pairs
4. Re-run this check

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
   Phase 4 (typography-color) completed. Primary palette: [colors].
   [N] tint/shade scales generated. [M] contrast pairs computed.
   All pairs pass WCAG AA. Dark mode validated. Colorblind notes present.
   Typography: [primary font] + [secondary font], [N]-level scale.
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
