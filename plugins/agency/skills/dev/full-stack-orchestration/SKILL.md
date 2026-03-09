---
name: full-stack-orchestration
description: >
  9-step full-stack feature orchestration with file-based state and phase checkpoints.
  Use when building end-to-end features spanning database, backend, frontend, testing,
  and deployment. Coordinates specialist agents across 3 phases with user approval gates.
user_invocable: false
interactive: false
depends_on: [feature-decomposer, team-planner, agent-dispatcher]
triggers:
  - "full-stack feature"
  - "end-to-end feature"
  - "build complete feature"
  - "feature orchestration"
reads:
  - ".full-stack-feature/*.md"
  - ".ai/projects/*/state.yml"
writes:
  - ".full-stack-feature/*.md"
  - ".full-stack-feature/state.json"
checkpoint:
  type: data_validation
  required_checks:
    - name: "state_file_exists"
      verify: ".full-stack-feature/state.json exists with correct status"
      fail_action: "Initialize state.json before proceeding"
    - name: "phase_outputs_exist"
      verify: "All numbered output files exist for completed steps"
      fail_action: "Re-run missing step before advancing"
model_tier: senior
_source:
  origin: "agency"
  inspired_by: "agents-main/plugins/full-stack-orchestration/commands/full-stack-feature.md"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Adapted from 594-line command to skill with SKILL.md router + references/process.md. Mapped agent types to agency agents. Added integration with agency:build pipeline."
---

# Full-Stack Feature Orchestration

Coordinates end-to-end feature development across 9 steps in 3 phases.

## When to trigger

- Building a feature that spans database + backend + frontend
- Agency:build dispatches a complex feature requiring structured orchestration
- User requests end-to-end feature development with checkpoints

## Pipeline overview

| Phase | Steps | Focus | Gate |
|-------|-------|-------|------|
| 1: Design | 1-3 | Requirements → DB design → Architecture | User approval |
| 2: Build | 4-7 | DB impl → Backend → Frontend → Test+Security+Perf | User approval |
| 3: Ship | 8-9 | Deployment config → Documentation | Complete |

## State management

All state persists in `.full-stack-feature/`:
- `state.json` — current step, completed steps, files created
- `01-requirements.md` through `09-documentation.md` — numbered outputs

Each step reads from prior output files, not context memory. This survives compaction.

## Session resume

If `.full-stack-feature/state.json` exists with `status: "in_progress"`, resume from `current_step`. Never restart without user confirmation.

## Integration with agency:build

When agency:build identifies a feature requiring full-stack orchestration:
1. Feature-decomposer breaks the feature into tasks
2. Team-planner assigns agents
3. This skill coordinates the 9-step pipeline for complex tasks
4. Completion-gate validates the final output

## Full process

For the complete 9-step specification with agent prompts, output formats, checkpoint protocols, and parallel execution patterns, read [references/process.md](references/process.md).
