#!/usr/bin/env bash
# claude-core — SessionStart wrapper for memory-health-check.sh
# Runs the health check at most once per day. Skips silently otherwise.
# Uses a timestamp file to track last run. Always exits 0.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
MARKER="$PROJECT_DIR/.ai/.memory-health-last-run"
TODAY=$(date -u +%Y-%m-%d)

# Fast path: already ran today
if [ -f "$MARKER" ]; then
  LAST_RUN=$(cat "$MARKER" 2>/dev/null || true)
  [ "$LAST_RUN" = "$TODAY" ] && exit 0
fi

# Run health check
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/memory-health-check.sh" 2>/dev/null || true

# Update marker
mkdir -p "$(dirname "$MARKER")" 2>/dev/null
echo "$TODAY" > "$MARKER" 2>/dev/null

exit 0
