---
name: team-planner
user-invocable: false
description: >
  Phase 2 of /agency:dev:build — PM creates work packages from decomposition, dispatches
  Frontend and Backend Tech Leads to assign specialists and model tiers, verifies file
  ownership overlap, and assembles the final wave plan. Components with source=existing_spec
  skip design task creation (specs already done). Frontend TL receives design token paths.
  Use when planning team execution, assigning agent tiers, checking file overlap, or
  assembling wave plans for /agency:dev:build phase 2.
phase: 2
depends_on: [feature-decomposer]
writes:
  - ".ai/projects/[name]/dev/team-state.yml (wave_plan section)"
reads:
  - ".ai/projects/[name]/dev/team-state.yml (decomposition section)"
  - ".ai/projects/[name]/dev/dev-config.yml"
  - ".ai/projects/[name]/design/component-specs/ (optional, reuse check)"
  - ".ai/projects/[name]/design/tokens/ (optional, passed to Frontend TL)"
model_tier: principal
interactive: true
checkpoint:
  type: data_validation
  required_checks:
    - name: "waves_exist"
      verify: "At least 1 wave in team-state.yml wave_plan.waves"
      fail_action: "Re-run PM wave assembly with simplified grouping"
    - name: "task_fields_complete"
      verify: "Every task has non-empty: id, description, assigned_agent, model_tier, component, files_owned"
      fail_action: "Fill missing fields from TL assignments or defaults"
    - name: "no_file_overlap"
      verify: "No two tasks in the same wave own the same file"
      fail_action: "Resequence conflicting tasks into separate waves"
    - name: "components_covered"
      verify: "Every component from decomposition.components has at least 1 task"
      fail_action: "Create tasks for uncovered components"
    - name: "tl_signoff"
      verify: "frontend_tl_approved and backend_tl_approved fields present in wave_plan"
      fail_action: "Dispatch TL agents for final review"
    - name: "user_confirmed"
      verify: "User explicitly confirmed the wave plan"
      fail_action: "Present wave plan to user for confirmation"
  on_fail: "Fix issues and re-run checkpoint. Do not advance to Phase 3."
  on_pass: "Update team-state.yml status to executing, advance to Phase 3."
---

# Team Planner

Phase 2 of /agency:dev:build. PM creates work packages from decomposition, dispatches
Frontend and Backend Tech Leads to assign specialists with model tiers, verifies file
ownership, and assembles the wave plan. Components with source=existing_spec skip design
tasks. Frontend TL receives design token paths for brand-consistent implementation.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | team-state.yml decomposition, dev-config.yml, design tokens (optional) |
| **Writes** | team-state.yml wave_plan section (waves, tasks, file_ownership) |
| **Checkpoint** | data_validation: waves exist, tasks complete, no file overlap, components covered, TL sign-off, user confirmed |
| **Dependencies** | feature-decomposer (decomposition must exist) |

## PM-TL Negotiation Summary

1. PM checks designer_specs[].source — skip design tasks for components where source=existing_spec
2. PM creates work packages from components (1+ tasks per component, ≤5 files per task)
3. Frontend TL assigns frontend tasks to specialists (receives design token paths if available)
4. Backend TL assigns backend tasks to specialists with model tiers
5. PM checks file overlap — no two tasks in same wave touch same file
6. If overlap: negotiate resolution (resequence, merge, or split)
7. PM assembles wave plan: independent tasks → parallel waves, dependent → sequential
8. Present plan to user — one question at a time
9. User confirms or adjusts → write to team-state.yml

## Findings Persistence

Write to `.ai/projects/[name]/dev/findings.md`. **2-Action Rule:** After every 2 planning operations, save findings immediately.

## Error Logging — Log errors to state.yml errors array. Check errors before retrying.
## Execution — [references/process.md](references/process.md)
