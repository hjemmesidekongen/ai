---
name: config-generator
user-invocable: false
description: >
  Transforms project-scanner findings into a validated dev-config.yml contract.
  Presents detected frameworks, conventions, and commands for user confirmation.
  Integrates design token paths from the design module when available. Use when
  generating dev config, running /agency:dev:init phase 2, confirming frameworks,
  setting project conventions, or mapping build commands.
phase: 2
depends_on: [project-scanner]
depends_on_greenfield: []  # No dependencies in greenfield mode
writes:
  - ".ai/projects/[name]/dev/dev-config.yml"
reads:
  - ".ai/projects/[name]/dev/findings.md#project-scan"
  - "plugins/agency/resources/templates/dev-config-schema.yml"
  - "package.json (for scripts mapping)"
greenfield_sources:
  - ".ai/brainstorm/*/decisions.yml (tech stack, architecture, conventions)"
  - "CLAUDE.md (package manager, monorepo, conventions)"
  - ".ai/projects/[name]/design/tokens/ (design token paths)"
  - ".ai/projects/[name]/brand/brand-summary.yml (brand context)"
model_tier: senior
model: sonnet
interactive: true
checkpoint:
  type: data_validation
  required_checks:
    - name: "config_exists"
      verify: "dev-config.yml exists at .ai/projects/[name]/dev/dev-config.yml"
      fail_action: "Write current config state to dev-config.yml immediately"
    - name: "meta_complete"
      verify: "meta section has plugin_name, project_name, created_at, version"
      fail_action: "Populate missing meta fields with defaults"
    - name: "frameworks_runtime_exists"
      verify: "frameworks.runtime array exists (can be empty)"
      fail_action: "Add empty runtime array to frameworks section"
    - name: "language_populated"
      verify: "conventions.language is one of: typescript, javascript, python, go, rust, other"
      fail_action: "Check findings.md language detection; if missing, ask user"
    - name: "build_command_populated"
      verify: "commands.build is a non-empty string"
      fail_action: "Ask user: 'What command builds your project?'"
    - name: "design_tokens_section_exists"
      verify: "design_tokens section is present in config (values may be null)"
      fail_action: "Add design_tokens section with null values; populate from findings if available"
    - name: "user_confirmed"
      verify: "User explicitly confirmed the final config summary"
      fail_action: "Present config summary and ask for confirmation"
  on_fail: "Fix issues and re-run checkpoint. Do not advance until all checks pass."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Config Generator

Phase 2 of /agency:dev:init. Reads project-scanner findings (or brainstorm decisions in greenfield mode), transforms them into dev-config.yml, and walks the user through confirming detections. Includes a design token integration step linking token files from scanner findings or `.ai/projects/[name]/design/tokens/`. Output is the central project contract for all downstream dev skills.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | findings.md (scan results), dev-config-schema.yml (target format), package.json (scripts) |
| **Reads (greenfield)** | decisions.yml (brainstorm), CLAUDE.md (conventions), design tokens, brand-summary.yml |
| **Writes** | dev-config.yml (the project contract) |
| **Checkpoint** | data_validation — 7 checks: config, meta, frameworks.runtime, language, build command, design_tokens section, user confirmation |
| **Dependencies** | project-scanner (must run first to produce findings.md) — OR greenfield_sources when invoked with greenfield_mode: true |

## Process

Reads scan results (or brainstorm decisions in greenfield mode), confirms frameworks/conventions interactively, integrates design tokens, maps package.json scripts to commands, writes dev-config.yml. Write confirmed values to findings.md (**2-Action Rule:** save every 2 interactions). Log errors to state.yml. See [references/process.md](references/process.md) for detailed steps.
