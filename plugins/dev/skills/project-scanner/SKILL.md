---
name: project-scanner
description: >
  Static analysis of a project to detect frameworks, language, package manager,
  architecture patterns, testing tools, linting, and key directories. Produces
  structured scan results consumed by config-generator. Use when initializing a
  dev project, running /dev:init phase 1, detecting project stack, scanning
  frameworks, or identifying project conventions.
phase: 1
depends_on: []
writes:
  - "~/.claude/dev/[project-name]/findings.md#project-scan"
reads:
  - "package.json"
  - "tsconfig.json, go.mod, Cargo.toml, pyproject.toml"
  - "Config files: next.config.*, vite.config.*, turbo.json, etc."
model_tier: junior
checkpoint:
  type: data_validation
  required_checks:
    - name: "framework_detected"
      verify: "Scan results contain at least 1 detected framework OR explicit 'none detected' marker"
      fail_action: "Re-scan project root; if truly empty, write 'none detected' with reason"
    - name: "language_populated"
      verify: "Language field is one of: typescript, javascript, python, go, rust, other"
      fail_action: "Check file extensions in src/ to determine dominant language"
    - name: "package_manager_populated"
      verify: "Package manager field is one of: npm, yarn, pnpm, bun, unknown"
      fail_action: "Check for lock files; if none found, set to 'unknown'"
    - name: "config_files_checked"
      verify: "At least 3 config file paths were checked (even if not found)"
      fail_action: "Run additional Glob checks for standard config files"
    - name: "findings_exist"
      verify: "findings.md exists at ~/.claude/dev/[project-name]/findings.md with scan results"
      fail_action: "Write current scan results to findings.md immediately"
  on_fail: "Fix issues and re-run checkpoint. Do not advance until all checks pass."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Project Scanner

Phase 1 of /dev:init. Performs autonomous static analysis of the project to detect its technology stack, conventions, architecture, and key files. Output feeds into config-generator (Phase 2) via findings.md.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | Project source files via Glob, Grep, and Read |
| **Writes** | findings.md (structured scan results for config-generator) |
| **Checkpoint** | data_validation: framework detected, language set, package manager set, 3+ config checks, findings.md exists |
| **Dependencies** | None — this is the first skill in the init flow |

## Process Summary

1. Read package.json — extract dependencies, devDependencies, scripts
2. Glob for known config files (next.config.*, vite.config.*, turbo.json, prisma/schema.prisma, etc.)
3. Detect language (tsconfig.json → TypeScript, go.mod → Go, etc.)
4. Detect package manager from lock files (pnpm-lock.yaml, yarn.lock, bun.lockb, package-lock.json)
5. Detect architecture pattern (monorepo, Next.js router style, SvelteKit/Remix routes)
6. Detect testing, linting, and formatting tools from config files
7. Map src structure — entry points, key directories, component libraries
8. Detect git conventions from recent commits and .github/ templates
9. Save all findings to findings.md following 2-Action Rule
10. Run checkpoint validation; fix failures up to 3 rounds

## Findings Persistence

Write intermediate discoveries to `~/.claude/dev/[project-name]/findings.md`.

**2-Action Rule:** After every 2 file reads or Glob/Grep operations, IMMEDIATELY save key findings to findings.md before continuing. This protects against context loss during /compact.

## Error Logging

Log errors to state.yml errors array. Check errors before retrying — never repeat a failed approach.

## Execution

Follow the detailed process in [references/process.md](references/process.md).
