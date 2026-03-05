---
name: visual-render
user-invocable: false
description: >
  Renders visual designs in Pencil from agency specs. Reads design tokens,
  component specs, web layouts, and app copy to produce a complete .pen file
  with reusable components, composed page screens, and AI-generated imagery.
  Use when rendering visual mockups from agency pipeline output, producing
  Pencil prototypes, creating design previews, or running /agency:render.
phase: 7
depends_on: [design-tokens, component-specs, web-layout, app-copy]
writes:
  - ".ai/projects/[name]/render/[project-name].pen"
  - ".ai/projects/[name]/render/render-manifest.yml"
  - ".ai/projects/[name]/render/screenshots/*.png"
  - ".ai/projects/[name]/asset-registry.yml"
reads:
  - ".ai/projects/[name]/design/tokens/variables.css"
  - ".ai/projects/[name]/design/tokens/tailwind.config.json"
  - ".ai/projects/[name]/design/components/*.yml"
  - ".ai/projects/[name]/design/layouts/*.yml"
  - ".ai/projects/[name]/design/navigation-map.yml"
  - ".ai/projects/[name]/content/pages/*.yml"
  - ".ai/projects/[name]/brand/brand-summary.yml"
model_tier: principal
model: opus
interactive: true
checkpoint:
  type: visual_validation
  required_checks:
    - name: "pen_file_created"
      verify: ".pen file exists in render/ directory"
    - name: "variables_set"
      verify: "Pencil variables count matches CSS custom property count from variables.css"
    - name: "components_built"
      verify: "1 reusable Pencil component per component spec YAML"
    - name: "pages_composed"
      verify: "1 screen frame per layout YAML in design/layouts/"
    - name: "screenshots_captured"
      verify: "1 PNG per page in render/screenshots/"
    - name: "manifest_complete"
      verify: "render-manifest.yml maps all pages and components to Pencil node IDs"
    - name: "assets_registered"
      verify: "All render outputs registered in asset-registry.yml"
  on_fail: "Rebuild missing artifacts and re-verify"
  on_pass: "Update state.yml modules.render.status → completed"
---

# Visual Render

Phase 7 of the agency pipeline — the final visual output stage. Reads all
upstream specs (tokens, components, layouts, content, brand) and produces
live Pencil `.pen` designs using the Pencil MCP server. Outputs reusable
components, composed page screens with real content, AI-generated imagery,
and a render manifest mapping every artifact to its Pencil node ID.

## Context

**Reads:** `design/tokens/variables.css`, `design/tokens/tailwind.config.json`,
`design/components/*.yml`, `design/layouts/*.yml`, `design/navigation-map.yml`,
`content/pages/*.yml`, `brand/brand-summary.yml`
**Writes:** `render/[project].pen`, `render/render-manifest.yml`,
`render/screenshots/*.png`, `asset-registry.yml`
**Checkpoint:** visual_validation — 7 checks
**Depends on:** design-tokens, component-specs, web-layout, app-copy

## Process Summary

1. Read all inputs — tokens, components, layouts, content, brand; fail fast if missing
2. Select Pencil style guide — match brand personality to tags, get guidelines
3. Create document and set variables — parse variables.css, convert to Pencil format
4. Build reusable components — one per component spec, with token-mapped properties
5. Compose page screens — one per layout, with navigation, sections, and real copy
6. Generate images — AI prompts from brand personality + section context
7. Mobile variants (optional) — 375px copies with responsive overrides
8. Finalize — manifest, asset-registry, 7-point checkpoint, state.yml update

## Findings Persistence

Write intermediate results to `.ai/projects/[name]/render/findings.md`.
**2-Action Rule:** after every 2 research/generation actions, IMMEDIATELY save
progress to findings.md. Log all errors to state.yml errors array — never
repeat a failed approach.

## Execution

Before executing, read `references/process.md` for the full step-by-step
instructions including token mapping strategy, component rendering approach,
page composition patterns, and image generation prompts.
