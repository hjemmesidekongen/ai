# Implementation Guide — Detailed Process

## Overview

The implementation guide is Layer 4 of the four-layer architecture. It translates
project-level creative direction into page-specific, section-level motion and
interaction specs that build agents consume directly.

### The Three-Reference Model

Build agents receive three references per page:

| Reference | Source | What It Provides |
|-----------|--------|-----------------|
| Pencil screenshot | Pencil design tool | **Looks** — visual layout, color, typography, imagery |
| Component spec | component-specs skill | **Structure** — props, slots, a11y, responsive rules |
| Implementation guide | **This skill** | **Feel/Motion** — animations, interactions, textures, choreography |

No single reference is sufficient. The screenshot shows _what_ it looks like,
the spec defines _what_ it is, and the guide defines _how_ it moves and responds.

### Four-Layer Architecture

| Layer | Source | Scope | Override Rule |
|-------|--------|-------|---------------|
| 1. Universal rules | frontend-design skill | All projects | Non-negotiable constraints |
| 2. Technology conventions | Codex skills | Framework-specific | Framework best practices |
| 3. Creative direction | creative-direction skill | Project-level intent | Brand expression |
| 4. Implementation guide | **This skill** | Page-level specifics | Concrete per-section specs |

Higher layers override lower layers, except Layer 1 constraints which are
non-negotiable (timing limits, a11y, reduced motion).

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

## Output YAML Schema

Save each guide as `design/implementation-guides/<page-name>.yml`, matching the
layout filename (e.g., `home.yml`, `pricing.yml`, `blog-slug.yml`).

```yaml
page: "home"
route: "/"
creative_direction_ref: "creative-direction.yml"
reduced_motion:
  strategy: "respect"          # always "respect" — Layer 1 constraint
  fallback: "opacity-only"     # animations degrade to simple opacity fade

sections:
  - name: "hero"
    entrance:
      type: "stagger"                          # stagger | viewport | immediate | none
      children: ["heading", "subheading", "cta"]
      delay_between: 0.1                       # seconds between children
      initial: { opacity: 0, y: 20 }
      animate: { opacity: 1, y: 0 }
      transition:
        type: "spring"
        stiffness: 300
        damping: 30
      reduced_motion:
        initial: { opacity: 0 }
        animate: { opacity: 1 }
        transition: { duration: 0.3 }
    scroll: null
    hover: null
    texture: "none"
    spatial:
      inner_rhythm: "comfortable"              # tight | comfortable | spacious
      section_gap: "var(--spacing-16)"
    choreography:
      role: "opener"                           # opener | supporting | closer | interlude
      notes: "First thing users see — fast entrance, no scroll dependency"

  - name: "features"
    entrance:
      type: "viewport"
      trigger: "whileInView"
      threshold: 0.3
      initial: { opacity: 0, y: 40 }
      animate: { opacity: 1, y: 0 }
      transition:
        duration: 0.5
        ease: [0.25, 0.1, 0.25, 1]
      reduced_motion:
        initial: { opacity: 0 }
        animate: { opacity: 1 }
        transition: { duration: 0.3 }
    scroll:
      type: "parallax"
      speed: 0.05
      api: "useScroll + useTransform"
    hover:
      cards:
        scale: 1.02
        transition: { type: "spring", stiffness: 400, damping: 25 }
      reduced_motion:
        cards:
          scale: 1                             # no scale change
          border_color: "var(--color-accent)"   # visual-only indicator
    texture: "subtle-grain"
    spatial:
      inner_rhythm: "comfortable"
      section_gap: "var(--spacing-12)"
    choreography:
      role: "supporting"
      notes: "Reveals as user scrolls — builds on hero's promise"

  - name: "cta-banner"
    entrance:
      type: "viewport"
      trigger: "whileInView"
      threshold: 0.5
      initial: { opacity: 0, scale: 0.98 }
      animate: { opacity: 1, scale: 1 }
      transition:
        type: "spring"
        stiffness: 200
        damping: 25
      reduced_motion:
        initial: { opacity: 0 }
        animate: { opacity: 1 }
        transition: { duration: 0.3 }
    scroll: null
    hover:
      cta_button:
        scale: 1.05
        transition: { type: "spring", stiffness: 500, damping: 20 }
    texture: "none"
    spatial:
      inner_rhythm: "spacious"
      section_gap: "var(--spacing-16)"
    choreography:
      role: "closer"
      notes: "Final conversion push — strong entrance, prominent hover on CTA"
```

