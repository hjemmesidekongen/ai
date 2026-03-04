---
name: plugin-spec-generator
user-invocable: false
description: >
  Reads design.yml from the design interview and generates the full spec
  documents: implementation plan, domain addendum, asset manifest (if applicable),
  and registers the verification profile. Produces everything downstream skills
  (execution-guide-generator, scaffolder) need to build the plugin. Use when
  generating plugin specs from design.yml, running /plugin:create step 2,
  creating implementation plan, or producing domain addendum.
interactive: false
depends_on:
  - plugin-design-interview
reads:
  - plugins/[plugin-name]/design.yml
  - docs/ecosystem-strategy.md (Section 3: Spec Document Template, Section 6: Brand Data)
  - plugins/task-planner/resources/plugin-blueprint.md (Sections 2-8)
  - plugins/task-planner/resources/verification-registry.yml
writes:
  - docs/[plugin-name]-implementation-plan.md
  - docs/[plugin-name]-addendum.md
  - docs/[plugin-name]-asset-manifest.md (if design.yml defines assets)
  - plugins/task-planner/resources/verification-registry.yml (appends verification profile)
checkpoint_type: data_validation
---

# Plugin Spec Generator

Autonomous skill that reads the `design.yml` produced by the plugin-design-interview
and generates the complete spec documents for the new plugin.

## Context

- Reads: design.yml (approved), ecosystem-strategy.md (Sections 3, 6), plugin-blueprint.md (Sections 2–8), verification-registry.yml
- Writes: implementation-plan.md, addendum.md, asset-manifest.md (if assets), verification-registry.yml (appended)
- Checkpoint: data_validation (plan has 6 sections, schema has 5+ top-level sections, all 7 cross-reference checks pass)
- Dependencies: plugin-design-interview

## Process Summary

1. Read and validate design.yml — must have all required fields and status "approved"
2. Generate implementation plan (6 sections: overview, architecture, YAML schema, commands, skills, build order with model tiers, tier distribution summary, and split verification tasks per skill)
3. Generate domain addendum (5 sections: domain knowledge, quality standards, tools, validation criteria, common mistakes)
4. Generate asset manifest if design.yml defines assets — skip entirely if none
5. Register verification profile in verification-registry.yml — add new types if needed
6. Cross-reference validate — skills, commands, schema sections, verification types, brand sections, dependencies, and wave plan must all be consistent

## Execution

Read `references/process.md` for the complete process, output formats, and quality rules.
