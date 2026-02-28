---
name: visual-identity
description: >
  Defines the brand's overall visual language: imagery direction, iconography
  rules, shape language, layout principles, and mood board description. This
  skill creates the visual framework that the logo design skill (Phase 6)
  must follow. Writes the visual section (excluding logo) to brand-reference.yml.
phase: 5
depends_on: [identity-interview, audience-personas, tone-of-voice, typography-color]
writes:
  - "brand-reference.yml#visual"
reads:
  - "brand-reference.yml#meta"
  - "brand-reference.yml#identity"
  - "brand-reference.yml#voice"
  - "brand-reference.yml#colors"
  - "brand-reference.yml#typography"
checkpoint:
  type: data_validation
  required_checks:
    - name: "visual_style_dimensions"
      verify: "At least 3 visual style dimensions defined (from: photography, illustration, iconography, shape_language, spacing)"
      fail_action: "Ask the user about the missing dimensions — offer industry-relevant examples"
    - name: "iconography_rules"
      verify: "visual.iconography has stroke_width and corner_radius defined"
      fail_action: "Ask the user to choose stroke width (1-3px) and corner radius (0-8px) with visual examples"
    - name: "layout_grid"
      verify: "visual.layout.grid is defined and includes base unit"
      fail_action: "Suggest a grid system based on the brand's spacing philosophy and ask for confirmation"
    - name: "shape_language"
      verify: "visual.shape_language is defined with primary_shapes and rationale"
      fail_action: "Present shape options (rounded/organic vs angular/geometric) and ask the user to choose"
  on_fail: "Fix issues and re-run checkpoint. Do NOT advance to next phase."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Visual Identity

Phase 5 of brand generation. This skill translates the brand's identity, voice, colors, and typography into a cohesive visual language — the rules that govern how the brand *looks* across all touchpoints. The output defines the visual framework that logo design (Phase 6), content rules (Phase 7), and social media (Phase 8) build on.

This skill does NOT create the logo. It defines the visual environment the logo must live in.

## Before You Start

Read the brand's existing data from brand-reference.yml:

- `meta.brand_name` and `meta.industry` — to ground visual suggestions in the right domain
- `identity.values` — values shape visual direction (a brand valuing "precision" looks different from one valuing "warmth")
- `identity.positioning.differentiator` — the visual system should reinforce what makes the brand unique
- `voice.personality` — personality attributes directly map to visual style (confident → bold shapes, warm → rounded corners, clear → clean layouts)
- `voice.spectrum` — formality and enthusiasm scores guide visual density and energy
- `colors.primary` and `colors.accent` — the existing palette constrains and inspires visual choices
- `typography.primary.family` — the font personality anchors the visual direction

Reference this data throughout the interview. Connect every visual decision back to identity and voice:

> "Your brand personality is [confident, warm, clear] — that suggests [visual direction]. Your primary color [Brand Blue] and font [Inter] already point toward [style]. Let's build on that."

## Interview Philosophy

Same rules as all previous phases:

- Ask **one question at a time**. Never present a wall of options.
- **Show before you tell** — describe visual examples rather than abstract concepts.
- If the user gives a **vague answer**, show a concrete contrast: "Do you mean more like Apple (minimal, lots of white space) or more like Spotify (bold, dense, colorful)?"
- If the user says **"I don't know"**, suggest 2-3 directions based on their voice personality and industry.
- Keep the tone visual and concrete — paint pictures with words.
- After each answer, briefly reflect back what you understood.

## Interview Flow

The interview has 6 stages. Each builds a different dimension of the visual system.

### Stage 1: Visual Direction Overview

Start by establishing the overall visual mood based on what you already know.

**Opening:**

"Let's define how your brand looks. Based on your voice personality ([list attributes]) and your color palette ([primary color name]), I see a few possible visual directions. Before we dive into specifics, let me describe three approaches:"

Present exactly **3 visual directions**, each grounded in the brand's existing data:

| Signal | Direction A | Direction B | Direction C |
|--------|------------|------------|------------|
| High formality (7-10) | Corporate refined | — | — |
| Low formality (1-4) | — | Casual & approachable | — |
| High enthusiasm (7-10) | — | Energetic & bold | — |
| Technical brand | Clean & systematic | — | — |
| Creative/artistic brand | — | — | Expressive & organic |
| Warm personality | — | Friendly & human | — |

Each direction should include:
- A one-sentence description
- A real-world brand example the user would recognize
- How it connects to their existing identity and voice data

