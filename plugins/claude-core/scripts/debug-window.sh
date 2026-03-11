#!/usr/bin/env bash
set -euo pipefail
# debug-window.sh — Captures test/build failures for debugging visibility
# claude-core PostToolUse hook (Bash)
# Detects failed Bash commands that look like test/build runs.
# Logs structured failure info to .ai/traces/debug-failures.log.
# Non-blocking (exit 0).

trap 'exit 0' ERR

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
DEBUG_LOG="$PROJECT_DIR/.ai/traces/debug-failures.log"
INPUT=$(cat)

# Extract exit code — only care about failures
EXIT_CODE=""
case "$INPUT" in *'"exit_code":'*)
  EXIT_CODE="${INPUT#*\"exit_code\":}"
  EXIT_CODE="${EXIT_CODE%%[,}]*}"
  EXIT_CODE=$(echo "$EXIT_CODE" | tr -d ' "')
  ;;
esac
[ -z "$EXIT_CODE" ] || [ "$EXIT_CODE" = "0" ] && exit 0

# Extract the command that failed
COMMAND=""
case "$INPUT" in *'"command":"'*)
  COMMAND="${INPUT#*\"command\":\"}"
  COMMAND="${COMMAND%%\"*}" ;;
esac
[ -z "$COMMAND" ] && exit 0

# Only log test/build/lint failures — skip general commands
IS_RELEVANT=false
case "$COMMAND" in
  *test*|*jest*|*vitest*|*pytest*|*mocha*|*cypress*) IS_RELEVANT=true ;;
  *build*|*compile*|*tsc*|*webpack*|*vite*|*esbuild*) IS_RELEVANT=true ;;
  *lint*|*eslint*|*prettier*|*stylelint*) IS_RELEVANT=true ;;
  *make*|*cargo*|*go\ build*|*go\ test*) IS_RELEVANT=true ;;
  *npm\ run*|*yarn*|*pnpm*|*bun\ run*) IS_RELEVANT=true ;;
esac
[ "$IS_RELEVANT" = false ] && exit 0

# Ensure log directory exists
mkdir -p "$(dirname "$DEBUG_LOG")"

# Extract stderr snippet if available (truncate to 500 chars)
STDERR=""
case "$INPUT" in *'"stderr":"'*)
  STDERR="${INPUT#*\"stderr\":\"}"
  STDERR="${STDERR%%\"*}"
  STDERR="${STDERR:0:500}" ;;
esac

# Log structured failure entry
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
{
  echo "---"
  echo "timestamp: $TIMESTAMP"
  echo "command: \"$COMMAND\""
  echo "exit_code: $EXIT_CODE"
  [ -n "$STDERR" ] && echo "stderr_snippet: \"$STDERR\""
  echo ""
} >> "$DEBUG_LOG"

exit 0