---

## Field Reference

### `entrance.type` values

| Type | Motion.dev Pattern | When to Use |
|------|-------------------|-------------|
| `stagger` | `m.div` with `staggerChildren` in `transition` | Multiple child elements that reveal sequentially |
| `viewport` | `whileInView` prop on `m.div` | Sections below the fold — animate on scroll into view |
| `immediate` | `m.div` with `initial`/`animate` on mount | Above-fold content that animates on page load |
| `none` | No animation wrapper | Static sections (footers, legal text) |

### `scroll` types

| Type | Motion.dev API | Description |
|------|---------------|-------------|
| `parallax` | `useScroll` + `useTransform` | Background moves slower than foreground |
| `progress` | `useScroll` + `useTransform` | Element transforms based on scroll position (e.g., progress bars) |
| `reveal` | `useScroll` + `useTransform` + clip-path | Content reveals as user scrolls through section |
| `pin` | `useScroll` with sticky positioning | Section stays pinned while scroll content changes within it |
| `null` | No scroll interaction | Default — section has no scroll-linked behavior |

### `hover` patterns

Hover specs are keyed by the interactive element name within the section.
Each hover spec maps directly to Motion.dev's `whileHover` prop.

```yaml
hover:
  <element_name>:
    scale: 1.02                    # maps to whileHover={{ scale: 1.02 }}
    y: -2                          # maps to whileHover={{ y: -2 }}
    transition:
      type: "spring"
      stiffness: 400
      damping: 25
```

Always include a `reduced_motion` variant for hover effects that use scale or
transform — replace with color/border changes.

### `texture` values

| Value | Implementation | When to Use |
|-------|---------------|-------------|
| `none` | No texture treatment | Clean, minimal sections |
| `subtle-grain` | CSS `background-image` with noise SVG at low opacity | Sections needing tactile warmth |
| `gradient-mesh` | CSS radial/conic gradients blended | Hero or CTA backgrounds with depth |
| `dot-grid` | CSS repeating radial-gradient | Technical/data-oriented sections |
| `blur-glow` | CSS blur filter on accent-colored pseudo-element | Emphasis sections, CTAs |

Texture choice derives from creative-direction.yml `texture` field.

### `spatial.inner_rhythm` values

| Value | Spacing Multiplier | Use Case |
|-------|--------------------|----------|
| `tight` | 0.75x base | Dense content: data tables, feature lists, footers |
| `comfortable` | 1x base | Standard content sections |
| `spacious` | 1.5x base | Hero sections, CTAs, breathing room between elements |

### `choreography.role` values

| Role | Position | Motion Character |
|------|----------|-----------------|
| `opener` | First section on page | Fast, confident entrance — sets the tone |
| `supporting` | Middle sections | Measured reveal — builds narrative |
| `interlude` | Between major sections | Subtle or no animation — visual rest |
| `closer` | Final section | Strong presence — drives action |

---

## Motion.dev API Mapping

All animation specs must use valid Motion.dev (formerly Framer Motion) API terms.
This ensures build agents can translate YAML directly into React components.

| Guide YAML Field | Motion.dev API | React Usage |
|-----------------|---------------|-------------|
| `initial` | `initial` prop | `<m.div initial={{ opacity: 0 }}>` |
| `animate` | `animate` prop | `<m.div animate={{ opacity: 1 }}>` |
| `transition.type: "spring"` | `transition` prop | `transition={{ type: "spring", stiffness: 300, damping: 30 }}` |
| `transition.duration` | `transition` prop | `transition={{ duration: 0.5 }}` |
| `transition.ease` | `transition` prop | `transition={{ ease: [0.25, 0.1, 0.25, 1] }}` |
| `entrance.trigger: "whileInView"` | `whileInView` prop | `<m.div whileInView={{ opacity: 1 }}>` |
| `entrance.threshold` | `viewport` prop | `viewport={{ amount: 0.3 }}` |
| `hover.<element>` | `whileHover` prop | `<m.button whileHover={{ scale: 1.05 }}>` |
| `scroll.api: "useScroll"` | `useScroll` hook | `const { scrollYProgress } = useScroll()` |
| `scroll.api: "useTransform"` | `useTransform` hook | `const y = useTransform(scrollYProgress, [0, 1], [0, -50])` |
| `stagger` entrance | `staggerChildren` | `transition={{ staggerChildren: 0.1 }}` |
| `AnimatePresence` | `AnimatePresence` component | Wrap route transitions, modals, list removals |
| `LazyMotion` | `LazyMotion` + `domAnimation` | Tree-shake unused features: `<LazyMotion features={domAnimation}>` |
| `layout` | `layout` prop | `<m.div layout>` for shared layout animations |

