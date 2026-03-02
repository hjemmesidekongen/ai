---
name: init
command: "/dev:init"
description: "Scan a project, detect frameworks and conventions, produce dev-config.yml and initial knowledge files"
arguments:
  - name: force
    type: boolean
    required: false
    default: false
    description: "Re-scan even if dev-config.yml already exists"
  - name: brand
    type: string
    required: false
    description: "Load brand context for designer-relevant knowledge (e.g., 'acme-corp')"
---

# /dev:init

Scans the current project, detects frameworks, conventions, and architecture, then produces a dev-config.yml and initial knowledge files. This is the first command to run before using `/dev:build` or `/dev:scan`.

## Usage

```
/dev:init                        # scan current project
/dev:init --force                # re-scan, overwrite existing config
/dev:init --brand acme-corp      # scan + load brand context for design knowledge
```

## Purpose

Performs a one-time project analysis that produces the configuration and knowledge base needed by all other `/dev:*` commands. Detects the tech stack, file structure, naming conventions, API patterns, and architectural boundaries — then stores them as structured knowledge for the agent team.

## Prerequisites

- Current directory is a project with source code
- plugins/dev must be active
- No prior dev-config.yml required (will be created)
- For `--brand`: brand-guideline plugin installed with at least one generated brand

## Input

- `--force` (optional) — bypass the "already initialized" check and re-scan
- `--brand [name]` (optional) — load brand context via brand-context-loader for designer knowledge

Interactive prompts during execution:
- Confirms detected frameworks and tech stack
- Asks about conventions not auto-detectable (e.g., PR review process, deployment strategy)

## Execution Strategy

This command does NOT use the task-planner — it runs sequentially because each step is fast and depends on the previous.

### Step 1: Check Existing Config

Check if `.ai/dev/[project-name]/dev-config.yml` already exists.

- If exists and no `--force`: ask user "Project already initialized. Re-scan? [Y/n]"
- If user declines: exit with message showing `/dev:status` for current config
- If exists and `--force`: proceed (will overwrite)
- If not exists: proceed

Create project directory: `mkdir -p .ai/dev/[project-name]`

### Step 2: Run project-scanner

Read SKILL.md at `plugins/dev/skills/project-scanner/SKILL.md`, follow its process.

This skill:
- Scans the project directory structure
- Detects frameworks, languages, build tools
- Identifies key directories (src/, tests/, config/, etc.)
- Maps API routes, data models, and architecture patterns
- Produces raw scan data in findings.md

### Step 3: Run config-generator

Read SKILL.md at `plugins/dev/skills/config-generator/SKILL.md`, follow its process.

This skill:
- Takes raw scan data from project-scanner
- Presents detected configuration to user for confirmation
- Asks about conventions not auto-detectable
- Produces `.ai/dev/[project-name]/dev-config.yml`

### Step 4: Run knowledge-initializer

Read SKILL.md at `plugins/dev/skills/knowledge-initializer/SKILL.md`, follow its process.

This skill:
- Reads confirmed dev-config.yml
- Creates tagged knowledge files: `knowledge/patterns.yml`, `knowledge/conventions.yml`
- Creates `knowledge/architecture.md` with mermaid diagrams
- Computes initial SHA-256 file hashes for delta scanning
- All entries start at `candidate` maturity

### Step 5: Load Brand Context (if --brand)

If `--brand` flag provided:
- Run brand-context-loader to load brand data from `.ai/brands/[brand-name]/`
- Store brand context in findings.md for future agent reference (design decisions, color palette, typography)
- This enables design-aware knowledge entries and agent guidance

### Step 6: Initialize State

Write `.ai/dev/[project-name]/state.yml`:

```yaml
status: "initialized"
current_skill: null
current_phase: null
errors: []
meta:
  plugin: "dev"
  plugin_version: "1.0.0"
  created_at: "[timestamp]"
  updated_at: "[timestamp]"
```

## Output

- `.ai/dev/[project-name]/dev-config.yml` — project configuration (framework, conventions, key directories)
- `.ai/dev/[project-name]/knowledge/*.yml` — tagged knowledge files (patterns.yml, conventions.yml)
- `.ai/dev/[project-name]/knowledge/architecture.md` — mermaid diagrams of project architecture
- `.ai/dev/[project-name]/state.yml` — initialized state with errors array
- `.ai/dev/[project-name]/findings.md` — intermediate scan findings

## Recovery

Idempotent — re-run `/dev:init` to overwrite. Use `--force` to bypass the "already initialized" prompt. If interrupted mid-scan, re-run from the start — partial config is unreliable.

## Error Handling

- **Empty project:** If no source files detected, warn user and create minimal dev-config.yml with just the project name
- **Permission errors:** Log to state.yml errors array, skip inaccessible directories, continue with available files
- **Brand not found:** If `--brand` name doesn't match any existing brand, warn and continue without brand context
