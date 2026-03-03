---
name: agency:status
description: "Show the current project's pipeline status across all modules (brand, design, content, dev, devops)"
arguments:
  - name: project
    description: "Project name (optional — defaults to active project)"
    required: false
---

# /agency:status

Shows the current pipeline status for a project across all agency modules.

## Usage

```
/agency:status              # Show active project status
/agency:status acme         # Show specific project status
```

## Execution Steps

### Step 1: Determine Project

```
if argument provided:
  project_name = argument
else:
  Read .ai/agency.yml → use active project
  If no agency.yml: "No agency registry found. Run /agency:init first."
```

### Step 2: Load State

```
state_file = .ai/projects/{project_name}/state.yml
if not exists:
  "Project '{project_name}' has no state file. Run /agency:init {project_name} first."

state = read_yaml(state_file)
```

### Step 3: Display Dashboard

```
## Project: {project_name}
Status: {state.status} | Updated: {state.updated_at}

### Module Pipeline

| Module | Status | Current Skill | Completed | Progress |
|--------|--------|---------------|-----------|----------|
| brand | ✓ completed | — | brand-loader | 1/1 |
| design | ▶ in_progress | design-tokens | logo-assets, asset-registry | 2/5 |
| content | ○ not_started | — | — | 0/2 |
| dev | ○ not_started | — | — | 0/10 |
| devops | ○ not_started | — | — | 0/2 |

### Assets
{count} assets registered in asset-registry.yml

### Recent Errors
{last 3 errors from state.yml errors array, if any}

### Recovery Notes
{state.recovery_notes}
```

Status icons:
- ✓ = completed
- ▶ = in_progress
- ○ = not_started
- ✗ = failed
- ⊘ = skipped

### Step 4: Show Asset Summary (if registry exists)

```
asset_file = .ai/projects/{project_name}/asset-registry.yml
if exists:
  Count assets by module/type
  Show: "{total} assets: {breakdown by type}"
```
