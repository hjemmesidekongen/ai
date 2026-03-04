#!/usr/bin/env bash
# Agency plugin — inject real timestamps into trace files
# Called by PostToolUse hook when Write targets a traces/ path
# Replaces [HOOK_TS] placeholders with real UTC timestamps

FILE="$1"
[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

# Only process files in a traces/ directory
case "$FILE" in
  *traces/*) ;;
  *) exit 0 ;;
esac

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
sed -i '' "s/\[HOOK_TS\]/$TS/g" "$FILE"
