# Logo Design — Detailed Process

Full instructions for the logo-design skill (Phase 6). Referenced by SKILL.md.

---

## Before You Start

Read all existing brand data from `brand-reference.yml`:

- `meta.brand_name` — the name that may appear in the wordmark
- `meta.industry` — grounds the design in the right domain
- `identity.positioning` — what the brand stands for
- `identity.values` — principles that should come through visually
- `voice.personality` — attributes the logo should embody (e.g., "Confident but not arrogant")
- `voice.spectrum` — formality/enthusiasm scores guide visual energy
- `colors.primary` — exact hex values to use in the logo
- `colors.secondary` and `colors.accent` — available palette for variants
- `typography.primary.family` — font family for wordmark elements
- `visual.imagery` — overall visual mood
- `visual.iconography` — stroke width, corner radius (icon consistency)
- `visual.shape_language` — primary shapes and direction (rounded vs angular)
- `visual.layout` — grid system and spacing philosophy
- `visual.mood_board` — the creative brief in prose

Reference this data throughout every phase. The logo is not designed in isolation — it is the visual distillation of everything captured so far.

---

## SVG Rules (Enforced on Every Generated SVG)

These rules apply to every SVG file produced by this skill. Validate after generation.

1. **Self-contained** — no external fonts, no linked images, no `<use>` referencing external files
2. **Meaningful group IDs** — `<g id="wordmark">`, `<g id="icon">`, `<g id="mark">` so elements can be extracted
3. **viewBox set, no fixed dimensions** — use `viewBox="0 0 W H"`, never set `width` or `height` attributes (allows infinite scaling)
4. **Text converted to paths** — all typography rendered as `<path>` elements (no font dependencies)
5. **Optimized** — no unnecessary `<g>` wrappers, no editor metadata, no hidden layers
6. **Under 15KB per file** — ideally under 5KB; strip decimal precision to 2 places if needed
7. **Accessible** — include `<title>` element with descriptive text (e.g., `<title>[Brand] Logo</title>`)
8. **No inline styles when avoidable** — prefer attributes (`fill`, `stroke`) over `<style>` blocks for simpler SVGs; use `<style>` only when dark mode media queries are needed

---

## Phase 1: Discovery

This phase collects preferences before generating any concepts. Ask questions **one at a time** following the same interview philosophy as previous skills.

### Step 1: Reflect Brand Context

Start by summarizing what you know:

> "Before we design the logo, let me share what I know about [brand_name] from the work we've done so far:
>
> **Personality:** [voice.personality attributes — e.g., 'Confident, warm, clear']
> **Colors:** [primary color name + hex]
> **Shape language:** [visual.shape_language.direction — e.g., 'Rounded, organic']
> **Visual mood:** [visual.mood_board — first sentence]
>
> This will guide the logo direction. Let's dive in."

### Step 2: Logo Type Preference

**Question:**

"What type of logo feels right for [brand_name]?"

| Type | Description | Best for |
|------|-------------|----------|
| **Wordmark** | The brand name styled as the logo (like Google, Coca-Cola) | Distinctive names, when name recognition is the priority |
| **Lettermark** | Initials only (like IBM, HBO, CNN) | Long names, B2B, when brevity matters |
| **Abstract mark** | A geometric or organic symbol (like Nike swoosh, Pepsi) | Brands that want a standalone icon |
| **Combination mark** | Symbol + wordmark together (like Adidas, Burger King) | Versatility — works as full logo or icon alone |
| **Emblem** | Text enclosed in a shape (like Starbucks, NFL) | Heritage brands, badges, seals |

"Which of these resonates? Or would you like me to explore a mix?"

**Follow-ups:**

| Answer | Follow-up |
|--------|-----------|
| Picks one | "Great choice. Any specific examples of [type] logos you like? Even outside your industry." |
| Unsure | "Based on your brand's personality ([attributes]) and industry ([industry]), I'd suggest [recommendation]. But I'll generate a mix so you can compare." |
| "All of them" | "I'll generate a mix. We'll narrow down after you see the concepts." |

### Step 3: Reference Logos

**Question:**

"Are there any logos — from any industry — that you admire? What do you like about them? You can describe them or upload screenshots."

