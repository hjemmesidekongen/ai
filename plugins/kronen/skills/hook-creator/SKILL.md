---
name: hook-creator
description: >
  Create, modify, or debug Claude Code hooks with correct event types, exit codes,
  JSON output formats, and shell best practices. Use when adding hooks to any plugin,
  fixing broken or silent hooks, blocking or allowing specific tools via PreToolUse,
  adding guards for SessionStart or Stop events, registering hooks in plugin.json,
  or converting hooks between types (command, prompt, HTTP, agent).
user_invocable: false
interactive: false
depends_on: []
triggers:
  - "create hook"
  - "add PreToolUse hook"
  - "fix silent hook"
  - "hook not firing"
  - "blocking hook"
  - "SessionStart hook"
reads:
  - "plugins/*/.claude-plugin/plugin.json"
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "hook_runs_clean"
      verify: "Hook script exits 0 when tested with sample input"
      fail_action: "Fix script errors and re-test"
    - name: "json_output_valid"
      verify: "Output is parseable JSON matching event-specific schema"
      fail_action: "Fix JSON structure per references/process.md"
    - name: "registered_in_plugin_json"
      verify: "Hook is registered in the target plugin's plugin.json"
      fail_action: "Add hook entry to plugin.json hooks section"
model_tier: senior
_source:
  origin: "kronen"
  inspired_by: "https://docs.anthropic.com/en/docs/claude-code/hooks"
  ported_date: "2026-03-09"
  iteration: 2
  changes: "v2: Added 9 events (18 total), HTTP and agent hook types, new handler fields (statusMessage, once, async), updated input fields, corrected tool_response naming and timeouts per official docs."
---

# Hook Creator

Creates and validates Claude Code hooks for any plugin in this workspace.

## When to trigger

- Creating a new hook for any event type
- Fixing a broken or misbehaving hook
- Converting between hook types (command, prompt, HTTP, agent)
- Adding hooks to plugin.json or skill/agent frontmatter

## Hook types

| Type | Best for | Events supported |
|------|----------|-----------------|
| **command** | Deterministic checks, file I/O, logging | All events |
| **prompt** | Context-aware LLM decisions | PreToolUse, Stop, SubagentStop, UserPromptSubmit |
| **http** | External service integration, webhooks | All events |
| **agent** | Multi-step autonomous tasks (50-turn limit) | All events |

Default to command hooks. Use prompt hooks only when the decision requires LLM reasoning.
Use HTTP hooks for webhooks/external integrations. Use agent hooks for complex multi-step logic.

## NEVER
- Create a hook without registering it in plugin.json
- Use prompt hooks for deterministic checks (use command hooks)
- Skip exit code testing — hooks fail silently on bad exit codes
- Hardcode file paths — use $HOOK_WORKING_DIR for portability
- Leave hooks unquoted when variables may contain spaces

## Process

See `references/process.md` for the full specification: 18 event types, 4 hook types,
input/output schemas, exit codes, shell conventions, testing protocol, and registration.
