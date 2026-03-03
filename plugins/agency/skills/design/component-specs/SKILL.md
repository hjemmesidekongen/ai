---
name: component-specs
user-invocable: false
description: >
  Generates structured YAML component specifications from design tokens. Each
  spec defines typed props, design token references, content slots, accessibility
  requirements, responsive breakpoint rules, and state variants. Consumed by
  app-copy (content slots), storybook-generator (stories), and scaffold
  (component code). Use when creating component specs, designing UI components,
  running /agency:design component phase, defining component contracts, or
  mapping design tokens to components.
phase: 3
depends_on: [design-tokens]
writes:
  - ".ai/projects/[name]/design/components/*.yml"
  - ".ai/projects/[name]/asset-registry.yml"
reads:
  - ".ai/projects/[name]/design/tokens/tailwind.config.json"
  - ".ai/projects/[name]/design/tokens/variables.css"
  - ".ai/projects/[name]/brand/brand-summary.yml"
model_tier: principal
interactive: true
checkpoint:
  type: data_validation
  required_checks:
    - name: "components_exist"
      verify: "At least 5 component spec YAML files exist in components/"
    - name: "required_fields"
      verify: "Every spec has: name, description, props, tokens, slots, a11y, responsive"
    - name: "token_references_valid"
      verify: "All token references map to keys in tailwind.config.json or variables.css"
    - name: "slots_defined"
      verify: "Every component with text content has at least 1 content slot"
    - name: "a11y_requirements"
      verify: "Every interactive component has ARIA roles, keyboard navigation, focus management"
    - name: "assets_registered"
      verify: "All component specs registered in asset-registry.yml"
  on_fail: "Fix and re-run"
  on_pass: "Update state.yml, advance to web-layout"
---

# Component Specs

Phase 3 of agency design. Reads design tokens and produces structured YAML
component specifications — the machine-readable contracts consumed by app-copy,
storybook-generator, and scaffold to auto-generate content, stories, and code.

## Context

**Reads:** `tailwind.config.json`, `variables.css`, `brand-summary.yml`
**Writes:** `design/components/*.yml`, `asset-registry.yml`
**Checkpoint:** data_validation — 6 checks
**Depends on:** design-tokens must be complete

## Process Summary

1. Read design tokens (tailwind.config.json + variables.css) — stop if
   design-tokens phase hasn't run
2. Present proposed component list to user; confirm additions, removals, extras
3. For each confirmed component, generate YAML spec (props, tokens, slots,
   states, a11y, responsive) — see references/process.md for full format
4. User reviews specs by category; iterate on feedback before proceeding
5. Register all component YAML files in asset-registry.yml
6. Run checkpoint — all 6 checks must pass before advancing to web-layout

## Findings Persistence

Write intermediate results to `.ai/projects/[name]/design/findings.md`. **2-Action Rule:** after every 2 research/generation actions, IMMEDIATELY save progress to findings.md. Log all errors to state.yml errors array — never repeat a failed approach.

## Execution

Before executing, read `references/process.md` for the full component spec
YAML format, the core component set, and step-by-step instructions.