- If the user uploads images, analyze the visual patterns: geometry, weight, spacing, color usage.
- If they describe verbally, capture the key attributes.
- If they have no references: "No problem — I'll pull from your brand's personality and visual direction."

### Step 4: What to Avoid

**Question:**

"Just as important — is there anything you definitely **don't** want? Specific styles, shapes, or cliches to avoid?"

**Industry-specific cliches to mention:**

| Industry | Common cliches |
|----------|---------------|
| Tech/SaaS | Generic globe, circuit board, cloud icon |
| Finance | Columns, shields, eagle |
| Health | Cross, heart, caduceus |
| Food | Chef hat, fork and knife |
| Education | Open book, graduation cap |
| Real estate | Rooftop silhouette, key |

"These are the cliches in [industry]. I'll steer clear unless you specifically want one."

### Step 5: Design Brief Summary

Before moving to concept generation, present the brief:

```
Logo Design Brief for [brand_name]:

Type preference: [answer or 'mixed']
Admired logos: [references or 'none — using brand data']
Avoid: [list]

Design constraints from brand data:
- Primary color: [hex + name]
- Shape language: [direction]
- Typography: [family] for any wordmark
- Iconography style: [style] with [stroke_width] stroke
- Corner radius: [corner_radius]
- Mood: [mood_board first sentence]

Ready to generate concepts?
```

Wait for user confirmation before proceeding.

---

## Phase 2: Concept Generation

Generate **20-25 diverse SVG logo concepts**. This is the creative exploration phase — variety is critical.

### Concept Mix

Ensure diversity across these dimensions:

| Dimension | Targets |
|-----------|---------|
| **Logo types** | At least 3 different types from Phase 1 (even if user picked one — include alternatives) |
| **Shape bases** | Circles, squares, hexagons, shields, organic, triangles, custom geometry |
| **Complexity** | Simple (3-5 elements) to moderate (8-12 elements). No complex illustrations. |
| **Typography** | With and without text. Different arrangements (horizontal, stacked, centered) |
| **Weight** | Light/thin variants and bold/heavy variants |
| **Color** | Primary color, secondary color, monochrome (black), and reversed (white) versions of select concepts |

### Concept Naming Convention

Name each concept with a descriptive ID:

```
concept-01-wordmark-modern.svg
concept-02-abstract-circle.svg
concept-03-combination-geometric.svg
concept-04-lettermark-bold.svg
...
concept-25-emblem-minimal.svg
```

### SVG Concept Template

Every concept must follow this structure:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 [W] [H]">
  <title>[Brand Name] Logo — Concept [N]: [Description]</title>
  <g id="logo">
    <g id="icon">
      <!-- Mark/symbol elements -->
    </g>
    <g id="wordmark">
      <!-- Text-as-paths elements (if applicable) -->
    </g>
  </g>
</svg>
```

### Sub-Agent Parallelization

To generate 20-25 concepts efficiently, dispatch **multiple sub-agents in parallel**:

- **Agent A** (5-6 concepts): Wordmark and lettermark variations
- **Agent B** (5-6 concepts): Abstract mark variations
- **Agent C** (5-6 concepts): Combination mark variations
- **Agent D** (5-7 concepts): Mixed types — emblems, experimental, wildcard ideas

Each agent receives:
- The full design brief from Phase 1
- The brand data summary (colors, typography, shape language)
- The SVG rules
- Its assigned concept range (e.g., "concepts 01-06, focus on wordmarks")

### Preview Page Generation

After all concepts are generated, create an **HTML preview page** at `preview/brand-preview.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>[Brand Name] — Logo Concepts</title>
  <style>
    /* Light/dark toggle, grid layout, concept cards */
  </style>
</head>
<body>
  <header>
    <h1>[Brand Name] Logo Concepts</h1>
    <button id="theme-toggle">Toggle Dark Mode</button>
  </header>

  <div class="grid">
    <!-- Each concept as a card with:
         - SVG rendered inline (not as <img> — allows CSS theming)
         - Concept number and name
         - Shown on light background
    -->
  </div>

  <script>
    // Theme toggle: switches body class between light/dark
    // Updates background so logos can be evaluated on both
  </script>
