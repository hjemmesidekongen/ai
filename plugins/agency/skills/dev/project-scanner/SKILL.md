---
name: project-scanner
user-invocable: false
description: >
  Static analysis of a project to detect frameworks, language, package manager,
  architecture patterns, testing tools, linting, key directories, design tooling
  (Tailwind, CSS variables, Storybook, design tokens), and existing brand files.
  Produces structured scan results consumed by config-generator. Use when
  initializing a project via /agency:dev:init, detecting the project stack,
  scanning for design system files, or checking for existing brand-reference.yml.
phase: 1
depends_on: []
writes:
  - ".ai/projects/[name]/dev/findings.md#project-scan"
reads:
  - "package.json"
  - "tsconfig.json, go.mod, Cargo.toml, pyproject.toml"
  - "Config files: next.config.*, vite.config.*, tailwind.config.*, etc."
model_tier: junior
model: haiku
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
    - name: "design_tooling_checked"
      verify: "findings.md contains a Design Tooling section (even if empty)"
      fail_action: "Run Glob checks for tailwind.config.*, .storybook/, design-tokens.*"
    - name: "findings_exist"
      verify: "findings.md exists at .ai/projects/[name]/dev/findings.md with scan results"
      fail_action: "Write current scan results to findings.md immediately"
  on_fail: "Fix issues and re-run checkpoint. Do not advance until all checks pass."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Project Scanner

Phase 1 of /agency:dev:init. Static analysis of the project's stack, conventions, architecture, design tooling, and brand files. Output feeds config-generator (Phase 2) via findings.md.

## Context
| Aspect | Details |
|--------|---------|
| **Reads** | Project source files via Glob, Grep, and Read |
| **Writes** | `.ai/projects/[name]/dev/findings.md` |
| **Checkpoint** | data_validation: framework, language, package manager, config files, design tooling, findings.md |
| **Dependencies** | None — first skill in the init flow |
## Process Summary

1. Read package.json — extract dependencies, devDependencies, scripts
2. Glob for known config files (next.config.*, vite.config.*, turbo.json, etc.)
3. Detect language (tsconfig.json → TypeScript, go.mod → Go, etc.)
4. Detect package manager from lock files (pnpm-lock.yaml, yarn.lock, bun.lockb, package-lock.json)
5. Detect architecture pattern (monorepo, Next.js router style, SvelteKit/Remix routes)
6. Detect testing, linting, and formatting tools from config files
7. Map src structure — entry points, key directories, component libraries
8. **Detect design tooling** — Tailwind, CSS variables, Storybook, design token files
9. **Detect brand files** — check for brand-reference.yml in project root and .ai/
10. Detect git conventions from recent commits and .github/ templates
11. Save findings following 2-Action Rule; run checkpoint (up to 3 fix rounds)

## Findings Persistence

Write to `.ai/projects/[name]/dev/findings.md`. **2-Action Rule:** After every 2 reads or Glob/Grep calls, save findings immediately — protects against context loss during /compact.

## Error Logging

Log errors to state.yml errors array. Check errors before retrying — never repeat a failed approach.

## Execution

Follow the detailed process in [references/process.md](references/process.md).
