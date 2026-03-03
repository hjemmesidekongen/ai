---
name: agency:scan
description: "Re-scan the active project for tech stack changes, new dependencies, and configuration drift since the last scan"
arguments:
  - name: --full
    description: "Force a full re-scan instead of delta-only"
    required: false
  - name: --module
    description: "Scan only a specific module's files (brand, design, content, dev, devops)"
    required: false
---

# /agency:scan

Re-scans the active project to detect changes since the last scan. Useful after adding dependencies, changing configuration, or pulling new code.

## Usage

```
/agency:scan              # Delta scan — only what changed
/agency:scan --full       # Full re-scan
/agency:scan --module dev # Scan only dev-related files
```

## Execution Steps

### Step 1: Load Project Context

```
Read .ai/agency.yml → get active project
Read .ai/projects/{name}/state.yml → get last scan info
Read .ai/projects/{name}/dev/findings.md → get previous scan results

app_path = agency.yml.projects.{name}.app_path
if app_path doesn't exist:
  "App path {app_path} not found. Update agency.yml or run /agency:init."
  STOP
```

### Step 2: Determine Scan Mode

```
if --full flag:
  mode = "full"
elif previous findings.md exists:
  mode = "delta"
else:
  mode = "full"  # No previous scan to delta against
```

### Step 3: Run Scan

**Full mode:** Run project-scanner skill on app_path (same as /agency:init)

**Delta mode:**
```
1. Get git diff since last scan timestamp (from findings.md header)
   git diff --name-only --since="{last_scan_date}" -- {app_path}

2. Categorize changed files:
   - package.json / lock files → dependency changes
   - Config files (tsconfig, next.config, etc.) → framework changes
   - New directories → architecture changes
   - tailwind.config.* / .storybook/ → design tooling changes

3. For each category with changes:
   - Re-run the relevant detection step from project-scanner
   - Compare with previous findings
   - Report what changed

4. Update findings.md with new results
   - Preserve unchanged sections
   - Update changed sections with "[UPDATED]" marker
   - Add timestamp of re-scan
```

### Step 4: Module-Specific Scan

```
if --module provided:
  Filter scan to module-relevant files only:
    brand: brand-reference.yml, brand-summary.yml, brand package
    design: design tokens, Tailwind config, Storybook, CSS
    content: content files, copy documents
    dev: source code, tests, configs, dependencies
    devops: Dockerfile, CI config, deployment files
```

### Step 5: Report Changes

```
## Scan Results: {project_name}
Mode: {full|delta} | App: {app_path}

### Changes Detected
  - Dependencies: {added X, removed Y, updated Z}
  - Config: {changed files}
  - Architecture: {new patterns detected}
  - Design tooling: {changes}

### Impact Analysis
  - Dev config may need updating: {yes/no}
  - Design tokens may be affected: {yes/no}
  - Build commands may have changed: {yes/no}

### Recommended Actions
  1. {action based on changes}
  2. {action based on changes}
```
