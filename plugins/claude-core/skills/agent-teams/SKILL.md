---
name: agent-teams
description: |
  Parallel team execution patterns for multi-agent workflows. Use when planning
  parallel agent dispatch, choosing team compositions (review, debug, feature,
  research, security teams), or integrating with Agent Teams experimental API.
  Covers file ownership rules, task coordination, and integration patterns.
user_invocable: true
interactive: true
depends_on: []
reads: []
writes: []
triggers:
  - agent teams
  - parallel agents
  - team composition
  - parallel execution
  - concurrent agents
checkpoint:
  type: data_validation
  required_checks:
    - name: "team_dispatched"
      verify: "Team composition selected and agents dispatched with file ownership"
      fail_action: "Verify team preset matches use case and retry dispatch"
  on_fail: "Re-evaluate team composition"
  on_pass: "Team dispatched with file ownership isolation"
model_tier: sonnet
_source:
  origin: original
  ported_date: "2026-03-09"
  iteration: 1
  changes: ["initial creation"]
---

# Agent Teams

Patterns for parallel agent execution using Claude Code's Agent Teams feature or manual parallel dispatch via the Agent tool.

## Team Presets

| Team | Agents | Use Case |
|------|--------|----------|
| **Review** | 3 parallel reviewers (security, performance, architecture) | Code review, PR review |
| **Debug** | N investigators (one per hypothesis) | Root cause investigation |
| **Feature** | 1 lead + 2 implementers | Feature development with file ownership |
| **Fullstack** | 1 lead + frontend + backend + test | End-to-end feature build |
| **Research** | 3 general-purpose agents | Parallel research questions |
| **Security** | 4 reviewers (OWASP, auth, deps, config) | Security audit |
| **Migration** | 1 lead + 2 implementers + 1 reviewer | Large-scale migration |

## File Ownership (Cardinal Rule)

One owner per file — no concurrent modifications. Period.

- When files must be shared: designate one owner, others request changes sequentially
- Extract interface contracts at boundaries (owned by lead, read-only for implementers)
- Use the `file-ownership` skill to decompose work into conflict-free streams

## Task Coordination

- Minimize dependency chain depth — wide, shallow graphs beat deep chains
- Use `blockedBy`/`blocks` only for true dependencies
- Design interface contracts at integration boundaries before implementation

## Integration Patterns

| Pattern | When | How |
|---------|------|-----|
| **Vertical slice** | Low coupling between features | Each agent builds full UI + API + tests for one feature |
| **Horizontal layer** | Shared data model | Each agent owns one layer across features |
| **Hybrid** | Mixed coupling | Vertical for independent features, horizontal for shared |

## Current Status

Agent Teams requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` and tmux or iTerm2. The patterns in this skill work regardless — they apply to both native Agent Teams and manual parallel dispatch via the Agent tool.

For full team sizing, display modes, and coordination strategies: `references/process.md`.
