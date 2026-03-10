#!/bin/bash

# Autopilot Stop Hook
# Prevents session exit when an autopilot loop is active
# Feeds the same prompt back to continue the loop
# Source ref: claude-code-main/plugins/ralph-wiggum/hooks/stop-hook.sh

set -euo pipefail

DEBUG_LOG="/tmp/autopilot-debug.log"

# Read hook input from stdin
HOOK_INPUT=$(cat)
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) HOOK_INPUT: $HOOK_INPUT" >> "$DEBUG_LOG"

# Check if autopilot is active
STATE_FILE=".claude/autopilot.local.md"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) No state file, allowing exit" >> "$DEBUG_LOG"
  exit 0
fi

# Parse markdown frontmatter (YAML between ---) and extract values
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//')
COMPLETION_PROMISE=$(echo "$FRONTMATTER" | grep '^completion_promise:' | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) State: iteration=$ITERATION max=$MAX_ITERATIONS promise=$COMPLETION_PROMISE" >> "$DEBUG_LOG"

# Validate numeric fields
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) FAIL: bad iteration value" >> "$DEBUG_LOG"
  echo "Autopilot: State file corrupted (iteration: '$ITERATION'). Stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) FAIL: bad max_iterations value" >> "$DEBUG_LOG"
  echo "Autopilot: State file corrupted (max_iterations: '$MAX_ITERATIONS'). Stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Check if max iterations reached
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Max iterations reached ($MAX_ITERATIONS)" >> "$DEBUG_LOG"
  echo "Autopilot: Max iterations ($MAX_ITERATIONS) reached. Stopping."
  rm "$STATE_FILE"
  exit 0
fi

# Get last assistant message directly from hook input (no transcript parsing needed)
LAST_OUTPUT=$(echo "$HOOK_INPUT" | jq -r '.last_assistant_message // empty')

if [[ -z "$LAST_OUTPUT" ]]; then
  # Fallback: try transcript path
  TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty')
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) No last_assistant_message, trying transcript: $TRANSCRIPT_PATH" >> "$DEBUG_LOG"

  if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
    LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
    if [[ -n "$LAST_LINE" ]]; then
      LAST_OUTPUT=$(echo "$LAST_LINE" | jq -r '
        .message.content |
        map(select(.type == "text")) |
        map(.text) |
        join("\n")
      ' 2>/dev/null || echo "")
    fi
  fi
fi

if [[ -z "$LAST_OUTPUT" ]]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) FAIL: no assistant output found" >> "$DEBUG_LOG"
  echo "Autopilot: No assistant output found. Stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Last output (first 200 chars): ${LAST_OUTPUT:0:200}" >> "$DEBUG_LOG"

# Check for completion promise
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Promise check: found='$PROMISE_TEXT' expected='$COMPLETION_PROMISE'" >> "$DEBUG_LOG"

  if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Promise matched, allowing exit" >> "$DEBUG_LOG"
    echo "Autopilot: Completion promise detected. Done."
    rm "$STATE_FILE"
    exit 0
  fi
fi

# Not complete — continue loop with SAME PROMPT
NEXT_ITERATION=$((ITERATION + 1))

# Extract prompt (everything after the closing ---) and strip leading blank lines
PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$STATE_FILE" | sed '/./,$!d')

if [[ -z "$PROMPT_TEXT" ]]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) FAIL: no prompt text in state file" >> "$DEBUG_LOG"
  echo "Autopilot: No prompt text found in state file. Stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Update iteration in frontmatter (portable across macOS and Linux)
TEMP_FILE="${STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$STATE_FILE"

# Build system message with iteration count and completion info
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  SYSTEM_MSG="Autopilot iteration $NEXT_ITERATION | To stop: output <promise>$COMPLETION_PROMISE</promise> (ONLY when statement is TRUE - do not lie to exit!)"
else
  SYSTEM_MSG="Autopilot iteration $NEXT_ITERATION | No completion promise set - loop runs until max iterations ($MAX_ITERATIONS)"
fi

# Output JSON to block the stop and feed prompt back
# reason = clean prompt (no iteration prefix), systemMessage = iteration metadata
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) BLOCKING: iteration $NEXT_ITERATION" >> "$DEBUG_LOG"
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
