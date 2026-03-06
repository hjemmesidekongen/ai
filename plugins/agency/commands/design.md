---
name: agency:design
description: "Orchestrate the full 8-phase design pipeline — brand-loader → logo-assets → design-tokens → creative-direction → component-specs → web-layout → visual-render → implementation-guide"
argument-hint: "[project] [--from brand|logo|tokens|creative|components|layout|render|guide] [--force]"
---

# /agency:design

Runs the full 8-phase design pipeline for an agency project. Each phase has a
checkpoint gate — the next phase only starts after the previous one passes.

## Usage

```
/agency:design                        # Run full pipeline for active project
/agency:design acme                   # Run full pipeline for specific project
/agency:design --from tokens          # Resume from design-tokens phase
/agency:design acme --from components # Resume acme from component-specs phase
/agency:design --from creative        # Resume from creative-direction phase
/agency:design --from render          # Resume from visual-render phase
/agency:design --from guide           # Resume from implementation-guide phase
/agency:design --force                # Reset design state and re-run full pipeline
/agency:design --from tokens --force  # Reset from tokens onward and re-run
```

## Phase Map

| Phase | Skill | Model | Checkpoint Type |
|-------|-------|-------|-----------------|
| brand | brand-loader | junior | data_validation (3 checks) |
| logo | logo-assets | principal | file_validation (6 checks) |
| tokens | design-tokens | senior | accessibility_validation (7 checks) |
| creative | creative-direction | principal | data_validation (3 checks) |
| components | component-specs | principal | data_validation (6 checks) |
| layout | web-layout | senior | data_validation (5 checks) |
| render | visual-render | principal | visual_validation (7 checks) |
| guide | implementation-guide | principal | data_validation (6 checks) |

## Execution Steps

### Step 1: Determine Project

```
if argument provided:
  project_name = argument
else:
  Read .ai/agency.yml → use active project
  If no agency.yml: "No agency registry found. Run /agency:init first."

state_file = .ai/projects/{project_name}/state.yml
if not exists:
  "Project '{project_name}' not found. Run /agency:init {project_name} first."

state = read_yaml(state_file)
```

### Step 2: Handle --force (if provided)

```
if --force flag provided:
  if --from flag provided:
    reset_from = --from value
  else:
    reset_from = brand   # reset everything

  phases = [brand, logo, tokens, creative, components, layout, render, guide]
  design_skills_to_remove = []
  brand_skills_to_remove = []

  skill_map = {
    brand:      brand-loader,
    logo:       logo-assets,
    tokens:     design-tokens,
    creative:   creative-direction,
    components: component-specs,
    layout:     web-layout,
    render:     visual-render,
    guide:      implementation-guide
  }

  for phase in phases starting from reset_from:
    skill = skill_map[phase]
    if phase == "brand":
      brand_skills_to_remove.append(skill)
    else:
      design_skills_to_remove.append(skill)

  # Reset state
  Remove brand_skills_to_remove from state.modules.brand.completed_skills
  Remove design_skills_to_remove from state.modules.design.completed_skills

  if brand_skills_to_remove:
    state.modules.brand.status → "completed" if brand-reference.yml exists, else "not_started"
  if design_skills_to_remove:
    state.modules.design.status → "in_progress" if any design skills remain, else "not_started"

  # Remove brand-loader from design.completed_skills if present (legacy cleanup)
  Remove "brand-loader" from state.modules.design.completed_skills if present

  Write updated state.yml

  Report: "Reset design state from '{reset_from}' onward. Cleared: {removed skills list}"
```

### Step 3: Determine Start Phase

```
phases = [brand, logo, tokens, creative, components, layout, render, guide]
skill_map = {
  brand:      brand-loader,
  logo:       logo-assets,
  tokens:     design-tokens,
  creative:   creative-direction,
  components: component-specs,
  layout:     web-layout,
  render:     visual-render,
  guide:      implementation-guide
}

if --from flag provided:
  start_phase = --from value
  if start_phase not in phases:
    "Unknown phase '{start_phase}'. Valid values: brand, logo, tokens, creative, components, layout, render, guide"
else:
  # Auto-detect: find first incomplete phase
  # Note: brand-loader lives in brand module, all others in design module
  for phase in phases:
    skill = skill_map[phase]
    if phase == "brand":
      if skill not in state.modules.brand.completed_skills:
        start_phase = phase
        break
    else:
      if skill not in state.modules.design.completed_skills:
        start_phase = phase
        break
  if all phases complete:
    "Design pipeline already complete for '{project_name}'. Use --from to re-run a phase."
    exit
```

