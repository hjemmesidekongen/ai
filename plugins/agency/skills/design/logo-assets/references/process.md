# Logo Assets — Detailed Process

Full instructions for the logo-assets skill. Referenced by SKILL.md.

---

## Step 0: Initialize Trace (mandatory if tracing enabled)

Read `state.yml` and check `trace.enabled`. If `true`:

1. Create trace file: `.ai/projects/[name]/traces/{skill-name}-{ISO-timestamp}.yml`
2. Write `_meta` block: schema `"trace"`, version `"1.1.0"`, skill, module, project, started_at, trace_mode
3. Initialize empty `steps: []`, `checkpoint_result: {}`, `quality_summary: {}`, `reflections: {}`

**Schema v1.1.0 — required fields per step:**
- `decision`, `reasoning`, `uncertainty` (always required)
- `observation` — what happened vs expected; surprises, gaps, confirmations
- `improvement_idea` — actionable suggestion for the skill/pipeline (if any)
- `design_decision` — lasting choice beyond this run (if any)

**Trace-level `reflections` section (REQUIRED — Stop hook enforces):**
```yaml
reflections:
  observations: ["at least one observation about the run"]
  improvement_ideas: []   # optional but encouraged
  design_decisions: []    # optional, only for lasting choices
```

The Stop hook will BLOCK completion if reflections section is missing.

---


## Pre-check: Fast-forward Detection

Before starting the interactive flow, check if production logos already exist
(e.g. from /brand:generate):

```
existing_logos = glob(.ai/projects/[name]/design/logos/*.svg)
  OR glob(.ai/projects/[name]/brand/logos/*.svg)
  OR glob(.ai/projects/[name]/brand/brand-package/logos/*.svg)

if existing_logos.count >= 4:
  Report existing assets found:
    "Found {count} existing logo SVGs. These appear to be from a prior
     brand generation run."
    List files found.
  Ask user:
    "[1] Fast-forward — validate existing logos, copy to design/logos/,
         generate any missing variants, and run checkpoint
     [2] Start fresh — run the full 5-phase interactive logo design process"

  if user picks [1] (fast-forward):
    - Validate existing SVGs (valid XML, viewBox, no raster, <50KB)
    - Copy ALL assets to project-local directories if not already there:
      - Logos → design/logos/ (6 SVGs)
      - Brand icons → design/logos/ (4 SVGs, flat — no subdirectory)
      - Social templates → design/logos/social-templates/ (3 SVGs)
      Also check .ai/brands/[brand]/assets/ as a source location
    - Identify missing variants from the 6 required logos and 4 brand icons
    - Generate only missing variants
    - Generate logo-preview.html (with <img src> refs to ../logos/)
    - Generate social templates if missing
    - Register ALL assets with project-local paths (.ai/projects/[name]/...)
      — never register .ai/brands/ paths in asset-registry.yml
    - Skip to checkpoint (Phase 4 Step 6 onward)

  if user picks [2]:
    Proceed with full interactive flow below
```

---

## Full Interactive Flow Summary

1. Read brand-summary.yml and brand-reference.yml — name, colors, typography, visual
2. **Phase 1 — Discovery:** Reflect brand context, logo type preference (wordmark/lettermark/abstract/combination/emblem), reference logos, what to avoid, design brief summary; wait for user confirmation
3. **Phase 2 — Concept Generation:** 20-25 SVG concepts via 4 parallel sub-agents (wordmarks, abstract, combination, wildcard); HTML preview; user picks 3-5 favorites
4. **Phase 3 — Refinement:** 3-4 variations per pick (weight/spacing/proportion/detail/color); multi-size testing (200px, 80px, 40px, 16px); background testing; final selection
5. **Phase 4 — Finalization:** 6 logo SVG variants, 4 brand icon variants, clear space + minimum size, misuse rules, update preview, confirm before writing
6. **Phase 4b — Social Templates:** OG image (1200x630), Twitter card (1200x628), LinkedIn banner (1584x396); each embeds final logo + brand colors
7. **Phase 5 — Optional refinement:** Figma/Illustrator import, CMYK/Pantone for print, trademark search guidance
8. Register all SVG outputs in asset-registry.yml (logos, icons, social templates)
9. Run file_validation checkpoint (6 checks); fix failures; advance only after all checks pass
10. Write recovery notes to state.yml

---

## Before You Start

Read all brand data from the project:

