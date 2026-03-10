---
name: design-to-code-patterns
description: >
  Translating design specs into frontend components — design token consumption,
  spacing/typography/color systems, responsive breakpoints, component decomposition
  from mockups, and design-code handoff conventions.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "design to code"
  - "design tokens"
  - "design handoff"
  - "figma to code"
  - "design system implementation"
  - "component from design"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "tokens_not_hardcoded"
      verify: "No hardcoded colors, spacing, or font sizes — all reference design tokens or CSS variables"
      fail_action: "Replace magic values with token references from the design system"
    - name: "responsive_breakpoints_match"
      verify: "Breakpoints match the design system definition, not arbitrary pixel values"
      fail_action: "Use named breakpoints (sm, md, lg) from the design system"
    - name: "component_boundaries_match_design"
      verify: "Component boundaries in code match the visual groupings in the design"
      fail_action: "Restructure components to match design hierarchy — one visual group per component"
    - name: "spacing_scale_consistent"
      verify: "Spacing uses scale values (4, 8, 12, 16, 24, 32, 48, 64), not arbitrary numbers"
      fail_action: "Snap spacing to the nearest scale value"
  on_fail: "Implementation drifts from design system — fix before shipping"
  on_pass: "Code faithfully implements the design spec"
_source:
  origin: "dev-engine"
  inspired_by: "original + design system best practices"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Original knowledge skill bridging design and code"
---

# design-to-code-patterns

## Design Token Consumption

Never hardcode colors, spacing, fonts, or shadows. Reference design tokens via CSS custom properties (`var(--color-primary-500)`) or utility classes. Token categories: color (palette + semantic), typography (family, size, weight, line-height), spacing (4px base scale), shadows, radii, breakpoints. If the design system provides tokens, consume them. If not, extract them from the design file first.

## Spacing System

Base unit: 4px. Scale: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96. All spacing (padding, margin, gap) snaps to scale values. Vertical rhythm: line-height multiples of the base unit. Component internal spacing is smaller (8-16px). Section spacing is larger (48-96px). Never use arbitrary pixel values.

## Typography Scale

Use a type scale (e.g., 12, 14, 16, 18, 20, 24, 30, 36, 48, 60px). Each size has a corresponding line-height and letter-spacing. Map semantic names: `text-xs` through `text-6xl`. Headlines: tighter letter-spacing (-0.01 to -0.02em). Body: default tracking. Use 2-3 font weights max (regular, medium, bold).

## Component Decomposition

Read the design top-down: page → sections → cards/groups → elements. Each visual group that repeats or has distinct state becomes a component. Props mirror design variants (size, variant, color). Slot patterns for flexible content areas. Component names match the design system naming.

## Responsive Implementation

Mobile-first: base styles are mobile, layer up with `min-width` queries. Named breakpoints: sm (640px), md (768px), lg (1024px), xl (1280px), 2xl (1536px). Grid: 4 cols mobile → 8 cols tablet → 12 cols desktop. Touch targets: 44px minimum. Check the design at each breakpoint — don't assume intermediate states.

## Color System

Palette: 10-step scales (50-950) per hue. Semantic tokens: `--color-primary`, `--color-error`, `--color-success`, `--color-text-primary`, `--color-bg-surface`. Dark mode: swap semantic tokens, not palette values. Contrast: 4.5:1 minimum for text (WCAG AA). Never reference palette values directly in components — use semantic tokens.

See `references/process.md` for token extraction workflow, component mapping examples, handoff checklists, and responsive grid patterns.
