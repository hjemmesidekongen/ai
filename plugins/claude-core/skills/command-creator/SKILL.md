---
name: command-creator
description: >
  Create, modify, or debug Claude Code slash commands with correct frontmatter,
  dynamic arguments, file references, and bash execution. Use when adding commands
  to any plugin, fixing broken or invisible commands, configuring argument-hint or
  positional arguments, namespacing commands with subdirectory prefixes, or building
  multi-step command workflows.
user_invocable: false
interactive: false
depends_on: []
triggers:
  - "create command"
  - "add slash command"
  - "fix broken command"
  - "command not showing"
  - "command arguments"
reads:
  - "plugins/*/commands/**/*.md"
  - ".claude/commands/**/*.md"
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "command_renders"
      verify: "Command file has valid frontmatter and renders in /help"
      fail_action: "Fix frontmatter syntax or file location"
    - name: "arguments_resolve"
      verify: "$ARGUMENTS and positional args resolve correctly when invoked"
      fail_action: "Check variable syntax and argument-hint alignment"
    - name: "registered_in_ecosystem"
      verify: "Command appears in ecosystem.json commands array if plugin-bundled"
      fail_action: "Add command entry to ecosystem.json"
model_tier: senior
_source:
  origin: "claude-core"
  inspired_by: "https://skills.sh/anthropics/claude-plugins-official/command-development"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Adapted from Anthropic command-development skill. Added <=80 line SKILL.md pattern, references/process.md overflow, checkpoint verification, plugin cache clearing, ecosystem.json registration."
---

# Command Creator

Creates and validates Claude Code slash commands for any plugin in this workspace.

## When to trigger

- Creating a new slash command for any plugin
- Fixing a broken or invisible command
- Adding dynamic arguments, file references, or bash execution to a command
- Registering commands in ecosystem.json

## Command locations

| Scope | Directory | Invocation |
|-------|-----------|------------|
| **Project** | `.claude/commands/` | `/command-name` |
| **Personal** | `~/.claude/commands/` | `/command-name` |
| **Plugin** | `plugins/<name>/commands/` | `/plugin:command-name` |

## Core concepts

| Concept | Summary |
|---------|---------|
| Frontmatter | YAML block with description, allowed-tools, model, argument-hint |
| Dynamic args | `$ARGUMENTS` (all), `$1`/`$2`/`$3` (positional) |
| File refs | `@filename` injects file contents via Read tool |
| Bash execution | `` `! command` `` runs shell and injects output |
| Namespacing | Subdirectories become prefixes: `dev/lint.md` = `/dev:lint` |

## Process

See `references/process.md` for the full specification: frontmatter fields, argument
patterns, file references, bash execution, plugin registration, testing, and checklist.
