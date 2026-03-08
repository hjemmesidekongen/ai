#!/usr/bin/env bash
# claude-core — SessionStart hook: report context for resumed sessions
# Checks plan state and agency project state. Always exits 0.

set -euo pipefail

echo "=== Session Recovery Check ==="

FOUND_CONTEXT=0

# --- Check active plans ---
for state_file in .ai/plans/*/state.yml; do
  [ ! -f "$state_file" ] && continue
  STATUS=$(grep '^status:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"')
  if [ "$STATUS" = "in_progress" ]; then
    PLAN=$(grep '^plan:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"')
    WAVE=$(grep '^current_wave:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"')
    TASK=$(grep '^current_task:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"')
    echo "Active plan: $PLAN (wave: $WAVE, task: $TASK)"

    ERRORS=$(grep -c '  - timestamp:' "$state_file" 2>/dev/null) || ERRORS=0
    [ "$ERRORS" -gt 0 ] && echo "  Logged errors: $ERRORS"
    FOUND_CONTEXT=1
  fi
done

# --- Check active agency project ---
AGENCY_FILE=".ai/agency.yml"
if [ -f "$AGENCY_FILE" ]; then
  ACTIVE=$(grep 'active:' "$AGENCY_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"' || true)
  if [ -n "$ACTIVE" ]; then
    STATE_FILE=".ai/projects/$ACTIVE/state.yml"
    if [ -f "$STATE_FILE" ]; then
      echo "Active project: $ACTIVE"
      echo "--- Project State ---"
      head -30 "$STATE_FILE"
      FOUND_CONTEXT=1
    fi
  fi
fi

if [ $FOUND_CONTEXT -eq 0 ]; then
  echo "No state.yml found. Fresh start."
fi

# --- Git status ---
echo "--- Git Status ---"
git status --short 2>/dev/null | head -20 || true

echo "=== End Recovery ==="
exit 0
