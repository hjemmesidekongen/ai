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
writes:
  - ".ai/projects/[name]/dev/dev-config.yml"
reads:
  - ".ai/projects/[name]/dev/findings.md#project-scan"
  - "plugins/agency/resources/templates/dev-config-schema.yml"
  - "package.json (for scripts mapping)"
model_tier: senior
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

Phase 2 of /agency:dev:init. Reads project-scanner findings, transforms them into dev-config.yml, and walks the user through confirming detections. Includes a design token integration step linking token files from scanner findings or `.ai/projects/[name]/design/tokens/`. Output is the central project contract for all downstream dev skills.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | findings.md (scan results), dev-config-schema.yml (target format), package.json (scripts) |
| **Writes** | dev-config.yml (the project contract) |
| **Checkpoint** | data_validation — 7 checks: config, meta, frameworks.runtime, language, build command, design_tokens section, user confirmation |
| **Dependencies** | project-scanner (must run first to produce findings.md) |

## Process Summary

1. Read scan results from findings.md — extract frameworks, language, package manager, architecture
2. Transform findings into dev-config.yml schema format
3. Present each detected framework to user for confirmation (one at a time)
4. Resolve ambiguous detections interactively
5. Integrate design token paths — check findings.md Design Tooling section and `.ai/projects/[name]/design/tokens/`
6. Ask about conventions not auto-detectable (branch pattern, commit format, coverage threshold)
7. Map package.json scripts to commands section (build, dev, test, lint, format, typecheck)
8. Write completed dev-config.yml; present final summary and wait for confirmation

## Findings Persistence

Write confirmed values to `.ai/projects/[name]/dev/findings.md`. **2-Action Rule:** After every 2 user interactions, IMMEDIATELY save to findings.md. Log all errors to state.yml errors array — never repeat a failed approach.

## Execution

Follow the detailed process in [references/process.md](references/process.md).
