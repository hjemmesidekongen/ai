---
name: skill-creator
description: >
  Create new skills, modify and improve existing skills, and measure skill performance.
  Use when users want to create a skill from scratch, edit or optimize an existing skill,
  run evals to test a skill, benchmark skill performance with variance analysis,
  optimize a skill's description for better triggering accuracy, or run a TDD
  baseline eval before writing a skill to target real behavior violations.
user_invocable: false
interactive: false
depends_on: []
triggers:
  - "create skill"
  - "modify skill"
  - "skill eval"
  - "skill triggering accuracy"
  - "benchmark skill"
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

Keep SKILL.md short. Overflow goes to `references/process.md`.

## Evaluation

Run evals after creating a skill: trigger eval, task eval, benchmark (A/B), description
optimization. Scripts: `scripts/run_eval.py`, `scripts/aggregate_benchmark.py`,
`scripts/improve_description.py`. Eval agents: `agents/grader.md`, `comparator.md`,
`analyzer.md`. Full eval pipeline and schemas: `references/process.md`.

## NEVER
- Create a skill without frontmatter or with incomplete frontmatter
- Exceed 80 lines in SKILL.md — overflow goes to references/process.md
- Use second-person pronouns ("you") in skill descriptions
- Skip checkpoint definition — every skill needs verification
- Add model_tier values outside junior/senior/principal

Quality scored on 8 dimensions (120 points). Most important: **knowledge delta**. Full framework: `references/quality-dimensions.md`. Progressive disclosure: `references/progressive-disclosure.md`.