Show header before starting:
```
## Design Pipeline: {project_name}
Starting from: {start_phase} phase
```

### Step 4: Run brand-loader (if start_phase <= brand)

```
if start_phase == brand:
  brand_ref = .ai/projects/{project_name}/brand/brand-reference.yml
  if not exists:
    "No brand-reference.yml found at {brand_ref}."
    "Run /agency:init {project_name} --brand <path> to import brand data."
    exit

  # brand.status may be "completed" (init copied brand-reference but didn't run brand-loader)
  # or "not_started". Either way, brand-loader needs to run.
  Update state.yml:
    modules.brand.status → in_progress
    current_skill → brand-loader

  Run skill: brand-loader
    Reads: .ai/projects/{project_name}/brand/brand-reference.yml
    Writes: .ai/projects/{project_name}/brand/brand-summary.yml
    Writes: .ai/projects/{project_name}/asset-registry.yml

  Run checkpoint (data_validation, 3 checks):
    - brand_reference_loaded
    - tokens_extracted
    - assets_registered

  if checkpoint fails:
    Log error to state.yml errors array
    "brand-loader checkpoint failed. Fix issues above and re-run /agency:design."
    exit

  Update state.yml:
    modules.brand.status → completed
    modules.brand.completed_skills → [brand-loader]
    modules.design.status → in_progress
    current_skill → null

  Report: "Phase 1/8: brand-loader complete"
```

### Step 5: Run logo-assets (if start_phase <= logo)

```
if start_phase in [brand, logo]:
  Verify prerequisite: brand-summary.yml exists
  if not exists:
    "brand-loader has not run. Start from --from brand or run Step 3 first."
    exit

  Update state.yml:
    current_skill → logo-assets

  Run skill: logo-assets (model: principal, interactive)
    Reads: brand-summary.yml, brand-reference.yml
    Writes: design/logos/*.svg, design/logos/brand-icon/*.svg
            design/logos/social-templates/*.svg
            design/previews/logo-preview.html
            asset-registry.yml

  Note: logo-assets is interactive — wait for user input at each design phase
  (discovery, concept generation, refinement, finalization, social templates)

  Run checkpoint (file_validation, 6 checks):
    - logo_svg_variants
    - brand_icon_variants
    - svg_validity
    - svg_file_size
    - preview_html
    - assets_registered

  if checkpoint fails:
    Log error to state.yml errors array
    "logo-assets checkpoint failed. Fix issues above and re-run with --from logo."
    exit

  Update state.yml:
    modules.design.completed_skills → append logo-assets
    current_skill → null

  Report: "Phase 2/8: logo-assets complete"
```

### Step 6: Run design-tokens (if start_phase <= tokens)

```
if start_phase in [brand, logo, tokens]:
  Verify prerequisite: brand-summary.yml exists
  if not exists:
    "brand-loader has not run. Start from --from brand."
    exit

  Update state.yml:
    current_skill → design-tokens

  Run skill: design-tokens (model: senior)
    Reads: brand-summary.yml
    Writes: design/tokens/tailwind.config.json
            design/tokens/variables.css
            design/tokens/tokens.dtcg.json
            design/tokens/contrast-matrix.md
            asset-registry.yml

  Run checkpoint (accessibility_validation, 7 checks):
    - tailwind_config_valid
    - css_variables_valid
    - dtcg_valid
    - wcag_aa_body
    - wcag_aa_large
    - colorblind_notes
    - assets_registered

  if checkpoint fails:
    Log error to state.yml errors array
    "design-tokens checkpoint failed. Fix accessibility issues above and re-run with --from tokens."
    exit

  Update state.yml:
    modules.design.completed_skills → append design-tokens
    current_skill → null

  Report: "Phase 3/8: design-tokens complete"
```

