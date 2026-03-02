---
name: version-meta-stamper
user-invocable: false
description: >
  Adds or updates the _meta version block in any plugin output YAML file.
  Use when stamping version metadata on YAML output, running compile-and-export
  final step, or adding _meta block to plugin output files.
---

# Version Meta Stamper

> checkpoint: data_validation

Utility skill that adds or updates the `_meta` version block in any plugin
output YAML file. Called as the final step before writing output to disk —
never invoked directly by the user.

## Context

- Reads: `.claude-plugin/plugin.json` (plugin name + version), target YAML file (existing `_meta` if any)
- Writes: `_meta` block inserted/replaced as the first top-level key in the target YAML; returns stamped data to calling skill (no direct disk write)
- Checkpoint: data_validation (meta_block_present, meta_fields_complete, created_at_immutable, version_matches_plugin, migrated_from_correct)
- Dependencies: none

## Process Summary

1. **Read plugin metadata** — load `plugin.json`, extract `name` and `version`; abort if missing
2. **Resolve schema version** — check `resources/schemas/schema-version.yml`, then schema file headers, then default to plugin version
3. **Read existing `_meta`** — preserve `created_at`; detect version change to set `migrated_from`
4. **Build `_meta` block** — six canonical fields: `plugin_name`, `plugin_version`, `schema_version`, `created_at`, `updated_at`, `migrated_from`
5. **Insert or replace** — `_meta` must be the first top-level key; replace entire block if it exists
6. **Return to calling skill** — stamped data returned; calling skill handles disk write and checkpoint

## Execution

Read `references/process.md` for the complete calling convention, field rules
table, edge cases, output examples, checkpoint spec, and integration points.
