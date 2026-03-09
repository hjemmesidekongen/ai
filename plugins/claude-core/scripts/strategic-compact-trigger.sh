#!/usr/bin/env bash
set -euo pipefail
# claude-core — strategic compact trigger (PostToolUse, always-on)
# Advisory hook that suggests /compact when context depth is high.
# Counts trace-light.log lines as a proxy for tool call depth.
# Samples every 10th call. Fires at 50, 100, 150... calls.
# Never blocks (exit 0 always). Never sets compact-needed flag.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
TRACE_FILE="$PROJECT_DIR/.ai/traces/trace-light.log"

# No trace file yet — too early to care
[ ! -f "$TRACE_FILE" ] && exit 0

# Fast line count using wc
LINE_COUNT=$(wc -l < "$TRACE_FILE" 2>/dev/null || echo 0)
LINE_COUNT="${LINE_COUNT// /}"

# Only evaluate every 10th call
(( LINE_COUNT % 10 != 0 )) && exit 0

# Below threshold — nothing to say
(( LINE_COUNT < 50 )) && exit 0

# If boundary gate already flagged compact, don't pile on
[ -f "$PROJECT_DIR/.ai/compact-needed" ] && exit 0

# Emit advisory
echo "Context depth: ~${LINE_COUNT} tool calls this session. Consider running /compact to preserve context quality."

exit 0
