#!/usr/bin/env bash
#
# check-wave-complete.sh
#
# Stop hook for seo-plugin. Prevents premature completion by
# checking whether the current skill/phase has been marked as
# completed or verified in state.yml.
#
# Usage: bash plugins/seo-plugin/scripts/check-wave-complete.sh
# Exit 0: Current skill is complete — safe to stop
# Exit 1: Current skill is NOT complete — Claude must keep working

set -euo pipefail

# Determine project directory from active-seo-project.yml or current directory
STATE_FILE=""
if [ -f .ai/active-seo-project.yml ]; then
  PROJECT_NAME=$(grep '^project_name:' .ai/active-seo-project.yml 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"' || true)
  if [ -n "$PROJECT_NAME" ] && [ -f ".ai/seo/$PROJECT_NAME/state.yml" ]; then
    STATE_FILE=".ai/seo/$PROJECT_NAME/state.yml"
  fi
fi

# Fallback: check current directory
if [ -z "$STATE_FILE" ] && [ -f state.yml ]; then
  STATE_FILE="state.yml"
fi

# If no state.yml exists, nothing to gate on
if [ -z "$STATE_FILE" ]; then
  echo "No state.yml found. Nothing to verify."
  exit 0
fi

# Read top-level fields only (no leading whitespace) to avoid matching nested phase entries
STATUS=$(grep '^status:' "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"')
SKILL=$(grep '^current_phase:' "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"')

# No current phase → no active skill, safe to stop
if [ -z "$SKILL" ]; then
  echo "No active skill. Safe to stop."
  exit 0
fi

# Empty status → not started yet, safe to stop
if [ -z "$STATUS" ]; then
  echo "No status set. Safe to stop."
  exit 0
fi

# Only block on active/incomplete statuses
case "$STATUS" in
  completed|verified)
    echo "Current skill '$SKILL' complete. Safe to stop."
    exit 0
    ;;
  blocked)
    echo "Current skill '$SKILL' is blocked. Safe to stop."
    exit 0
    ;;
  *)
    echo "Current skill '$SKILL' is not complete (status: $STATUS)."
    echo "Please complete the current skill and run verification before stopping."
    exit 1
    ;;
esac