### Step 7: Run creative-direction (if start_phase <= creative)

```
if start_phase in [brand, logo, tokens, creative]:
  Verify prerequisite: brand-summary.yml exists
  if not exists:
    "brand-loader has not run. Start from --from brand."
    exit

  Update state.yml:
    current_skill → creative-direction

  Run skill: creative-direction (model: principal)
    Reads: brand-summary.yml, frontend-design/SKILL.md
    Writes: design/creative-direction.yml

  Run checkpoint (data_validation):
    - creative_direction_generated
    - All 11 fields present (identity, feel, motion_philosophy, spatial_philosophy,
      texture, interaction_weight, color_strategy, typography_personality,
      hero_approach, scroll_behavior, anti_patterns)
    - No Layer 1 contradictions

  if checkpoint fails:
    Log error to state.yml errors array
    "creative-direction checkpoint failed. Fix issues above and re-run with --from creative."
    exit

  Update state.yml:
    modules.design.completed_skills → append creative-direction
    current_skill → null

  Report: "Phase 4/8: creative-direction complete"
```

### Step 8: Run component-specs (if start_phase <= components)

```
if start_phase in [brand, logo, tokens, creative, components]:
  Verify prerequisites:
    - design/tokens/tailwind.config.json exists
    - design/tokens/variables.css exists
  if either missing:
    "design-tokens has not run. Start from --from tokens."
    exit

  Update state.yml:
    current_skill → component-specs

  Run skill: component-specs (model: principal, interactive)
    Reads: tailwind.config.json, variables.css, brand-summary.yml
    Writes: design/components/*.yml
            asset-registry.yml

  Note: component-specs is interactive — present proposed component list to
  user, confirm additions/removals, then iterate on feedback per category

  Run checkpoint (data_validation, 6 checks):
    - components_exist
    - required_fields
    - token_references_valid
    - slots_defined
    - a11y_requirements
    - assets_registered

  if checkpoint fails:
    Log error to state.yml errors array
    "component-specs checkpoint failed. Fix issues above and re-run with --from components."
    exit

  Update state.yml:
    modules.design.completed_skills → append component-specs
    current_skill → null

  Report: "Phase 5/8: component-specs complete"
```

### Step 9: Run web-layout (if start_phase <= layout)

```
if start_phase in [brand, logo, tokens, creative, components, layout]:
  Verify prerequisite: at least 1 file exists in design/components/
  if not:
    "component-specs has not run. Start from --from components."
    exit

  Update state.yml:
    current_skill → web-layout

  Run skill: web-layout (model: senior, interactive)
    Reads: design/components/*.yml, brand-summary.yml
    Writes: design/layouts/*.yml
            design/navigation-map.yml
            asset-registry.yml

  Note: web-layout is interactive — confirm site map with user, iterate on
  layout compositions, validate all component references before finalizing

  Run checkpoint (data_validation, 5 checks):
    - layouts_exist
    - components_referenced
    - navigation_map
    - responsive_rules
    - assets_registered

  if checkpoint fails:
    Log error to state.yml errors array
    "web-layout checkpoint failed. Fix issues above and re-run with --from layout."
    exit

  Update state.yml:
    modules.design.completed_skills → append web-layout
    current_skill → null

  Report: "Phase 6/8: web-layout complete"
```

### Step 10: Run visual-render (if start_phase <= render)

