#!/usr/bin/env bash
#
# check-wave-complete.sh
#
# Stop hook for dev plugin. Only blocks session exit when an active
# build phase is running. Allows exit when idle, complete, or blocked.
#
# Usage: bash plugins/dev/scripts/check-wave-complete.sh
# Always exits 0 — warnings are informational, not errors

set -euo pipefail

# Find team-state.yml in any dev project directory
STATE_FILE=""
for f in .ai/dev/*/team-state.yml; do
  [ -f "$f" ] && STATE_FILE="$f" && break
done

# No state file → nothing to gate on
if [ -z "$STATE_FILE" ]; then
  echo "No team-state.yml found. Safe to stop."
  exit 0
fi

# Read build.status (nested under build:)
BUILD_STATUS=$(grep -A5 '^build:' "$STATE_FILE" 2>/dev/null | grep 'status:' | head -1 | awk '{print $2}' | tr -d '"' || true)

# Empty/null status → no active build
if [ -z "$BUILD_STATUS" ]; then
  echo "No active build. Safe to stop."
  exit 0
fi

# Only block on active build phases
case "$BUILD_STATUS" in
  decomposing|planning|executing|reviewing)
    FEATURE=$(grep -A5 '^build:' "$STATE_FILE" 2>/dev/null | grep 'feature:' | head -1 | awk '{$1=""; print $0}' | sed 's/^ *//' | tr -d '"' || true)
    echo "⚠ Build is actively running (status: $BUILD_STATUS, feature: $FEATURE)."
    echo "Consider completing the current build phase before stopping."
    exit 0
    ;;
  *)
    echo "Build status: $BUILD_STATUS. Safe to stop."
    exit 0
    ;;
esac
