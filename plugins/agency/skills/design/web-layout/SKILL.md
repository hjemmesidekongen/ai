---
name: web-layout
user-invocable: false
description: >
  Composes page layouts from component specs with Pencil guidelines and style
  guide integration. Produces layout YAMLs, navigation map, responsive
  breakpoints, and layout shift rules. Loads get_guidelines (landing-page or
  web-app) and matches brand personality to style guide tags. Consumes
  creative-direction.yml for spatial philosophy, hero approach, and color
  strategy. Use when designing page structure, site navigation, responsive
  layouts, or running /agency:design layout phase.
phase: 4
depends_on: [component-specs]
writes:
  - ".ai/projects/[name]/design/layouts/*.yml"
  - ".ai/projects/[name]/design/navigation-map.yml"
  - ".ai/projects/[name]/asset-registry.yml"
reads:
  - ".ai/projects/[name]/design/components/*.yml"
  - ".ai/projects/[name]/brand/brand-summary.yml"
  - ".ai/projects/[name]/design/creative-direction.yml"
model_tier: senior
model: sonnet
interactive: true
checkpoint:
  type: data_validation
  required_checks:
    - name: "layouts_exist"
      verify: "At least 1 layout YAML exists per route defined in navigation-map.yml"
    - name: "components_referenced"
      verify: "Every component reference in section.component maps to an existing spec in components/"
    - name: "navigation_map"
      verify: "navigation-map.yml exists with primary nav, footer, and mobile_menu blocks"
    - name: "responsive_rules"
      verify: "Every layout with multi-column sections includes responsive overrides for mobile"
    - name: "assets_registered"
      verify: "All layout YAMLs and navigation-map.yml registered in asset-registry.yml"
    - name: "routes_covered"
      verify: "Every route in navigation-map.yml either has a layout YAML or is flagged as missing_layout in the trace"
  on_fail: "Fix and re-run"
  on_pass: "Update state.yml, advance to next design phase"
---

# Web Layout

Phase 4 of agency design. Reads component specs from phase 3 and composes
them into full page layouts, a navigation map, and responsive breakpoint rules.
Outputs machine-readable YAMLs consumed by app-copy (content slots), scaffold
(page component code), and storybook-generator (page stories).

## Context

**Reads:** `design/components/*.yml`, `brand/brand-summary.yml`, `design/creative-direction.yml`
**Writes:** `design/layouts/*.yml`, `design/navigation-map.yml`, `asset-registry.yml`
**Checkpoint:** data_validation — 6 checks
**Depends on:** component-specs must be complete

## Process Summary

1. Read all component spec YAMLs from `design/components/` — stop if
   component-specs phase hasn't run
2. Present proposed site map (pages + hierarchy) to user; confirm routes, add
   extras, remove defaults
3. For each confirmed page, compose layout using available components: arrange
   sections, assign props, map slots, set layout widths
4. Define responsive breakpoints and per-section overrides for mobile/tablet
5. Generate `navigation-map.yml` — primary nav, footer columns, mobile menu,
   breadcrumb strategy
6. User review and iteration — present layouts grouped by page type
7. Register all output files in `asset-registry.yml`
8. Run checkpoint — all 6 checks must pass before advancing

## Findings & Execution

Write intermediate results to `.ai/projects/[name]/design/findings.md` every 2 actions. Log errors to state.yml — never repeat a failed approach. Before executing, read `references/process.md` for layout YAML format, nav map format, default page set, responsive rules, and step-by-step instructions.
