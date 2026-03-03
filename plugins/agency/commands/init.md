---
name: agency:init
description: "Initialize a new agency project — creates project directory, loads brand data, scans tech stack, and registers in agency.yml"
arguments:
  - name: project_name
    description: "Name for the project (kebab-case)"
    required: true
  - name: --app-path
    description: "Path to the application root (default: apps/[project_name])"
    required: false
  - name: --brand
    description: "Path to existing brand-reference.yml to import"
    required: false
  - name: --skip-scan
    description: "Skip tech stack scanning"
    required: false
---

# /agency:init

Creates and registers a new agency project. Sets up the project directory, loads brand data (if available), and scans the tech stack.

## Usage

```
/agency:init acme --app-path apps/acme-web --brand .ai/brands/acme/brand-reference.yml
/agency:init my-project
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

### Step 2: Initialize State

Create `{project_dir}/state.yml` following project-state-schema.yml:
```yaml
project: "{project_name}"
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

### Step 3: Register in Agency Registry

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

### Step 4: Load Brand (if --brand provided)

```
if --brand flag provided:
  Copy brand-reference.yml to {project_dir}/brand/
  Run brand-loader skill:
    - Extract design tokens
    - Register brand assets in asset-registry.yml
  Update state.yml: modules.brand.status → "completed"
  Update agency.yml: brand_reference → path
else:
  Report: "No brand data provided. Run /agency:init with --brand or create brand data manually."
  Skip brand loading
```

### Step 5: Scan Tech Stack (unless --skip-scan)

```
if --skip-scan NOT set:
  app_path = resolved --app-path
  if app_path exists:
    Run project-scanner skill on app_path
    Report scan results
  else:
    Report: "App path {app_path} not found. Skipping scan. Create the app directory and run /agency:scan later."
```

### Step 6: Report

```
## Project Initialized: {project_name}

### Directory
  .ai/projects/{project_name}/ (created)

### Brand
  {Loaded from X / No brand data}

### Tech Stack
  {Scan results / Skipped / App not found}

### Next Steps
  1. /agency:design — run the design pipeline
  2. /agency:build — start development
  3. /agency:status — check progress
```
