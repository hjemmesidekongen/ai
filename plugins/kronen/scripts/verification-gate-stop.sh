#!/usr/bin/env bash
set -euo pipefail
# kronen — Stop hook: verify that proof was run before claiming done
# Checks trace-light.log: if an active plan has in_progress tasks but
# the last session operations were only writes with no verification run,
# emits an advisory reminder.
# Output: JSON with decision (approve always — advisory only).
# Exit 0 always.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
TRACE_FILE="$PROJECT_DIR/.ai/traces/trace-light.log"
MSG=""

# Only meaningful if a plan is in progress
ACTIVE_PLAN=""
for state_file in "$PROJECT_DIR"/.ai/plans/*/state.yml; do
  [ ! -f "$state_file" ] && continue
  STATUS=$(grep '^status:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"') || true
  if [ "$STATUS" = "in_progress" ]; then
    ACTIVE_PLAN=$(grep '^plan:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"') || true
    break
  fi
done

[ -z "$ACTIVE_PLAN" ] && echo '{"decision": "approve"}' && exit 0
[ ! -f "$TRACE_FILE" ] && echo '{"decision": "approve"}' && exit 0

# Scan last 30 trace entries for verification signals
# Verification tools: Bash (running commands), Read (reading output)
# Write-only session: only Write/Edit with no Bash/Read/Grep after the last write
LAST_WRITE_LINE=0
LAST_VERIFY_LINE=0
LINE_NUM=0

while IFS='|' read -r _ts tool _status _ctx; do
  LINE_NUM=$((LINE_NUM + 1))
  case "$tool" in
    Write|Edit)
      LAST_WRITE_LINE=$LINE_NUM ;;
    Bash|Read|Grep)
      LAST_VERIFY_LINE=$LINE_NUM ;;
  esac
done < <(tail -30 "$TRACE_FILE")

# If there were writes but no verification step after the last write
if [ "$LAST_WRITE_LINE" -gt 0 ] && [ "$LAST_VERIFY_LINE" -lt "$LAST_WRITE_LINE" ]; then
  MSG="Plan '${ACTIVE_PLAN}' has recent writes with no verification step. Run proof before marking tasks done (verification-gate protocol)."
fi

if [ -n "$MSG" ]; then
  MSG="${MSG//\"/\'}"
  echo "{\"decision\": \"approve\", \"reason\": \"Verification reminder.\", \"systemMessage\": \"${MSG}\"}"
else
  echo '{"decision": "approve"}'
fi

exit 0