### Layer 1 Constraints (non-negotiable)

These come from the frontend-design skill and must never be violated:

- **Timing:** All animations 100-500ms. No animation exceeds 500ms duration.
- **Springs:** Every spring must have a `damping` value (no undamped oscillation).
- **Reduced motion:** Every section with animation must include a `reduced_motion`
  fallback that degrades to opacity-only or no animation.
- **Performance:** Use `LazyMotion` with `domAnimation` features — never import
  full motion bundle. Prefer `transform` and `opacity` (GPU-composited).

---

## Derivation Logic: Creative Direction to Implementation Guide

The creative-direction.yml has 11 fields. Here is how each maps to guide decisions:

### `motion_philosophy`

The overarching motion intent. Drives timing, easing, and entrance type selection.

| Creative Direction Value | Guide Translation |
|-------------------------|-------------------|
| "swift and purposeful" | Short durations (200-350ms), snappy springs (stiffness 300+, damping 25+), minimal stagger delays |
| "fluid and organic" | Medium durations (300-450ms), soft springs (stiffness 100-200, damping 15-25), flowing staggers |
| "dramatic and cinematic" | Longer durations (400-500ms), ease curves over springs, larger Y offsets (40-60px) |
| "minimal and restrained" | Very short durations (100-200ms), opacity-only where possible, few viewport triggers |

### `spatial_philosophy`

Maps to `spatial.inner_rhythm` and `spatial.section_gap` choices.

| Creative Direction Value | Guide Translation |
|-------------------------|-------------------|
| "dense and information-rich" | Mostly `tight` rhythm, smaller section gaps |
| "balanced and structured" | Mostly `comfortable` rhythm, standard gaps |
| "open and breathable" | Mostly `spacious` rhythm, larger section gaps |

### `texture`

Maps directly to section `texture` values.

| Creative Direction Value | Guide Translation |
|-------------------------|-------------------|
| "clean, no texture" | All sections `texture: "none"` |
| "subtle tactile warmth" | Key sections get `subtle-grain`, rest `none` |
| "layered depth" | Heroes get `gradient-mesh`, supporting sections get `subtle-grain` |
| "technical precision" | Data sections get `dot-grid`, CTAs get `blur-glow` |

### `interaction_weight`

Controls how many sections get hover effects and how prominent they are.

| Creative Direction Value | Guide Translation |
|-------------------------|-------------------|
| "light" | Hover on CTAs only, scale ≤1.02 |
| "moderate" | Hover on cards and CTAs, scale 1.02-1.03 |
| "heavy" | Hover on most interactive elements, scale up to 1.05, cursor effects |

### `scroll_behavior`

Controls which sections get scroll-linked animations.

| Creative Direction Value | Guide Translation |
|-------------------------|-------------------|
| "static" | No scroll interactions — all `scroll: null` |
| "subtle parallax" | 1-2 sections with gentle parallax (speed ≤0.05) |
| "scroll-driven narrative" | Multiple sections with parallax, progress, or reveal |
| "immersive" | Pin sections, reveal effects, progress indicators |

### `hero_approach`

Specifically targets the hero section's entrance and texture.

| Creative Direction Value | Guide Translation |
|-------------------------|-------------------|
| "bold statement" | Immediate entrance, large text, `gradient-mesh` texture, spacious rhythm |
| "visual showcase" | Stagger entrance with image reveal, parallax scroll on background |
| "understated" | Simple opacity fade, no texture, comfortable rhythm |

### `identity`, `feel`, `color_strategy`, `typography_personality`

These primarily inform Pencil screenshots and component specs. The implementation
guide references them for consistency checks but does not derive motion specs
from them directly. If `feel` includes words like "energetic" or "calm", use
that to calibrate the motion philosophy translation.

### `anti_patterns`

List of things to explicitly avoid. Cross-check every guide section against
anti-patterns. Examples:
- "no parallax" — set all `scroll: null`
- "no bounce" — avoid underdamped springs
- "no stagger on mobile" — add reduced stagger in responsive considerations

---

## Section Type Defaults

When generating guides for common section types, start from these defaults and
adjust based on creative direction.

### Hero

