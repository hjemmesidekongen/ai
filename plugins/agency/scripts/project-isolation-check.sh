#!/bin/bash
# Agency plugin — project isolation enforcement
# Called by PreToolUse hook on Write|Edit|Bash operations
# Blocks writes to non-active project paths
#
# Usage: echo "$TOOL_INPUT" | bash project-isolation-check.sh

set -euo pipefail
trap 'exit 0' ERR

# Read tool input from stdin (contains file_path or command)
TOOL_INPUT=$(cat)

# Find active project
AGENCY_FILE=".ai/agency.yml"
if [ ! -f "$AGENCY_FILE" ]; then
  # No agency.yml — no isolation to enforce
  exit 0
fi

ACTIVE=$(grep 'active:' "$AGENCY_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"' || true)
if [ -z "$ACTIVE" ]; then
  exit 0
fi

# Extract file path from tool input
# Handle both Write/Edit (file_path field) and general path references
FILE_PATH=$(echo "$TOOL_INPUT" | grep -oE '(\.ai/projects/[a-zA-Z0-9_-]+|packages/brand/[a-zA-Z0-9_-]+)' | head -1 || true)

if [ -z "$FILE_PATH" ]; then
  # No project-scoped path detected — allow
  exit 0
fi

# Check if path targets a different project
if echo "$FILE_PATH" | grep -qE "^\.ai/projects/"; then
  TARGET_PROJECT=$(echo "$FILE_PATH" | sed 's|^\.ai/projects/||' | cut -d'/' -f1)
  if [ "$TARGET_PROJECT" != "$ACTIVE" ]; then
    printf '{"decision":"block","reason":"Write targets project '\''%s'\'' but active project is '\''%s'\''. Use /agency:switch %s to change the active project first."}\n' "$TARGET_PROJECT" "$ACTIVE" "$TARGET_PROJECT"
    exit 2
  fi
fi

if echo "$FILE_PATH" | grep -qE "^packages/brand/"; then
  TARGET_BRAND=$(echo "$FILE_PATH" | sed 's|^packages/brand/||' | cut -d'/' -f1)
  if [ "$TARGET_BRAND" != "$ACTIVE" ]; then
    printf '{"decision":"block","reason":"Write targets brand package '\''%s'\'' but active project is '\''%s'\''. Use /agency:switch %s to change the active project first."}\n' "$TARGET_BRAND" "$ACTIVE" "$TARGET_BRAND"
    exit 2
  fi
fi

# All checks passed — allow
exit 0
