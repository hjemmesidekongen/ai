---
name: storybook-generator
user-invocable: false
description: >
  Auto-generates Storybook story YAML templates by combining component specs,
  page copy, and UX microcopy into per-component story sets. Produces Default,
  state variant (loading, error, empty, disabled), responsive (mobile/tablet/
  desktop), and a11y annotated stories — with every slot pre-filled from
  app-copy and ux-writing outputs. Use when generating Storybook stories,
  creating component story files, populating story props and slots with real
  copy, documenting component states in Storybook, producing a11y annotated
  stories, or running /agency:build storybook phase.
phase: 6
depends_on: [component-specs, app-copy, ux-writing]
writes:
  - ".ai/projects/[name]/dev/stories/*.stories.yml"
  - ".ai/projects/[name]/asset-registry.yml"
reads:
  - ".ai/projects/[name]/design/components/*.yml"
  - ".ai/projects/[name]/content/pages/*.yml"
  - ".ai/projects/[name]/content/ux/*.yml"
  - ".ai/projects/[name]/brand/brand-summary.yml"
model_tier: senior
model: sonnet
interactive: true
checkpoint:
  type: data_validation
  required_checks:
    - name: "stories_exist_per_component"
      verify: "One .stories.yml file exists in dev/stories/ for every component spec"
    - name: "props_covered"
      verify: "Every required prop defined in the component spec appears in the Default story"
    - name: "slots_filled_with_copy"
      verify: "Every slot in Default and state stories is filled with copy from pages/*.yml or ux/*.yml"
    - name: "a11y_annotations_present"
      verify: "Every .stories.yml has an a11y story with role, aria_label, and keyboard fields"
    - name: "assets_registered"
      verify: "All .stories.yml files registered in asset-registry.yml under dev.stories"
  on_fail: "Fix missing stories or annotations and re-run checkpoint"
  on_pass: "Update state.yml, advance to scaffold"
---

# Storybook Generator

Phase 6 of agency dev. Reads component specs, page copy YAMLs, and UX
microcopy YAMLs to auto-generate a complete set of Storybook story YAML
templates — one file per component, covering all states and viewports.

## Context

**Reads:** `design/components/*.yml`, `content/pages/*.yml`,
`content/ux/*.yml`, `brand/brand-summary.yml`
**Writes:** `dev/stories/*.stories.yml`, `asset-registry.yml`
**Checkpoint:** data_validation — 5 checks
**Depends on:** component-specs, app-copy, and ux-writing must all be complete

## Process Summary

1. Read all component specs — extract names, required props, slots, states,
   a11y requirements, and responsive breakpoints
2. Read page copy YAMLs — build component → slot → copy map for Default stories
3. Read UX copy YAMLs — build component → state → microcopy map for variants
4. For each component, generate a `.stories.yml` with Default + state + responsive
   + a11y stories; see `references/process.md` for full YAML format
5. Present generated stories to user grouped by component category; iterate on
   content, annotations, and variant coverage
6. Register all `.stories.yml` files in asset-registry.yml
7. Run checkpoint — all 5 checks must pass before advancing to scaffold

## Findings Persistence

Save intermediate discoveries to `findings.md` every 2 read operations.
Record: components parsed, slot mappings resolved, copy gaps found, a11y
coverage. If session is interrupted, findings.md lets the next session resume
without re-reading all upstream files.

## Execution

Before executing, read `references/process.md` for the full story YAML
format, state variant rules, responsive breakpoint definitions, a11y
annotation schema, and per-component generation instructions.
