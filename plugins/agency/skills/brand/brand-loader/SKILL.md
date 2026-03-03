---
name: brand-loader
user-invocable: false
description: >
  Loads existing brand-reference.yml into the agency pipeline. Reads from
  .ai/projects/[name]/brand/, extracts design tokens (colors, typography,
  spacing), and registers brand assets in the project's asset-registry.yml.
  Use when initializing a project with existing brand data, running
  /agency:init brand phase, loading brand context, or extracting design
  tokens from brand reference.
phase: 1
depends_on: []
writes:
  - ".ai/projects/[name]/brand/brand-summary.yml"
  - ".ai/projects/[name]/asset-registry.yml"
reads:
  - ".ai/projects/[name]/brand/brand-reference.yml"
  - "plugins/agency/resources/templates/asset-registry-schema.yml"
model_tier: junior
checkpoint:
  type: data_validation
  required_checks:
    - name: "brand_reference_loaded"
      verify: "brand-reference.yml was read and parsed successfully"
      fail_action: "Check file path and YAML syntax"
    - name: "tokens_extracted"
      verify: "brand-summary.yml contains colors, typography, and spacing sections"
      fail_action: "Re-read brand-reference.yml sections: colors, typography"
    - name: "assets_registered"
      verify: "asset-registry.yml has at least 1 brand asset entry"
      fail_action: "Register brand-reference.yml as an asset with type: document"
  on_fail: "Fix and re-run checkpoint"
  on_pass: "Update state.yml brand module status, advance to design"
---

# Brand Loader

Loads an existing brand-reference.yml and prepares it for the agency pipeline.
Extracts design tokens and registers brand assets.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | brand-reference.yml from .ai/projects/[name]/brand/ |
| **Writes** | brand-summary.yml (extracted tokens), asset-registry.yml (brand entries) |
| **Checkpoint** | data_validation: brand loaded, tokens extracted, assets registered |

## Process Summary

1. Read .ai/projects/[name]/brand/brand-reference.yml
2. Extract design tokens: colors (primary, secondary, accent, neutrals),
   typography (families, scale), spacing
3. Write brand-summary.yml with extracted tokens in design-friendly format
4. Register brand assets in asset-registry.yml (brand-reference, brand-summary)
5. Report loaded brand name, token counts, registered assets

## Execution

Follow the detailed process in [references/process.md](references/process.md).
