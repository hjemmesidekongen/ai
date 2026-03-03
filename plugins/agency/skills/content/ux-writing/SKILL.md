---
name: ux-writing
user-invocable: false
description: >
  Generates systematic microcopy for all interactive states: error messages,
  validation feedback, tooltips, confirmations, loading and empty states, and
  CTA labels. Reads component specs to identify every content slot and
  interactive state, then produces structured YAML copy organized by category.
  Applies brand voice tokens throughout. Use when writing error messages,
  microcopy, UI copy, validation text, tooltip content, confirmation dialogs,
  empty state copy, or running /agency:content ux-writing phase.
phase: 5
depends_on: [component-specs]
writes:
  - ".ai/projects/[name]/content/ux/error-messages.yml"
  - ".ai/projects/[name]/content/ux/validation-messages.yml"
  - ".ai/projects/[name]/content/ux/tooltips.yml"
  - ".ai/projects/[name]/content/ux/confirmations.yml"
  - ".ai/projects/[name]/content/ux/states.yml"
  - ".ai/projects/[name]/content/ux/labels.yml"
  - ".ai/projects/[name]/asset-registry.yml"
reads:
  - ".ai/projects/[name]/design/components/*.yml"
  - ".ai/projects/[name]/brand/brand-summary.yml"
model_tier: senior
interactive: true
checkpoint:
  type: data_validation
  required_checks:
    - name: "categories_complete"
      verify: "All 6 UX copy YAML files exist and are non-empty"
    - name: "brand_voice_applied"
      verify: "Tone and personality tokens from brand-summary.yml are reflected in copy"
    - name: "component_coverage"
      verify: "Every component slot and interactive state from component specs is addressed"
    - name: "error_taxonomy_applied"
      verify: "Every error message has: code, severity, category, title, description, action"
    - name: "assets_registered"
      verify: "All 6 UX copy files registered in asset-registry.yml under content.ux"
  on_fail: "Fix and re-run"
  on_pass: "Update state.yml, advance to next content phase"
---

# UX Writing

Phase 5 of agency content. Reads component specs to identify interactive
states and content slots, then produces structured YAML microcopy for every
category — errors, validation, tooltips, confirmations, loading states, and
labels — with brand voice applied throughout.

## Context

**Reads:** `design/components/*.yml`, `brand-summary.yml` (voice section)
**Writes:** `content/ux/*.yml` (6 files), `asset-registry.yml`
**Checkpoint:** data_validation — 5 checks
**Depends on:** component-specs must be complete

## Process Summary

1. Read all component spec YAML files — extract interactive states and
   content slots; stop if component-specs phase hasn't run
2. Read brand voice tokens (personality, tone spectrum, vocabulary rules)
3. Generate microcopy for each category — see references/process.md for
   YAML formats, error taxonomy, and per-category rules
4. User reviews copy category by category; iterate on tone and wording
5. Register all 6 UX copy files in asset-registry.yml
6. Run checkpoint — all 5 checks must pass before advancing

## Execution

Before executing, read `references/process.md` for full YAML formats,
the error message taxonomy, brand voice application rules, and per-category
generation instructions.
