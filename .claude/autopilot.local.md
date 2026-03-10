---
active: true
iteration: 10
max_iterations: 50
completion_promise: null
started_at: "2026-03-09T22:46:09Z"
---

# Autonomous Build: dev-engine + taskflow

You are running inside an autopilot loop. Each iteration, you receive this same prompt. Your job is to make progress on building two plugins: dev-engine and taskflow.

## FIRST ACTION — Mandatory

Read `.ai/plans/build-dev-engine-and-taskflow/master-state.yml` before doing anything else. Do not skip this. Your entire iteration depends on the current state.

## How This Works
1. Read `master-state.yml` to determine current phase
2. Read `.ai/brainstorm/work-modes-and-jira-workflow/decisions.yml` for architectural decisions (D-001 to D-030)
3. Execute the current phase based on its status
4. Update master-state.yml after completing work
5. When ALL phases are complete, output `<promise>ALL PHASES COMPLETE</promise>`

## Tool Usage

Skills are invoked via the Skill tool, not typed as slash commands. Use these exact names:

| Action | Skill tool invocation |
|--------|----------------------|
| Create a plan | `skill: "claude-core:plan-create"` |
| Execute a plan | `skill: "claude-core:plan-execute"` |
| Resume a plan | `skill: "claude-core:plan-resume"` |
| Check plan status | `skill: "claude-core:plan-status"` |

Do NOT type `/plan:create` as text. Use the Skill tool with the skill name above.

## State Machine

On each iteration, follow this logic:

```
1. Read master-state.yml
2. Find the first phase in build_order where status != "done"
3. Based on that phase's status:
   - "not_started" → Create a plan using Skill tool: claude-core:plan-create
   - "planning" → Resume plan creation if interrupted
   - "in_progress" → Resume with Skill tool: claude-core:plan-resume or claude-core:plan-execute
   - "done" → Move to next phase
4. If ALL phases are "done" → output completion promise
```

## Phase Execution Flow

### Starting a New Phase (with pre-written spec)
1. Read the spec file for this phase (path in build_order)
2. Update master-state.yml: set current_plugin, current_phase, status to "planning"
3. Use Skill tool with `skill: "claude-core:plan-create"` — pass the spec content as context
4. The plan MUST be named exactly as specified in `plan_name` field of build_order
5. After plan is created, update master-state.yml: status to "in_progress", record plan path
6. Use Skill tool with `skill: "claude-core:plan-execute"` to start building

### Starting a New Phase (without pre-written spec — phases 3-5)
1. Read decisions.yml and the completed artifacts from prior phases
2. Write a spec file to `.ai/plans/build-dev-engine-and-taskflow/<plugin>-phase-<N>-spec.md`
3. Update master-state.yml: add the spec path, set status to "planning"
4. The written spec becomes the contract — proceed as with a pre-written spec

### Resuming a Phase
1. Check if there's an active plan at `.ai/plans/<plan_name>/state.yml`
2. Use Skill tool with `skill: "claude-core:plan-status"` to see where you left off
3. Use Skill tool with `skill: "claude-core:plan-resume"` to continue execution

### Completing a Phase
1. All plan tasks must be "done"
2. Run verification checks from the plan verifier
3. Update master-state.yml: mark phase as "done"
4. Do NOT plan the next phase yet — that happens on the next iteration

## Plan Names

Each phase has a fixed plan name. Use these exactly:

| Phase | Plan name |
|-------|-----------|
| dev-engine Phase 1 | `dev-engine-phase-1` |
| taskflow Phase 1 | `taskflow-phase-1` |
| dev-engine Phase 2 | `dev-engine-phase-2` |
| taskflow Phase 2 | `taskflow-phase-2` |
| dev-engine Phase 3 | `dev-engine-phase-3` |

## Build Order
1. dev-engine Phase 1 (core execution loop) — spec: `dev-engine-phase-1-spec.md`
2. taskflow Phase 1 (core task management) — spec: `taskflow-phase-1-spec.md`
3. dev-engine Phase 2 (tech knowledge + disciplines) — spec: write before planning
4. taskflow Phase 2 (full workplace integration) — spec: write before planning
5. dev-engine Phase 3 (polish + integration) — spec: write before planning

## MCP Ownership Rules
- claude-core owns: Atlassian, Azure DevOps, Slack, M365, Figma, Playwright, Storybook, Pencil
- dev-engine owns: Expo (configs only — others deferred to Phase 2)
- See `claude-core-mcp-additions-spec.md` for claude-core MCP additions needed during taskflow Phase 1

## Key Rules (from decisions.yml)
- D-002: Build fresh — study agency and external references, but write new code
- D-005: Never depend on external plugins — port, modify, track source refs
- D-006: Every ported skill includes source_ref
- D-009: Phase N+1 planned only after Phase N is built
- D-017: Agent tiers — Opus for decisions/review, Sonnet for implementation, Haiku for simple tasks
- D-018: Implementing agent never marks own work done
- D-020: Full 10-point completion gate

## External References

Pattern sources referenced in specs are in `external-references/` directory:
- `external-references/superpowers-main/` — writing-plans, executing-plans, dispatching-parallel-agents
- `external-references/agents-main/` — tier model, agent patterns
- `external-references/agent-toolkit-main/` — Jira skill patterns

If a referenced repo or path doesn't exist locally, skip the pattern study and build from the decision description instead. Do not waste iterations searching for missing references.

## Error Recovery

When a plan wave fails verification:
1. Read the error details from state.yml
2. Fix the failing task directly — do not restart the entire wave
3. Re-run verification on the fixed task only
4. If a hook blocks a write, read the hook error log (`.ai/traces/hook-errors.log`) to understand why

When a skill or tool errors out:
1. Log the error in master-state.yml under `errors` array
2. Do not retry the same failing approach — try an alternative
3. If no alternative exists, mark the task as blocked and move on

## Stuck Detection
If you find yourself working on the same task for 3+ iterations with no progress:
1. Log the blocker in master-state.yml under a `blockers` field
2. Skip the blocked task and move to the next one
3. If all remaining tasks are blocked, log the situation and continue to the next phase

## File Paths
- This prompt: `.ai/plans/build-dev-engine-and-taskflow/autopilot-prompt.md`
- Master state: `.ai/plans/build-dev-engine-and-taskflow/master-state.yml`
- Decisions: `.ai/brainstorm/work-modes-and-jira-workflow/decisions.yml`
- Dev-engine Phase 1 spec: `.ai/plans/build-dev-engine-and-taskflow/dev-engine-phase-1-spec.md`
- Taskflow Phase 1 spec: `.ai/plans/build-dev-engine-and-taskflow/taskflow-phase-1-spec.md`
- Claude-core MCP spec: `.ai/plans/build-dev-engine-and-taskflow/claude-core-mcp-additions-spec.md`

## Start
Read master-state.yml now and begin.
