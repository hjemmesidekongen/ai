# Hook Creator — Full Reference

## Events

| Event | Trigger | Can block? | Input fields | Matcher target |
|-------|---------|------------|-------------|----------------|
| **PreToolUse** | Before tool execution | Yes (deny) | `tool_name`, `tool_input` | Tool name |
| **PostToolUse** | After tool completion | No | `tool_name`, `tool_input`, `tool_response` | Tool name |
| **PostToolUseFailure** | After tool execution fails | No | `tool_name`, `tool_input`, `tool_response` | Tool name |
| **Stop** | Agent considering halt | Yes (block) | `stop_reason`, `transcript_path` | — |
| **SubagentStop** | Subagent finishing | Yes (block) | `transcript_path` | — |
| **SubagentStart** | Subagent spawning | Yes (block) | `agent_type`, `agent_id` | Agent type |
| **UserPromptSubmit** | User input received | Yes (block) | user prompt content | — |
| **PermissionRequest** | Permission check triggered | Yes | `tool_name`, `tool_input`, `permission_type` | Tool name |
| **SessionStart** | Session initialization | No | `cwd` | — |
| **SessionEnd** | Session termination | No | — | — |
| **PreCompact** | Before context compression | No | — | — |
| **Notification** | Claude sends notification | No | notification content | — |
| **TeammateIdle** | Teammate agent goes idle | No | `agent_id`, `agent_type` | Agent type |
| **TaskCompleted** | Background task finishes | No | `task_id`, `task_result` | — |
| **InstructionsLoaded** | CLAUDE.md / plugin instructions loaded | No | instruction source paths | — |
| **ConfigChange** | Configuration modified | No | changed config keys | — |
| **WorktreeCreate** | Git worktree created | No | `worktree_path`, `branch` | — |
| **WorktreeRemove** | Git worktree removed | No | `worktree_path` | — |

### Per-event matcher behavior

Matchers control which specific instances of an event trigger the hook:

| Event | Matcher matches against | Example |
|-------|------------------------|---------|
| PreToolUse | `tool_name` | `"Write\|Edit"` |
| PostToolUse | `tool_name` | `"Bash"` |
| PostToolUseFailure | `tool_name` | `"Bash"` |
| SubagentStart | `agent_type` | `"Explore"` |
| PermissionRequest | `tool_name` | `"mcp__.*__delete.*"` |
| TeammateIdle | `agent_type` | `"task-planner:worker"` |
| All others | No matcher — hook fires on every occurrence | *(omit matcher)* |

### MCP tool matching

MCP tools follow the pattern `mcp__<server>__<tool>`. Use regex matchers:

| Pattern | Matches |
|---------|---------|
| `"mcp__slack__.*"` | All Slack MCP tools |
| `"mcp__.*__delete.*"` | Any MCP delete operation |
| `"mcp__Neon__run_sql"` | Exact Neon SQL tool |

## Hook types

### Command hooks (default)

Shell scripts that receive JSON stdin and return JSON stdout.

```json
{
  "type": "command",
  "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/my-hook.sh 2>/dev/null || true",
  "timeout": 30,
  "statusMessage": "Running validation..."
}
```

### Prompt hooks

LLM-evaluated prompts. Claude reads the prompt and the event context, then decides.

```json
{
  "type": "prompt",
  "prompt": "Check if this file edit is safe. Look for: system paths, credentials, path traversal. Return approve or deny with reason.",
  "timeout": 30
}
```

Supported events: PreToolUse, Stop, SubagentStop, UserPromptSubmit.

### HTTP hooks

Send event data to an external URL. The endpoint receives JSON and returns JSON.

```json
{
  "type": "http",
  "url": "https://hooks.example.com/claude-events",
  "headers": {
    "Authorization": "Bearer $API_TOKEN"
  },
  "allowedEnvVars": ["API_TOKEN"],
  "timeout": 15
}
```

Key fields:
- `url` — HTTPS endpoint (required)
- `headers` — optional headers object; values can reference env vars with `$VAR`
- `allowedEnvVars` — array of env var names the hook can access (security boundary)
- Response format matches command hook JSON output

### Agent hooks

Spawn an autonomous agent to handle the event. Has tool access and runs up to 50 turns.

```json
{
  "type": "agent",
  "prompt": "Review this code change for security issues. Check for injection, XSS, and credential exposure.",
  "timeout": 60
}
```

Key constraints:
- 50-turn limit per invocation
- Has access to Read, Grep, Glob tools (not Write/Edit)
- Receives event context automatically
- Heavier than command/prompt — use only when multi-step reasoning is required

## Standard input (stdin)

All command hooks receive JSON on stdin:
```json
{
  "session_id": "string",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/working/dir",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "Write",
  "tool_input": { "file_path": "/path", "content": "..." },
  "tool_response": "...",
  "agent_id": "string",
  "agent_type": "string"
}
```

### Field presence by event

