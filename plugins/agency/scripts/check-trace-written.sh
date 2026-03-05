#!/usr/bin/env bash
# Agency plugin — Stop hook: verify trace completeness when tracing is enabled
# Scans all trace files for missing reflections section (v1.1.0 requirement)
# Does NOT depend on current_skill — works regardless of pipeline timing
#
# Exit codes: 0 = pass, 2 = non-blocking warning

# Find active project
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

# Scan all trace files for missing reflections
INCOMPLETE=""
for trace_file in "$TRACES_DIR"*.yml; do
  [ ! -f "$trace_file" ] && continue
  if ! grep -q 'reflections:' "$trace_file" 2>/dev/null; then
    SKILL=$(basename "$trace_file" | sed 's/-[0-9T].*\.yml$//')
    INCOMPLETE="${INCOMPLETE}  - ${SKILL} ($(basename "$trace_file"))\n"
  fi
done

if [ -n "$INCOMPLETE" ]; then
  echo "WARNING: Trace files missing 'reflections:' section:"
  printf "$INCOMPLETE"
  echo "Add reflections with at least one observation before completing."
  exit 2
fi

exit 0
