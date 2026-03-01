#!/usr/bin/env bash
#
# session-recovery.sh
#
# SessionStart hook for task-planner. Detects if this is a resumed
# session by checking for state.yml, then reports current progress
# so Claude can orient before doing any work.
#
# Usage: bash packages/task-planner/scripts/session-recovery.sh
# Exit 0: Always (informational only — never blocks startup)

set -euo pipefail

echo "=== Session Recovery Check ==="

# Look for state.yml in the current directory (where the plan is being executed)
if [ -f state.yml ]; then
  echo "State file found."
  echo "Current phase: $(grep '^current_phase:' state.yml 2>/dev/null | head -1 | awk '{print $2}' | tr -d '\"' || echo 'unknown')"
  echo "Status: $(grep '^status:' state.yml 2>/dev/null | head -1 | awk '{print $2}' | tr -d '\"' || echo 'unknown')"

  # Report last modified time (macOS and Linux compatible)
  if stat -f %Sm state.yml &>/dev/null; then
    echo "Last updated: $(stat -f '%Sm' state.yml)"
  elif stat -c %y state.yml &>/dev/null; then
    echo "Last updated: $(stat -c '%y' state.yml)"
  fi

  # Count logged errors
  ERRORS=$(grep -c '  - timestamp:' state.yml 2>/dev/null || echo 0)
  echo "Logged errors: $ERRORS"

  # Show completed phases if available
  COMPLETED=$(grep -A1 'status: completed' state.yml 2>/dev/null | grep 'name:' | awk '{print $2}' | tr -d '"' | tr '\n' ', ' || true)
  if [ -n "$COMPLETED" ]; then
    echo "Completed phases: $COMPLETED"
  fi

  # Show git changes since last commit
  echo "Git changes since last commit:"
  git diff --stat HEAD 2>/dev/null || echo "  (not a git repo)"
else
  echo "No state.yml found. Fresh start."
fi