```
if start_phase in [brand, logo, tokens, creative, components, layout, render]:
  Verify prerequisites:
    - At least 1 layout YAML exists in design/layouts/
    - design/creative-direction.yml exists
  if missing:
    "web-layout or creative-direction has not run. Start from the missing phase."
    exit

  Update state.yml:
    current_skill → visual-render

  Run skill: visual-render (model: principal, interactive)
    Reads: tokens, components, layouts, nav-map, brand, creative-direction
    Reads (optional): page copy from content/pages/*.yml
    Writes: render/[project].pen, render-manifest.yml, screenshots/*.png, asset-registry.yml

  Note: visual-render uses Pencil MCP tools. Load guidelines (landing-page or web-app
  based on project type), select style guide via tags matching brand personality,
  run full creative process. Export screenshots as first-class artifacts.
  visual-render uses placeholder copy if /agency:content has not run yet —
  the design pipeline is self-contained and does not require content to proceed.

  Run checkpoint (visual_validation, 7 checks):
    - pen_file_created
    - variables_set
    - components_built
    - pages_composed
    - screenshots_captured
    - manifest_complete
    - assets_registered

  if checkpoint fails:
    Log error to state.yml errors array
    "visual-render checkpoint failed. Fix issues above and re-run with --from render."
    exit

  Update state.yml:
    modules.design.completed_skills → append visual-render
    current_skill → null

  Report: "Phase 7/8: visual-render complete"
```

### Step 11: Run implementation-guide (if start_phase <= guide)

```
if start_phase in [brand, logo, tokens, creative, components, layout, render, guide]:
  Verify prerequisites:
    - creative-direction.yml exists
    - At least 1 component spec YAML exists
    - At least 1 layout YAML exists
    - render/screenshots/ has at least 1 PNG
  if missing:
    "Required upstream phases not complete. Start from the missing phase."
    exit

  Update state.yml:
    current_skill → implementation-guide

  Run skill: implementation-guide (model: principal, interactive)
    Reads: creative-direction.yml, tokens, component specs, layouts, Pencil screenshots
    Writes: design/implementation-guides/*.yml, asset-registry.yml

  Run checkpoint (data_validation, 6 checks):
    - guides_exist
    - sections_covered
    - motion_api_valid
    - creative_direction_aligned
    - layer1_compliant
    - assets_registered

  if checkpoint fails:
    Log error to state.yml errors array
    "implementation-guide checkpoint failed. Fix issues above and re-run with --from guide."
    exit

  Update state.yml:
    modules.design.status → completed
    modules.design.completed_skills → append implementation-guide
    current_skill → null
    updated_at → now
    recovery_notes → "Design pipeline complete. All 8 phases passed checkpoints.
      Run /agency:content to start the content pipeline."

  Report: "Phase 8/8: implementation-guide complete"
```

### Step 12: Report

```
## Design Pipeline Complete: {project_name}

### Phases Completed This Run

| Phase | Skill | Status | Outputs |
|-------|-------|--------|---------|
| brand | brand-loader | {status} | brand-summary.yml, asset-registry entries |
| logo | logo-assets | {status} | {N} SVGs, logo-preview.html |
| tokens | design-tokens | {status} | tailwind.config.json, variables.css, tokens.dtcg.json, contrast-matrix.md |
| creative | creative-direction | {status} | creative-direction.yml |
| components | component-specs | {status} | {N} component YAMLs |
| layout | web-layout | {status} | {N} layout YAMLs, navigation-map.yml |
| render | visual-render | {status} | [project].pen, screenshots/*.png, render-manifest.yml |
| guide | implementation-guide | {status} | {N} implementation guide YAMLs |

(Only show phases that ran in this invocation; show "skipped" for phases
skipped via --from)

### Asset Summary
{total} assets now registered in asset-registry.yml

### Next Steps
  1. /agency:content — generate copy and UX writing
  2. /agency:build   — scaffold and build the application
  3. /agency:status  — review full project status
```

## Error Handling

**Checkpoint failures** — each phase logs to `state.yml errors array`:
```yaml
errors:
  - timestamp: "[now]"
    skill: "design-tokens"
    error: "wcag_aa_body check failed — 3 color pairs below 4.5:1"
    attempted_fix: "Darkened primary-600 from #2563EB to #1D4ED8"
    result: "unresolved"
    next_approach: "Adjust secondary palette neutrals if contrast still fails"
```

**Missing brand data:**
```
No brand-reference.yml found at .ai/projects/{project_name}/brand/brand-reference.yml
Run: /agency:init {project_name} --brand <path-to-brand-reference.yml>
```

**Unknown --from value:**
```
Unknown phase 'xyz'. Valid values: brand, logo, tokens, creative, components, layout, render, guide
```
