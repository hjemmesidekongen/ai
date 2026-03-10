# Plugin Settings — Process Reference

## 1. File Convention

**Path:** `.claude/{plugin-name}.local.md` in the project root (not the user's home directory).

Match the plugin name exactly. Use `.local.md` suffix — the `.local` signals user-local
(not committed), and tools can glob `*.local.md` to find all plugin settings files.

**gitignore:** Add this to every plugin that uses settings:

```gitignore
.claude/*.local.md
.claude/*.local.json
```

**Restart requirement:** Hooks load settings at session start. Any edit to a settings
file requires restarting Claude Code before it takes effect. Document this in the plugin
README and surface it in any commands that write the file.

**Permissions:** `chmod 600 .claude/my-plugin.local.md` — readable by owner only.

---

## 2. Parsing Techniques

### Extract Frontmatter Block

```bash
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$FILE")
```

How it works: `-n` suppresses output. The range `/^---$/,/^---$/` selects lines between
the two markers. `{ /^---$/d; p; }` deletes the marker lines and prints the rest.

Parse once, then extract all fields from `$FRONTMATTER` — don't re-read the file per field.

### Extract Individual Fields

```bash
# String (handles both quoted and unquoted YAML values)
VALUE=$(echo "$FRONTMATTER" | grep '^field:' | sed 's/field: *//' | sed 's/^"\(.*\)"$/\1/')

# Boolean — compare as string
ENABLED=$(echo "$FRONTMATTER" | grep '^enabled:' | sed 's/enabled: *//')
[[ "$ENABLED" == "true" ]]

# Numeric — validate before arithmetic
MAX=$(echo "$FRONTMATTER" | grep '^max_value:' | sed 's/max_value: *//')
[[ "$MAX" =~ ^[0-9]+$ ]] || MAX=10   # default on invalid

# List (simple containment check — no yq needed)
LIST=$(echo "$FRONTMATTER" | grep '^items:' | sed 's/items: *//')
[[ "$LIST" == *"target-item"* ]]
```

### Extract Markdown Body

```bash
BODY=$(awk '/^---$/{i++; next} i>=2' "$FILE")
```

Counts `---` markers. Everything after the second marker is the body. Safe when `---`
appears in the body content (only the first two markers are counted).

### Field with Default

```bash
MODE=$(echo "$FRONTMATTER" | grep '^mode:' | sed 's/mode: *//' | sed 's/^"\(.*\)"$/\1/')
MODE=${MODE:-standard}   # bash default substitution — cleaner than an if block
```

### Atomic Updates (Temp File + mv)

Never use `sed -i` in-place for settings files — it can corrupt on interruption.

```bash
TEMP="${FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT/" "$FILE" > "$TEMP"
mv "$TEMP" "$FILE"
```

For multiple fields:

```bash
TEMP="${FILE}.tmp.$$"
sed -e "s/^iteration: .*/iteration: $NEXT/" \
    -e "s/^pr_number: .*/pr_number: $PR_NUM/" \
    "$FILE" > "$TEMP"
mv "$TEMP" "$FILE"
```

---

## 3. Core Patterns

### Quick-Exit Hook

Check file existence as the very first thing. Zero overhead when the plugin isn't active.

```bash
#!/bin/bash
set -euo pipefail

STATE_FILE=".claude/my-plugin.local.md"

if [[ ! -f "$STATE_FILE" ]]; then
  exit 0   # Not configured — skip cleanly
fi

FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")
ENABLED=$(echo "$FRONTMATTER" | grep '^enabled:' | sed 's/enabled: *//')

if [[ "$ENABLED" != "true" ]]; then
  exit 0   # Disabled — skip cleanly
fi

# Hook logic here
```

### Temporarily-Active Hooks

Use the `enabled` field to toggle hook behavior without editing `hooks.json` (which
requires a restart). The user flips `enabled: false`, the hook exits early next time.

This makes hooks conditional on project state rather than on whether they're wired up.

### Configuration-Driven Behavior

```bash
LEVEL=$(echo "$FRONTMATTER" | grep '^validation_level:' | sed 's/validation_level: *//')
LEVEL=${LEVEL:-standard}

case "$LEVEL" in
  strict)   # strict path ;;
  standard) # standard path ;;
  lenient)  # lenient path ;;
  *)
    echo "Unknown validation_level: $LEVEL, using standard" >&2
    # standard path
    ;;
esac
```

### Agent State Management

Frontmatter holds coordination metadata. Body holds the task prompt or instructions.

```yaml
---
agent_name: auth-agent
task_number: 3.5
coordinator_session: team-leader
enabled: true
---

# Task Assignment

Implement JWT authentication for the REST API.
```

The hook reads frontmatter to identify the agent and coordinator, extracts the body as
the prompt, and updates state (e.g., iteration counter) atomically before proceeding.

---

## 4. Real-World Examples

### multi-agent-swarm — Stop Hook for Agent Coordination

Settings file (`.claude/multi-agent-swarm.local.md`):
```yaml
---
agent_name: auth-implementation
task_number: 3.5
pr_number: 1234
coordinator_session: team-leader
enabled: true
---
Build JWT-based authentication for the REST API.
```

Hook extracts `coordinator_session` and `agent_name`, then sends a tmux notification:
```bash
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$SWARM_FILE")
COORDINATOR=$(echo "$FRONTMATTER" | grep '^coordinator_session:' | sed 's/coordinator_session: *//' | sed 's/^"\(.*\)"$/\1/')
AGENT=$(echo "$FRONTMATTER" | grep '^agent_name:' | sed 's/agent_name: *//' | sed 's/^"\(.*\)"$/\1/')
ENABLED=$(echo "$FRONTMATTER" | grep '^enabled:' | sed 's/enabled: *//')

[[ "$ENABLED" != "true" ]] && exit 0

if tmux has-session -t "$COORDINATOR" 2>/dev/null; then
  tmux send-keys -t "$COORDINATOR" "Agent $AGENT is idle." Enter
fi
```

PR number updated after PR creation:
```bash
TEMP="${SWARM_FILE}.tmp.$$"
sed "s/^pr_number: .*/pr_number: $PR_NUM/" "$SWARM_FILE" > "$TEMP"
mv "$TEMP" "$SWARM_FILE"
```

### autopilot — Stop Hook for Agentic Loops

Settings file (`.claude/autopilot.local.md`):
```yaml
---
iteration: 1
max_iterations: 10
completion_promise: "All tests passing and build successful"
---

Fix all the linting errors in the project.
Make sure tests pass after each fix.
```

Key patterns:
- Read `iteration` and `max_iterations` — exit if limit reached, delete the file
- Extract body with `awk '/^---$/{i++; next} i>=2'` — that's the prompt to loop back
- Increment `iteration` atomically before feeding the prompt back
- Block exit via `{"decision": "block", "reason": $prompt}` JSON response
- Use `jq -n --arg prompt "$PROMPT_TEXT"` for safe JSON construction with multiline content

---

## 5. Best Practices

**Always provide defaults.** A missing field should never crash the hook. Use bash default
substitution (`${VAR:-default}`) rather than if-blocks for concision.

**Check `enabled` explicitly.** Don't assume presence of the file means active. Always
read and check `enabled: true` before doing anything consequential.

**Handle both quoted and unquoted YAML.** YAML allows `field: value` and `field: "value"`.
Strip surrounding quotes with: `sed 's/^"\(.*\)"$/\1/'`

**Lazy loading in PreToolUse hooks.** Run fast checks first (tool_name from JSON input)
before opening the settings file. Avoid file I/O on every tool call.

**Document the restart requirement.** Every plugin README and every command that modifies
settings should remind the user to restart Claude Code after editing.

---

## 6. Anti-Patterns

**Complex YAML without yq.** Don't try to parse nested objects or multi-line strings
with sed/grep. If your schema needs that, either simplify it or require yq.

**Secrets in settings.** Settings files are plaintext and project-local. Don't store
API keys, tokens, or credentials. Use environment variables or a secrets manager instead.

**Skipping validation.** Always validate numeric fields before arithmetic. Always validate
enums with a case statement that has a `*)` error branch.

**Non-atomic updates.** Never `sed -i` in-place. Always write to a temp file and `mv`.

**Hardcoded absolute paths.** Use `.claude/plugin-name.local.md` (relative), not
`/Users/alice/.claude/...`. Hooks run from the project root.

**Unquoted variable expansion.** Always quote: `"$VALUE"`, `"$FILE"`, `"$FRONTMATTER"`.
Unquoted variables break on paths with spaces.

---

## 7. Validation

### File Exists and Is Readable

```bash
[[ -f "$FILE" ]] || { echo "Settings file not found" >&2; exit 1; }
[[ -r "$FILE" ]] || { echo "Settings file not readable" >&2; exit 1; }
```

### Frontmatter Structure

```bash
MARKER_COUNT=$(grep -c '^---$' "$FILE" 2>/dev/null || echo "0")
[[ $MARKER_COUNT -ge 2 ]] || { echo "Missing frontmatter markers" >&2; exit 1; }

FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$FILE")
[[ -n "$FRONTMATTER" ]] || { echo "Empty frontmatter" >&2; exit 1; }
```

### Field Values

```bash
# Boolean validation
if [[ "$ENABLED" != "true" ]] && [[ "$ENABLED" != "false" ]]; then
  echo "enabled must be true or false, got: $ENABLED" >&2
  exit 1
fi

# Numeric range validation
if ! [[ "$MAX" =~ ^[0-9]+$ ]] || [[ $MAX -lt 1 ]] || [[ $MAX -gt 100 ]]; then
  echo "max_value out of range (1-100)" >&2
  MAX=10
fi

# Enum validation
case "$MODE" in
  strict|standard|lenient) ;;
  *) echo "Invalid mode: $MODE" >&2; exit 1 ;;
esac
```

### Required Fields

```bash
for field in enabled agent_name coordinator_session; do
  VALUE=$(echo "$FRONTMATTER" | grep "^${field}:" | sed "s/${field}: *//")
  if [[ -z "$VALUE" ]]; then
    echo "Required field missing: $field" >&2
    exit 1
  fi
done
```

Use the `scripts/validate-settings.sh` utility for ad-hoc file validation during
development. Use `scripts/parse-frontmatter.sh` to extract fields interactively.
