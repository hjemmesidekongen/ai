---
name: trace:full
description: "Toggle full tracing on/off — structured YAML session capture with decision context"
---

# /trace:full

Toggle full tracing mode. When active, Claude writes structured YAML entries
capturing decision context, file changes, and outcomes for every significant
action. Light tracing (always-on) continues independently.

## Usage

```
/trace:full          # Toggle: enables if off, disables if on
```

## Execution Steps

### Step 1: Read Current State

```
config_path = .ai/traces/trace-config.yml

if config_path exists:
  config = read_yaml(config_path)
  current_level = config.level    # "light" or "full"
else:
  current_level = "light"         # default — no config means light-only
```

### Step 2: Toggle

```
if current_level == "full":
  → go to "Disable Full Tracing"
else:
  → go to "Enable Full Tracing"
```

---

### Enable Full Tracing

#### 2a. Create session file

```
today = date in YYYY-MM-DD format
now = ISO 8601 UTC timestamp
session_filename = "trace-full-{today}.yml"
sessions_dir = .ai/traces/sessions/

Create sessions_dir if it does not exist (mkdir -p).

Write .ai/traces/sessions/{session_filename}:
```

```yaml
session:
  started_at: "{now}"
  level: "full"
  entries: []
```

#### 2b. Update trace config

```
Write .ai/traces/trace-config.yml:
```

```yaml
level: "full"
enabled_at: "{now}"
session_file: "{session_filename}"
```

#### 2c. Report

```
"Full tracing enabled. Session: {session_filename}"
"Light tracing continues in parallel (additive)."
"I will now write structured entries to the session file during this work session."
```

---

### Disable Full Tracing

#### 3a. Read session summary

```
session_file = config.session_file
session_path = .ai/traces/sessions/{session_file}

if session_path exists:
  session = read_yaml(session_path)
  entry_count = length(session.session.entries)
  error_count = count entries where outcome == "error"
else:
  entry_count = 0
  error_count = 0
```

#### 3b. Update trace config

```
now = ISO 8601 UTC timestamp

Write .ai/traces/trace-config.yml:
```

```yaml
level: "light"
disabled_at: "{now}"
```

#### 3c. Report

```
"Full tracing disabled. Reverting to light mode."
"Session summary: {entry_count} entries, {error_count} errors."
```

If error_count > 0, list the error entries (timestamp + notes) as a brief summary.

---

## Full Trace Entry Format

**This section defines how Claude writes entries during work when full tracing is active.**

Before performing a significant action (Write, Edit, Bash, skill invocation, architectural decision), append an entry to the active session file's `entries` array:

```yaml
entries:
  - timestamp: "2026-03-08T14:35:00Z"
    tool: "Write"
    decision_context: "Creating README because user requested marketing-quality docs"
    files_changed:
      - "plugins/kronen/README.md"
    outcome: "success"
    notes: null

  - timestamp: "2026-03-08T14:36:12Z"
    tool: "Edit"
    decision_context: "Fixing YAML indentation — validator reported parse error on line 12"
    files_changed:
      - ".ai/traces/sessions/trace-full-2026-03-08.yml"
    outcome: "success"
    notes: "Root cause was tab character mixed with spaces"

  - timestamp: "2026-03-08T14:37:45Z"
    tool: "Bash"
    decision_context: "Running test suite to verify hook registration"
    files_changed: []
    outcome: "error"
    notes: "Exit code 1 — jq not installed. Falling back to grep-based parsing."
```

### Entry field rules

| Field | Required | Description |
|-------|----------|-------------|
| `timestamp` | yes | ISO 8601 UTC |
| `tool` | yes | Tool or skill name (Write, Edit, Bash, Skill, etc.) |
| `decision_context` | yes | WHY this action is being taken — one sentence |
| `files_changed` | yes | List of files modified (empty array `[]` if none) |
| `outcome` | yes | `"success"` or `"error"` |
| `notes` | no | Additional context, error details, or null |

### When to write entries

Write a full trace entry for:
- File writes and edits (Write, Edit)
- Shell commands that change state (Bash with side effects)
- Skill invocations
- Architectural decisions or approach changes
- Error recovery actions

Do NOT write entries for:
- Read-only operations (Read, Grep, Glob) — these are already in light trace
- Consecutive minor edits to the same file (batch into one entry)
- The trace file writes themselves (avoid recursion)

### How to write entries

1. Read the current session file
2. Append the new entry to the `entries` array
3. Write the updated session file

Keep entries concise. The `decision_context` is the most valuable field — it
captures reasoning that the light trace cannot.

---

## Checking Full Trace Status

To determine if full tracing is active (used by status bar and other features):

```
Read .ai/traces/trace-config.yml
If file exists AND level == "full" → full tracing is active
Otherwise → light-only
```

## Relationship to Light Tracing

Full tracing is **additive**. Light tracing (the PostToolUse hook in trace-light.sh)
continues to append to `.ai/traces/trace-light.log` regardless of full trace state.
They serve different purposes:

- **Light:** Machine-parseable, grep-friendly, every tool call, near-zero cost
- **Full:** Human-readable YAML, decision context, selective, moderate cost

Disabling full tracing has no effect on light tracing.
