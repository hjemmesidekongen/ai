#!/bin/bash
# Agency plugin — project isolation enforcement
# Called by PreToolUse hook on Write|Edit|Bash operations
# Blocks writes to non-active project paths
#
# Usage: echo "$TOOL_INPUT" | bash project-isolation-check.sh

set -euo pipefail

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
    echo "BLOCKED: Write targets project '$TARGET_PROJECT' but active project is '$ACTIVE'."
    echo "Use /agency:switch $TARGET_PROJECT to change the active project first."
    exit 1
  fi
fi

if echo "$FILE_PATH" | grep -qE "^packages/brand/"; then
  TARGET_BRAND=$(echo "$FILE_PATH" | sed 's|^packages/brand/||' | cut -d'/' -f1)
  if [ "$TARGET_BRAND" != "$ACTIVE" ]; then
    echo "BLOCKED: Write targets brand package '$TARGET_BRAND' but active project is '$ACTIVE'."
    echo "Use /agency:switch $TARGET_BRAND to change the active project first."
    exit 1
  fi
fi

# All checks passed — allow
exit 0
