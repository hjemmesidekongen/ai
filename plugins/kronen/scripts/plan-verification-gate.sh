#!/usr/bin/env bash
set -euo pipefail
# plan-verification-gate.sh — Blocking PreToolUse hook (Write|Edit)
# Prevents advancing to a future wave's files without current wave verification passing.
# Exit 0 = allow, Exit 2 with JSON = block.

trap 'exit 0' ERR

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LOG_FILE="$PROJECT_DIR/.ai/traces/hook-errors.log"
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=""
case "$INPUT" in *'"file_path":"'*)
  FILE_PATH="${INPUT#*\"file_path\":\"}"
  FILE_PATH="${FILE_PATH%%\"*}" ;;
esac
[ -z "$FILE_PATH" ] && exit 0

# Skip non-project files and meta files
case "$FILE_PATH" in
  */state.yml|*/learnings.yml|*/plan.yml|*/plan.md|*/artifacts/*) exit 0 ;;
  */.ai/*|*/CLAUDE.md|*/MEMORY.md|*.log) exit 0 ;;
esac

# Find active plan
ACTIVE_PLAN_DIR=""
ACTIVE_STATE=""
for state_file in "$PROJECT_DIR"/.ai/plans/*/state.yml; do
  [ ! -f "$state_file" ] && continue
  if grep -q '^status: in_progress' "$state_file" 2>/dev/null; then
    ACTIVE_STATE="$state_file"
    ACTIVE_PLAN_DIR="$(dirname "$state_file")"
    break
  fi
done

# No active plan — allow
[ -z "$ACTIVE_PLAN_DIR" ] && exit 0

# Check if plan.yml exists
PLAN_YML="$ACTIVE_PLAN_DIR/plan.yml"
[ ! -f "$PLAN_YML" ] && exit 0

# Extract current wave from state.yml
# Look for the last entry in planned_waves array
CURRENT_WAVE=""
PLANNED_WAVES=$(sed -n '/^planned_waves:/,/^[a-z_]*:/{ /^  - /p; }' "$ACTIVE_STATE" 2>/dev/null | tail -1 | sed 's/^  - *//' | sed 's/^"\(.*\)"$/\1/' | tr -d "'")
if [ -n "$PLANNED_WAVES" ]; then
  CURRENT_WAVE="$PLANNED_WAVES"
fi

# If no waves planned yet, allow everything
[ -z "$CURRENT_WAVE" ] && exit 0

# Extract files_written for each wave from plan.yml
# This is a simplified check — we look for files_written entries under each wave section
# and check if the target file belongs to a future wave

# Get all wave names in order
WAVE_NAMES=$(grep '^  - wave:' "$PLAN_YML" 2>/dev/null | sed 's/.*wave: *//' | sed 's/^"\(.*\)"$/\1/' | tr -d "'")
[ -z "$WAVE_NAMES" ] && exit 0

# Determine if we've passed the current wave
PAST_CURRENT=0
FOUND_IN_FUTURE=0

while IFS= read -r wave_name; do
  [ -z "$wave_name" ] && continue

  if [ "$PAST_CURRENT" -eq 1 ]; then
    # We're looking at future waves — check if target file is declared here
    # Extract files_written for this wave section from plan.yml
    # This is approximate — complex YAML parsing in bash is limited
    WAVE_FILES=$(awk "/^  - wave: .*${wave_name}/,/^  - wave:/" "$PLAN_YML" 2>/dev/null | grep 'files_written' | sed 's/.*files_written.*\[//' | sed 's/\].*//' | tr ',' '\n' | sed 's/^[[:space:]]*"//' | sed 's/"[[:space:]]*$//')

    while IFS= read -r declared_file; do
      [ -z "$declared_file" ] && continue
      # Direct match or suffix match (handles relative vs absolute paths)
      if [ "$FILE_PATH" = "$declared_file" ] || [[ "$FILE_PATH" == */"$declared_file" ]]; then
        FOUND_IN_FUTURE=1
        break
      fi
    done <<< "$WAVE_FILES"

    [ "$FOUND_IN_FUTURE" -eq 1 ] && break
  fi

  # Check if this is the current wave
  if [ "$wave_name" = "$CURRENT_WAVE" ]; then
    PAST_CURRENT=1
  fi
done <<< "$WAVE_NAMES"

# If the file belongs to a future wave, block it
if [ "$FOUND_IN_FUTURE" -eq 1 ]; then
  mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
  printf '%s|plan-verification-gate|block|%s|file belongs to future wave, current wave not yet verified\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$FILE_PATH" >> "$LOG_FILE" 2>/dev/null || true

  printf '{"decision": "block", "reason": "File \"%s\" belongs to a future wave. Complete and verify the current wave (%s) first."}' \
    "$(basename "$FILE_PATH")" "$CURRENT_WAVE" >&2
  exit 2
fi

# File is either in the current wave, a past wave, or not claimed by any wave — allow
exit 0
