#!/usr/bin/env bash
set -euo pipefail
# claude-core — compact gate (PreToolUse on Write|Edit)
# Blocks writes when compact is needed AND the target file is not part of the current unit.
# Unit-completion artifacts (SKILL.md, commands/*.md, agents/*.md, etc.) are allowed through
# because they're likely still part of the finishing unit.
# Non-unit files after the flag is set indicate a new unit starting — block with exit 2.
# Performance target: <30ms. Exits 0 (allow) or 2 (block).

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
FLAG_FILE="$PROJECT_DIR/.ai/compact-needed"

# Fast path: no flag = no gate
[ ! -f "$FLAG_FILE" ] && exit 0

# Read hook input JSON from stdin
INPUT=$(cat)

# Extract file_path using bash builtins
FILE_PATH=""
case "$INPUT" in *'"file_path":"'*)
  FILE_PATH="${INPUT#*\"file_path\":\"}"
  FILE_PATH="${FILE_PATH%%\"*}" ;;
esac

# If we can't extract a file path, allow (don't break anything)
[ -z "$FILE_PATH" ] && exit 0

# Check if the target file is a unit-completion artifact (same unit, allow through)
case "$FILE_PATH" in
  */SKILL.md | */commands/*.md | */agents/*.md | *decisions.yml | */findings.md)
    exit 0 ;;
  .ai/plans/*/state.yml | */plans/*/state.yml)
    exit 0 ;;
esac

# Target file is NOT a unit-completion artifact and the compact flag exists.
# This likely means a new unit is starting — block it.
printf '{"decision":"block","reason":"Compact required before starting next unit. Run /compact, then retry."}\n'
exit 2