</body>
</html>
```

**Preview page requirements:**

- Responsive grid (3-4 columns on desktop, 2 on tablet, 1 on mobile)
- Light/dark mode toggle button
- Each concept displayed at ~200px width with its name below
- Clean, distraction-free layout — the logos are the focus
- All SVGs embedded inline (not as external files) for simplicity
- No external dependencies — the page must work offline

### Presenting Concepts

After generating the preview:

> "I've generated [N] logo concepts for [brand_name]. You can view them all at:
>
> `preview/brand-preview.html`
>
> Open this file in your browser and toggle between light/dark backgrounds. Take your time — then tell me which **3-5 concepts** you'd like to refine.
>
> You can reference them by number (e.g., 'concepts 3, 7, 12, and 19')."

---

## Phase 3: Refinement

The user has picked 3-5 favorites. Now iterate on each.

### Step 1: Generate Variations

For each picked concept, generate **3-4 variations** that explore:

| Variation type | What changes |
|----------------|-------------|
| **Weight** | Thicker or thinner strokes/elements |
| **Spacing** | Tighter or looser letterspacing and element gaps |
| **Proportion** | Icon larger/smaller relative to wordmark |
| **Detail** | Add or remove a subtle element (underline, dot, accent shape) |
| **Color** | Try secondary color as the primary, or a two-tone approach |

Name variations: `concept-07-var-a.svg`, `concept-07-var-b.svg`, etc.

### Step 2: Multi-Size Testing

Test every variation at these sizes:

| Size | Context | What to check |
|------|---------|---------------|
| **200px+** | Hero banner, splash screen | Full detail visible, balanced composition |
| **80px** | Navigation bar | Still readable, no elements merge |
| **40px** | Small nav, profile avatar | Core shape holds, details may simplify |
| **16px** | Favicon | Only the essential shape remains recognizable |

If a concept breaks down at small sizes, create a **simplified variant** (fewer details, bolder strokes) specifically for small contexts. This becomes the logo mark.

### Step 3: Background Testing

Show each finalist on:

| Background | Why |
|------------|-----|
| **White (#FFFFFF)** | Standard light background |
| **Dark (#1A1A2E or brand dark)** | Dark mode / dark UI |
| **Brand primary color** | On colored sections |
| **Photography** | Overlaid on a busy image (test contrast) |
| **Light gray (#F5F5F5)** | Subtle background — tests if logo disappears |

Update the preview page with a **refinement section** that shows each finalist across all sizes and backgrounds.

### Step 4: User Selection

> "Here are the refined variations. For each original concept, I've created [N] variations and tested them at multiple sizes and on different backgrounds.
>
> Check the updated preview page — there's now a 'Refinement' section below the original concepts.
>
> Which one is THE logo? Pick your final choice, or tell me what to adjust."

If the user wants further tweaks, iterate. Max 3 refinement rounds before pushing to finalize.

---

## Phase 4: Finalization

The user has chosen a final design. Now produce the complete logo system.

### Step 1: Generate All Required Variants

From the chosen design, produce these 6 SVG files:

| File | Description | Key rules |
|------|-------------|-----------|
| `logo-full-light.svg` | Full logo (icon + wordmark) for light backgrounds | Uses brand primary colors |
| `logo-full-dark.svg` | Full logo for dark backgrounds | Reversed — white/light elements, adjusted brand colors per dark_mode spec |
| `logo-wordmark-light.svg` | Text-only version for light backgrounds | Same typography as full logo, no icon |
| `logo-wordmark-dark.svg` | Text-only version for dark backgrounds | Reversed colors |
| `logo-mark.svg` | Icon/symbol only (no text) | Must work at 32px+, uses brand colors |
| `logo-mark-mono.svg` | Monochrome mark (single color, typically black) | For watermarks, single-color contexts |

**File destinations:** `assets/logo/svg/`

Each variant must:
- Follow all SVG rules from the "SVG Rules" section above
- Include the correct `<title>` element
- Use only brand colors from `brand-reference.yml`
- Have meaningful group IDs

### Step 2: Generate Brand Icon

The brand icon is a **simplified version of the logo mark**, optimized for very small contexts (app icons, social avatars, favicons).

**Rules:**
- Must be recognizable at 32x32px
- Works in both circle crop (social) and square crop (app icons)
- No fine details that disappear at small sizes
- If the logo mark is already simple enough, the brand icon may be identical

**Produce 4 variants:**

| File | Description |
|------|-------------|
| `brand-icon.svg` | Default — brand colors on transparent background |
| `brand-icon-light.svg` | For dark backgrounds — light/white mark |
| `brand-icon-dark.svg` | For light backgrounds — dark mark |
| `brand-icon-mono.svg` | Single color (black) for monochrome contexts |

**File destinations:** `assets/brand-icon/`

### Step 3: Define Clear Space & Minimum Size

Define the rules and write them to the YAML output:

**Clear space:**
> Minimum clear space equal to [measurement — typically the height of the mark or a specific element like the letter 'x'] on all sides.

**Minimum size:**

| Context | Minimum |
|---------|---------|
| Digital | 24px height |
| Print | 10mm height |

Present a visual explanation to the user showing the clear space boundary around the logo.

### Step 4: Create Misuse Examples

Document what should **never** be done to the logo. These are standard misuse rules:

1. Never stretch or distort proportions
2. Never change brand colors to non-approved colors
3. Never place on busy backgrounds without a contrast overlay
4. Never add drop shadows, gradients, or outlines
5. Never rotate the logo
6. Never rearrange logo elements (e.g., icon below wordmark if designed as horizontal)

Ask the user if there are any additional misuse rules specific to their context.

### Step 5: Update Preview Page

Add a **"Final Logo System"** section to `preview/brand-preview.html` showing:

- All 6 logo variants side by side
- All 4 brand icon variants
- Size comparison (200px → 80px → 40px → 16px)
- Background tests (white, dark, brand color, photography)
- Clear space visualization
- Misuse examples (can be described, not necessarily rendered as altered SVGs)

### Step 6: Summary Before Writing

Present the complete logo system for approval:

```
Logo System for [brand_name]:

