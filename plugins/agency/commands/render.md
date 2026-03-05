---
name: agency:render
description: "Render visual designs in Pencil from agency specs — tokens, components, layouts, and copy"
argument-hint: "[project] [--from variables|components|pages|images]"
---

# /agency:render

Renders the complete visual design in Pencil using all upstream agency specs.
Runs after both the design and content pipelines are complete. Each phase has
a verification step — the next phase only starts after the previous one passes.

## Usage

```
/agency:render                          # Run full render for active project
/agency:render acme                     # Run full render for specific project
/agency:render --from components        # Resume from component building phase
/agency:render acme --from pages        # Resume acme from page composition phase
```

## Phase Map

| Phase | What It Does | Pencil Tools Used |
|-------|-------------|-------------------|
| variables | Parse tokens → set Pencil variables | set_variables, get_variables |
| components | Build reusable components from specs | batch_design (I, U), get_screenshot |
| pages | Compose page screens with real copy | batch_design (I, C, U), snapshot_layout |
| images | Generate AI/stock images for sections | batch_design (G), get_screenshot |

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

### Step 2: Verify Prerequisites

```
# Design pipeline must be complete
required_design_skills = [design-tokens, component-specs, web-layout]
for skill in required_design_skills:
  if skill not in state.modules.design.completed_skills:
    "Design pipeline incomplete — '{skill}' has not run."
    "Run /agency:design first to complete the design pipeline."
    exit

# Content pipeline must have app-copy complete
if "app-copy" not in state.modules.content.completed_skills:
  "Content pipeline incomplete — 'app-copy' has not run."
  "Run /agency:content first to generate page copy."
  exit
```

### Step 3: Determine Start Phase

```
phases = [variables, components, pages, images]

if --from flag provided:
  start_phase = --from value
  if start_phase not in phases:
    "Unknown phase '{start_phase}'. Valid values: variables, components, pages, images"
    exit
else:
  # Auto-detect from render module state
  if state.modules.render does not exist or status == "not_started":
    start_phase = variables
  else:
    # Check findings.md or manifest for progress
    Read render/findings.md and render/render-manifest.yml
    Determine last completed step → set start_phase to next
  if render module status == "completed":
    "Render already complete for '{project_name}'. Use --from to re-run a phase."
    exit
```

Show header before starting:
```
## Visual Render: {project_name}
Starting from: {start_phase} phase
```

### Step 4: Run Style Guide Selection (always, unless resuming past it)

```
if start_phase == variables:
  Update state.yml:
    modules.render.status → in_progress
    current_module → render
    current_skill → visual-render

  Run visual-render Step 2 (Style Guide Selection):
    - get_style_guide_tags() → match brand personality
    - get_style_guide(tags) → visual inspiration
    - get_guidelines("landing-page") → layout patterns
    - Present to user, get confirmation

  Report: "Style guide selected"
```

### Step 5: Run Variables Phase (if start_phase <= variables)

```
if start_phase == variables:
  Run visual-render Step 3 (Create Document & Set Variables):
    - open_document("new") or open existing
    - Parse variables.css → convert to Pencil format
    - set_variables() with full token set
    - get_variables() to verify count match

  Verify: variable count matches CSS property count
  if mismatch:
    Log error, re-run set_variables
    if still mismatched: halt and report

  Report: "Phase 1/4: variables set — {N} design tokens loaded"
```

### Step 6: Run Components Phase (if start_phase <= components)

```
if start_phase in [variables, components]:
  Run visual-render Step 4 (Build Reusable Components):
    - For each component spec: create reusable Pencil frame
    - Map tokens to Pencil variable references
    - Create child nodes per slot
    - Screenshot each component for verification
    - Build slot node ID registry

  Verify: 1 reusable component per spec file
  if missing components: rebuild missing ones

  Present component gallery to user for review

  Report: "Phase 2/4: components built — {N} reusable components"
```

### Step 7: Run Pages Phase (if start_phase <= pages)

```
if start_phase in [variables, components, pages]:
  Run visual-render Step 5 (Compose Page Screens):
    - For each layout: create screen frame at 1440px
    - Build nav header from navigation-map.yml
    - Insert component instances with real copy
    - Apply section backgrounds and spacing
    - Screenshot each page

  Verify: 1 screen frame per layout YAML
  if missing pages: recompose missing ones

  Report: "Phase 3/4: pages composed — {N} screens with live content"
```

### Step 8: Run Images Phase (if start_phase <= images)

```
Run visual-render Step 6 (Generate Images):
  - Scan pages for image-worthy sections
  - Build prompts from brand + content context
  - G() operations for AI/stock images
  - Re-screenshot pages after images added

Verify: images inserted in identified sections
if failures: log, attempt fallback prompts

Report: "Phase 4/4: images generated — {N} images across {N} pages"
```

### Step 9: Mobile Variants (Optional)

```
Run visual-render Step 7:
  Ask user: "Generate mobile (375px) variants?"
  if yes: copy and resize each page, apply responsive overrides
  if no: skip
```

### Step 10: Finalize

```
Run visual-render Step 8 (Finalize):
  - Generate render-manifest.yml
  - Register all outputs in asset-registry.yml
  - Run 7-point checkpoint
  - Update state.yml: modules.render.status → completed

if checkpoint fails:
  Log error to state.yml errors array
  "visual-render checkpoint failed. Fix issues above and re-run with --from {failed_phase}."
  exit

Report:
## Render Complete: {project_name}

| Phase | Status | Output |
|-------|--------|--------|
| variables | {status} | {N} Pencil variables set |
| components | {status} | {N} reusable components |
| pages | {status} | {N} page screens |
| images | {status} | {N} AI/stock images |

### Files Generated
- render/{project}.pen — full visual design
- render/render-manifest.yml — node ID map
- render/screenshots/ — {N} page screenshots

### Next Steps
  1. Open the .pen file in Pencil to review and iterate
  2. /agency:build — scaffold and build the application
  3. /agency:deploy — deploy the project
```

## Error Handling

**Prerequisite failures:**
```
Design pipeline incomplete — 'component-specs' has not run.
Run /agency:design first to complete the design pipeline.
```

**Pencil MCP failures:**
```
Pencil document closed unexpectedly. Re-opening render/{project}.pen...
```

**Unknown --from value:**
```
Unknown phase 'xyz'. Valid values: variables, components, pages, images
```
