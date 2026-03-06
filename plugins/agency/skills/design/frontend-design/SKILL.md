---
name: "frontend-design"
description: "Production-grade frontend design rules — typography, color, motion, accessibility. Loaded by build agents."
phase: "dev"
depends_on: []
reads:
  - ".ai/projects/{project}/design/design-tokens.yml"
  - ".ai/projects/{project}/design/creative-direction.yml"
writes: []
model_tier: "principal"
checkpoint: "design_rules_loaded"
---

# Frontend Design Skill

Production-grade design rules that build agents load before writing any UI code.
This skill is Layer 1 of the four-layer design architecture.

## Four-Layer Architecture

| Layer | Source | Purpose |
|-------|--------|---------|
| 1. Universal rules | **This skill** | Anti-slop, typography math, color theory, accessibility |
| 2. Technology conventions | Codex skills | Motion.dev, Tailwind, React patterns |
| 3. Creative direction | `creative-direction` skill | Project-specific brand expression |
| 4. Implementation guide | `implementation-guide` skill | Page-specific layout and component decisions |

Layers stack: lower layers are overridden by higher layers when conflicts arise.
Layer 1 rules are non-negotiable — they apply to every project regardless of
creative direction or technology choice.

## Reference Files

| File | Covers |
|------|--------|
| `references/anti-slop.md` | Design quality enforcement — what to never do |
| `references/typography.md` | Mathematical typographic scales, font pairing, vertical rhythm |
| `references/color-system.md` | Neutral/accent palette architecture, semantic tokens, dark mode |
| `references/motion.md` | Motion.dev timing, easing, spring physics, scroll animations |
| `references/accessibility.md` | WCAG 2.1 AA requirements — contrast, focus, keyboard, screen readers |

## Defaults

- **Component library:** Untitled UI (override in creative-direction if needed)
- **Animation library:** Motion.dev (not GSAP, not CSS-only)
- **Typographic scale:** 1.25 Major Third (body-heavy) or 1.333 Perfect Fourth (headline-heavy)
- **Base font size:** 16px / 1rem
- **Max font families:** 2

## When This Skill Activates

Build agents load these rules at the start of any UI implementation task.
The checkpoint `design_rules_loaded` confirms the agent has internalized all
five reference files before writing component code.