Logo type: [wordmark / combination mark / etc.]
Based on: Concept [N], variation [X]

Files to write:
  assets/logo/svg/
    - logo-full-light.svg
    - logo-full-dark.svg
    - logo-wordmark-light.svg
    - logo-wordmark-dark.svg
    - logo-mark.svg
    - logo-mark-mono.svg
  assets/brand-icon/
    - brand-icon.svg
    - brand-icon-light.svg
    - brand-icon-dark.svg
    - brand-icon-mono.svg
  preview/
    - brand-preview.html

Clear space: [rule]
Minimum size: 24px digital / 10mm print
Misuse rules: [count] defined

brand-reference.yml sections:
  - visual.logo (primary, mark, variants, clear_space, minimum_size, misuse_rules)
  - assets.logo (file paths)
  - assets.brand_icon (file paths)

Does this look right? I'll write everything once you confirm.
```

Only write to disk after user confirmation.

---

## Phase 5: Professional Refinement (Optional)

After all files are written, inform the user about optional next steps:

> "The logo system is complete. All SVGs are production-ready for web use.
>
> **Optional next steps for professional refinement:**
>
> 1. **Import to Figma or Illustrator** — The SVGs import cleanly. You can:
>    - Clean up anchor points and bezier curves
>    - Fine-tune kerning in wordmark elements
>    - Add to a Figma component library
>
> 2. **Print production** — If you need the logo for print:
>    - Convert to CMYK color space
>    - Define Pantone spot colors for exact reproduction
>    - Export as AI/EPS/PDF for print vendors
>
> 3. **Trademark search** — Before using the logo commercially:
>    - Run a visual similarity search on trademark databases
>    - Consider consulting a trademark attorney
>
> These steps happen outside Claude Code — I've noted them in the brand reference for your team."

---

## Writing the Output

### 1. brand-reference.yml — `visual.logo` section

```yaml
visual:
  logo:
    primary: "assets/logo/svg/logo-full-light.svg"
    mark: "assets/logo/svg/logo-mark.svg"
    variants:
      - name: "Full — light background"
        file: "assets/logo/svg/logo-full-light.svg"
        use_on: "White and light-colored backgrounds"
      - name: "Full — dark background"
        file: "assets/logo/svg/logo-full-dark.svg"
        use_on: "Dark backgrounds, photography overlays"
      - name: "Wordmark — light background"
        file: "assets/logo/svg/logo-wordmark-light.svg"
        use_on: "Tight horizontal spaces on light backgrounds"
      - name: "Wordmark — dark background"
        file: "assets/logo/svg/logo-wordmark-dark.svg"
        use_on: "Tight horizontal spaces on dark backgrounds"
      - name: "Mark only"
        file: "assets/logo/svg/logo-mark.svg"
        use_on: "App icons, favicons, avatars, small spaces"
      - name: "Mark — monochrome"
        file: "assets/logo/svg/logo-mark-mono.svg"
        use_on: "Single-color contexts, watermarks, embossing"
    clear_space: "[rule — e.g., Height of the mark on all sides]"
    minimum_size:
      digital: "24px height"
      print: "10mm height"
    misuse_rules:
      - "Never stretch or distort proportions"
      - "Never change brand colors to non-approved colors"
      - "Never place on busy backgrounds without a contrast overlay"
      - "Never add drop shadows, gradients, or outlines"
      - "Never rotate the logo"
      - "Never rearrange logo elements"
