#!/usr/bin/env bash
set -euo pipefail
# plan-recovery.sh — SessionStart hook
# Detects interrupted plans and surfaces them so the user or autopilot can resume.
# Informational only — never modifies state. Always exits 0.

trap 'exit 0' ERR

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PLANS_DIR="$PROJECT_DIR/.ai/plans"

# No plans directory — nothing to recover
[ ! -d "$PLANS_DIR" ] && exit 0

ACTIVE_PLANS=""
COUNT=0

for state_file in "$PLANS_DIR"/*/state.yml; do
  [ ! -f "$state_file" ] && continue

  STATUS=$(grep '^status:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"') || true
  [ "$STATUS" != "in_progress" ] && continue

  PLAN=$(grep '^plan:' "$state_file" 2>/dev/null | head -1 | sed 's/^plan: *//' | sed 's/^"\(.*\)"$/\1/') || true
  CYCLE=$(grep '^cycle:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}') || true
  UPDATED=$(grep '^updated_at:' "$state_file" 2>/dev/null | head -1 | sed 's/^updated_at: *//' | sed 's/^"\(.*\)"$/\1/') || true

  # Extract remaining_goal (handles multiline >)
  REMAINING=$(grep '^remaining_goal:' "$state_file" 2>/dev/null | head -1 | sed 's/^remaining_goal: *//' | sed 's/^"\(.*\)"$/\1/')
  if [ "$REMAINING" = ">" ] || [ "$REMAINING" = "|" ]; then
    REMAINING=$(awk '/^remaining_goal:/{found=1; next} found && /^  /{print; next} found{exit}' "$state_file" 2>/dev/null | head -1 | sed 's/^  //')
  fi

  # Truncate remaining_goal for display
  if [ ${#REMAINING} -gt 80 ]; then
    REMAINING="${REMAINING:0:77}..."
  fi

  COUNT=$((COUNT + 1))
  ACTIVE_PLANS="${ACTIVE_PLANS}  - ${PLAN}: cycle ${CYCLE}, remaining: ${REMAINING}\n"
  ACTIVE_PLANS="${ACTIVE_PLANS}    Last updated: ${UPDATED}\n"
  ACTIVE_PLANS="${ACTIVE_PLANS}    Resume with: /plan resume ${PLAN}\n"
done

if [ "$COUNT" -gt 0 ]; then
  printf "Active plans detected:\n"
  printf '%b' "$ACTIVE_PLANS"
fi

exit 0
