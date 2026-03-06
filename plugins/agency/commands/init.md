---
name: agency:init
description: "Initialize a new agency project — creates project directory, loads brand data, scans tech stack, and registers in agency.yml"
argument-hint: "<project> [--app-path <path>] [--brand <path>] [--profile <name>] [--skip-scan]"
---

# /agency:init

Creates and registers a new agency project. Sets up the project directory, loads brand data (if available), and scans the tech stack.

## Usage

```
/agency:init acme --app-path apps/acme-web --brand .ai/brands/acme/brand-reference.yml
/agency:init my-project --profile personal
/agency:init my-project --skip-scan
```

## Execution Steps

### Step 1: Create Project Structure

```
project_dir = .ai/projects/{project_name}/
Create directories:
  {project_dir}/brand/
  {project_dir}/design/
    logos/, tokens/, components/, layouts/, previews/
  {project_dir}/content/
  {project_dir}/dev/
  {project_dir}/devops/
  {project_dir}/media/
```

### Step 2: Select Profile

```
if --profile flag provided:
  profile_path = .ai/profiles/{--profile}.yml
  if profile_path exists:
    selected = load profile_path
    Report: "Using profile: {selected.name}"
  else:
    Report: "Profile '{--profile}' not found at {profile_path}. Continuing without profile."
    selected = null
elif .ai/profiles/ exists:
  profiles = list all .yml files in .ai/profiles/
  if exactly 1 profile:
    selected = that profile
    Report: "Using profile: {selected.name}"
  elif multiple profiles:
    Present list to user:
    "Available profiles:"
    for each profile:
      "  {N}. {profile.name} — {profile.description}"
    Ask: "Select a profile (or 'none' for no profile):"
    selected = user choice (null if 'none')
  else:
    selected = null
else:
  selected = null

if selected:
  Store selected profile name for state.yml
  Report: "Profile '{selected.name}' selected — defaults will apply during stack negotiation."
else:
  Report: "No profile selected. Full negotiation will be used."
```

### Step 3: Initialize State

Create `{project_dir}/state.yml` following project-state-schema.yml:
```yaml
project: "{project_name}"
profile: null  # or "{selected_profile_name}" if profile was selected in Step 2
status: "created"
created_at: "[now]"
updated_at: "[now]"
modules:
  brand: { status: "not_started", completed_skills: [] }
  design: { status: "not_started", completed_skills: [] }
  content: { status: "not_started", completed_skills: [] }
  dev: { status: "not_started", completed_skills: [] }
  devops: { status: "not_started", completed_skills: [] }
current_module: null
current_skill: null
errors: []
recovery_notes: "Project initialized. Run /agency:design to start the design pipeline."
```

Create empty `{project_dir}/asset-registry.yml`:
```yaml
project: "{project_name}"
updated_at: "[now]"
assets: []
```

### Step 4: Register in Agency Registry

Read or create `.ai/agency.yml`:
```yaml
active: "{project_name}"
projects:
  {project_name}:
    app_path: "{--app-path or apps/{project_name}}"
    brand_package_path: null
    brand_reference: null
    project_dir: ".ai/projects/{project_name}"
    created_at: "[now]"
    modules:
      brand: "not_started"
      design: "not_started"
      content: "not_started"
      dev: "not_started"
      devops: "not_started"
shared_packages: []
```

If agency.yml already exists, append the new project and set it as active.

### Step 5: Load Brand (if --brand provided)

```
if --brand flag provided:
  Copy brand-reference.yml to {project_dir}/brand/
  Update state.yml: modules.brand.status → "completed"
  Update agency.yml: brand_reference → path
  Report: "Brand reference imported. /agency:design will run brand-loader to extract tokens and generate brand-summary.yml."
else:
  Report: "No brand data provided. Run /agency:init with --brand or create brand data manually."
  Skip brand loading
```

### Step 6: Scan Tech Stack & Negotiate (unless --skip-scan)

```
if --skip-scan NOT set:
  app_path = resolved --app-path
  if app_path exists:
    Run project-scanner skill on app_path
    Report scan results

    # Stack negotiation — first consumer of the profile
    if profile selected:
      Run skill: stack-negotiation
        Reads: findings.md, profile YAML (.ai/profiles/{profile}.yml)
        Writes: {project_dir}/dev/stack.yml
      Report: "Stack negotiation complete. Confirmed stack saved to stack.yml."
    else:
      Run skill: stack-negotiation (full mode)
        Reads: findings.md
        Writes: {project_dir}/dev/stack.yml
      Report: "Stack negotiation complete (full mode). Confirmed stack saved to stack.yml."
  else:
    Report: "App path {app_path} not found. Skipping scan and negotiation. Create the app directory and run /agency:scan later."
else:
  Report: "Scan skipped. Stack negotiation also skipped."
```

### Step 7: Report

```
## Project Initialized: {project_name}

### Directory
  .ai/projects/{project_name}/ (created)

### Profile
  {profile_name} / No profile

### Brand
  {Loaded from X / No brand data}

### Tech Stack
  {Scan results / Skipped / App not found}

### Stack
  {stack.yml summary / Negotiation skipped / App not found}

### Next Steps
  1. /agency:design — run the design pipeline
  2. /agency:build — start development
  3. /agency:status — check progress
```