```yaml
entrance:
  type: "stagger"
  children: ["heading", "subheading", "cta"]
  delay_between: 0.1
  initial: { opacity: 0, y: 20 }
  animate: { opacity: 1, y: 0 }
  transition: { type: "spring", stiffness: 300, damping: 30 }
scroll: null
hover: null
texture: "none"
spatial: { inner_rhythm: "spacious", section_gap: "var(--spacing-16)" }
choreography: { role: "opener" }
```

### Feature Grid / Card Grid

```yaml
entrance:
  type: "viewport"
  trigger: "whileInView"
  threshold: 0.3
  initial: { opacity: 0, y: 40 }
  animate: { opacity: 1, y: 0 }
  transition: { duration: 0.5, ease: [0.25, 0.1, 0.25, 1] }
scroll: null
hover:
  cards: { scale: 1.02, transition: { type: "spring", stiffness: 400, damping: 25 } }
texture: "none"
spatial: { inner_rhythm: "comfortable", section_gap: "var(--spacing-12)" }
choreography: { role: "supporting" }
```

### Testimonial / Social Proof

```yaml
entrance:
  type: "viewport"
  trigger: "whileInView"
  threshold: 0.4
  initial: { opacity: 0 }
  animate: { opacity: 1 }
  transition: { duration: 0.4 }
scroll: null
hover: null
texture: "subtle-grain"
spatial: { inner_rhythm: "comfortable", section_gap: "var(--spacing-10)" }
choreography: { role: "supporting" }
```

### CTA Banner

```yaml
entrance:
  type: "viewport"
  trigger: "whileInView"
  threshold: 0.5
  initial: { opacity: 0, scale: 0.98 }
  animate: { opacity: 1, scale: 1 }
  transition: { type: "spring", stiffness: 200, damping: 25 }
scroll: null
hover:
  cta_button: { scale: 1.05, transition: { type: "spring", stiffness: 500, damping: 20 } }
texture: "none"
spatial: { inner_rhythm: "spacious", section_gap: "var(--spacing-16)" }
choreography: { role: "closer" }
```

### Footer

```yaml
entrance:
  type: "none"
scroll: null
hover:
  links: { color: "var(--color-accent)", transition: { duration: 0.15 } }
texture: "none"
spatial: { inner_rhythm: "tight", section_gap: "var(--spacing-8)" }
choreography: { role: "closer" }
```

### Pricing / Comparison

```yaml
entrance:
  type: "viewport"
  trigger: "whileInView"
  threshold: 0.3
  initial: { opacity: 0, y: 30 }
  animate: { opacity: 1, y: 0 }
  transition: { duration: 0.4, ease: [0.25, 0.1, 0.25, 1] }
scroll: null
hover:
  pricing_cards: { scale: 1.02, y: -4, transition: { type: "spring", stiffness: 300, damping: 25 } }
  featured_card: { scale: 1.03, y: -6, transition: { type: "spring", stiffness: 300, damping: 25 } }
texture: "none"
spatial: { inner_rhythm: "comfortable", section_gap: "var(--spacing-12)" }
choreography: { role: "supporting" }
```

---

## Step-by-Step Execution

### Step 1 — Read creative direction and inputs

```
Read: .ai/projects/[name]/design/creative-direction.yml
Read: .ai/projects/[name]/design/tokens/variables.css
Read: .ai/projects/[name]/design/layouts/*.yml
Read: .ai/projects/[name]/design/components/*.yml
```

If `creative-direction.yml` is missing, stop:
"creative-direction phase must run first."

If `design/layouts/` is empty, stop:
"web-layout phase must run first."

Extract the 11 creative direction fields. Build a derivation map using the
tables in the "Derivation Logic" section above.

**Save to findings.md after this step (2-Action Rule checkpoint).**

### Step 2 — Review Pencil screenshots

```
Read: .ai/projects/[name]/design/pencil-screenshots/*.png
```

For each page screenshot, note:
- Visual density and whitespace distribution
- Emphasis hierarchy (what draws the eye first, second, third)
- Section boundaries and rhythm
- Any visual effects suggested by the design (gradients, textures, overlays)

These observations inform choreography roles and texture choices. If no
screenshots exist, proceed using layout YAMLs and creative direction only —
note the gap in the trace.

**Save to findings.md after this step (2-Action Rule checkpoint).**

### Step 3 — Generate implementation guides per page

For each layout YAML:

