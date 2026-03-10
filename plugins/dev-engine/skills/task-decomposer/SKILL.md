---
name: task-decomposer
description: >
  Decomposes task descriptions into ordered subtask lists with complexity estimates,
  file scope, dependency chains, and 5-factor risk scores. Handles ambiguity by
  requesting clarification when task scope is insufficiently defined.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "decompose task"
  - "break down task"
  - "task decomposition"
reads: []
writes:
  - ".ai/tasks/decomposed/<task-id>.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "subtask_completeness"
      verify: "Every subtask has description, complexity, file_scope, dependencies, and risk_score"
      fail_action: "Fill missing fields before proceeding"
    - name: "dependency_acyclicity"
      verify: "No circular dependencies in subtask graph"
      fail_action: "Break cycle by splitting the coupled subtask"
    - name: "scope_coverage"
      verify: "Union of subtask file_scopes covers all files implied by the original task"
      fail_action: "Add missing subtasks for uncovered files"
  on_fail: "Decomposition incomplete — fix flagged issues before dispatch"
  on_pass: "Decomposition valid — ready for tier-assignment"
_source:
  origin: "dev-engine"
  inspired_by: "superpowers-main/skills/writing-plans/SKILL.md + executing-plans/SKILL.md"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Built for dev-engine orchestration pipeline with risk scoring and dependency tracking"
---

# Task Decomposer

Breaks a task into an ordered list of subtasks suitable for parallel or sequential agent dispatch.

## Core Algorithm

1. Parse the input task description and any referenced files.
2. Identify logical units of work — each unit should be independently testable.
3. For each subtask, determine: complexity (S/M/L/XL), file scope, dependencies on other subtasks, and a 5-factor risk score.
4. Order subtasks by dependency graph (topological sort).
5. Write the decomposed output to `.ai/tasks/decomposed/<task-id>.yml`.

## Ambiguity Gate

If the task description scores above 3.5 on the ambiguity factor, halt and request clarification. Do not guess at scope — unclear tasks produce bad subtask graphs.

Questions to ask:
- What files or modules are in scope?
- What is the expected end state?
- Are there constraints (performance, backwards compat, etc.)?

## Complexity Sizing

| Size | Rough scope | Typical files |
|------|------------|---------------|
| S | Single function or config change | 1-2 |
| M | Feature within one module | 3-5 |
| L | Cross-module change | 5-10 |
| XL | Architectural change | 10+ |

## Risk Score

Each subtask gets a 5-factor risk vector: `[scope, reversibility, ambiguity, impact, dependencies]`, each 1-5. Feeds into tier-assignment downstream.

## Rules

- Max 12 subtasks per decomposition. If more are needed, split the parent task first.
- Each subtask must have at least one file in its scope.
- Dependencies must reference subtask IDs within the same decomposition.
- If a subtask has no dependencies, mark it as `parallel_eligible: true`.
See `references/process.md` for detailed algorithm, schemas, and examples.
