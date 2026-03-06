---
name: visual-render
user-invocable: false
description: >
  Renders visual designs in Pencil from agency specs. Reads tokens, components,
  layouts, copy, brand, and creative direction to produce a .pen file with
  reusable components, page screens, and AI imagery. Screenshots are first-class
  artifacts and ground truth for visual verification (dec-01). Use when rendering
  mockups, producing Pencil prototypes, or running /agency:render.
phase: 7
depends_on: [design-tokens, component-specs, web-layout]
optional_inputs: [app-copy]  # uses placeholder copy if app-copy hasn't run
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
  - ".ai/projects/[name]/design/creative-direction.yml"
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

Phase 7 — final visual output. Produces live Pencil `.pen` designs from all
upstream specs. Screenshots serve as ground truth for visual verification.

## Context

**Reads:** tokens, components, layouts, nav-map, page copy, brand, creative-direction
**Writes:** `render/[project].pen`, `render-manifest.yml`, `screenshots/*.png`, `asset-registry.yml`
**Checkpoint:** visual_validation — 7 checks
**Depends on:** design-tokens, component-specs, web-layout
**Optional:** app-copy (uses placeholder copy if content pipeline hasn't run)

## Process Summary

1. Read all inputs — tokens, components, layouts, content, brand; fail fast if missing
2. Select Pencil style guide — match brand personality to tags, get guidelines
3. Create document and set variables — parse variables.css, convert to Pencil format
4. Build reusable components — one per component spec, with token-mapped properties
5. Compose page screens — one per layout, with navigation, sections, and real or placeholder copy
6. Generate images — AI prompts from brand personality + section context
7. Mobile variants (optional) — 375px copies with responsive overrides
8. Finalize — manifest, asset-registry, 7-point checkpoint, state.yml update

## Findings & Execution

Write intermediate results to `.ai/projects/[name]/render/findings.md` every 2 actions. Log errors to state.yml — never repeat a failed approach. Before executing, read `references/process.md` for token mapping, component rendering, page composition, and image generation instructions.
