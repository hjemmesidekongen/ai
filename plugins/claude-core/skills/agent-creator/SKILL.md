---
name: agent-creator
description: >
  Create autonomous Claude Code agents with correct frontmatter, triggering examples,
  system prompts, and tool restrictions. Use when adding agents to any plugin,
  defining agent behavior, or configuring agent model and tool access.
user_invocable: false
interactive: false
depends_on: []
reads:
  - "plugins/*/agents/**/*.md"
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "agent_triggers"
      verify: "Description includes 2-4 concrete triggering examples with context"
      fail_action: "Add examples showing when this agent should activate"
    - name: "system_prompt_structured"
      verify: "System prompt defines role, responsibilities, process, and output format"
      fail_action: "Structure prompt per references/process.md template"
    - name: "tools_least_privilege"
      verify: "Tool list is minimal — only what the agent needs"
      fail_action: "Remove unnecessary tools, scope to actual requirements"
model_tier: senior
_source:
  origin: "claude-core"
  inspired_by: "https://skills.sh/anthropics/claude-plugins-official/agent-development"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Adapted from Anthropic agent-development skill. Added our <=80 line pattern, references/process.md overflow, our agent directory conventions, tier system, checkpoint verification."
---

# Agent Creator

Creates and validates Claude Code agents for any plugin in this workspace.

## When to trigger

- Adding a new autonomous agent to a plugin
- Defining agent behavior, model tier, or tool access
- Setting up agent triggering examples and system prompts
- Organizing agents into plugin directory structure

## Agent vs command — quick reference

| Dimension | Agent | Command |
|-----------|-------|---------|
| **Invocation** | Auto-triggered by matching user intent | Explicit `/plugin:command` |
| **Autonomy** | Runs independently, makes decisions | Single action, returns result |
| **Scope** | Multi-step workflows | Focused operations |
| **Model** | Configurable per agent | Inherits session model |

Default to commands for deterministic operations. Use agents for autonomous multi-step work.

## Process

See `references/process.md` for the full specification: frontmatter fields, triggering
examples format, system prompt structure, model/color selection, tool restrictions,
directory layout, tier system, testing protocol, and pre-commit checklist.
