#!/usr/bin/env bash
set -euo pipefail
# plan-scope-guard.sh — Advisory scope warning for active plan tasks
# kronen PreToolUse hook (Write|Edit)
# Two checks (both advisory, non-blocking):
#   1. Task-level: warns when writing a file not in the current wave's declared task writes
#   2. Plan-level: warns when writing outside scope.paths.include (if declared in state.yml)
# Complements compact-gate-pre.sh which blocks writes when compact is needed.

trap 'exit 0' ERR

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LOG_FILE="$PROJECT_DIR/.ai/traces/hook-errors.log"
INPUT=$(cat)

# Extract file path
FILE_PATH=""
case "$INPUT" in *'"file_path":"'*)
  FILE_PATH="${INPUT#*\"file_path\":\"}"
  FILE_PATH="${FILE_PATH%%\"*}" ;;
esac
[ -z "$FILE_PATH" ] && exit 0

# Always-allowed patterns — meta, config, tracing, and docs never need scope check
case "$FILE_PATH" in
  */SKILL.md|*/CLAUDE.md|*/ecosystem.json|*/plugin.json|*/README.md) exit 0 ;;
  *state.yml|*decisions.yml|*findings.md|*roadmap.yml|*MEMORY.md) exit 0 ;;
  *.log|*snapshot.yml|*external-reference-findings.md|*.gitignore) exit 0 ;;
  *trace-light.log|*observations.jsonl|*instincts.yml) exit 0 ;;
esac

# Find active plan
ACTIVE_PLAN=""
for state_file in "$PROJECT_DIR"/.ai/plans/*/state.yml; do
  [ ! -f "$state_file" ] && continue
  grep -q '^status: in_progress' "$state_file" 2>/dev/null || continue
  ACTIVE_PLAN="$state_file"
  break
done
[ -z "$ACTIVE_PLAN" ] && exit 0

# Get current wave name
WAVE=""
while IFS= read -r line; do
  case "$line" in "current_wave: "*)
    WAVE="${line#current_wave: }"; WAVE="${WAVE%\"*}"; WAVE="${WAVE#\"}" ;;
  esac
done < "$ACTIVE_PLAN"
[ -z "$WAVE" ] || [ "$WAVE" = "null" ] && exit 0

# Get task IDs for current wave
WAVE_TASK_IDS=""
IN_WAVES=0; IN_TARGET_WAVE=0
while IFS= read -r line; do
  case "$line" in "waves:"*) IN_WAVES=1; continue ;; esac
  [ "$IN_WAVES" -eq 0 ] && continue
  case "$line" in [a-zA-Z]*) break ;; esac
  case "$line" in
    "  $WAVE:"*) IN_TARGET_WAVE=1; continue ;;
    "  "[a-zA-Z]*) [ "$IN_TARGET_WAVE" -eq 1 ] && break ;;
  esac
  [ "$IN_TARGET_WAVE" -eq 0 ] && continue
  case "$line" in *"tasks:"*"["*)
    WAVE_TASK_IDS="${line#*\[}"; WAVE_TASK_IDS="${WAVE_TASK_IDS%\]*}"; break ;;
  esac
done < "$ACTIVE_PLAN"
[ -z "$WAVE_TASK_IDS" ] && exit 0

# Collect writes from current wave tasks
WAVE_WRITES=""
IN_TASKS=0; CURRENT_TASK=""; IN_WRITES=0
while IFS= read -r line; do
  case "$line" in "tasks:"*) IN_TASKS=1; continue ;; esac
  [ "$IN_TASKS" -eq 0 ] && continue
  case "$line" in "  "[a-zA-Z0-9_-]*":"*)
    tid="${line#  }"; tid="${tid%%:*}"
    CURRENT_TASK=""
    case " $WAVE_TASK_IDS" in *"$tid"*) CURRENT_TASK="$tid" ;; esac
    IN_WRITES=0; continue ;;
  esac
  [ -z "$CURRENT_TASK" ] && continue
  case "$line" in "    writes:"*) IN_WRITES=1; continue ;; esac
  if [ "$IN_WRITES" -eq 1 ]; then
    case "$line" in "      - "*)
      wp="${line#      - }"; WAVE_WRITES="$WAVE_WRITES $wp" ;;
    *) IN_WRITES=0 ;;
    esac
  fi
done < "$ACTIVE_PLAN"

# No writes declared — cannot verify scope, allow silently
[ -z "$WAVE_WRITES" ] && exit 0

# Check if target file matches any declared write path (suffix match)
for wp in $WAVE_WRITES; do
  case "$FILE_PATH" in *"$wp") exit 0 ;; esac
  [ "$FILE_PATH" = "$wp" ] && exit 0
done

# File not found in declared task writes — advisory warning
PLAN_NAME=$(basename "$(dirname "$ACTIVE_PLAN")")
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
printf '%s|plan-scope-guard|warn|%s|not in declared writes for %s (plan: %s)\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$FILE_PATH" "$WAVE" "$PLAN_NAME" >> "$LOG_FILE" 2>/dev/null || true
printf 'SCOPE GUARD: "%s" not in declared writes for wave "%s" (plan: %s).\n' \
  "$(basename "$FILE_PATH")" "$WAVE" "$PLAN_NAME" >&2
printf '  Confirm intent or add path to the task writes list in state.yml.\n' >&2

# --- Plan-level scope.paths.include check ---
# If the plan declares scope.paths.include, warn when writing outside all include patterns.
# This is independent of the task-writes check above — both fire independently.
SCOPE_INCLUDES=""
IN_SCOPE=0; IN_PATHS=0; IN_INCLUDE=0
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
    "    include:"*) IN_INCLUDE=1; continue ;;
    "    "[a-zA-Z]*) IN_INCLUDE=0 ;;
  esac
  if [ "$IN_INCLUDE" -eq 1 ]; then
    case "$line" in "      - "*)
      pattern="${line#      - }"; pattern="${pattern%\"*}"; pattern="${pattern#\"}"
      SCOPE_INCLUDES="$SCOPE_INCLUDES $pattern" ;;
    esac
  fi
done < "$ACTIVE_PLAN"

# If scope.paths.include is declared, check if file matches any pattern
if [ -n "$SCOPE_INCLUDES" ]; then
  SCOPE_MATCH=0
  for pattern in $SCOPE_INCLUDES; do
    # Use bash glob matching (fnmatch-style via case)
    # Convert ** to match-all for simple glob matching
    simple_pattern="${pattern//\*\*/DOUBLEGLOBSTAR}"
    simple_pattern="${simple_pattern//\*/[^/]*}"
    simple_pattern="${simple_pattern//DOUBLEGLOBSTAR/*}"
    case "$FILE_PATH" in $simple_pattern) SCOPE_MATCH=1; break ;; esac
  done
  if [ "$SCOPE_MATCH" -eq 0 ]; then
    printf '%s|plan-scope-guard|warn|%s|outside scope.paths.include (plan: %s)\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$FILE_PATH" "$PLAN_NAME" >> "$LOG_FILE" 2>/dev/null || true
    printf 'SCOPE GUARD: "%s" is outside plan scope.paths.include (plan: %s).\n' \
      "$(basename "$FILE_PATH")" "$PLAN_NAME" >&2
    printf '  This file does not match any include pattern. Confirm intent.\n' >&2
  fi
fi

exit 0