- `.ai/projects/[name]/brand/brand-summary.yml` — primary source; has brand
  name, industry, positioning, values, personality, colors, typography, visual mood
- `.ai/projects/[name]/brand/brand-reference.yml` — full visual spec if present

Key fields to extract:

- `brand_name` — the name that may appear in the wordmark
- `industry` — grounds the design in the right domain
- `positioning` — what the brand stands for
- `values` — principles that should come through visually
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

Reference this data throughout every phase. The logo is not designed in
isolation — it is the visual distillation of everything captured so far.

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
8. **No inline styles when avoidable** — prefer attributes (`fill`, `stroke`) over `<style>` blocks; use `<style>` only when dark mode media queries are needed

---

## Phase 1: Discovery

This phase collects preferences before generating any concepts. Ask questions
**one at a time** — same interview philosophy as all agency skills.

### Step 1: Reflect Brand Context

Start by summarizing what you know:

> "Before we design the logo, let me share what I know about [brand_name] from
> the brand data:
>
> **Personality:** [voice.personality attributes]
> **Colors:** [primary color name + hex]
> **Shape language:** [visual.shape_language.direction]
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

"Are there any logos — from any industry — that you admire? What do you like
about them? You can describe them or upload screenshots."

- If the user uploads images, analyze the visual patterns: geometry, weight, spacing, color usage.
- If they describe verbally, capture the key attributes.
- If they have no references: "No problem — I'll pull from your brand's personality and visual direction."

### Step 4: What to Avoid

**Question:**

"Just as important — is there anything you definitely **don't** want? Specific
styles, shapes, or cliches to avoid?"

**Industry-specific cliches to mention:**

| Industry | Common cliches |
|----------|----------------|
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

**Save to findings.md after this step (2-Action Rule checkpoint).**

---

## Phase 2: Concept Generation

Generate **20-25 diverse SVG logo concepts**. This is the creative exploration
phase — variety is critical.

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

After all concepts are generated, create an **HTML preview page** at
`.ai/projects/[name]/design/previews/logo-preview.html`:

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
         - <img src="path/to/concept-NN.svg"> referencing the actual file
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
- **Use `<img src>` tags referencing the actual SVG files** — the preview
  doubles as a functional test that all files exist at their expected paths
- All paths must be **relative to the preview file's location** (e.g.
  `../logos/logo-full-light.svg`, `../logos/brand-icon.svg`)
- **Never reference `.ai/brands/`** — always reference the project-local
  copies in `design/logos/` and `design/logos/social-templates/`
- No external dependencies — the page must work offline

### Presenting Concepts

After generating the preview:

> "I've generated [N] logo concepts for [brand_name]. You can view them all at:
>
> `.ai/projects/[name]/design/previews/logo-preview.html`
>
> Open this file in your browser and toggle between light/dark backgrounds.
> Take your time — then tell me which **3-5 concepts** you'd like to refine.
>
> You can reference them by number (e.g., 'concepts 3, 7, 12, and 19')."

**Save to findings.md after this step (2-Action Rule checkpoint).**

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

If a concept breaks down at small sizes, create a **simplified variant** (fewer
details, bolder strokes) specifically for small contexts. This becomes the logo mark.

### Step 3: Background Testing

Show each finalist on:

