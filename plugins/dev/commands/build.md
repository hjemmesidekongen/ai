---
name: build
command: "/dev:build"
description: "Decompose a feature, plan agent assignments, execute with parallel agents, and review the result"
arguments:
  - name: feature-description
    type: string
    required: true
    description: "Natural language description of what to build"
  - name: brand
    type: string
    required: false
    description: "Load brand context for planning and design agents (e.g., 'acme-corp')"
  - name: dry-run
    type: boolean
    required: false
    default: false
    description: "Decompose and plan but don't execute — write plan to team-state.yml and stop"
  - name: wave
    type: number
    required: false
    description: "Resume from a specific wave number (for recovery)"
---

# /dev:build

Main workflow — take a feature description, decompose it into components, plan agent assignments, execute with parallel agents, and review the result. This is the primary command for building features with the dev agent team.

## Usage

```
/dev:build "Add user authentication with JWT and role-based access"
/dev:build "Redesign the dashboard" --brand acme-corp
/dev:build "Add payment integration" --dry-run
/dev:build "Add payment integration" --wave 3
```

## Purpose

Orchestrates the full 4-phase build lifecycle:
- **Phase 1 — Decompose:** PM + Architect + Designer + PO decompose the feature into components with boundaries and file ownership
- **Phase 2 — Plan:** PM + Tech Leads assign tasks to agents, set tiers, verify file overlap, and build a wave plan
- **Phase 3 — Execute:** Agent dispatcher sends tasks to specialist agents in parallel waves, completion gate verifies each
- **Phase 4 — Review:** Code review audits the diff, QA validation checks spec alignment, build report generated

## Prerequisites

- `/dev:init` must have been run (dev-config.yml must exist at `~/.claude/dev/[project-name]/`)
- Task-planner plugin must be active
- For `--brand`: brand-guideline plugin installed with generated brand data

## Input

- `[feature-description]` (required) — natural language description of what to build
- `--brand [name]` (optional) — load brand context for design-aware planning and agent guidance
- `--dry-run` (optional) — decompose and plan only; writes plan to team-state.yml without executing
- `--wave [N]` (optional) — resume from wave N (reads existing team-state.yml, skips phases 1-2)

Interactive prompts during execution:
- Phase 1: Confirms the decomposition (components, boundaries, file ownership)
- Phase 2: Reviews the wave plan before execution begins

## Execution Strategy

### Interactive Phases (sequential — each needs user confirmation)

#### Phase 0: Validate Prerequisites

Read `~/.claude/dev/[project-name]/dev-config.yml`. If missing:
- Error: "Project not initialized. Run `/dev:init` first."
- Exit

If `--wave [N]` provided: skip to Phase 3 Resume below.

#### Phase 1: Initialize + Decompose

1. Create `~/.claude/dev/[project-name]/team-state.yml` with build metadata:

```yaml
build:
  feature_description: "[user's feature description]"
  status: "decomposing"
  current_phase: 1
  started_at: "[timestamp]"
```

2. If `--brand` flag provided: run brand-context-loader to load brand data into findings.md

3. Read SKILL.md at `plugins/dev/skills/feature-decomposer/SKILL.md`, follow its process.

This skill: PM + Architect + Designer + PO collaborate to break the feature into components with boundaries, dependencies, and files_affected. Results are written to `team-state.yml` decomposition section.

#### Phase 2: Plan

Read SKILL.md at `plugins/dev/skills/team-planner/SKILL.md`, follow its process.

This skill: PM + Tech Leads assign tasks to agents, set model tiers, verify file overlap across tasks, and build a wave plan. Results are written to `team-state.yml` wave_plan section.

If `--dry-run`: present the wave plan summary to the user and stop. Update `build.status` to "planned". Exit.

### Planned Phases (use task-planner for parallel wave dispatch)

#### Phase 3: Execute

Call `/plan:create` with:
- Tasks: from `team-state.yml` wave_plan (each task with assigned_agent, model_tier, files_owned)
- Verification profile: `dev_profile`
- QA frequency: `every_wave`

Call `/plan:execute` to run the plan:
- `agent-dispatcher` dispatches tasks to specialist agents
- `tier-assigner` handles self-tiering adjustments
- `completion-gate` verifies each agent's output (build, lint, tests)

#### Phase 4: Review

After all execution waves complete:
- `code-review` skill audits the full diff (base_sha to HEAD)
- `qa-validation` skill validates the build against the original spec
- Build report generated and written to `~/.claude/dev/[project-name]/build-report.md`

Present the build report to the user.

#### Phase 3 Resume (--wave N)

When `--wave [N]` is provided:
1. Read existing `~/.claude/dev/[project-name]/team-state.yml`
2. Verify decomposition and wave_plan sections exist
3. Call `/plan:resume` at wave N — task-planner handles wave-level recovery
4. Continue with Phase 4 review after execution completes

## Output

- Code committed to repository (by specialist agents during Phase 3)
- `~/.claude/dev/[project-name]/team-state.yml` — full execution record (decomposition, wave plan, agent reports, review results)
- `~/.claude/dev/[project-name]/build-report.md` — human-readable build report with spec alignment score and PO sign-off

## Recovery

Check `team-state.yml` at `~/.claude/dev/[project-name]/`. The `build.status` field indicates where the build stopped:

| Status | Recovery |
|--------|----------|
| decomposing | Re-run `/dev:build` — Phase 1 will re-run |
| planning | Re-run `/dev:build` — reads existing decomposition, re-plans |
| planned | Re-run `/dev:build` without `--dry-run` to start execution |
| executing | Resume with `/dev:build --wave N` where N is the last incomplete wave |
| reviewing | Re-run Phase 4 skills manually or wait for review to complete |
| completed | Build is done — view report at build-report.md |
| failed | Check build-report.md for failure details, fix issues, re-run affected wave |

Task-planner's `/plan:resume` handles wave-level recovery within Phase 3.

## Error Handling

- **dev-config.yml missing:** Error message directing user to run `/dev:init` first
- **Decomposition fails:** team-state.yml preserves partial state; re-run restarts Phase 1
- **Agent execution fails:** task-planner retries per wave; failures logged to state.yml errors array
- **Review fails (spec alignment < 70%):** QA presents gaps and options: fix tasks, accept as-is, or abort