| Field | Events |
|-------|--------|
| `session_id` | All |
| `transcript_path` | All |
| `cwd` | All |
| `permission_mode` | All |
| `hook_event_name` | All |
| `tool_name` | PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest |
| `tool_input` | PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest |
| `tool_response` | PostToolUse, PostToolUseFailure |
| `agent_id` | SubagentStart, SubagentStop, TeammateIdle (subagent context) |
| `agent_type` | SubagentStart, SubagentStop, TeammateIdle (subagent context) |
| `stop_reason` | Stop |
| `task_id` | TaskCompleted |

### permission_mode values

| Value | Meaning |
|-------|---------|
| `"default"` | Standard permission mode |
| `"plan"` | Plan mode active |
| `"acceptEdits"` | Auto-accept file edits |
| `"dontAsk"` | Auto-accept all tools |
| `"bypassPermissions"` | All permissions bypassed (dangerous) |

## Standard output

### Default (most events)
```json
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "Message injected into Claude's context"
}
```

### PreToolUse specific
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask",
    "updatedInput": { "field": "modified_value" }
  },
  "systemMessage": "Explanation for Claude"
}
```

**Important:** `hookEventName` is required inside `hookSpecificOutput`. Without it,
the hook-specific fields are ignored.

### Stop / SubagentStop specific
```json
{
  "decision": "approve|block",
  "reason": "Why this decision was made",
  "systemMessage": "Additional context for Claude"
}
```

### PermissionRequest specific
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "permissionDecision": "allow|deny|ask"
  }
}
```

## Handler fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `type` | string | — | `"command"`, `"prompt"`, `"http"`, or `"agent"` (required) |
| `command` | string | — | Shell command (command type only) |
| `prompt` | string | — | LLM prompt (prompt/agent type only) |
| `url` | string | — | Endpoint URL (http type only) |
| `timeout` | number | varies | Seconds before timeout |
| `statusMessage` | string | — | Custom spinner text shown during execution |
| `once` | boolean | `false` | Run only once per session (skills-defined hooks only) |
| `async` | boolean | `false` | Run in background without blocking |

### Default timeouts

| Hook type | Default timeout |
|-----------|----------------|
| command | 600s |
| prompt | 30s |
| agent | 60s |
| http | 15s |

**Always set timeout explicitly** — defaults may change between versions.

## Exit codes

| Code | Meaning | Behavior |
|------|---------|----------|
| `0` | Success | stdout is shown in transcript |
| `2` | **Blocking error** | stderr is fed to Claude as error context |
| Other (1, etc.) | Non-blocking error | Warning shown, execution continues |

**Critical:** Exit 2 is BLOCKING. Never use exit 2 for informational warnings.
For advisory hooks, always exit 0 and use `systemMessage` for communication.

## Shell conventions

Every command hook script MUST follow these rules:

### Header
```bash
#!/usr/bin/env bash
set -euo pipefail
```

### Environment variables
```bash
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"    # Project root (always use this)
# ${CLAUDE_PLUGIN_ROOT}                   # Plugin directory (use in plugin.json commands)
# ${CLAUDE_ENV_FILE}                      # SessionStart only — append to persist env vars
```

**Never use relative paths.** Always prefix with `$PROJECT_DIR` or `$CLAUDE_PROJECT_DIR`.

### Reading stdin
```bash
INPUT=$(cat)
```

### Extracting fields (bash builtins, no jq dependency)
```bash
# Extract a JSON string field using parameter expansion
TOOL="${INPUT#*\"tool_name\":\"}"
TOOL="${TOOL%%\"*}"

# Fallback: if jq is available
if command -v jq &>/dev/null; then
  TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
fi
```

### Grep/awk with pipefail
When `set -euo pipefail` is active, grep returning no matches (exit 1) kills the
script. Always append `|| true` after grep/awk pipelines:
```bash
STATUS=$(grep '^status:' "$file" 2>/dev/null | awk '{print $2}' | tr -d '"') || true
```

### Quote stripping
YAML values may be quoted (`"in_progress"`) or unquoted (`in_progress`).
Always strip quotes when comparing:
```bash
VALUE=$(grep 'key:' "$file" | awk '{print $2}' | tr -d '"') || true
```

### JSON output
Use printf for valid JSON. Escape special characters:
```bash
printf '{"decision": "approve", "systemMessage": "%s"}\n' "$MSG"
```

For complex messages, use a heredoc:
```bash
cat <<EOF
{"decision": "approve", "reason": "All checks passed", "systemMessage": "$MSG"}
EOF
```

### Exit
Always exit 0 for advisory hooks. Only exit 2 if you intend to BLOCK the action.

## Matchers

In plugin.json, the `matcher` field controls which tools/agents trigger the hook:

| Pattern | Matches |
|---------|---------|
| `"Write"` | Exact tool name |
| `"Read\|Write\|Edit"` | Multiple tools (pipe-separated) |
| `"mcp__.*__delete.*"` | Regex pattern (all MCP delete tools) |
| `"mcp__slack__.*"` | All tools from a specific MCP server |
| *(omitted)* | All tools / all events |