| Background | Why |
|------------|-----|
| **White (#FFFFFF)** | Standard light background |
| **Dark (#1A1A2E or brand dark)** | Dark mode / dark UI |
| **Brand primary color** | On colored sections |
| **Photography** | Overlaid on a busy image (test contrast) |
| **Light gray (#F5F5F5)** | Subtle background — tests if logo disappears |

Update the preview page with a **refinement section** showing each finalist
across all sizes and backgrounds.

### Step 4: User Selection

> "Here are the refined variations. For each original concept, I've created [N]
> variations and tested them at multiple sizes and on different backgrounds.
>
> Check the updated preview page — there's now a 'Refinement' section below the
> original concepts.
>
> Which one is THE logo? Pick your final choice, or tell me what to adjust."

If the user wants further tweaks, iterate. Max 3 refinement rounds before pushing to finalize.

**Save to findings.md after this step (2-Action Rule checkpoint).**

---

## Phase 4: Finalization

The user has chosen a final design. Now produce the complete logo system.

### Step 1: Generate All Required Logo Variants

From the chosen design, produce these 6 SVG files:

| File | Description | Key rules |
|------|-------------|-----------|
| `logo-full-light.svg` | Full logo (icon + wordmark) for light backgrounds | Uses brand primary colors |
| `logo-full-dark.svg` | Full logo for dark backgrounds | Reversed — white/light elements, adjusted brand colors |
| `logo-wordmark-light.svg` | Text-only version for light backgrounds | Same typography as full logo, no icon |
| `logo-wordmark-dark.svg` | Text-only version for dark backgrounds | Reversed colors |
| `logo-mark.svg` | Icon/symbol only (no text) | Must work at 32px+, uses brand colors |
| `logo-mark-mono.svg` | Monochrome mark (single color, typically black) | For watermarks, single-color contexts |

**File destinations:** `.ai/projects/[name]/design/logos/`

Each variant must:
- Follow all SVG rules from the "SVG Rules" section above
- Include the correct `<title>` element
- Use only brand colors from brand-summary.yml
- Have meaningful group IDs

### Step 2: Generate Brand Icon

The brand icon is a **simplified version of the logo mark**, optimized for
very small contexts (app icons, social avatars, favicons).

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

**File destinations:** `.ai/projects/[name]/design/logos/`

### Step 3: Define Clear Space & Minimum Size

Define the rules and write them to YAML output:

**Clear space:**
> Minimum clear space equal to [measurement — typically the height of the mark
> or a specific element like the letter 'x'] on all sides.

**Minimum size:**

| Context | Minimum |
|---------|---------|
| Digital | 24px height |
| Print | 10mm height |

Present a visual explanation showing the clear space boundary around the logo.

### Step 4: Create Misuse Examples

Document what should **never** be done to the logo:

1. Never stretch or distort proportions
2. Never change brand colors to non-approved colors
3. Never place on busy backgrounds without a contrast overlay
4. Never add drop shadows, gradients, or outlines
5. Never rotate the logo
6. Never rearrange logo elements (e.g., icon below wordmark if designed as horizontal)

Ask the user if there are any additional misuse rules specific to their context.

### Step 5: Update Preview Page

Add a **"Final Logo System"** section to `logo-preview.html` showing:

- All 6 logo variants side by side
- All 4 brand icon variants
- Size comparison (200px → 80px → 40px → 16px)
- Background tests (white, dark, brand color, photography)
- Clear space visualization
- Misuse examples (can be described, not necessarily rendered as altered SVGs)

**Path rules for the preview HTML:**

- **Use `<img src>` tags** pointing to the actual SVG files — the preview
  page is a functional test that all logo files exist at their expected paths.
  If images are broken, the files are missing or misplaced.
- All paths must be **relative to the preview file's location**:
  - Logos: `../logos/logo-full-light.svg`
  - Brand icons: `../logos/brand-icon.svg`
  - Social templates: `../logos/social-templates/og-image-template.svg`
- **Never reference `.ai/brands/`** — always reference the project-local
  copies in `design/logos/`. The preview file lives in `design/previews/`,
  so `../logos/` reaches the right directory.
- After generating the preview, **open the HTML and verify all images render**.
  Broken images mean broken paths or missing files — fix before proceeding.

### Step 6: Summary Before Writing

Present the complete logo system for approval:

```
Logo System for [brand_name]:

Logo type: [wordmark / combination mark / etc.]
Based on: Concept [N], variation [X]

Files to write:
  .ai/projects/[name]/design/logos/
    - logo-full-light.svg
    - logo-full-dark.svg
    - logo-wordmark-light.svg
    - logo-wordmark-dark.svg
    - logo-mark.svg
    - logo-mark-mono.svg
  .ai/projects/[name]/design/logos/
    - brand-icon.svg
    - brand-icon-light.svg
    - brand-icon-dark.svg
    - brand-icon-mono.svg
  .ai/projects/[name]/design/logos/social-templates/
    - og-image-template.svg
    - twitter-card-template.svg
    - linkedin-banner-template.svg
  .ai/projects/[name]/design/previews/
    - logo-preview.html

Clear space: [rule]
Minimum size: 24px digital / 10mm print
Misuse rules: [count] defined

Does this look right? I'll write everything once you confirm.
```

Only write to disk after user confirmation.

---

## Phase 4b: Social Templates

After the logo system is finalized and written to disk, generate 3 social
media template SVGs using the final logo and brand colors.

### Templates to Produce

| File | Dimensions | Purpose |
|------|-----------|---------|
| `og-image-template.svg` | 1200×630 | Open Graph image — shared link previews on Facebook, LinkedIn, Slack |
| `twitter-card-template.svg` | 1200×628 | Twitter/X summary_large_image card |
| `linkedin-banner-template.svg` | 1584×396 | LinkedIn company page header banner |

**File destinations:** `.ai/projects/[name]/design/logos/social-templates/`

### Template Structure

Each template must:

1. **Embed the logo** — inline the finalized `logo-full-light.svg` or `logo-full-dark.svg` content directly into the template SVG (whichever reads better on the template background)
2. **Use brand colors** — background drawn from `colors.primary` or `colors.secondary`; text elements (if any) drawn from the complementary contrast color
3. **Include placeholder zones** — mark the area where campaign-specific text or images would be placed (dashed border, labeled `<!-- CONTENT ZONE — replace per campaign -->`)
4. **Follow SVG rules** — all rules from the "SVG Rules" section apply; under 15KB; valid XML; accessible `<title>`
5. **Be production-ready** — import cleanly into Figma or Illustrator for per-campaign customization

### Social Template SVG Template

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 [W] [H]">
  <title>[Brand Name] — [Template Name] Template</title>

  <!-- Background -->
  <rect width="[W]" height="[H]" fill="[brand primary hex]"/>

  <!-- Logo (inlined from logo-full-light.svg or logo-full-dark.svg) -->
  <g id="logo" transform="translate([x], [y]) scale([s])">
    <!-- paste logo SVG content here, strip outer <svg> wrapper -->
  </g>

  <!-- Content zone placeholder -->
  <rect id="content-zone"
        x="[x]" y="[y]" width="[w]" height="[h]"
        fill="none"
        stroke="rgba(255,255,255,0.3)"
        stroke-dasharray="8 4"/>
  <!-- CONTENT ZONE — replace per campaign -->

</svg>
```

### Logo Placement in Templates

| Template | Logo position | Content zone |
|----------|--------------|-------------|
| OG image (1200×630) | Bottom-left or top-left, 30% of height | Center-right area |
| Twitter card (1200×628) | Top-left, 25% of height | Center area |
| LinkedIn banner (1584×396) | Left-aligned, 60% of height | Right two-thirds |

After writing all social templates, add them to the preview page under a
**"Social Templates"** section showing each template at reduced scale.

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
> These steps happen outside Claude Code — I've noted them in the project state
> for your team."

---

## Asset Registration

After all files are written (logos, brand icons, social templates), register
every asset in `.ai/projects/[name]/asset-registry.yml`.

**Critical:** All registered paths must use project-local directories
(`.ai/projects/[name]/design/logos/...`), never `.ai/brands/...`. The
asset-registry is consumed by downstream skills which expect project-local
paths. If logos were copied from `.ai/brands/`, register the copy location.

### Registration Schema

Add one entry per SVG file under the `logo_assets` group:

```yaml
logo_assets:
  registered_at: "[ISO timestamp]"
  logos:
    - id: "logo-full-light"
      path: ".ai/projects/[name]/design/logos/logo-full-light.svg"
      type: logo_variant
      use_on: "White and light-colored backgrounds"
    - id: "logo-full-dark"
      path: ".ai/projects/[name]/design/logos/logo-full-dark.svg"
      type: logo_variant
      use_on: "Dark backgrounds, photography overlays"
    - id: "logo-wordmark-light"
      path: ".ai/projects/[name]/design/logos/logo-wordmark-light.svg"
      type: logo_variant
      use_on: "Tight horizontal spaces on light backgrounds"
    - id: "logo-wordmark-dark"
      path: ".ai/projects/[name]/design/logos/logo-wordmark-dark.svg"
      type: logo_variant
      use_on: "Tight horizontal spaces on dark backgrounds"
    - id: "logo-mark"
      path: ".ai/projects/[name]/design/logos/logo-mark.svg"
      type: logo_variant
      use_on: "App icons, favicons, avatars, small spaces"
    - id: "logo-mark-mono"
      path: ".ai/projects/[name]/design/logos/logo-mark-mono.svg"
      type: logo_variant
      use_on: "Single-color contexts, watermarks, embossing"
  brand_icons:
    - id: "brand-icon"
      path: ".ai/projects/[name]/design/logos/brand-icon.svg"
      type: brand_icon
    - id: "brand-icon-light"
      path: ".ai/projects/[name]/design/logos/brand-icon-light.svg"
      type: brand_icon
    - id: "brand-icon-dark"
      path: ".ai/projects/[name]/design/logos/brand-icon-dark.svg"
      type: brand_icon
    - id: "brand-icon-mono"
      path: ".ai/projects/[name]/design/logos/brand-icon-mono.svg"
      type: brand_icon
  social_templates:
    - id: "og-image-template"
      path: ".ai/projects/[name]/design/logos/social-templates/og-image-template.svg"
      type: social_template
      dimensions: "1200x630"
      platform: "Open Graph / Facebook / LinkedIn / Slack"
    - id: "twitter-card-template"
      path: ".ai/projects/[name]/design/logos/social-templates/twitter-card-template.svg"
      type: social_template
      dimensions: "1200x628"
      platform: "Twitter / X"
    - id: "linkedin-banner-template"
      path: ".ai/projects/[name]/design/logos/social-templates/linkedin-banner-template.svg"
      type: social_template
      dimensions: "1584x396"
      platform: "LinkedIn company page"
  preview:
    - id: "logo-preview"
      path: ".ai/projects/[name]/design/previews/logo-preview.html"
      type: preview_html
```

If `asset-registry.yml` already exists (created by a prior skill), merge under
the `logo_assets` key — do not overwrite the entire file.

---

## Checkpoint: file_validation

After writing all files, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `logo_svg_variants` | All 6 logo SVGs exist in `design/logos/` | Generate the missing variants |
| `brand_icon_variants` | All 4 brand icon SVGs exist in `design/logos/` (brand-icon.svg, brand-icon-light/dark/mono.svg) | Derive from the logo mark |
| `svg_validity` | Every SVG is valid XML with `viewBox`, no fixed `width`/`height` | Fix the invalid SVGs |
| `svg_file_size` | No SVG exceeds 15KB | Optimize — simplify paths, reduce precision, strip metadata |
| `preview_html` | `design/previews/logo-preview.html` exists, all `<img src>` paths use `../logos/` relative refs (no `.ai/brands/`), and every referenced SVG file exists on disk | Fix paths to use `../logos/` relative refs; verify all referenced files exist |
| `assets_registered` | All 13 assets are present in asset-registry.yml | Add missing entries |

**On pass:** Update `state.yml` → mark logo-assets complete, write recovery
notes, advance to next phase.

**On fail:** Fix the failing checks, re-run validation. Do NOT advance. Max 3 rounds.

---

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- logo_svg_variants: all 6 logo SVGs exist in `design/logos/`
- brand_icon_variants: all 4 brand icon SVGs exist in `design/logos/brand-icon/`
- svg_validity: every SVG is valid XML with `viewBox`, no fixed `width`/`height`
- svg_file_size: no SVG exceeds 15KB
- preview_html: `design/previews/logo-preview.html` exists
- assets_registered: all 13 assets present in asset-registry.yml

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Logo design reflects brand personality, colors, and shape language from brand-summary.yml
- All 6 variants form a coherent system (consistent style across light/dark/wordmark/mark)
- Brand icon is recognizable at 32×32px
- Social templates embed the final logo and use brand colors correctly
- SVGs follow all rules (self-contained, paths not text, optimized, accessible title)

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.

---

## Recovery Notes

After checkpoint passes, write recovery notes to `state.yml`:

```
Project: [name] ([industry])
Logo type: [wordmark / combination / abstract / lettermark / emblem]
Based on concept: [concept number and description]
Logo files: 6 SVG variants in design/logos/
Brand icon: 4 SVG variants in design/logos/brand-icon/
Social templates: 3 SVGs in design/logos/social-templates/ (OG, Twitter, LinkedIn)
Clear space: [rule summary]
Minimum size: 24px digital / 10mm print
Misuse rules: [count] defined
Preview: design/previews/logo-preview.html
Assets registered: 13 entries in asset-registry.yml
Professional refinement: [recommended / not needed]
```

---

## Trace Finalization (mandatory if tracing enabled)

Before completing, verify your trace file has:
1. All steps recorded (written every 2 steps per the 2-Action Rule)
2. `checkpoint_result` with pass/fail status
3. `quality_summary` with avg_uncertainty and recommendation
4. `reflections` section with at least one observation (REQUIRED — Stop hook enforces this)
5. Step-level `observation`, `improvement_idea`, or `design_decision` where applicable

The Stop hook will BLOCK completion if tracing is enabled and the trace file
is missing or has no `reflections:` section.
