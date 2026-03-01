---
name: version-compatibility-checker
description: >
  Checks whether a project's data files are compatible with the current plugin
  version. Use when loading existing project data, checking version
  compatibility, running brand-context-loader, or verifying _meta version
  before data import.
---

# Version Compatibility Checker

> checkpoint: data_validation

Checks whether a project's data files are compatible with the current plugin
version. Called automatically when any plugin loads existing project data —
ensures stale or incompatible data is never silently loaded.

## Context

- Reads: `.claude-plugin/plugin.json` (current version), target YAML file `_meta` block
- Writes: compatibility result returned to caller — no file written
- Checkpoint: data_validation (handles all four cases, returns structured result, identifies legacy files, reads MIGRATION-REGISTRY.yml)
- Dependencies: none

## Process Summary

1. **Read current plugin version** — load `plugin.json`, extract `name` and `version`
2. **Read file version metadata** — check `_meta` block in target YAML; legacy files (no `_meta`) treated as `0.0.0`
3. **Compare versions** — apply severity rules: `ok` (exact/patch), `warning` (minor or legacy), `blocking` (major or file newer than plugin)
4. **Check migration path** — if warning/blocking, read `migrations/MIGRATION-REGISTRY.yml` and walk chain from file version to current
5. **Build and return compatibility result** — structured object with `compatible`, `severity`, versions, `migration_available`, `migration_chain`, `message`

## Execution

Read `references/process.md` for the complete severity table, message
templates, migration-chain walking algorithm, output examples for all
severity levels, edge cases, and integration points.