**Question:**

"Which direction feels closest to how you want your brand to look? Or describe something different."

→ This sets the visual baseline for all subsequent stages.

### Stage 2: Imagery Style → `visual.imagery`

Based on the chosen direction, explore how the brand uses images.

**Question 1 — Medium:**

"Does your brand primarily use photography, illustrations, or a mix of both?"

| Answer | Follow-up |
|--------|-----------|
| Photography | "What style? Candid/documentary vs. polished/staged? People-focused vs. product-focused? Natural light vs. studio?" |
| Illustration | "What style? Flat/minimal, isometric/3D, hand-drawn/organic, or geometric/abstract?" |
| Mixed | "When do you use photography vs. illustration? For example, photography for testimonials and illustration for features?" |
| "I don't know" | Suggest based on industry and personality — e.g., B2B SaaS tends toward illustration + selective photography; lifestyle brands lean photography-heavy |

**Question 2 — Mood:**

"Describe the feeling your imagery should create. For example:"

| Mood | Description |
|------|-------------|
| Warm & authentic | Natural light, real people, imperfect moments |
| Clean & professional | High contrast, well-composed, minimal distractions |
| Bold & energetic | Bright colors, dynamic angles, movement |
| Calm & trustworthy | Soft tones, balanced composition, open space |
| Technical & precise | Diagrams, data visualization, structured layouts |

"Which of these resonates? Or describe your own."

**Question 3 — Subjects and avoidance:**

"What should appear in your brand imagery? And equally important — what should you *never* show?"

**Industry-specific prompts:**

| Industry | Typical subjects | Common things to avoid |
|----------|-----------------|----------------------|
| SaaS | Product UI, team, abstract shapes | Generic stock, handshakes, skyscrapers |
| E-commerce | Product shots, lifestyle, unboxing | Low-quality photos, cluttered backgrounds |
| Agency | Client work, process, team culture | Cheesy stock, over-filtered images |
| Healthcare | Real patients (with consent), care moments | Clinical/cold imagery, graphic content |
| Fintech | Data visualization, real people, devices | Piles of cash, Wall Street cliches |

**Output:**

```yaml
visual:
  imagery:
    style: "[Photography / Illustration / Mixed]"
    mood: "[description]"
    subjects: "[what appears]"
    avoid: "[what to never show]"
```

### Stage 3: Iconography → `visual.iconography`

Icons are a critical part of the visual system. They appear in UI, marketing, presentations, and social media.

**Question 1 — Style:**

"For icons and small graphics, which style fits your brand?"

Present options with descriptions:

| Style | Description | Best for |
|-------|-------------|----------|
| Outline / line | Thin strokes, no fill — clean and modern | SaaS, tech, minimal brands |
| Filled / solid | Solid shapes — bold and immediate | Consumer brands, high-energy |
| Duotone | Two-tone fills — distinctive and branded | Brands with strong color identity |
| Hand-drawn | Organic, imperfect lines — warm and human | Creative, education, lifestyle |

**Question 2 — Specifications:**

"Let's nail down the technical details. These keep icons consistent everywhere."

Ask one at a time:

1. **Stroke width:** "For line-style icons, how thick should the strokes be?"
   - 1px — delicate, refined (good for luxury, minimal brands)
   - 1.5px — balanced, readable at small sizes (most common)
   - 2px — bold, confident (good for energetic brands)
   - 2.5-3px — chunky, friendly (good for playful brands)

   If user doesn't have a preference, suggest based on voice personality:
   - Formal/precise → 1-1.5px
   - Warm/approachable → 1.5-2px
   - Bold/energetic → 2-3px

2. **Corner radius:** "How rounded should corners be on icons and UI elements?"
   - 0px — sharp, geometric, authoritative
   - 2-4px — slightly softened, professional default
   - 6-8px — noticeably rounded, friendly and approachable
   - Full/pill — maximally rounded, playful and modern

   Connect to shape language: "This should match the overall shape language we'll define next."

3. **Grid size:** "What base size should icons be designed on?"
   - 16px — compact, for dense UIs
   - 20px — small, common for body text inline icons
   - 24px — standard, most versatile (recommended default)
   - 32px — large, for feature showcases

**Output:**

```yaml
  iconography:
    style: "[outline / filled / duotone / hand-drawn]"
    stroke_width: "[value]px"
    corner_radius: "[value]px"
    grid_size: "[value]px"
    notes: "[any additional rules — e.g., 'always use brand blue for primary icons']"
```

