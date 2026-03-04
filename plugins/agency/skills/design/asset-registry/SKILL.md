---
name: asset-registry
user-invocable: false
description: >
  Utility skill for managing the centralized asset registry. Provides
  register, query, validate, and list operations on asset-registry.yml.
  Called by any skill that produces or consumes assets. Use when registering
  new assets, querying assets by type/tag/producer, validating asset
  integrity, listing project assets, or checking asset dependencies.
phase: null
depends_on: []
writes:
  - ".ai/projects/[name]/asset-registry.yml"
reads:
  - ".ai/projects/[name]/asset-registry.yml"
  - "plugins/agency/resources/templates/asset-registry-schema.yml"
model_tier: junior
model: haiku
checkpoint:
  type: none
  required_checks: []
---

# Asset Registry

Utility skill for centralized asset management. Every module that produces
an asset calls `register()`. Every module that needs an asset calls `query()`.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | asset-registry.yml, asset-registry-schema.yml |
| **Writes** | asset-registry.yml (append/update entries) |
| **Checkpoint** | None — utility called by other skills |

## Operations

### register(asset)
Add or update an asset entry. Required fields: id, name, type, format, path,
producer, tags.

### query(filters)
Find assets matching filters. Supports: by_type, by_producer, by_tag,
by_consumer, by_format.

### validate()
Check all registered assets: file exists at path, no duplicate IDs, required
fields present.

### list(options)
List all assets, optionally filtered by module or type.

## Findings Persistence

Write operation results to `.ai/projects/[name]/design/findings.md`. Log all errors to state.yml errors array — never repeat a failed approach.

## Execution

Follow the detailed process in [references/process.md](references/process.md).
