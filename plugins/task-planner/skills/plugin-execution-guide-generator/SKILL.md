---
name: plugin-execution-guide-generator
description: >
  Reads the spec documents (implementation plan, addendum, asset manifest) and
  design.yml for a plugin, then generates a complete execution guide with one
  full prompt per skill. The guide is what Claude Code follows step by step to
  build every skill, command, and test for the new plugin. Use when generating
  execution guide, running /plugin:create step 3, creating per-skill build
  prompts, or producing step-by-step plugin build guide.
interactive: false
depends_on:
  - plugin-spec-generator
reads:
  - plugins/[plugin-name]/design.yml
  - docs/[plugin-name]-implementation-plan.md
  - docs/[plugin-name]-addendum.md
  - docs/[plugin-name]-asset-manifest.md (if it exists)
  - docs/ecosystem-strategy.md (Section 4: Skill Prompt Template)
  - plugins/task-planner/resources/plugin-blueprint.md (Sections 3-4)
writes:
  - docs/[plugin-name]-execution-guide.md
checkpoint_type: data_validation
---

# Plugin Execution Guide Generator

Autonomous skill that reads the spec documents produced by the plugin-spec-generator
and produces a complete, step-by-step execution guide. The guide contains ONE FULL
PROMPT per skill — create a fully self-contained prompt for each skill instead of repeating patterns.

## Context

- Reads: design.yml, implementation-plan.md, addendum.md, asset-manifest.md (if exists), ecosystem-strategy.md (Section 4), plugin-blueprint.md (Sections 3–4)
- Writes: `docs/[plugin-name]-execution-guide.md`
- Checkpoint: data_validation (every skill has a dedicated prompt with 11 required elements, no forbidden phrases)
- Dependencies: plugin-spec-generator

## Process Summary

1. Collect inputs — index all data from design.yml, implementation plan, addendum, and asset manifest
2. Determine step numbering — scaffold (1), schema (2), skills in build order (3–N), commands (N+1–M-1), end-to-end test (M)
3. Generate per-skill prompts — one fully self-contained prompt per skill with spec reference, model tier, findings persistence, error logging, process steps, checkpoint, two-stage verification, completion gate awareness, self-tiering support, and CLAUDE.md update
4. Generate scaffold prompt (Step 1) — directory structure, plugin.json with hooks, session-recovery.sh, check-wave-complete.sh, README
5. Generate schema + templates prompt (Step 2) — YAML schema, markdown template, DOCX styles if needed
6. Generate command prompts — one per command with purpose, prerequisites, execution strategy, output, recovery
7. Generate end-to-end test prompt — fictional project, all skills in wave order, final output verification, recovery test
8. Generate CLAUDE.md progress checklist — one checkbox per step
9. Assemble guide — reality check, prerequisites, steps, after-each-skill rules, timeline table, tips
10. Quality validation — completeness, prompt quality (9 elements), exhaustiveness (no "etc."), timeline, checklist

## Execution

Read `references/process.md` for the complete process, output formats, and quality rules.
