---
name: migration-guide-generator
description: >
  Utility skill called by /plugin:version to generate migration artifacts when
  bumping a plugin's minor or major version. Diffs old and new YAML schemas
  field by field, classifies the migration type, and produces a human-readable
  guide, a structured transform script, and an updated MIGRATION-REGISTRY.yml.
  Use when generating migration artifacts, running /plugin:version for minor
  or major bumps, diffing old and new schemas, or creating transform scripts.
interactive: false
depends_on: []
reads:
  - "plugins/[plugin]/resources/schemas/archive/v[old].yml"
  - "plugins/[plugin]/resources/templates/[plugin]-schema.yml"
writes:
  - "plugins/[plugin]/migrations/v[old]-to-v[new].md"
  - "plugins/[plugin]/migrations/scripts/v[old]-to-v[new].yml"
  - "plugins/[plugin]/migrations/MIGRATION-REGISTRY.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "migration_guide_complete"
      verify: "Migration file documents every schema difference (no undocumented changes)"
      fail_action: "Re-diff schemas and update migration guide"
    - name: "breaking_changes_noted"
      verify: "Every breaking change has a manual review note"
      fail_action: "Add manual review notes for all breaking changes"
    - name: "additive_defaults_set"
      verify: "Every additive change has a default value"
      fail_action: "Add default values for all new fields"
    - name: "transform_script_complete"
      verify: "Migration script handles all automatic transformations"
      fail_action: "Update transform script to cover missing transformations"
    - name: "registry_updated"
      verify: "MIGRATION-REGISTRY.yml updated with correct metadata"
      fail_action: "Append or update the registry entry"
    - name: "rollback_present"
      verify: "Rollback instructions present in migration guide"
      fail_action: "Add rollback section to migration guide"
  on_fail: "Re-diff the schemas, identify missing changes, update all three output files"
  on_pass: "Calling command proceeds to update CHANGELOG.md"
---

# Migration Guide Generator

Utility skill — diffs plugin schemas and generates migration guide, transform script, and registry entry. Called by `/plugin:version` for minor/major bumps.

## Context
- Reads: archived old schema, current schema template
- Writes: migration guide (.md), transform script (.yml), MIGRATION-REGISTRY.yml
- Checkpoint: data_validation (enforced by calling command after invocation)
- Dependencies: none

## Process Summary
1. Load and parse both schemas into flat field-path maps
2. Diff field by field — classify as added, removed, renamed, modified, or unchanged
3. Classify migration as minor (additions only) or major (any breaking changes); warn user if major
4. Generate migration guide markdown with breaking changes, new fields, steps, and rollback
5. Generate transform script YAML with typed actions (add, rename, transform, remove, update_meta)
6. Append entry to MIGRATION-REGISTRY.yml; validate chain continuity and no duplicates

## Execution
Read `references/process.md` for the complete process, schema diff logic, output file formats, transform action types, edge cases, and integration points.
