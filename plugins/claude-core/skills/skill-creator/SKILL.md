---
name: skill-creator
description: >
  Create new Claude Code skills with correct SKILL.md structure, frontmatter fields,
  progressive disclosure, and resource organization. Use when building skills for any
  plugin, structuring skill content, or validating skill files.
user_invocable: false
interactive: false
depends_on: []
reads:
  - "plugins/*/skills/*/SKILL.md"
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "skill_md_valid"
      verify: "SKILL.md has valid YAML frontmatter with all required fields"
      fail_action: "Fix frontmatter per references/process.md field table"
    - name: "line_budget_met"
      verify: "SKILL.md ≤80 lines, overflow in references/"
      fail_action: "Move detailed content to references/process.md"
    - name: "description_triggers"
      verify: "Description includes concrete trigger scenarios"
      fail_action: "Add 'Use when...' phrases with specific user actions"
model_tier: senior
_source:
  origin: "claude-core"
  inspired_by: "https://skills.sh/anthropics/claude-plugins-official/skill-development"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Adapted from Anthropic skill-development skill. Enforces our ≤80 line SKILL.md rule, references/process.md overflow pattern, _source block, checkpoint verification, ecosystem.json registration."
---

# Skill Creator

Creates and validates Claude Code skills for any plugin in this workspace.

## When to trigger

- Building a new skill from scratch
- Structuring skill content across SKILL.md and references/
- Validating frontmatter fields and line budget
- Porting an external skill to local conventions

## Skill structure

| File | Purpose | Required |
|------|---------|----------|
| `SKILL.md` | Frontmatter + brief body (≤80 lines) | Yes |
| `references/process.md` | Full specification, tables, examples | When body overflows |
| `references/*.md` | Additional reference material | No |
| `scripts/` | Automation scripts for the skill | No |
| `assets/` | Templates, schemas, static resources | No |

Keep SKILL.md short: when to trigger, quick overview, pointer to references/.
Detailed process, tables, examples, and checklists belong in `references/process.md`.

## Evaluation

After creating a skill, run evaluations to verify triggering accuracy and task completion.

| Mode | Purpose | Script |
|------|---------|--------|
| Trigger eval | Does the description cause skill activation? | `scripts/run_eval.py` |
| Task eval | Can the skill complete complex tasks? | `scripts/run_eval.py` |
| Benchmark | A/B comparison across multiple runs | `scripts/aggregate_benchmark.py` |
| Description optimization | Iterative improvement of trigger phrases | `scripts/improve_description.py` |

Eval agents (`agents/grader.md`, `comparator.md`, `analyzer.md`) handle grading, blind
comparison, and post-hoc analysis. See `references/process.md` for the full eval pipeline
and `references/schemas.md` for eval JSON schemas.

## Process

See `references/process.md` for the full specification: frontmatter fields, description
writing, content organization, the 80-line rule, progressive disclosure, checkpoint
patterns, ecosystem.json registration, the 6-step creation workflow, and the evaluation
pipeline.
