# Visual Identity — Detailed Process

## 1. Context Resolution

### Brand exists (.ai/brand/{name}/)
Read guideline.yml for: industry context, personality attributes, color preferences,
target audience. Read voice.yml for tone spectrum (formality, enthusiasm, technicality) —
these inform color temperature and typography weight.

### No brand
Gather from user: industry/domain, mood (2-3 adjectives), color preferences
(must-have or must-avoid), audience (developers, consumers, enterprise).

## 2. Color Palette Generation

### OKLCH Color Space
Use OKLCH (Oklab Lightness, Chroma, Hue) for perceptually uniform scales.
OKLCH ensures equal lightness steps look equally spaced to human eyes,
unlike HSL which distorts at certain hues.

### Scale generation (10 stops: 50-950)
For each palette (primary, secondary, accent):
1. Pick base hue (H) and chroma (C) from brand direction
2. Anchor at stop 500-600 (the "main" shade)
3. Lightness ramp: 50=0.97, 100=0.93, 200=0.87, 300=0.77, 400=0.67,
   500=0.55, 600=0.48, 700=0.40, 800=0.33, 900=0.25, 950=0.18
4. Chroma: bell curve peaking at 400-600, tapering at extremes
5. Convert OKLCH → hex for compatibility

### Color harmony
- Primary: brand main color — hero elements, CTAs
- Secondary: complementary or analogous — supporting UI
- Accent: contrast color — highlights, badges, special states
- Harmony types: complementary (180°), analogous (±30°), split-comp (±150°), triadic (±120°)

### Neutrals
Desaturate primary hue with 2-5% chroma for warm/cool tint.
Pure gray feels disconnected; tinted neutrals feel cohesive.

## 3. Semantic Color Mapping

Map palette → intent:
- success: green family (hue ~145°)
- warning: amber/orange (hue ~75°)
- error: red family (hue ~25°)
- info: reuse primary

### Surface & text tokens
Light: bg=neutral-50, surface=white, foreground=neutral-900,
foreground-secondary=neutral-600, foreground-muted=neutral-400

Dark (semantic override): bg=neutral-950, surface=neutral-900,
foreground=neutral-50, primary→lighter stop (600→400)

## 4. Typography

### Selection by brand personality
- High formality → serif or geometric sans (Playfair, Outfit)
- Low formality → rounded/humanist sans (Nunito, Source Sans)
- Technical → geometric mono-linear (Space Grotesk, IBM Plex)
- Body: prioritize x-height, open counters (Inter, Source Sans 3, Geist)
- Mono: JetBrains Mono, Fira Code, Source Code Pro, Geist Mono

### Anti-patterns
- Never use Inter for headings (generic)
- Never pair fonts from same superfamily
- Max 2 non-mono families
- No display fonts for body text

### Type scale (ratio 1.2-1.333)
display: clamp(2.5rem,5vw,3.5rem)/bold/1.1, h1: clamp(2rem,4vw,2.5rem)/bold/1.2,
h2: clamp(1.5rem,3vw,2rem)/semibold/1.25, h3: 1.5rem/semibold/1.3,
h4: 1.25rem/medium/1.4, body: 1rem/regular/1.6, body-sm: 0.875rem/regular/1.5,
caption: 0.75rem/medium/1.4

## 5. Spacing, Radius, Shadow

### Spacing (4px base)
space-1:4px, 2:8px, 3:12px, 4:16px, 5:20px, 6:24px, 8:32px, 10:40px, 12:48px, 16:64px, 20:80px, 24:96px

### Radius
sm:0.25rem, md:0.375rem, lg:0.5rem, xl:0.75rem, 2xl:1rem, full:9999px

### Shadow
sm: 0 1px 2px rgb(0 0 0/0.05)
md: 0 4px 6px -1px rgb(0 0 0/0.1), 0 2px 4px -2px rgb(0 0 0/0.1)
lg: 0 10px 15px -3px rgb(0 0 0/0.1), 0 4px 6px -4px rgb(0 0 0/0.1)

## 6. WCAG Contrast Validation

### Formula
L = 0.2126*R + 0.7152*G + 0.0722*B (linearized sRGB)
ratio = (L_lighter + 0.05) / (L_darker + 0.05)

### Required checks
- foreground on background: ≥4.5:1
- foreground-secondary on background: ≥4.5:1
- foreground-muted on background: ≥3:1
- primary on background: ≥3:1
- white on primary: ≥4.5:1
- Same checks for dark mode pairs

### Colorblind notes
- Protanopia/deuteranopia: red/green confusion (use icons, not just color)
- Tritanopia: blue/yellow confusion (rare)

## 7. Output Format

### tokens.yml structure
```yaml
_meta:
  name: "{brand-name}"
  created_at: "ISO-8601"
  schema: "design-plugin-v1"

primitives:
  color:
    primary:   { 50: { value: "#hex", oklch: "oklch(...)" }, ... 950 }
    secondary: { ... }
    accent:    { ... }
    neutral:   { ... }
    red:       { ... }
    amber:     { ... }
    green:     { ... }

semantic:
  color:
    primary: "{primitives.color.primary.600}"
    # ... all semantic mappings
  dark:
    background: "{primitives.color.neutral.950}"
    # ... dark mode overrides

typography:
  family: { heading: "...", body: "...", mono: "..." }
  scale: { display: { size, weight, line_height, family }, ... }
  weight: { regular: 400, medium: 500, semibold: 600, bold: 700 }

spacing: { base: "4px", scale: { 1: "4px", ... } }
radius: { sm: "0.25rem", ... }
shadow: { sm: "...", md: "...", lg: "..." }
```

### identity.yml structure
```yaml
name: "{brand-name}"
created_at: "ISO-8601"
color_rationale:
  primary: "Why this hue"
  secondary: "Harmony relationship"
  accent: "Contrast purpose"
  neutrals: "Warm vs cool tint"
typography_rationale:
  heading: "Personality match"
  body: "Readability, pairing logic"
accessibility:
  contrast_pairs: [{ pair, ratio, status }, ...]
  colorblind_notes: "Risk areas and mitigations"
```
