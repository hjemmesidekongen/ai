---
name: "creative-direction"
description: >
  Generates project-specific creative direction from brand context. Reads
  brand-summary.yml (personality, audience, tone, product type) and produces
  creative-direction.yml — the Layer 3 bridge between universal design rules
  and page-level implementation. Consumed by Pencil design sessions and build
  agents. Use when running /agency:design creative phase, generating brand
  expression rules, or preparing design context for Pencil.
phase: "design"
depends_on: ["brand-loader"]
reads:
  - ".ai/projects/{project}/brand/brand-summary.yml"
  - "plugins/agency/skills/design/frontend-design/SKILL.md"
writes:
  - ".ai/projects/{project}/design/creative-direction.yml"
model_tier: "principal"
checkpoint: "creative_direction_generated"
---

# Creative Direction Generator

Layer 3 of the four-layer design architecture. Reads brand context from
brand-loader output and generates a project-specific `creative-direction.yml`
that governs all visual and interaction decisions.

## Four-Layer Position

| Layer | Source | Purpose |
|-------|--------|---------|
| 1. Universal rules | frontend-design skill | Anti-slop, typography, color, motion, a11y |
| 2. Technology conventions | Codex skills | Motion.dev, Tailwind, React patterns |
| 3. **Creative direction** | **This skill** | Project-specific brand expression |
| 4. Implementation guide | implementation-guide skill | Page-specific layout decisions |

Higher layers override lower layers. Layer 1 rules remain non-negotiable.

## Context

**Reads:** `brand/brand-summary.yml` (colors, typography, spacing, personality)
**Reads:** `frontend-design/SKILL.md` (Layer 1 baseline — must not contradict)
**Writes:** `design/creative-direction.yml`
**Checkpoint:** creative_direction_generated

## Output Schema

`creative-direction.yml` must define all of: identity, feel,
motion_philosophy, spatial_philosophy, texture, interaction_weight,
color_strategy, typography_personality, hero_approach, scroll_behavior,
anti_patterns. See `references/process.md` for full schema and generation
logic.

## Process Summary

1. Read brand-summary.yml — extract personality, audience, tone, product type
2. Load frontend-design SKILL.md — internalize Layer 1 constraints
3. Derive each creative-direction field from brand signals
4. Write creative-direction.yml with all 11 required sections
5. Validate no Layer 1 contradictions exist

## Findings Persistence

Write intermediate results to `.ai/projects/{project}/design/findings.md`.
**2-Action Rule:** save progress every 2 research/generation actions.
Log all errors to state.yml errors array.

## Execution

Follow the detailed process in [references/process.md](references/process.md).
