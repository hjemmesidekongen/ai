---
name: config-generator
description: >
  Transforms project-scanner findings into a validated dev-config.yml contract.
  Presents detected frameworks, conventions, and commands to the user for
  confirmation or correction. Use when generating dev config, running /dev:init
  phase 2, confirming detected frameworks, setting project conventions, or
  mapping build commands.
phase: 2
depends_on: [project-scanner]
writes:
  - ".ai/dev/[project-name]/dev-config.yml"
reads:
  - ".ai/dev/[project-name]/findings.md#project-scan"
  - "plugins/dev/resources/templates/dev-config-schema.yml"
  - "package.json (for scripts mapping)"
model_tier: senior
interactive: true
checkpoint:
  type: data_validation
  required_checks:
    - name: "config_exists"
      verify: "dev-config.yml exists at .ai/dev/[project-name]/dev-config.yml"
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
    - name: "user_confirmed"
      verify: "User explicitly confirmed the final config summary"
      fail_action: "Present config summary and ask for confirmation"
  on_fail: "Fix issues and re-run checkpoint. Do not advance until all checks pass."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Config Generator

Phase 2 of /dev:init. Reads project-scanner findings, transforms them into the dev-config.yml schema, and walks the user through confirming or correcting each detection. Output is the central project contract consumed by all downstream skills.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | findings.md (scan results), dev-config-schema.yml (target format), package.json (scripts) |
| **Writes** | dev-config.yml (the project contract) |
| **Checkpoint** | data_validation: config exists, meta complete, frameworks.runtime exists, language set, build command set, user confirmed |
| **Dependencies** | project-scanner (must run first to produce findings.md) |

## Process Summary

1. Read scan results from findings.md — extract frameworks, language, package manager, architecture
2. Transform findings into dev-config.yml schema format
3. Present each detected framework to user for confirmation (one at a time)
4. Ask about conventions not auto-detectable (branch pattern, commit format, coverage threshold)
5. Map package.json scripts to commands section (build, dev, test, lint, format, typecheck)
6. For missing commands, ask user explicitly
7. Write completed dev-config.yml
8. Present final summary, wait for explicit user confirmation

## Findings Persistence

Write confirmed values to `.ai/dev/[project-name]/findings.md`.

**2-Action Rule:** After every 2 user interactions (questions asked and answered), IMMEDIATELY save confirmed values to findings.md before continuing.

## Error Logging

Log errors to state.yml errors array. Check errors before retrying — never repeat a failed approach.

## Execution

Follow the detailed process in [references/process.md](references/process.md).
