---
name: agent-dispatcher
user-invocable: false
description: >
  Phase 3 of /agency:build — dispatch consolidated specialist agents (frontend-worker,
  backend-worker, project-manager, etc.) via Task() for isolated parallel execution,
  manage wave sequencing, map model_tier values to dispatch params (junior→Haiku,
  senior→Sonnet, principal→Opus), collect structured reports, and update execution
  state. Also includes brand context for UI tasks. Use when dispatching agents,
  running /agency:build phase 3, executing wave plans, managing parallel task
  dispatch, or collecting subagent reports.
phase: 3
depends_on: [team-planner]
writes:
  - ".ai/projects/[name]/project-state.yml (execution section)"
reads:
  - ".ai/projects/[name]/project-state.yml (wave_plan section)"
  - ".ai/projects/[name]/project-state.yml (dev module)"
  - ".ai/projects/[name]/knowledge/*.yml (tag-filtered per task)"
model_tier: senior
model: sonnet
interactive: false
checkpoint:
  type: data_validation
  required_checks:
    - name: "tasks_dispatched"
      verify: "All tasks in the current wave have status completed or failed in execution.dispatched_tasks"
      fail_action: "Check for hung dispatches, re-dispatch failed tasks with escalated tier"
    - name: "reports_collected"
      verify: "Every completed task has a subagent report with non-empty files_changed list"
      fail_action: "Re-dispatch task to collect missing report"
    - name: "commits_recorded"
      verify: "Every completed task has a non-empty commit_sha"
      fail_action: "Run git log to recover commit SHA from task's commit message"
    - name: "wave_tracking"
      verify: "execution.current_wave is updated to the current wave number"
      fail_action: "Update execution.current_wave from dispatched_tasks records"
    - name: "commit_range"
      verify: "execution.commit_range has base_sha and head_sha populated"
      fail_action: "Record base_sha from wave start, head_sha from git rev-parse HEAD"
  on_fail: "Fix issues and re-run checkpoint. Do not advance to Phase 4."
  on_pass: "Update project-state.yml status, hand off to completion-gate."
---

# Agent Dispatcher

Phase 3 of /agency:build. Reads the wave plan, dispatches specialist agents via Task() with model tier mapping, manages parallel vs sequential waves, and collects structured reports.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | project-state.yml wave_plan and dev module, knowledge files (tag-filtered) |
| **Writes** | project-state.yml execution section (dispatched_tasks, commit_range) |
| **Checkpoint** | data_validation: tasks dispatched, reports collected, commits recorded, wave tracking, commit range |
| **Dependencies** | team-planner (wave_plan must exist) |

## Dispatch Flow Summary

1. Read wave_plan from project-state.yml — get waves, tasks, assignments, tiers
2. For each wave in sequence:
   a. Record base_sha (git rev-parse HEAD)
   b. Build dispatch prompts: task description, agent role, file ownership, knowledge, conventions
   c. Map model_tier: junior → Haiku, senior → Sonnet, principal → Opus
   d. Self-tiering agents: dispatch at Haiku first (tier-assigner), then at declared tier
   e. Parallel waves: dispatch all tasks simultaneously (multiple Task() calls)
   f. Sequential waves: dispatch one at a time, wait for completion
   g. Collect subagent reports: files_changed, commit_sha, notes, gate_results
   h. Update project-state.yml execution section with dispatch records
3. Record wave commit range (base_sha → current HEAD)
4. Pass to completion-gate for verification

## Findings Persistence

Write dispatch records to `.ai/projects/[name]/findings.md`.
**2-Action Rule:** After every 2 Task() dispatches, save dispatch records and reports immediately.

## Error Logging — Log errors to project-state.yml errors array. Check errors before retrying.

## Execution — [references/process.md](references/process.md)