1. Read the layout's `sections` list
2. For each section, look up the component spec for `section.component`
3. Assign entrance type based on section position:
   - First section on page: `stagger` or `immediate` (above fold)
   - Below-fold sections: `viewport` with `whileInView`
   - Footer/legal: `none`
4. Apply creative direction derivation rules to set timing, easing, texture
5. Determine scroll interactions based on `scroll_behavior` field
6. Set hover behaviors based on `interaction_weight` field
7. Assign texture based on `texture` field and section role
8. Set spatial rhythm based on `spatial_philosophy` field
9. Assign choreography role based on position and purpose
10. Add `reduced_motion` fallback for every animated section

Cross-check every section against creative direction `anti_patterns`.

**Save to findings.md every 2 pages (2-Action Rule checkpoint).**

### Step 4 — User review cycle

After generating guides for each page group:

```
Here are the implementation guides for the [template] pages. Review and let me
know:
  - Timing adjustments (faster/slower entrances)
  - Scroll interaction additions or removals
  - Hover behavior changes
  - Texture preferences
  - Choreography flow changes
Reply "ok" to continue, or list changes.
```

Apply all feedback before writing files.

### Step 5 — Write implementation guide YAMLs

Write each guide to: `.ai/projects/[name]/design/implementation-guides/<page-name>.yml`

Filename must match the corresponding layout file exactly.

### Step 6 — Register in asset-registry.yml

Read existing `asset-registry.yml` and merge. Add an `implementation_guides`
section:

```yaml
implementation_guides:
  - path: "design/implementation-guides/home.yml"
    type: "implementation_guide"
    name: "Home"
    route: "/"
    phase: 5
  - path: "design/implementation-guides/pricing.yml"
    type: "implementation_guide"
    name: "Pricing"
    route: "/pricing"
    phase: 5
```

Do not overwrite existing sections (tokens, components, layouts).

### Step 7 — Run checkpoint

Verify all 6 checkpoint checks:

1. **guides_exist** — count YAML files in `design/implementation-guides/` —
   must have at least 1 per layout file in `design/layouts/`
2. **sections_covered** — for every section in every layout YAML, verify there
   is a corresponding section entry in the matching implementation guide
3. **motion_api_valid** — all `transition.type`, `trigger`, scroll API references
   use valid Motion.dev terms (spring, tween, inertia; whileInView, whileHover;
   useScroll, useTransform; AnimatePresence, LazyMotion, layout)
4. **creative_direction_aligned** — sample 3 sections and verify their motion
   choices trace back to creative-direction.yml fields using the derivation logic
5. **layer1_compliant** — no `duration` value exceeds 0.5 (500ms), every spring
   has a `damping` value, every animated section has `reduced_motion` fallback
6. **assets_registered** — count entries in `asset-registry.yml`
   `implementation_guides` section matches guide file count

On failure: fix the failing check and re-run that check only.
On pass: update `state.yml` — set implementation-guide phase to `completed`.

---

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- guides_exist: at least 1 guide per layout
- sections_covered: every layout section has a guide entry
- motion_api_valid: all terms are valid Motion.dev API
- layer1_compliant: timing limits, damping, reduced motion

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Motion choices feel cohesive across pages (consistent easing, timing family)
- Creative direction intent is preserved (not just mechanically mapped)
- Choreography roles create a narrative flow per page
- Texture usage is intentional, not arbitrary
- Hover interactions are discoverable but not distracting
- Scroll interactions enhance rather than obstruct content consumption

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.

---

## Common Issues

**Inconsistent timing across pages:** All pages in a project should use the same
timing family. If hero entrance is 300ms spring, feature viewport should be in
the 300-500ms range — not 150ms on one page and 500ms on another.

**Missing reduced motion:** Every section with `entrance`, `scroll`, or `hover`
animation must have a `reduced_motion` block. The checkpoint will fail without it.

**Overanimating:** Not every section needs scroll, hover, and texture. Use
`interaction_weight` from creative direction. For "light" weight, most sections
should have `hover: null` and `scroll: null`.

**Spring without damping:** Every spring transition must include `damping`.
Undamped springs oscillate indefinitely — Layer 1 violation.

**Texture overuse:** Texture should appear on 0-3 sections per page max. Using
texture on every section creates visual noise rather than tactile warmth.

**Stagger on too many children:** Stagger works best with 2-5 children. More
than 5 creates noticeable delay. Split into groups or use viewport entrance.

**Contradicting anti-patterns:** Always read creative-direction.yml `anti_patterns`
first. If it says "no parallax", every section must have `scroll: null`.

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
