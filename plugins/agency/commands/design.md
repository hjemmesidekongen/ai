---
name: agency:design
description: "Orchestrate the full design pipeline — brand-loader → logo-assets → design-tokens → component-specs → web-layout"
arguments:
  - name: project
    description: "Project name (optional — defaults to active project)"
    required: false
  - name: --from
    description: "Resume from a specific phase: brand | logo | tokens | components | layout"
    required: false
---

# /agency:design

Runs the full 5-phase design pipeline for an agency project. Each phase has a
checkpoint gate — the next phase only starts after the previous one passes.

## Usage

```
/agency:design                        # Run full pipeline for active project
/agency:design acme                   # Run full pipeline for specific project
/agency:design --from tokens          # Resume from design-tokens phase
/agency:design acme --from components # Resume acme from component-specs phase
```

## Phase Map

| Phase | Skill | Model | Checkpoint Type |
|-------|-------|-------|-----------------|
| brand | brand-loader | junior | data_validation (3 checks) |
| logo | logo-assets | principal | file_validation (6 checks) |
| tokens | design-tokens | senior | accessibility_validation (7 checks) |
| components | component-specs | principal | data_validation (6 checks) |
| layout | web-layout | senior | data_validation (5 checks) |

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

### Step 2: Determine Start Phase

```
phases = [brand, logo, tokens, components, layout]
skill_map = {
  brand:      brand-loader,
  logo:       logo-assets,
  tokens:     design-tokens,
  components: component-specs,
  layout:     web-layout
}

if --from flag provided:
  start_phase = --from value
  if start_phase not in phases:
    "Unknown phase '{start_phase}'. Valid values: brand, logo, tokens, components, layout"
else:
  # Auto-detect: find first incomplete phase
  for phase in phases:
    skill = skill_map[phase]
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

### Step 3: Run brand-loader (if start_phase <= brand)

```
if start_phase == brand:
  brand_ref = .ai/projects/{project_name}/brand/brand-reference.yml
  if not exists:
    "No brand-reference.yml found at {brand_ref}."
    "Run /agency:init {project_name} --brand <path> to import brand data."
    exit

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

  Report: "Phase 1/5: brand-loader complete"
```

### Step 4: Run logo-assets (if start_phase <= logo)

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

  Report: "Phase 2/5: logo-assets complete"
```

### Step 5: Run design-tokens (if start_phase <= tokens)

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

  Report: "Phase 3/5: design-tokens complete"
```

### Step 6: Run component-specs (if start_phase <= components)

```
if start_phase in [brand, logo, tokens, components]:
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

  Report: "Phase 4/5: component-specs complete"
```

### Step 7: Run web-layout (if start_phase <= layout)

```
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
  modules.design.status → completed
  modules.design.completed_skills → append web-layout
  current_skill → null
  updated_at → now
  recovery_notes → "Design pipeline complete. All 5 phases passed checkpoints.
    Run /agency:content to start the content pipeline."
```

### Step 8: Report

```
## Design Pipeline Complete: {project_name}

### Phases Completed This Run

| Phase | Skill | Status | Outputs |
|-------|-------|--------|---------|
| brand | brand-loader | {status} | brand-summary.yml, asset-registry entries |
| logo | logo-assets | {status} | {N} SVGs, logo-preview.html |
| tokens | design-tokens | {status} | tailwind.config.json, variables.css, tokens.dtcg.json, contrast-matrix.md |
| components | component-specs | {status} | {N} component YAMLs |
| layout | web-layout | {status} | {N} layout YAMLs, navigation-map.yml |

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
    result: "pending"
    next_approach: "Adjust secondary palette neutrals if contrast still fails"
```

**Missing brand data:**
```
No brand-reference.yml found at .ai/projects/{project_name}/brand/brand-reference.yml
Run: /agency:init {project_name} --brand <path-to-brand-reference.yml>
```

**Unknown --from value:**
```
Unknown phase 'xyz'. Valid values: brand, logo, tokens, components, layout
```
