#!/usr/bin/env bash
# claude-core — SessionStart hook: report context for resumed sessions
# 1. Refreshes snapshot via assembler (source=session-start)
# 2. Reads enriched snapshot and outputs structured context
# 3. Stale check: deletes snapshots older than 48h
# 4. Falls back to plan/project recovery if no snapshot
# Always exits 0.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SNAPSHOT="$PROJECT_DIR/.ai/context/snapshot.yml"
FLAG="$PROJECT_DIR/.ai/compact-needed"

# --- Stale check: delete snapshots older than 48h ---
find "$PROJECT_DIR/.ai/context" -name "snapshot.yml" -mmin +2880 -delete 2>/dev/null || true

# --- Clean up legacy path ---
rm -f "$PROJECT_DIR/.ai/compact-snapshot.yml" 2>/dev/null

# --- Refresh snapshot via assembler ---
ASSEMBLER="$PLUGIN_ROOT/scripts/assemble-context.sh"
if [ -f "$ASSEMBLER" ]; then
  bash "$ASSEMBLER" session-start 2>/dev/null || true
fi

# --- Output snapshot if it exists ---
if [ -f "$SNAPSHOT" ]; then
  echo "=== Context Snapshot ==="
  cat "$SNAPSHOT"
  echo "=== End Snapshot ==="
  rm -f "$FLAG" 2>/dev/null
fi

echo "=== Session Recovery Check ==="

FOUND_CONTEXT=0

# --- Check active plans ---
for state_file in "$PROJECT_DIR"/.ai/plans/*/state.yml; do
  [ ! -f "$state_file" ] && continue
  STATUS=$(grep '^status:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"') || true
  if [ "$STATUS" = "in_progress" ]; then
    PLAN=$(grep '^plan:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"') || true
    WAVE=$(grep '^current_wave:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"') || true
    TASK=$(grep '^current_task:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"') || true
    echo "Active plan: $PLAN (wave: $WAVE, task: $TASK)"

    ERRORS=$(grep -c '  - timestamp:' "$state_file" 2>/dev/null) || ERRORS=0
    [ "$ERRORS" -gt 0 ] && echo "  Logged errors: $ERRORS"
    FOUND_CONTEXT=1
  fi
done

# --- Check active agency project ---
AGENCY_FILE="$PROJECT_DIR/.ai/agency.yml"
if [ -f "$AGENCY_FILE" ]; then
  ACTIVE=$(grep 'active:' "$AGENCY_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"') || true
  if [ -n "$ACTIVE" ]; then
    STATE_FILE="$PROJECT_DIR/.ai/projects/$ACTIVE/state.yml"
    if [ -f "$STATE_FILE" ]; then
      echo "Active project: $ACTIVE"
      echo "--- Project State ---"
      head -30 "$STATE_FILE"
      FOUND_CONTEXT=1
    fi
  fi
fi

if [ $FOUND_CONTEXT -eq 0 ]; then
  echo "No state.yml found. Fresh start."
fi

# --- Git status ---
echo "--- Git Status ---"
git status --short 2>/dev/null | head -20 || true

echo "=== End Recovery ==="
exit 0
