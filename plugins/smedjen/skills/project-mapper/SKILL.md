---
name: project-mapper
description: >
  Scan a repository to detect tech stack, workspace shape, and produce a
  project profile at .ai/project-map.yml. Includes skills matching: maps
  detected stack to relevant smedjen knowledge skills for reference_paths
  dispatch. Use when onboarding to a codebase, before agent dispatch, when
  checking which skills apply, or generating a project profile.
user_invocable: true
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "scan project"
  - "project mapper"
  - "detect tech stack"
  - "project profile"
  - "project map"
  - "what stack"
  - "which skills"
  - "dev scan"
reads:
  - "package.json"
  - "tsconfig*.json"
  - "prisma/schema.prisma"
  - "app.json / app.config.*"
  - "next.config.* / nuxt.config.* / vite.config.*"
  - "turbo.json / pnpm-workspace.yaml"
writes:
  - ".ai/project-map.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "profile_written"
      verify: ".ai/project-map.yml exists with repo_type, apps, and content_hash fields"
      fail_action: "Scan config files and write the profile"
    - name: "skills_matched"
      verify: "Each app entry has a skills[] array mapping stack to smedjen skill names"
      fail_action: "Run skills matching algorithm from references/process.md"
    - name: "hash_computed"
      verify: "content_hash field contains SHA-256 of source config files"
      fail_action: "Compute hash from workspace config files"
  on_fail: "Re-scan and rewrite profile"
  on_pass: "Report repo type, app count, and matched skills count"
_source:
  origin: "smedjen"
  inspired_by: "SA-D007 decision"
  ported_date: "2026-03-10"
  iteration: 2
  changes: "Simplified from module-boundary mapper to project profile with skills matching"
---

# Project Mapper

Scans a repo and produces a lightweight project profile at `.ai/project-map.yml`.
Focuses on what agents need: repo shape, stack per app, and which smedjen knowledge
skills are relevant.

## When to trigger

- Onboarding to a new codebase
- Before dispatching agents (profile provides reference_paths)
- Checking which tech skills apply to the current project
- After workspace topology changes (new app, new package)

## What it produces

`.ai/project-map.yml` with:
- **repo_type**: monorepo | single-package
- **workspace**: pnpm/yarn/npm workspace config
- **apps**: each with platform, path, stack entries, and matched skills
- **packages**: brand-specific, shared, forbidden topology
- **conventions**: detected coding conventions
- **commands**: dev/build/test/lint commands
- **content_hash**: SHA-256 of source config files (for freshness checking)

Full schema, detection heuristics, skills matching algorithm, and monorepo
support: `references/process.md`.
