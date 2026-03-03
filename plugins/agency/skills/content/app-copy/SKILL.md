---
name: app-copy
user-invocable: false
description: >
  Fills every content slot defined in component specs and web layouts with
  production-ready copy, organized by page > component > slot. Reads layout
  YAMLs to enumerate pages, reads component specs to enumerate slots per
  component, and generates copy for each slot while enforcing brand voice
  throughout. Use when writing page copy, filling content slots, producing
  headline and body text, writing CTA copy, generating placeholder text,
  applying brand voice to UI content, or running /agency:content app-copy phase.
phase: 5
depends_on: [component-specs, web-layout]
writes:
  - ".ai/projects/[name]/content/pages/*.yml"
  - ".ai/projects/[name]/asset-registry.yml"
reads:
  - ".ai/projects/[name]/design/layouts/*.yml"
  - ".ai/projects/[name]/design/components/*.yml"
  - ".ai/projects/[name]/design/navigation-map.yml"
  - ".ai/projects/[name]/brand/brand-summary.yml"
model_tier: senior
interactive: true
checkpoint:
  type: data_validation
  required_checks:
    - name: "pages_covered"
      verify: "One copy YAML exists per page route defined in navigation-map.yml"
    - name: "slots_filled"
      verify: "Every slot referenced in layout YAMLs has copy in the page YAML"
    - name: "brand_voice_applied"
      verify: "Headlines, CTAs, and body copy reflect tone and vocabulary from brand-summary.yml"
    - name: "slot_types_complete"
      verify: "All slot types present: headline, body, cta, label, description, placeholder"
    - name: "assets_registered"
      verify: "All page copy YAMLs registered in asset-registry.yml under content.pages"
  on_fail: "Fix and re-run"
  on_pass: "Update state.yml, advance to ux-writing or next content phase"
---

# App Copy

Phase 5 of agency content. Reads web layouts (pages + component arrangement)
and component specs (content slots per component) to produce a complete set of
page copy YAMLs. Every slot is filled with production-ready copy that reflects
the project's brand voice.

## Context

**Reads:** `design/layouts/*.yml`, `design/components/*.yml`,
`design/navigation-map.yml`, `brand/brand-summary.yml`
**Writes:** `content/pages/*.yml`, `asset-registry.yml`
**Checkpoint:** data_validation — 5 checks
**Depends on:** component-specs and web-layout must both be complete

## Process Summary

1. Read brand-summary.yml — extract voice attributes, tone spectrum,
   terminology, and vocabulary rules; stop if file is absent
2. Read navigation-map.yml to enumerate all pages and routes; stop if
   web-layout phase hasn't run
3. Read all layout YAMLs — build page > section > component map
4. Read all component spec YAMLs — extract slot definitions per component
5. For each page, generate a copy YAML with every slot filled — present
   to user grouped by page; iterate on tone and wording
6. Register all page copy YAMLs in asset-registry.yml
7. Run checkpoint — all 5 checks must pass before advancing

## Execution

Before executing, read `references/process.md` for the full page copy YAML
format, slot type rules, brand voice application guidelines, and per-page
generation instructions.
