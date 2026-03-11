---
name: context-assembler
description: >
  Assemble relevant context for agent dispatch — reads project map, active task,
  and relevant knowledge skills with token budget awareness.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "assemble context"
  - "context package"
  - "agent context"
  - "prepare dispatch"
reads:
  - ".ai/tasks/decomposed/<task-id>.yml"
  - ".ai/project-map.yml"
writes:
  - ".ai/tasks/context/<task-id>-<subtask-id>.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "task_context_present"
      verify: "Context package includes task description and acceptance criteria"
      fail_action: "Halt — no context package is valid without the active task"
    - name: "budget_respected"
      verify: "Total token estimate does not exceed configured budget ceiling"
      fail_action: "Trim knowledge sections by priority order until within budget"
    - name: "no_stale_project_map"
      verify: "project-map.yml mtime is within 24h or task has no file scope dependency"
      fail_action: "Flag stale map in context package metadata; do not silently use it"
  on_fail: "Context package incomplete — fix flagged issues before dispatch"
  on_pass: "Context package valid — ready for agent-dispatcher"
_source:
  origin: "smedjen"
  inspired_by: "kronen context-manager"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Task-aware context assembly for smedjen agent dispatch"
---

# Context Assembler

Builds a bounded context package for each agent being dispatched. Pulls from the project map, active task definition, and tech-stack-matched knowledge skills — then trims to fit the token budget.

## Inputs

- **Project map** — output from project-mapper: file tree, detected tech stack, module boundaries.
- **Active task** — decomposed subtask from task-decomposer: description, file scope, acceptance criteria, dependencies.
- **Knowledge skills** — smedjen knowledge skills selected by tech stack match (e.g. `nextjs-app-router`, `prisma-patterns`).

## Token Budget Management

Default ceiling: 8,000 tokens per agent context package. Budget allocation:

| Section | Priority | Max tokens |
|---------|----------|------------|
| Task description + acceptance criteria | 1 (required) | 1,500 |
| Relevant file contents (read scope) | 2 | 3,000 |
| Project map excerpt (affected modules) | 3 | 2,000 |
| Knowledge skill summaries | 4 | 1,500 |

If the budget ceiling is breached, trim from lowest priority first. Never drop the task section.

## Context Package Format

Written to `.ai/tasks/context/<task-id>-<subtask-id>.yml`. See `references/process.md` for full schema.

## Key Rules

- Context is assembled per subtask, not per parent task — agents get exactly what they need.
- Knowledge skills are selected by tech stack tag match, not bulk inclusion.
- Duplicate content across agents is deduplicated at the file level — same file is not repeated verbatim.
- If project-map.yml is missing, assemble from file scope only and set `map_available: false`.
- Never include secrets, credentials, or `.env` file contents in a context package.

See `references/process.md` for context sources, budget algorithm, schema, caching, and anti-patterns.
