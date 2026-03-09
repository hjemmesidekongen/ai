#!/usr/bin/env bash
set -euo pipefail
# claude-core — Stop hook: clear plugin cache at session end
# Prevents stale cache from persisting across sessions in this dev workspace.

rm -rf ~/.claude/plugins/cache/local-workspace/ 2>/dev/null || true

exit 0
