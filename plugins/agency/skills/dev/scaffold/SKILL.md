---
name: scaffold
user-invocable: false
description: >
  Generates a project skeleton with Tailwind + design tokens + component library
  setup. Creates directory structure, installs dependencies, configures build
  tools, and sets up component library foundation. Use when scaffolding a new
  project, running /agency:build scaffold phase, setting up Tailwind with
  design tokens, or creating component library structure.
phase: 3
depends_on: [config-generator, design-tokens]
writes:
  - "{app_path}/tailwind.config.ts"
  - "{app_path}/src/styles/globals.css"
  - "{app_path}/src/styles/tokens.css"
  - "{app_path}/src/components/ui/ (component library directory)"
  - ".ai/projects/[name]/dev/findings.md#scaffold"
reads:
  - ".ai/projects/[name]/dev/dev-config.yml"
  - ".ai/projects/[name]/design/tokens/tailwind.config.json"
  - ".ai/projects/[name]/design/tokens/variables.css"
model_tier: senior
model: sonnet
checkpoint:
  type: code_quality_gate
  required_checks:
    - name: "tailwind_config_exists"
      verify: "tailwind.config.ts exists in app root with design token colors"
    - name: "globals_css_imports_tokens"
      verify: "globals.css imports tokens.css and has Tailwind directives"
    - name: "component_dir_exists"
      verify: "src/components/ui/ directory exists with at least index.ts"
    - name: "build_passes"
      verify: "Project builds without errors after scaffold"
  on_fail: "Fix and re-run"
  on_pass: "Update state.yml, advance to feature-decomposer"
---

# Scaffold

Phase 1 of /agency:build. Reads dev-config.yml and design tokens to generate
a working project skeleton: Tailwind config wired to brand tokens, CSS custom
properties, and a component library directory with a reference Button component.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | dev-config.yml (framework, language, package manager, commands), tailwind.config.json + variables.css (design tokens) |
| **Writes** | tailwind.config.ts, globals.css, tokens.css, src/components/ui/ |
| **Checkpoint** | code_quality_gate — 4 checks: tailwind config, globals.css, component dir, build passes |
| **Dependencies** | config-generator + design-tokens must both be complete |

## Process Summary

1. Read dev-config.yml — extract framework, language, package manager, app_path, build command
2. Read design tokens — tailwind.config.json (colors, fonts, spacing) and variables.css
3. Generate tailwind.config.ts — convert JSON token config, add content paths and plugins
4. Generate tokens.css — CSS custom properties verbatim from variables.css
5. Generate globals.css — Tailwind directives, tokens.css import, base layer resets
6. Set up src/components/ui/ — index.ts barrel file + reference Button component

Framework-specific paths and structure vary (Next.js, Vite, generic). See references/process.md.

## Findings Persistence

Append scaffold results to `.ai/projects/[name]/dev/findings.md#scaffold` after
each major step. **2-Action Rule:** save after every 2 file writes. Log errors to
state.yml errors array — never repeat a failed approach.

## Execution

Follow the detailed process in [references/process.md](references/process.md).
