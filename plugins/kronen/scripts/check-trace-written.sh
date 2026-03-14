#!/usr/bin/env bash
set -euo pipefail
# kronen — Stop hook: remind about missing trace reflections
# Checks agency project traces for missing reflections section.
# Output: JSON with decision (approve/block) per Stop hook spec.
# Exit 0 always — signaling is via JSON decision field.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# --- Profile check ---
CACHE="${CLAUDE_PROJECT_DIR:-.}/.ai/context/kronen-profile-cache"
if [ -f "$CACHE" ]; then
  eval "$(grep '^KRONEN_[A-Z_]*=' "$CACHE")"
fi
[ "${KRONEN_TRACING:-light}" = "disabled" ] && exit 0

AGENCY_FILE="$PROJECT_DIR/.ai/agency.yml"
[ ! -f "$AGENCY_FILE" ] && exit 0

ACTIVE=$(grep 'active:' "$AGENCY_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"') || true
[ -z "$ACTIVE" ] && exit 0

STATE_FILE="$PROJECT_DIR/.ai/projects/$ACTIVE/state.yml"
[ ! -f "$STATE_FILE" ] && exit 0

# Check if tracing is enabled
TRACE_ENABLED=$(grep 'enabled: true' "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}') || true
[ "$TRACE_ENABLED" != "true" ] && exit 0

# Get traces directory
TRACES_DIR=$(grep 'traces_dir:' "$STATE_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"') || true
[ -z "$TRACES_DIR" ] && TRACES_DIR="$PROJECT_DIR/.ai/projects/$ACTIVE/traces/"
# Resolve relative paths against project dir
[[ "$TRACES_DIR" != /* ]] && TRACES_DIR="$PROJECT_DIR/$TRACES_DIR"
# Canonicalize and bounds check — must be inside PROJECT_DIR
TRACES_DIR=$(cd "$TRACES_DIR" 2>/dev/null && pwd -P) || exit 0
CANONICAL_PROJECT=$(cd "$PROJECT_DIR" 2>/dev/null && pwd -P) || exit 0
case "$TRACES_DIR" in "$CANONICAL_PROJECT"/*) ;; *) exit 0 ;; esac
[ ! -d "$TRACES_DIR" ] && exit 0

# Only check traces modified in the last 60 minutes (current session)
RECENT_COUNT=$(find "$TRACES_DIR" -name "*.yml" -mmin -60 2>/dev/null | wc -l) || true
[ "$RECENT_COUNT" -eq 0 ] 2>/dev/null && exit 0

INCOMPLETE=""
while IFS= read -r trace_file; do
  [ ! -f "$trace_file" ] && continue
  if ! grep -q 'reflections:' "$trace_file" 2>/dev/null; then
    SKILL=$(basename "$trace_file" | sed 's/-[0-9T].*\.yml$//')
    INCOMPLETE="${INCOMPLETE}${SKILL}, "
  fi
done < <(find "$TRACES_DIR" -name "*.yml" -mmin -60 2>/dev/null)

if [ -n "$INCOMPLETE" ]; then
  INCOMPLETE=$(echo "$INCOMPLETE" | sed 's/, $//')
  INCOMPLETE="${INCOMPLETE//\"/\'}"
  echo "{\"decision\": \"approve\", \"reason\": \"Traces missing reflections.\", \"systemMessage\": \"Trace reminder: ${INCOMPLETE} missing reflections section.\"}"
fi

exit 0
