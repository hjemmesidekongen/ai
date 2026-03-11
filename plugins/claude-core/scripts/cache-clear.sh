#!/usr/bin/env bash
set -euo pipefail
# claude-core — Stop hook: clear plugin cache at session end
# Prevents stale cache from persisting across sessions in this dev workspace.

[ -z "${HOME:-}" ] && exit 0
CACHE_DIR="$HOME/.claude/plugins/cache/hjemmesidekongen-ai"
[ -d "$CACHE_DIR" ] && rm -rf "$CACHE_DIR"

exit 0
