#!/usr/bin/env bash
# Agency plugin — inject real timestamps into trace files
# Called by PostToolUse hook when Write/Edit targets a traces/ path
# Reads hook input from stdin (JSON), extracts file_path, replaces [HOOK_TS]

# Read stdin JSON from Claude Code hook system
INPUT=$(cat)

# Extract file_path from tool_input using jq (preferred) or grep fallback
if command -v jq &>/dev/null; then
  FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  FILE=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | sed 's/"file_path":"//;s/"$//')
fi

[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

# Only process files in a traces/ directory
case "$FILE" in
  *traces/*) ;;
  *) exit 0 ;;
esac

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
sed -i '' "s/\[HOOK_TS\]/$TS/g" "$FILE"
