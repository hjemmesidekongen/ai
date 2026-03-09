#!/usr/bin/env bash
# claude-core — Stop hook: capture session context before exit
# Writes .ai/context/snapshot.yml via shared assembler.
# Non-blocking — always exits 0. Timeout 10s.

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
ASSEMBLER="$PLUGIN_ROOT/scripts/assemble-context.sh"

if [ -f "$ASSEMBLER" ]; then
  bash "$ASSEMBLER" stop 2>/dev/null || true
fi

exit 0
