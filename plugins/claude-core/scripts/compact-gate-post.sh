#!/usr/bin/env bash
set -euo pipefail
# claude-core — compact gate (PostToolUse on Write|Edit)
# Detects unit-completion artifacts and sets .ai/compact-needed flag.
# A "unit" is one logical work item: a skill, command, agent, decision, plan wave, or research.
# When a unit's final artifact is written, this flags compact as needed before next unit.
# Performance target: <30ms. Always exits 0.

# Read hook input JSON from stdin
INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Extract file_path using bash builtins (mirrors trace-light.sh pattern)
case "$INPUT" in *'"file_path":"'*)
  FILE_PATH="${INPUT#*\"file_path\":\"}"
  FILE_PATH="${FILE_PATH%%\"*}" ;;
  *) exit 0 ;;
esac

[ -z "$FILE_PATH" ] && exit 0

# Check if file matches a unit-completion pattern
MATCHED=0
case "$FILE_PATH" in
  */SKILL.md)
    MATCHED=1 ;;
  */commands/*.md)
    MATCHED=1 ;;
  */agents/*.md)
    MATCHED=1 ;;
  *decisions.yml)
    MATCHED=1 ;;
  */findings.md)
    MATCHED=1 ;;
  .ai/plans/*/state.yml | */plans/*/state.yml)
    # Only flag if a wave status changed to done/completed
    # Check tool_input content for wave completion signals
    case "$INPUT" in
      *'"status: done"'*|*'"status: completed"'*|*'status: done'*|*'status: completed'*)
        MATCHED=1 ;;
    esac ;;
esac

if [ "$MATCHED" -eq 1 ]; then
  FLAG_FILE="$PROJECT_DIR/.ai/compact-needed"
  # Ensure .ai directory exists
  [ ! -d "$PROJECT_DIR/.ai" ] && mkdir -p "$PROJECT_DIR/.ai" 2>/dev/null
  # Write ISO timestamp
  date -u +%Y-%m-%dT%H:%M:%SZ > "$FLAG_FILE" 2>/dev/null
fi

exit 0
