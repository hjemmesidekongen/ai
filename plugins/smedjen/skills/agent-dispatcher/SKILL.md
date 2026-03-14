---
name: agent-dispatcher
description: >
  Dispatches decomposed subtasks to worker agents with tier-appropriate model
  assignment. Enforces file ownership, includes reference_paths from project
  profile for knowledge loading, collects reports, retries failures once at
  the same tier, then escalates to the next tier. Called after task-decomposer
  and tier-assignment complete.
user_invocable: false
interactive: false
model_tier: senior
depends_on:
  - task-decomposer
  - tier-assignment
triggers:
  - "dispatch agents"
  - "agent dispatch"
  - "parallel execution"
  - "run agents"
  - "parallel agents"
  - "multi-agent execution"
reads:
  - ".ai/tasks/decomposed/*.yml"
  - ".ai/project-map.yml"
writes:
  - ".ai/tasks/dispatched/<task-id>.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "prerequisites_met"
      verify: "Decomposition exists and file ownership is resolved before dispatch"
      fail_action: "Run task-decomposer and resolve ownership first"
    - name: "all_dispatched"
      verify: "Every subtask has a dispatch record with agent_id and status"
      fail_action: "Retry dispatch for missing subtasks"
    - name: "reports_collected"
      verify: "Every dispatched agent returned a completion report"
      fail_action: "Check for timed-out agents and log as failed"
    - name: "no_ownership_violations"
      verify: "No two agents wrote to the same file"
      fail_action: "Log conflict and re-dispatch with corrected ownership"
  on_fail: "Dispatch incomplete — resolve failures before proceeding to completion gate"
  on_pass: "All agents dispatched and reported — ready for completion gate"
_source:
  origin: "smedjen"
  inspired_by: "SA-D009 + SA-D011 decisions"
  ported_date: "2026-03-09"
  iteration: 2
  changes: "Added reference_paths, prerequisites checkpoint, ordering invariants. Removed pipeline dependency."
---

# Agent Dispatcher

Coordinates parallel agent execution. Each agent gets an exclusive file list,
a model tier, relevant skill references, and a focused prompt.

## Hard rules

- NEVER dispatch before file ownership is resolved
- NEVER let an agent self-grade — completion-gate reviews all work
- NEVER skip the same-tier retry before escalating

## Prerequisites (SA-D011)

Before dispatching, verify: (1) decomposition exists, (2) file ownership resolved.

## Dispatch Flow

1. Read decomposed subtasks with tier assignments
2. Load `.ai/project-map.yml` for reference_paths
3. Group by dependency level — independent tasks run in parallel
4. Assign file ownership (no shared files between agents)
5. Build agent prompt with reference_paths from profile's skills field
6. Dispatch via Agent tool at assigned tier
7. Collect reports; retry once at same tier, then escalate
8. Write dispatch records

## reference_paths

Agents receive 1-2 skill reference paths matched to their task's tech stack.
Agent decides whether to read. See `references/process.md` for resolution
algorithm, prompt templates, retry flow, and dispatch record schema.
