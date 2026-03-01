#!/usr/bin/env bash
#
# check-wave-complete.sh
#
# Stop hook for task-planner. Prevents premature completion by
# checking whether the current skill/phase has been marked as
# completed or verified in state.yml.
#
# Usage: bash plugins/task-planner/scripts/check-wave-complete.sh
# Exit 0: Current skill is complete — safe to stop
# Exit 1: Current skill is NOT complete — Claude must keep working

set -euo pipefail

# If no state.yml exists, nothing to gate on
if [ ! -f state.yml ]; then
  echo "No state.yml found. Nothing to verify."
  exit 0
fi

# Read top-level fields only (no leading whitespace) to avoid matching nested phase entries
STATUS=$(grep '^status:' state.yml 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"')
SKILL=$(grep '^current_phase:' state.yml 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"')

if [ "$STATUS" != "completed" ] && [ "$STATUS" != "verified" ]; then
  echo "Current skill '$SKILL' is not complete (status: $STATUS)."
  echo "Please complete the current skill and run verification before stopping."
  exit 1
fi

echo "Current skill complete. Safe to stop."
exit 0
