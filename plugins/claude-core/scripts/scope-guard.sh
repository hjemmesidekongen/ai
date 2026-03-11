#!/usr/bin/env bash
set -euo pipefail
# scope-guard.sh — Advisory scope warning for active plan tasks
# claude-core PreToolUse hook (Write|Edit)
# Warns when writing a file not in the current wave's declared task writes.
# Non-blocking (exit 0). Only fires when active plan has non-empty writes lists.
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

# File not found in declared scope — advisory only
PLAN_NAME=$(basename "$(dirname "$ACTIVE_PLAN")")
# Log to hook-errors.log
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
printf '%s|scope-guard|warn|%s|not in declared writes for %s (plan: %s)\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$FILE_PATH" "$WAVE" "$PLAN_NAME" >> "$LOG_FILE" 2>/dev/null || true
printf 'SCOPE GUARD: "%s" not in declared writes for wave "%s" (plan: %s).\n' \
  "$(basename "$FILE_PATH")" "$WAVE" "$PLAN_NAME" >&2
printf '  Confirm intent or add path to the task writes list in state.yml.\n' >&2
exit 0
