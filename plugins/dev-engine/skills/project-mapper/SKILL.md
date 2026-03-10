---
name: project-mapper
description: >
  Scan a repository to detect tech stack, map file dependencies and module
  boundaries, and output a Mermaid C4 context diagram. Use when onboarding
  to a new codebase, determining which tech knowledge skills to activate,
  generating an architecture overview, or producing a project-map.yml for
  downstream agent dispatch.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "scan project"
  - "project mapper"
  - "detect tech stack"
  - "codebase overview"
reads:
  - "package.json"
  - "tsconfig*.json"
  - "prisma/schema.prisma"
  - "app.json"
  - "app.config.js"
  - "next.config.*"
  - "nuxt.config.*"
  - "vite.config.*"
  - "turbo.json"
writes:
  - ".ai/project-map.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "stack_detected"
      verify: "At least one framework detected and written to project-map.yml"
      fail_action: "Check config file globs — scan root and workspaces if monorepo"
    - name: "diagram_valid"
      verify: "Mermaid output parses without syntax errors (C4Context block present)"
      fail_action: "Validate against references/process.md diagram template"
    - name: "module_boundaries"
      verify: "Each detected workspace/package has an entry in modules[]"
      fail_action: "Re-scan packages/ or apps/ directories for missing entries"
    - name: "output_written"
      verify: ".ai/project-map.yml exists and contains stack, modules, and diagram fields"
      fail_action: "Write project-map.yml before reporting completion"
_source:
  origin: "dev-engine"
  inspired_by: "D-027 decisions"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Codebase scanning and tech stack detection"
---

# Project Mapper

Scans a repo to build a structured picture of its tech stack, module boundaries,
and architecture — written to `.ai/project-map.yml` with a Mermaid diagram.

## When to trigger

- Onboarding to an unfamiliar codebase before dispatching agents
- Determining which tech knowledge skills are relevant
- Generating an architecture diagram for documentation or planning
- Detecting monorepo structure before decomposing tasks

## What it scans

Reads config files at repo root (and workspace roots for monorepos):
`package.json` → deps/scripts, `tsconfig*.json` → TS config, `prisma/schema.prisma` → DB,
`app.json`/`app.config.js` → Expo, `next.config.*` → Next.js, `nuxt.config.*` → Nuxt,
`vite.config.*` → Vite, `turbo.json` → monorepo pipeline.

## Output

Writes `.ai/project-map.yml` (stack, modules[], diagram) and prints a Mermaid C4
context diagram. Full detection patterns, dependency mapping, module boundary rules,
diagram template, output schema, monorepo support, and anti-patterns: `references/process.md`.
