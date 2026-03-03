---
name: agency:switch
description: "Switch the active project in the agency registry. Updates agency.yml and verifies brand isolation."
argument-hint: "<project>"
---

# /agency:switch

Switches the active project. All subsequent agency commands operate on the new active project.

## Usage

```
/agency:switch acme
/agency:switch other-project
```

## Execution Steps

### Step 1: Validate Project Exists

```
Read .ai/agency.yml
if agency.yml doesn't exist:
  "No agency registry found. Run /agency:init first."
  STOP

if project_name not in agency.yml.projects:
  "Project '{project_name}' not found in registry."
  "Available projects: {list projects}"
  STOP
```

### Step 2: Check Current State

```
current = agency.yml.active
if current == project_name:
  "Already on project '{project_name}'. No change needed."
  STOP

# Check if current project has in-progress work
current_state = read .ai/projects/{current}/state.yml
if current_state.status == "in_progress":
  WARN: "Project '{current}' has work in progress."
  Show current module and skill
  Ask: "Switch anyway? Any unsaved state will be preserved."
```

### Step 3: Switch Active Project

```
Update .ai/agency.yml:
  active: "{project_name}"

Report:
  "Switched active project: {current} → {project_name}"
```

### Step 4: Load New Project Context

```
new_state = read .ai/projects/{project_name}/state.yml
Report:
  "Project: {project_name}"
  "Status: {new_state.status}"
  "Modules: {module status summary}"
  "Last updated: {new_state.updated_at}"
```

### Step 5: Verify Isolation

```
Remind:
  "Brand isolation active. Writes to other projects' directories will be blocked."
  "Use /agency:switch to change projects before working on another brand."
```
