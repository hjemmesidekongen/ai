#!/usr/bin/env bash
# observation-recorder.sh — PostToolUse hook
# Records structured observations from tool calls for instinct extraction.
# Always exits 0. Output: JSON advisory only.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
OBSERVATIONS_FILE="$PROJECT_DIR/.ai/instincts/observations.jsonl"
TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
TOOL_OUTPUT="${CLAUDE_TOOL_OUTPUT:-}"

# Sanitize tool name for JSON safety
TOOL_NAME="${TOOL_NAME//\"/\'}"

# Truncate tool output before processing (prevent memory issues)
TOOL_OUTPUT="${TOOL_OUTPUT:0:2000}"

# Create storage dir if needed
mkdir -p "$PROJECT_DIR/.ai/instincts"

# Determine outcome from tool output (error indicators)
outcome="success"
error_summary="null"
if echo "$TOOL_OUTPUT" | grep -qiE "(error:|failed|not found|no such file|permission denied)" 2>/dev/null; then
  outcome="error"
  error_summary="$(echo "$TOOL_OUTPUT" | grep -iE "(error:|failed|not found)" | head -1 | cut -c1-80 | tr '"' "'")"
fi

# Infer context type from tool name and recent trace
context_type="general"
if echo "$TOOL_NAME" | grep -qiE "(bash|grep)"; then context_type="search"; fi
if echo "$TOOL_NAME" | grep -qiE "(edit|write)"; then context_type="write"; fi
if echo "$TOOL_NAME" | grep -qiE "read"; then context_type="review"; fi

# Approximate sequence key from last 3 tools in trace-light.log
seq_key="none"
if [[ -f "$PROJECT_DIR/.ai/traces/trace-light.log" ]]; then
  seq_key=$(tail -3 "$PROJECT_DIR/.ai/traces/trace-light.log" 2>/dev/null | awk -F'|' '{print $2}' | tr '\n' '-' | sed 's/-$//' | md5 2>/dev/null || echo "none")
fi

# Build JSON observation
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
observation="{\"timestamp\":\"$timestamp\",\"tool\":\"$TOOL_NAME\",\"outcome\":\"$outcome\",\"context_type\":\"$context_type\",\"sequence_key\":\"$seq_key\",\"error_summary\":$( [[ "$error_summary" == "null" ]] && echo "null" || echo "\"$error_summary\"")}"

echo "$observation" >> "$OBSERVATIONS_FILE"

# Trim to last 500 observations (keep file bounded)
if [[ -f "$OBSERVATIONS_FILE" ]]; then
  line_count=$(wc -l < "$OBSERVATIONS_FILE" 2>/dev/null || echo 0)
  if (( line_count > 500 )); then
    TMP=$(mktemp "${OBSERVATIONS_FILE}.XXXXXX")
    tail -500 "$OBSERVATIONS_FILE" > "$TMP" && mv "$TMP" "$OBSERVATIONS_FILE"
  fi
fi

echo '{"decision":"approve","reason":"observation recorded"}'
exit 0
