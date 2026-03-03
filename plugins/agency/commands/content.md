---
name: content
description: "Orchestrate agency content pipeline — generate page copy from layouts then UX microcopy from component specs."
arguments:
  - name: project
    description: "Project name (optional — defaults to active project)"
    required: false
  - name: --from
    description: "Resume from a specific phase: app-copy | ux-writing"
    required: false
model_tier: senior
---

# /agency:content

Runs the full 2-phase content pipeline for an agency project. Each phase has a
checkpoint gate — the next phase only starts after the previous one passes.
Design pipeline must be complete before content can run.

## Usage

```
/agency:content                          # Run full pipeline for active project
/agency:content blik                     # Run full pipeline for specific project
/agency:content --from ux-writing        # Resume from ux-writing phase
/agency:content blik --from app-copy     # Re-run full content pipeline for blik
```

## Phase Map

| Phase | Skill | Model | Checkpoint Type |
|-------|-------|-------|-----------------|
| app-copy | app-copy | senior | data_validation (5 checks) |
| ux-writing | ux-writing | senior | data_validation (5 checks) |

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

### Step 2: Verify Design Pipeline Completed

```
design_required = [component-specs, web-layout]
missing = []

for skill in design_required:
  if skill not in state.modules.design.completed_skills:
    missing.append(skill)

if missing is not empty:
  "Design pipeline incomplete. The following skills have not run: {missing}"
  "Run /agency:design {project_name} first, then re-run /agency:content."
  exit
```

### Step 3: Determine Start Phase

```
phases = [app-copy, ux-writing]
skill_map = {
  app-copy:   app-copy,
  ux-writing: ux-writing
}

if --from flag provided:
  start_phase = --from value
  if start_phase not in phases:
    "Unknown phase '{start_phase}'. Valid values: app-copy, ux-writing"
    exit
else:
  # Auto-detect: find first incomplete phase
  for phase in phases:
    skill = skill_map[phase]
    if skill not in state.modules.content.completed_skills:
      start_phase = phase
      break
  if all phases complete:
    "Content pipeline already complete for '{project_name}'. Use --from to re-run a phase."
    exit
```

Show header before starting:
```
## Content Pipeline: {project_name}
Starting from: {start_phase} phase
```

### Step 4: Run app-copy (if start_phase <= app-copy)

```
if start_phase == app-copy:
  Verify prerequisites:
    - .ai/projects/{project_name}/design/layouts/ contains at least 1 YAML
    - .ai/projects/{project_name}/design/navigation-map.yml exists
    - .ai/projects/{project_name}/design/components/ contains at least 1 YAML
    - .ai/projects/{project_name}/brand/brand-summary.yml exists
  if any missing:
    "Required design outputs not found. Run /agency:design {project_name} first."
    exit

  Update state.yml:
    modules.content.status → in_progress
    current_skill → app-copy

  Run skill: app-copy (model: senior, interactive)
    Reads: design/layouts/*.yml, design/components/*.yml,
           design/navigation-map.yml, brand/brand-summary.yml
    Writes: content/pages/*.yml
            asset-registry.yml

  Note: app-copy is interactive — present generated copy page by page,
  iterate on tone and wording per user feedback before finalizing

  Run checkpoint (data_validation, 5 checks):
    - pages_covered
    - slots_filled
    - brand_voice_applied
    - slot_types_complete
    - assets_registered

  if checkpoint fails:
    Log error to state.yml errors array
    "app-copy checkpoint failed. Fix issues above and re-run /agency:content."
    exit

  Update state.yml:
    modules.content.completed_skills → append app-copy
    current_skill → null

  Report: "Phase 1/2: app-copy complete"
```

### Step 5: Run ux-writing (if start_phase <= ux-writing)

```
Verify prerequisite:
  - .ai/projects/{project_name}/content/pages/ contains at least 1 YAML
if not:
  "app-copy has not run. Start from --from app-copy or run Step 4 first."
  exit

Update state.yml:
  current_skill → ux-writing

Run skill: ux-writing (model: senior, interactive)
  Reads: design/components/*.yml, brand/brand-summary.yml
  Writes: content/ux/error-messages.yml
          content/ux/validation-messages.yml
          content/ux/tooltips.yml
          content/ux/confirmations.yml
          content/ux/states.yml
          content/ux/labels.yml
          asset-registry.yml

Note: ux-writing is interactive — user reviews copy category by category
and iterates on tone and wording before finalizing

Run checkpoint (data_validation, 5 checks):
  - categories_complete
  - brand_voice_applied
  - component_coverage
  - error_taxonomy_applied
  - assets_registered

if checkpoint fails:
  Log error to state.yml errors array
  "ux-writing checkpoint failed. Fix issues above and re-run with --from ux-writing."
  "Note: app-copy results are preserved."
  exit

Update state.yml:
  modules.content.status → completed
  modules.content.completed_skills → append ux-writing
  current_skill → null
  updated_at → now
  recovery_notes → "Content pipeline complete. All 2 phases passed checkpoints.
    Run /agency:build to scaffold and build the application."
```

### Step 6: Report

```
## Content Pipeline Complete: {project_name}

### Phases Completed This Run

| Phase | Skill | Status | Outputs |
|-------|-------|--------|---------|
| app-copy | app-copy | {status} | {N} page copy YAMLs |
| ux-writing | ux-writing | {status} | 6 UX copy YAMLs (errors, validation, tooltips, confirmations, states, labels) |

(Only show phases that ran in this invocation; show "skipped" for phases
skipped via --from)

### Content Summary
{N} page copy files + 6 UX copy files now registered in asset-registry.yml

### Next Steps
  1. /agency:build  — scaffold and build the application
  2. /agency:status — review full project status
```

## Error Handling

**Design pipeline incomplete:**
```
Design pipeline incomplete. The following skills have not run: [component-specs, web-layout]
Run /agency:design {project_name} first, then re-run /agency:content.
```

**app-copy checkpoint failure** — logged to `state.yml errors array`:
```yaml
errors:
  - timestamp: "[now]"
    skill: "app-copy"
    error: "slots_filled check failed — 3 slots missing copy in landing.yml"
    attempted_fix: "Reviewed layout YAML slot definitions"
    result: "pending"
    next_approach: "Re-run app-copy and regenerate copy for landing page slots"
```

**ux-writing checkpoint failure** — app-copy is preserved:
```
ux-writing checkpoint failed. Fix issues above and re-run with --from ux-writing.
Note: app-copy results are preserved.
```

**Unknown --from value:**
```
Unknown phase 'xyz'. Valid values: app-copy, ux-writing
```
