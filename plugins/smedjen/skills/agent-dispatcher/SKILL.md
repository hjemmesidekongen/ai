---
name: agent-dispatcher
description: >
  Dispatches decomposed subtasks to worker agents with tier-appropriate model
  assignment. Enforces file ownership, collects reports, retries failures once
  at the same tier, then escalates to the next tier.
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
reads:
  - ".ai/tasks/decomposed/*.yml"
writes:
  - ".ai/tasks/dispatched/<task-id>.yml"
checkpoint:
  type: data_validation
  required_checks:
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
  inspired_by: "superpowers-main/skills/dispatching-parallel-agents/SKILL.md + agency agent-dispatcher"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Built for smedjen with tier escalation, file ownership enforcement, and structured dispatch records"
---

# Agent Dispatcher

Coordinates parallel agent execution for decomposed subtasks. Each agent gets an exclusive file list, a model tier, and a focused prompt.

## Dispatch Flow

1. Read decomposed subtasks with tier assignments.
2. Group subtasks by dependency level — independent tasks dispatch in parallel.
3. For each group, assign file ownership (no shared files between agents).
4. Dispatch via the Agent tool with the assigned model tier.
5. Collect completion reports from all agents.
6. Failed agents: retry once at same tier, then escalate one tier up.
7. Write dispatch records to `.ai/tasks/dispatched/<task-id>.yml`.

## Retry and Escalation

| Attempt | Action |
|---------|--------|
| 1st | Dispatch at assigned tier |
| 2nd | Retry at same tier with error context |
| 3rd | Escalate to next tier (junior→senior, senior→principal) |
| After 3rd | Mark as failed, log blocker |

## File Ownership

Before dispatching parallel agents, each agent receives an exclusive file list. If two subtasks need the same file, they are serialized (dispatched sequentially, not in parallel).

## Agent Prompt Template

Each dispatched agent receives:
- Task description and acceptance criteria
- File ownership list (what it may read and write)
- Context files to read first
- Instruction: "Report completion, never mark your own work done"

See `references/process.md` for dispatch schemas, prompt templates, and error handling.
