#!/usr/bin/env bash
set -euo pipefail
# plan-gate.sh — Advisory warning when modifying plugin files without an active plan
# kronen PreToolUse hook (Write|Edit)
# Non-blocking (exit 0). Encourages plan-first workflow for plugin development.
# Source: adapted from claude-code-templates-main quality-gates/plan-gate.sh

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

# Only check plugin source files (skills, commands, agents, hooks, scripts)
# These are the files that benefit most from plan-first discipline
case "$FILE_PATH" in
  */plugins/*/skills/*|*/plugins/*/commands/*|*/plugins/*/agents/*) ;;
  */plugins/*/scripts/*|*/plugins/*/resources/*) ;;
  *) exit 0 ;;
esac

# Skip meta/config/doc files — they don't need a plan
case "$FILE_PATH" in
  */ecosystem.json|*/plugin.json|*/CLAUDE.md|*.yml|*.yaml|*.log) exit 0 ;;
  */MEMORY.md|*/README.md|*/CHANGELOG.md|*.gitignore) exit 0 ;;
esac

# Check for an active plan in .ai/plans/
HAS_ACTIVE_PLAN=0
for state_file in "$PROJECT_DIR"/.ai/plans/*/state.yml; do
  [ ! -f "$state_file" ] && continue
  grep -q '^status: in_progress' "$state_file" 2>/dev/null && HAS_ACTIVE_PLAN=1 && break
done

if [ "$HAS_ACTIVE_PLAN" -eq 0 ]; then
  # Log to hook-errors.log
  mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
  printf '%s|plan-gate|warn|%s|no active plan found\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$FILE_PATH" >> "$LOG_FILE" 2>/dev/null || true
  printf '\nPLAN GATE: Modifying "%s" without an active plan.\n' "$(basename "$FILE_PATH")" >&2
  printf '  For multi-file tasks, consider /plan:create before implementing.\n' >&2
  printf '  (Advisory only — does not block)\n\n' >&2
fi

exit 0