### Stage 4: Shape Language → `visual.shape_language`

Shape language defines the geometric vocabulary used across the brand — in layouts, graphics, icons, decorative elements, and eventually the logo.

**Question:**

"Every brand has a shape language — the kinds of shapes that feel 'on brand'. Think about your brand personality: does it feel more..."

| Direction | Shapes | Conveys | Example brands |
|-----------|--------|---------|----------------|
| Rounded / organic | Circles, soft curves, blobs, rounded rectangles | Warmth, approachability, friendliness | Slack, Headspace, Mailchimp |
| Angular / geometric | Sharp corners, triangles, hexagons, straight lines | Precision, authority, innovation | IBM, Stripe, Tesla |
| Mixed / balanced | Rounded containers with angular details, or vice versa | Versatility, modernity | Spotify (rounded but bold), Notion (clean but warm) |

"Which feels right for [brand_name]? Remember, your voice personality is [attributes] and your primary shapes should reinforce that."

**Follow-ups:**

- If rounded: "Are we talking gentle curves (like Headspace) or more playful blobs (like Mailchimp)?"
- If angular: "Strict geometry (like IBM) or dynamic angles (like a tech startup)?"
- If mixed: "Which is dominant — the softness or the sharpness?"

Then ask:

"Are there specific shapes that feel particularly 'on brand' for you? For example, circles for community, hexagons for technology, or shields for trust?"

**Output:**

```yaml
  shape_language:
    direction: "[rounded / angular / mixed]"
    primary_shapes: "[e.g., rounded rectangles, circles, soft curves]"
    accent_shapes: "[e.g., angular badges for emphasis, subtle triangles]"
    rationale: "[why this fits the brand — tie to personality and values]"
```

### Stage 5: Layout Principles → `visual.layout`

Layout defines how elements are arranged spatially.

**Question 1 — Grid system:**

"Let's set up your grid system. This keeps layouts consistent across your website, marketing materials, and presentations."

Recommend based on brand type:

| Brand type | Recommended grid | Why |
|-----------|-----------------|-----|
| Web-first SaaS | 12-column, 8px base grid | Industry standard, flexible |
| Content-heavy (blog, news) | 12-column, 8px base grid, with max-width content column | Readability |
| Portfolio / creative | Freeform with 8px snap grid | Creative flexibility |
| E-commerce | 12-column, dense grid, 4-6 product columns | Product density |
| Corporate / enterprise | 12-column, generous gutters | Clean, spacious |

"I'd recommend [suggestion] based on your industry. The base grid unit of 8px means all spacing is a multiple of 8 (8, 16, 24, 32...). Does that work, or do you prefer a different approach?"

**Question 2 — Whitespace philosophy:**

"How much breathing room should your designs have?"

| Philosophy | Description | Best for |
|-----------|-------------|----------|
| Airy / minimal | Generous margins, lots of white space, content floats | Luxury, premium, design-forward |
| Balanced | Standard spacing, clear hierarchy, neither dense nor sparse | Most brands (safe default) |
| Dense / content-heavy | Tight spacing, more information per screen | Dashboards, data products, news |

Connect to voice spectrum: "Your enthusiasm score is [N] and formality is [N] — [airy/balanced/dense] matches that energy."

**Question 3 — Image treatment:**

"How should images be treated in layouts?"

| Treatment | Description |
|----------|-------------|
| Clean / contained | Rectangular, no overlap, consistent rounded corners |
| Overlapping / layered | Images peek out from behind cards or overlap sections |
| Masked / shaped | Images cropped to circles, rounded rectangles, or custom shapes |
| Full-bleed | Edge-to-edge images, immersive |
| Framed | Borders or shadows around images |

**Output:**

```yaml
  layout:
    grid: "[e.g., 12-column, 8px base grid]"
    max_content_width: "[e.g., 1280px]"
    spacing_principle: "[airy / balanced / dense]"
    alignment: "[left-aligned / centered / mixed]"
    image_treatment: "[clean / overlapping / masked / full-bleed / framed]"
    corner_radius: "[e.g., 8px for cards, matches iconography]"
```

### Stage 6: Mood Board Description

The mood board captures the overall *feeling* of the visual identity in prose — it's the bridge between the technical specs and the creative intent.

**Question:**

