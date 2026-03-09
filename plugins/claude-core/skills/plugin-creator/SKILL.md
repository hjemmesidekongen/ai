---
name: plugin-creator
description: >
  Create Claude Code plugins with correct directory structure, plugin.json manifest,
  component organization, and marketplace registration. Use when scaffolding new plugins,
  adding components to existing plugins, or troubleshooting plugin loading issues.
user_invocable: false
interactive: false
depends_on:
  - command-creator
  - skill-creator
  - agent-creator
  - hook-creator
reads:
  - "plugins/*/.claude-plugin/plugin.json"
  - "plugins/*/.claude-plugin/ecosystem.json"
  - "plugins/.claude-plugin/marketplace.json"
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "plugin_json_valid"
      verify: "plugin.json has all required fields with correct types"
      fail_action: "Fix manifest per references/process.md field table"
    - name: "ecosystem_registered"
      verify: "ecosystem.json lists all commands, skills, and agents"
      fail_action: "Add missing components to ecosystem.json arrays"
    - name: "marketplace_entry"
      verify: "Plugin appears in marketplace.json with matching metadata"
      fail_action: "Add entry to plugins/.claude-plugin/marketplace.json"
model_tier: senior
_source:
  origin: "claude-core"
  inspired_by: "https://skills.sh/josiahsiegel/claude-plugin-marketplace/plugin-master"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Adapted from plugin-master skill. Added our ecosystem.json pattern, our marketplace.json location, plugin cache clearing, cross-references to 4 component creator skills, our <=80 line SKILL.md convention."
---

# Plugin Creator

Creates and validates Claude Code plugins for any plugin in this workspace.

## When to trigger

- Scaffolding a new plugin from scratch
- Adding components (commands, skills, agents, hooks) to an existing plugin
- Fixing a plugin that fails to load or register
- Registering a plugin in the marketplace

## Component types

| Type | Purpose | Creator skill |
|------|---------|---------------|
| **Commands** | User-initiated slash commands | command-creator |
| **Skills** | Progressive disclosure knowledge | skill-creator |
| **Agents** | Autonomous multi-step workers | agent-creator |
| **Hooks** | Event-driven automation | hook-creator |

For component-specific guidance, load the corresponding creator skill.
Do not duplicate component-level details here — delegate to the specialist.

## Plugin structure

| Path | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | Manifest (name, version, hooks) |
| `.claude-plugin/ecosystem.json` | Component registry |
| `commands/` | Slash command markdown files |
| `skills/` | Skill directories with SKILL.md |
| `agents/` | Agent markdown files |
| `scripts/` | Hook scripts and utilities |

## Process

See `references/process.md` for the full specification: plugin.json fields,
ecosystem.json format, marketplace registration, naming conventions, creation
workflow, ${CLAUDE_PLUGIN_ROOT} usage, cache management, and pre-commit checklist.
