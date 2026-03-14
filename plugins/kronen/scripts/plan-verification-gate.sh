#!/usr/bin/env bash
set -euo pipefail
# plan-verification-gate.sh — Blocking PreToolUse hook (Write|Edit)
# Prevents advancing to a future wave's files without current wave verification passing.
# Exit 0 = allow, Exit 2 with JSON = block.

trap 'exit 0' ERR

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LOG_FILE="$PROJECT_DIR/.ai/traces/hook-errors.log"

# --- Profile check ---
CACHE="${CLAUDE_PROJECT_DIR:-.}/.ai/context/kronen-profile-cache"
if [ -f "$CACHE" ]; then
  eval "$(grep '^KRONEN_[A-Z_]*=' "$CACHE")"
fi
[ "${KRONEN_VERIFICATION:-strict}" = "disabled" ] && exit 0

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

# --- Scope.paths.exclude enforcement ---
# If the active plan declares scope.paths.exclude, block writes matching excluded patterns.
# Per-task scope_override provides an escape hatch for legitimate exceptions.

# Extract scope.paths.exclude from state.yml
SCOPE_EXCLUDES=""
IN_SCOPE=0; IN_PATHS=0; IN_EXCLUDE=0
while IFS= read -r line; do
  case "$line" in "scope:"*) IN_SCOPE=1; continue ;; esac
  [ "$IN_SCOPE" -eq 0 ] && continue
  case "$line" in [a-zA-Z]*) break ;; esac
  case "$line" in
    "  paths:"*) IN_PATHS=1; continue ;;
    "  "[a-zA-Z]*) [ "$IN_PATHS" -eq 1 ] && IN_PATHS=0 ;;
  esac
  [ "$IN_PATHS" -eq 0 ] && continue
  case "$line" in
    "    exclude:"*) IN_EXCLUDE=1; continue ;;
    "    "[a-zA-Z]*) IN_EXCLUDE=0 ;;
  esac
  if [ "$IN_EXCLUDE" -eq 1 ]; then
    case "$line" in "      - "*)
      pattern="${line#      - }"; pattern="${pattern%\"*}"; pattern="${pattern#\"}"
      SCOPE_EXCLUDES="$SCOPE_EXCLUDES $pattern" ;;
    esac
  fi
done < "$ACTIVE_STATE"

# If no excludes declared, skip
if [ -n "$SCOPE_EXCLUDES" ]; then
  EXCLUDE_MATCH=0
  MATCHED_PATTERN=""
  for pattern in $SCOPE_EXCLUDES; do
    simple_pattern="${pattern//\*\*/DOUBLEGLOBSTAR}"
    simple_pattern="${simple_pattern//\*/[^/]*}"
    simple_pattern="${simple_pattern//DOUBLEGLOBSTAR/*}"
    case "$FILE_PATH" in $simple_pattern)
      EXCLUDE_MATCH=1; MATCHED_PATTERN="$pattern"; break ;;
    esac
  done

  if [ "$EXCLUDE_MATCH" -eq 1 ]; then
    # Check for per-task scope_override in plan.yml
    # Extract scope_override entries for all tasks in the current wave
    OVERRIDE_MATCH=0
    if [ -f "$PLAN_YML" ]; then
      OVERRIDES=$(grep -A 50 'scope_override:' "$PLAN_YML" 2>/dev/null | grep '^ *- ' | sed 's/^ *- *//' | sed 's/^"\(.*\)"$/\1/' | tr -d "'" || true)
      while IFS= read -r override; do
        [ -z "$override" ] && continue
        ovr_pattern="${override//\*\*/DOUBLEGLOBSTAR}"
        ovr_pattern="${ovr_pattern//\*/[^/]*}"
        ovr_pattern="${ovr_pattern//DOUBLEGLOBSTAR/*}"
        case "$FILE_PATH" in $ovr_pattern) OVERRIDE_MATCH=1; break ;; esac
      done <<< "$OVERRIDES"
    fi

    if [ "$OVERRIDE_MATCH" -eq 0 ]; then
      mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
      printf '%s|plan-verification-gate|block|%s|matches scope.paths.exclude pattern: %s\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$FILE_PATH" "$MATCHED_PATTERN" >> "$LOG_FILE" 2>/dev/null || true
      printf '{"decision": "block", "reason": "File \"%s\" matches scope.paths.exclude pattern \"%s\". Add scope_override to the task in plan.yml if this is intentional."}' \
        "$(basename "$FILE_PATH")" "$MATCHED_PATTERN" >&2
      exit 2
    fi
  fi
fi

# File is either in the current wave, a past wave, not claimed by any wave, or override matched — allow
exit 0
