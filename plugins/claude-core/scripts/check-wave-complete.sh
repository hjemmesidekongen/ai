#!/usr/bin/env bash
# claude-core — Stop hook: check for incomplete work before session end
# Checks both plan state (.ai/plans/) and agency project state (.ai/agency.yml).
# Always exits 0. Prints warnings to stdout if active work is found.

# --- Check active plans ---
for state_file in .ai/plans/*/state.yml; do
  [ ! -f "$state_file" ] && continue
  STATUS=$(grep '^status:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"')
  if [ "$STATUS" = "in_progress" ]; then
    PLAN=$(grep '^plan:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"')
    TASK=$(grep '^current_task:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"')
    echo "WARNING: Plan '$PLAN' has work in progress (task: $TASK)."
    echo "  Verify the current task is complete before stopping."
  fi
done

# --- Check active agency project ---
AGENCY_FILE=".ai/agency.yml"
if [ -f "$AGENCY_FILE" ]; then
  ACTIVE=$(grep 'active:' "$AGENCY_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"' || true)
  if [ -n "$ACTIVE" ]; then
    STATE_FILE=".ai/projects/$ACTIVE/state.yml"
    if [ -f "$STATE_FILE" ]; then
      STATUS=$(grep 'status:' "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' || true)
      if [ "$STATUS" = "in_progress" ]; then
        CURRENT=$(grep 'current_module:' "$STATE_FILE" 2>/dev/null | awk '{print $2}' || true)
        CURRENT_SKILL=$(grep 'current_skill:' "$STATE_FILE" 2>/dev/null | awk '{print $2}' || true)
        echo "WARNING: Project '$ACTIVE' has work in progress."
        [ -n "$CURRENT" ] && echo "  Module: $CURRENT"
        [ -n "$CURRENT_SKILL" ] && echo "  Skill: $CURRENT_SKILL"
        echo "  Verify the current skill is complete before stopping."
      fi
    fi
  fi
fi

exit 0
