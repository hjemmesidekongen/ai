#!/bin/bash
# Agency plugin — stop hook
# Prevents Claude from stopping if there's active work in progress

set -euo pipefail

# Find active project
AGENCY_FILE=".ai/agency.yml"
if [ ! -f "$AGENCY_FILE" ]; then
  exit 0
fi

ACTIVE=$(grep 'active:' "$AGENCY_FILE" 2>/dev/null | awk '{print $2}' || true)
if [ -z "$ACTIVE" ]; then
  exit 0
fi

STATE_FILE=".ai/projects/$ACTIVE/state.yml"
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Check if any module is in_progress
STATUS=$(grep 'status:' "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' || true)
if [ "$STATUS" = "in_progress" ]; then
  CURRENT=$(grep 'current_module:' "$STATE_FILE" 2>/dev/null | awk '{print $2}' || true)
  CURRENT_SKILL=$(grep 'current_skill:' "$STATE_FILE" 2>/dev/null | awk '{print $2}' || true)
  echo "WARNING: Project '$ACTIVE' has work in progress."
  [ -n "$CURRENT" ] && echo "  Module: $CURRENT"
  [ -n "$CURRENT_SKILL" ] && echo "  Skill: $CURRENT_SKILL"
  echo "  Verify the current skill is complete before stopping."
fi

exit 0