Matchers are case-sensitive. They use regex matching (not glob).

## Registration

### plugin.json (primary location)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/my-hook.sh 2>/dev/null || true",
            "timeout": 30,
            "statusMessage": "Validating changes..."
          }
        ]
      }
    ]
  }
}
```

### hooks/hooks.json (alternative location)

Plugins can also define hooks in a separate `hooks/hooks.json` file inside the
plugin directory. The format is identical to the `hooks` object in plugin.json.
This keeps the manifest clean for plugins with many hooks.

```
plugins/<name>/
  .claude-plugin/
    plugin.json          # No hooks key needed
  hooks/
    hooks.json           # Same structure as plugin.json "hooks" value
```

Both locations are valid. Pick one — do not duplicate hooks across both.

### Skill/agent frontmatter hooks

Skills and agents can define hooks directly in their YAML frontmatter:

```yaml
---
name: my-skill
hooks:
  PreToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh"
          timeout: 10
---
```

These hooks are active only when the skill/agent is loaded. Use for hooks tightly
coupled to a specific skill's behavior.

### Key rules

- `${CLAUDE_PLUGIN_ROOT}` — always use for script paths (resolves at runtime)
- `2>/dev/null || true` — suppress stderr and prevent non-zero exits for advisory hooks
- `2>/dev/null` (without `|| true`) — only for hooks that intentionally use exit codes
- `timeout` — always set explicitly
- `statusMessage` — optional custom spinner text during execution
- `async: true` — for hooks that should run in background without blocking
- `once: true` — for hooks that should only fire once per session
- Hooks in the same group run **in parallel** — design for independence

## Testing protocol

Before marking any hook complete, run this sequence:

### 1. Direct script test
```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"/test.md"},"hook_event_name":"PreToolUse"}' | \
  bash plugins/<plugin>/scripts/<hook>.sh
echo "Exit: $?"
```

### 2. JSON validation
```bash
bash plugins/<plugin>/scripts/<hook>.sh < test-input.json | python3 -m json.tool
```

### 3. Edge cases to test
- Missing fields in input JSON (should not crash)
- Empty stdin (should exit 0 gracefully)
- Target files/directories don't exist (should exit 0, not error)
- YAML values with/without quotes
- Long strings (truncation behavior)

### 4. Exit code verification
```bash
bash scripts/hook.sh < input.json; echo "EXIT:$?"
```
Confirm: 0 for success, 2 only if intentionally blocking.

### 5. Live test
Run Claude Code with `--debug` to see hook registration, execution, and timing.

## Common mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| Using exit 2 for warnings | **Blocks** the action | Use exit 0 + systemMessage |
| Relative paths (`.ai/...`) | Breaks if cwd differs | Use `$CLAUDE_PROJECT_DIR/.ai/...` |
| Missing `\|\| true` after grep | Script dies under `pipefail` | Append `\|\| true` |
| No `tr -d '"'` on YAML values | String comparison fails | Always strip quotes |
| Echoing plain text from Stop hooks | Claude ignores it | Use JSON `{"decision": ...}` |
| Missing `set -euo pipefail` | Silent failures | Add to every script |
| Grepping tool input for error keywords | False positives | Scope to `tool_response` |
| `\|\| true` on Stop hooks that signal via exit code | Masks the signal | Remove `\|\| true` if using exit codes |
| Not clearing plugin cache after changes | Old hook version runs | `rm -rf ~/.claude/plugins/cache/local-workspace/` |
| Using `tool_result` instead of `tool_response` | Field not found | Use `tool_response` (official name) |
| Missing `hookEventName` in hookSpecificOutput | Hook-specific fields ignored | Always include `hookEventName` |
| Default timeout assumption | Behavior changes between versions | Always set `timeout` explicitly |

## Checklist

Before committing any hook:

- [ ] Script has `#!/usr/bin/env bash` + `set -euo pipefail`
- [ ] Uses `$CLAUDE_PROJECT_DIR` (not relative paths)
- [ ] Uses `$CLAUDE_PLUGIN_ROOT` in plugin.json command
- [ ] All grep/awk pipelines have `|| true` suffix
- [ ] YAML value extraction uses `tr -d '"'`
- [ ] Output is valid JSON matching event-specific schema
- [ ] `hookEventName` included in any `hookSpecificOutput`
- [ ] Exit code is correct (0 for advisory, 2 only for blocking)
- [ ] Tested with sample JSON input
- [ ] Tested with missing/empty input (graceful exit)
- [ ] JSON output validated with `python3 -m json.tool`
- [ ] Script passes `bash -n` syntax check
- [ ] Registered in target plugin.json (or hooks.json or skill frontmatter)
- [ ] Plugin cache cleared
- [ ] Timeout set explicitly
- [ ] `statusMessage` set if hook takes >2s (user feedback)
