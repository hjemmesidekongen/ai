#!/bin/bash
STATUS=$(grep 'status:' state.yml 2>/dev/null | tail -1 | awk '{print $2}' | tr -d '"')
SKILL=$(grep 'current_phase:' state.yml 2>/dev/null | awk '{print $2}' | tr -d '"')

if [ "$STATUS" != "completed" ] && [ "$STATUS" != "verified" ]; then
  echo "Current skill '$SKILL' is not complete (status: $STATUS)."
  echo "Please complete the current skill and run verification before stopping."
  exit 1
fi
echo "Current skill complete. Safe to stop."
exit 0