"Let's capture what the visual world of [brand_name] feels like. I'll draft a mood board description based on everything we've discussed. Think of it as a brief a designer would read before creating anything for your brand."

Draft a 3-5 sentence mood board description that weaves together:
- The imagery mood
- The shape language
- The color palette feel
- The typography personality
- The overall energy level

**Example:**

> "[Brand] lives in a world of clean, confident geometry. Sharp lines meet generous whitespace, punctuated by bold blue accents that demand attention without shouting. Photography is authentic and people-focused — real moments, natural light, no stock poses. The visual system feels like a well-designed tool: everything has a purpose, nothing is decorative for its own sake."

Present the draft:

"Here's how I'd describe your visual world. This will guide designers and content creators who work with your brand:"

> [draft]

"Does this capture the right feeling? I can adjust the emphasis or energy."

→ Store as `visual.mood_board`

## Writing the Output

After all stages are complete, present the full summary for approval:

```
Here's the visual identity I captured for [brand_name]:

Visual direction: [one-line summary]

Imagery:
  Style: [photography / illustration / mixed]
  Mood: [description]
  Subjects: [what appears]
  Avoid: [what to never show]

Iconography:
  Style: [outline / filled / duotone / hand-drawn]
  Stroke width: [N]px
  Corner radius: [N]px
  Grid size: [N]px

Shape language:
  Direction: [rounded / angular / mixed]
  Primary shapes: [description]
  Accent shapes: [description]

Layout:
  Grid: [description]
  Spacing: [airy / balanced / dense]
  Alignment: [left / centered / mixed]
  Image treatment: [description]

Mood board:
  "[mood board description]"

Does this look right? I can adjust anything before we save.
```

Only write to disk after the user confirms.

### brand-reference.yml — `visual` section

Write everything under the `visual` key, **excluding `visual.logo`** (that section is reserved for Phase 6: logo-design):

```yaml
visual:
  imagery:
    style: "[Photography / Illustration / Mixed]"
    mood: "[description]"
    subjects: "[what appears]"
    avoid: "[what to never show]"
  iconography:
    style: "[outline / filled / duotone / hand-drawn]"
    stroke_width: "[N]px"
    corner_radius: "[N]px"
    grid_size: "[N]px"
    notes: "[additional rules]"
  shape_language:
    direction: "[rounded / angular / mixed]"
    primary_shapes: "[description]"
    accent_shapes: "[description]"
    rationale: "[why this fits the brand]"
  layout:
    grid: "[e.g., 12-column, 8px base grid]"
    max_content_width: "[e.g., 1280px]"
    spacing_principle: "[airy / balanced / dense]"
    alignment: "[left-aligned / centered / mixed]"
    image_treatment: "[clean / overlapping / masked / full-bleed / framed]"
    corner_radius: "[e.g., 8px]"
  mood_board: |
    [3-5 sentence mood board description]
```

## Checkpoint: data_validation

After writing, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `visual_style_dimensions` | At least 3 of these are defined: imagery, iconography, shape_language, layout, mood_board | Ask the user about the missing dimensions — offer industry-relevant examples |
| `iconography_rules` | `visual.iconography` has `stroke_width` and `corner_radius` defined | Ask the user to choose stroke width (1-3px) and corner radius (0-8px) with examples |
| `layout_grid` | `visual.layout.grid` is defined and includes a base unit | Suggest a grid system based on the brand's spacing philosophy and ask for confirmation |
| `shape_language` | `visual.shape_language` has `primary_shapes` and `rationale` | Present shape options (rounded/organic vs angular/geometric) and ask the user to choose |

**On pass:** Update `state.yml` → mark phase 5 complete, write recovery notes, advance to phase 6 (logo-design).

**On fail:** Fix the failing checks (ask targeted questions), re-run validation. Do NOT advance. Max 3 rounds.

## Recovery Notes

After checkpoint passes, write recovery notes to `state.yml`:

```
Brand: [name] ([industry])
Visual direction: [one-line summary]
Imagery: [style] — [mood in 5 words]
Iconography: [style], [stroke_width]px stroke, [corner_radius]px corners
Shape language: [direction] — [primary_shapes]
Layout: [grid], [spacing_principle] spacing
Mood board: [first 80 chars]...
Logo constraints from visual identity: [key constraints logo must follow]
```

These notes let a future session (especially logo-design in Phase 6) understand the visual rules without re-reading the full brand-reference.yml. The "logo constraints" line is particularly important — it bridges directly to Phase 6.
