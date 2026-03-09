#!/usr/bin/env bash
# claude-core — PreCompact hook: capture working state before context compression
# Delegates to shared assembler. Always exits 0.

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
ASSEMBLER="$PLUGIN_ROOT/scripts/assemble-context.sh"

if [ -f "$ASSEMBLER" ]; then
  bash "$ASSEMBLER" precompact 2>/dev/null || true
fi

exit 0
