---
name: plugin-design-interview
user-invocable: false
description: >
  Walks the user through the 8 design questions every new plugin must answer
  before any code is written. Produces a structured design.yml that downstream
  skills (spec-generator, scaffolder) consume. Use when designing a new plugin,
  running /plugin:create, walking through 8 design questions, or starting
  plugin creation workflow.
interactive: true
depends_on: []
reads:
  - docs/ecosystem-strategy.md (Section 2: The 8 Design Questions, Section 6: Brand Data)
  - plugins/task-planner/resources/plugin-blueprint.md (Section 1: Questions)
  - plugins/task-planner/resources/verification-registry.yml
writes:
  - plugins/[plugin-name]/design.yml
checkpoint_type: data_validation
---

# Plugin Design Interview

Interactive skill that walks the user through the 8 design questions from
`docs/ecosystem-strategy.md`. Every new plugin must complete this interview
before any code or specs are written.

## Context

- Reads: ecosystem-strategy.md (Sections 2, 6), plugin-blueprint.md (Section 1), verification-registry.yml
- Writes: `plugins/[plugin-name]/design.yml`
- Checkpoint: data_validation (all 8 questions answered, status "approved")
- Dependencies: none (first skill in plugin creation workflow)

## Process Summary

1. Check decision-reader for prior brainstorm decisions — pre-fill high-confidence answers
2. Q0: Get the plugin idea (one-sentence description)
3. Q1: Refine scope — reject vague descriptions, flag if "and" joins unrelated features
4. Q2: Identify user persona — role, technical level, what they care about
5. Q3: Determine brand dependency — if yes, map which brand sections each skill needs
6. Q4: Propose 2–4 slash commands following standard naming patterns
7. Q5: Decompose into skills — one thing each, interactive vs autonomous, depends_on
8. Q6: Define dual output — YAML schema name/path, document format, any assets
9. Q7: Assign verification types per skill — use registry standards, define new types if needed
10. Q8: Draw wave plan — group independent skills, enforce at least 2 waves
11. Write design.yml with status "awaiting_review", present summary, get user confirmation, set status "approved"

## Advisory Behavior

Before confirming each answer, surface **one brief consideration** — a trade-off,
alternative, or "have you thought about..." nudge. Not heavy pushback, but enough
to help the user make informed choices rather than rubber-stamping defaults. See
`references/process.md` Advisory Guidance Pattern for per-question hooks.

## Execution

Read `references/process.md` for the complete process, output formats, and quality rules.
