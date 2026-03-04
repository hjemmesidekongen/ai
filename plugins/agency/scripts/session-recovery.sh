#!/bin/bash
# Agency plugin — session recovery hook
# Reads active project state and reports context for resumed sessions

set -euo pipefail

echo "=== Agency Plugin Session Recovery ==="

# Find active project
AGENCY_FILE=".ai/agency.yml"
if [ ! -f "$AGENCY_FILE" ]; then
  echo "No agency.yml found. No active project."
  exit 0
fi

ACTIVE=$(grep 'active:' "$AGENCY_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"' || true)
if [ -z "$ACTIVE" ]; then
  echo "No active project set in agency.yml."
  exit 0
fi

echo "Active project: $ACTIVE"

# Read project state
STATE_FILE=".ai/projects/$ACTIVE/state.yml"
if [ -f "$STATE_FILE" ]; then
  echo "--- Project State ---"
  head -30 "$STATE_FILE"
else
  echo "No state.yml found for project $ACTIVE."
fi

# Check for uncommitted changes
echo "--- Git Status ---"
git status --short 2>/dev/null | head -20 || true

echo "=== End Recovery ==="
exit 0