```

### 2. brand-reference.yml — `assets.logo` and `assets.brand_icon` sections

```yaml
assets:
  logo:
    full_light: "assets/logo/svg/logo-full-light.svg"
    full_dark: "assets/logo/svg/logo-full-dark.svg"
    wordmark_light: "assets/logo/svg/logo-wordmark-light.svg"
    wordmark_dark: "assets/logo/svg/logo-wordmark-dark.svg"
    mark: "assets/logo/svg/logo-mark.svg"
    mark_mono: "assets/logo/svg/logo-mark-mono.svg"
    clear_space: "[rule]"
    minimum_size:
      digital: "24px height"
      print: "10mm height"
    misuse:
      - "Never stretch or distort proportions"
      - "Never change brand colors"
      - "Never place on busy backgrounds without overlay"
      - "Never add shadows, gradients, or outlines"
      - "Never rotate the logo"
      - "Never rearrange logo elements"

  brand_icon:
    default: "assets/brand-icon/brand-icon.svg"
    light: "assets/brand-icon/brand-icon-light.svg"
    dark: "assets/brand-icon/brand-icon-dark.svg"
    mono: "assets/brand-icon/brand-icon-mono.svg"
```

### 3. SVG Files

Write all 10 SVG files:
- 6 in `assets/logo/svg/`
- 4 in `assets/brand-icon/`

### 4. Preview HTML

Write the complete `preview/brand-preview.html` with all sections:
- Concept gallery (from Phase 2)
- Refinement comparisons (from Phase 3)
- Final logo system (from Phase 4)

---

## Checkpoint: file_validation

After writing all files, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `logo_svg_variants` | All 6 logo SVGs exist in `assets/logo/svg/` | Generate the missing variants |
| `brand_icon_variants` | All 4 brand icon SVGs exist in `assets/brand-icon/` | Derive from the logo mark |
| `svg_validity` | Every SVG is valid XML with `viewBox`, no fixed `width`/`height` | Fix the invalid SVGs |
| `svg_file_size` | No SVG exceeds 15KB | Optimize — simplify paths, reduce precision, strip metadata |
| `preview_html` | `preview/brand-preview.html` exists and has no broken references | Regenerate the preview page |
| `logo_mark_small_size` | `logo-mark.svg` is recognizable at 32px (**manual approval**) | Simplify the mark — reduce detail until clear at 32px |

**On pass:** Update `state.yml` → mark phase 6 complete, write recovery notes, advance to phase 7 (content-rules).

**On fail:** Fix the failing checks, re-run validation. Do NOT advance. Max 3 rounds.

---

## Recovery Notes

After checkpoint passes, write recovery notes to `state.yml`:

```
Brand: [name] ([industry])
Logo type: [wordmark / combination / abstract / lettermark / emblem]
Based on concept: [concept number and description]
Logo files: 6 SVG variants in assets/logo/svg/
Brand icon: 4 SVG variants in assets/brand-icon/
Clear space: [rule summary]
Minimum size: 24px digital / 10mm print
Misuse rules: [count] defined
Preview: preview/brand-preview.html
Professional refinement: [recommended / not needed]
```
