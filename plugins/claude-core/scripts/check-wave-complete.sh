#!/usr/bin/env bash
set -euo pipefail
# claude-core — Stop hook: check for incomplete work before session end
# Checks both plan state and agency project state.
# Output: JSON with decision (approve/block) per Stop hook spec.
# Exit 0 always — signaling is via JSON decision field.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
WARNINGS=""

# --- Check active plans ---
for state_file in "$PROJECT_DIR"/.ai/plans/*/state.yml; do
  [ ! -f "$state_file" ] && continue
  STATUS=$(grep '^status:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"') || true
  if [ "$STATUS" = "in_progress" ]; then
    PLAN=$(grep '^plan:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"') || true
    TASK=$(grep '^current_task:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"') || true
    WARNINGS="${WARNINGS}Plan '${PLAN}' has work in progress (task: ${TASK}). "
  fi
done

# --- Check active agency project ---
AGENCY_FILE="$PROJECT_DIR/.ai/agency.yml"
if [ -f "$AGENCY_FILE" ]; then
  ACTIVE=$(grep 'active:' "$AGENCY_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"') || true
  if [ -n "$ACTIVE" ]; then
    STATE_FILE="$PROJECT_DIR/.ai/projects/$ACTIVE/state.yml"
    if [ -f "$STATE_FILE" ]; then
      STATUS=$(grep 'status:' "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"') || true
      if [ "$STATUS" = "in_progress" ]; then
        MODULE=$(grep 'current_module:' "$STATE_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"') || true
        SKILL=$(grep 'current_skill:' "$STATE_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"') || true
        MSG="Project '${ACTIVE}' has work in progress."
        [ -n "$MODULE" ] && [ "$MODULE" != "null" ] && MSG="${MSG} Module: ${MODULE}."
        [ -n "$SKILL" ] && [ "$SKILL" != "null" ] && MSG="${MSG} Skill: ${SKILL}."
        WARNINGS="${WARNINGS}${MSG} "
      fi
    fi
  fi
fi

# --- Output ---
if [ -n "$WARNINGS" ]; then
  WARNINGS="${WARNINGS//\"/\'}"
  echo "{\"decision\": \"approve\", \"reason\": \"Active work detected — informational only.\", \"systemMessage\": \"${WARNINGS}This is informational — brainstorms, exploration, and other independent work are unaffected.\"}"
else
  echo "{\"decision\": \"approve\"}"
fi

exit 0
