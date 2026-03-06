---
name: implementation-guide
user-invocable: false
description: >
  Translates creative direction, design tokens, component specs, and Pencil
  screenshots into per-page implementation guides. Each guide specifies entrance
  animations, hover behaviors, scroll interactions, texture treatments, spatial
  rules, and component choreography using Motion.dev API terms. Layer 4 of the
  four-layer architecture — page-specific layout and motion decisions that build
  agents consume alongside Pencil screenshots (looks) and component specs
  (structure) to produce the final implementation (feel/motion).
phase: 5
depends_on: [creative-direction, component-specs, web-layout]
writes:
  - ".ai/projects/[name]/design/implementation-guides/*.yml"
  - ".ai/projects/[name]/asset-registry.yml"
reads:
  - ".ai/projects/[name]/design/creative-direction.yml"
  - ".ai/projects/[name]/design/tokens/variables.css"
  - ".ai/projects/[name]/design/tokens/tailwind.config.json"
  - ".ai/projects/[name]/design/components/*.yml"
  - ".ai/projects/[name]/design/layouts/*.yml"
  - ".ai/projects/[name]/design/pencil-screenshots/*.png"
model_tier: principal
model: opus
interactive: true
checkpoint:
  type: data_validation
  required_checks:
    - name: "guides_exist"
      verify: "At least 1 implementation guide YAML exists per layout in layouts/"
    - name: "sections_covered"
      verify: "Every section in the layout YAML has a corresponding entry in the guide"
    - name: "motion_api_valid"
      verify: "All animation specs use Motion.dev API terms (spring, layout, useScroll, useTransform, AnimatePresence, LazyMotion)"
    - name: "creative_direction_aligned"
      verify: "Guide motion/texture choices trace back to creative-direction.yml fields"
    - name: "layer1_compliant"
      verify: "No animation exceeds 500ms, springs have damping, reduced-motion fallbacks present"
    - name: "assets_registered"
      verify: "All implementation guide YAMLs registered in asset-registry.yml"
  on_fail: "Fix and re-run"
  on_pass: "Update state.yml, advance to build phase"
---

# Implementation Guide

Phase 5 of agency design. Reads creative direction (Layer 3), design tokens
(Layer 1), component specs, layout YAMLs, and Pencil screenshots, then produces
per-page implementation guides — the motion and interaction layer that build
agents use alongside screenshots (looks) and specs (structure).

## Context

**Reads:** `creative-direction.yml`, design tokens, component specs, layouts, Pencil screenshots
**Writes:** `design/implementation-guides/*.yml`, `asset-registry.yml`
**Checkpoint:** data_validation — 6 checks
**Depends on:** creative-direction, component-specs, web-layout must be complete

## Process Summary

1. Read creative-direction.yml — extract motion philosophy, texture, interaction
   weight, spatial philosophy, scroll behavior
2. Read all layout YAMLs and component specs — build section inventory per page
3. Review Pencil screenshots — identify visual rhythm, density, emphasis points
4. For each page, generate implementation guide: entrance animations, hover
   behaviors, scroll interactions, textures, spatial rules, choreography
5. User reviews guides per page; iterate on timing, easing, and interaction feel
6. Register all guides in asset-registry.yml
7. Run checkpoint — all 6 checks must pass before advancing

## Findings Persistence

Write intermediate results to `.ai/projects/[name]/design/findings.md`. **2-Action Rule:** after every 2 research/generation actions, IMMEDIATELY save progress to findings.md. Log all errors to state.yml errors array — never repeat a failed approach.

## Execution

Before executing, read `references/process.md` for the full output YAML schema,
Motion.dev API mapping, creative direction derivation logic, section type
defaults, and the three-reference model.
