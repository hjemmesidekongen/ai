---
name: stack-negotiation
user-invocable: false
description: >
  Interactive stack negotiation between project-scanner and config-generator.
  Presents scanner findings to the user, classifies decisions into three tiers
  (always-ask, ask-if-ambiguous, silent), negotiates the confirmed stack with
  MCP-aware recommendations and workspace context. Profile-aware — personal
  profiles get fast-path confirmation, work profiles get full negotiation.
phase: 2
depends_on: [project-scanner]
reads:
  - ".ai/projects/[name]/dev/findings.md"
  - ".ai/profiles/{profile}.yml"
writes:
  - ".ai/projects/[name]/dev/stack.yml"
model_tier: senior
model: sonnet
interactive: true
checkpoint:
  type: data_validation
  required_checks:
    - name: "stack_exists"
      verify: "stack.yml exists at .ai/projects/[name]/dev/stack.yml"
      fail_action: "Write current stack state to stack.yml immediately"
    - name: "always_ask_confirmed"
      verify: "All always-ask tier items have explicit user confirmation logged"
      fail_action: "Re-prompt user for unconfirmed always-ask items"
    - name: "decision_sources_logged"
      verify: "Every decision in stack.yml has a source field (profile_default, user_choice, workspace_match, scanner_detection, silent_default)"
      fail_action: "Add missing source fields by reviewing findings.md and interaction log"
    - name: "mcp_recommendations_surfaced"
      verify: "MCP servers from findings.md were surfaced as recommendations (or 'none found')"
      fail_action: "Re-read findings.md MCP Servers section and present recommendations"
    - name: "stack_confirmed"
      verify: "User explicitly confirmed the final stack summary"
      fail_action: "Present stack summary and ask for confirmation"
  on_fail: "Fix issues and re-run checkpoint. Do not advance until all checks pass."
  on_pass: "Update state.yml, write recovery_notes, advance to config-generator."
---

# Stack Negotiation

Phase 2 of /agency:dev:init. Sits between project-scanner and config-generator. Reads scanner findings + active profile, classifies technology decisions into three tiers, negotiates the confirmed stack interactively, and outputs stack.yml for config-generator.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | findings.md (scan results + MCP servers + workspace context + shared configs), profile YAML |
| **Writes** | stack.yml (confirmed technology stack with decision sources) |
| **Checkpoint** | 5 checks: stack exists, always-ask confirmed, sources logged, MCP surfaced, user confirmed |
| **Dependencies** | project-scanner (must run first to produce findings.md) |

## Decision Tiers

| Tier | Items | When to Prompt |
|------|-------|---------------|
| **Always-ask** | Framework, CSS approach, component library, icon library | Always — even if profile has defaults |
| **Ask-if-ambiguous** | Auth provider, database, API style (REST/GraphQL/tRPC) | Only if scanner found conflicts or nothing detected |
| **Silent** | Linting, formatting, tsconfig | Apply defaults without asking; surface only if conflicts found |

## Profile Modes

- **Personal ("confirm"):** Show defaults, ask "Use these? [Y/n]" — fast path
- **Work ("full"):** Full negotiation for always-ask + ask-if-ambiguous tiers

## Rules

- **Findings:** Write to `.ai/projects/[name]/dev/findings.md`. **2-Action Rule:** save after every 2 interactions.
- **Errors:** Log to state.yml errors array. Check before retrying — never repeat a failed approach.
- **Shared configs:** Extend, don't duplicate. Never edit shared packages.
- **Execution:** Follow [references/process.md](references/process.md).
