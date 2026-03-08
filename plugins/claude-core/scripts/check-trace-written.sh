#!/usr/bin/env bash
# claude-core — Stop hook: remind about missing trace reflections
# Checks agency project traces for missing reflections section.
# Always exits 0 (informational, never blocks).

# --- Check agency project traces ---
AGENCY_FILE=".ai/agency.yml"
[ ! -f "$AGENCY_FILE" ] && exit 0

ACTIVE=$(grep 'active:' "$AGENCY_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"' || true)
[ -z "$ACTIVE" ] && exit 0

STATE_FILE=".ai/projects/$ACTIVE/state.yml"
[ ! -f "$STATE_FILE" ] && exit 0

# Check if tracing is enabled
TRACE_ENABLED=$(grep 'enabled: true' "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' || true)
[ "$TRACE_ENABLED" != "true" ] && exit 0

# Get traces directory
TRACES_DIR=$(grep 'traces_dir:' "$STATE_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"' || true)
[ -z "$TRACES_DIR" ] && TRACES_DIR=".ai/projects/$ACTIVE/traces/"
[ ! -d "$TRACES_DIR" ] && exit 0

# Only check traces modified in the last 60 minutes (current session)
RECENT_TRACES=$(find "$TRACES_DIR" -name "*.yml" -mmin -60 2>/dev/null)
[ -z "$RECENT_TRACES" ] && exit 0

INCOMPLETE=""
for trace_file in $RECENT_TRACES; do
  [ ! -f "$trace_file" ] && continue
  if ! grep -q 'reflections:' "$trace_file" 2>/dev/null; then
    SKILL=$(basename "$trace_file" | sed 's/-[0-9T].*\.yml$//')
    INCOMPLETE="${INCOMPLETE}${SKILL}, "
  fi
done

if [ -n "$INCOMPLETE" ]; then
  INCOMPLETE=$(echo "$INCOMPLETE" | sed 's/, $//')
  echo "{\"systemMessage\": \"Trace reminder: ${INCOMPLETE} missing reflections section\"}"
fi

exit 0
