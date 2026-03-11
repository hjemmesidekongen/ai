#!/usr/bin/env bash
set -euo pipefail
# claude-core — light tracing hook (PostToolUse, always-on)
# Appends one line per tool invocation to .ai/traces/trace-light.log
# Format: timestamp|tool_name|status|context
# Optimized for <30ms — minimal subprocesses, bash builtins where possible.
# Always exits 0.

# Read hook input JSON from stdin
INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Timestamp (UTC ISO 8601)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# --- Extract fields using bash builtins (avoid subshells) ---

# tool_name
TOOL="${INPUT#*\"tool_name\":\"}"
[ "$TOOL" = "$INPUT" ] && exit 0
TOOL="${TOOL%%\"*}"
[ -z "$TOOL" ] && exit 0

# status — prefer explicit is_error field, fall back to tool_result error signals
STATUS="success"
case "$INPUT" in
  *'"is_error"'*true*|*'"is_error": true'*)
    STATUS="error" ;;
  *)
    # Check tool_result only (not tool_input) for error signals
    RESULT="${INPUT#*\"tool_result\"}"
    if [ "$RESULT" != "$INPUT" ]; then
      case "$RESULT" in
        *'Exit code'*|*'No such file'*|*'Permission denied'*|*'command not found'*|*'ENOENT'*|*'EACCES'*)
          STATUS="error" ;;
      esac
    fi ;;
esac

# Extract context field based on tool type
CONTEXT=""
case "$TOOL" in
  Write|Edit|Read)
    case "$INPUT" in *'"file_path":"'*)
      CONTEXT="${INPUT#*\"file_path\":\"}"
      CONTEXT="${CONTEXT%%\"*}" ;; esac ;;
  Bash)
    case "$INPUT" in *'"command":"'*)
      CONTEXT="${INPUT#*\"command\":\"}"
      # Cut at JSON structural boundary instead of interior escaped quotes
      tmp="${CONTEXT%%\",\"*}"; tmp2="${CONTEXT%%\"\}*}"
      [ ${#tmp2} -lt ${#tmp} ] && tmp="$tmp2"
      CONTEXT="$tmp"
      # Unescape JSON quotes
      CONTEXT="${CONTEXT//\\\"/\"}"
      ;; esac
    [ ${#CONTEXT} -gt 80 ] && CONTEXT="${CONTEXT:0:77}..." ;;
  Grep|Glob)
    case "$INPUT" in *'"pattern":"'*)
      CONTEXT="${INPUT#*\"pattern\":\"}"
      CONTEXT="${CONTEXT%%\"*}" ;; esac ;;
  Skill)
    case "$INPUT" in *'"skill":"'*)
      CONTEXT="${INPUT#*\"skill\":\"}"
      CONTEXT="${CONTEXT%%\"*}" ;; esac ;;
  Agent)
    case "$INPUT" in *'"description":"'*)
      CONTEXT="${INPUT#*\"description\":\"}"
      tmp="${CONTEXT%%\",\"*}"; tmp2="${CONTEXT%%\"\}*}"
      [ ${#tmp2} -lt ${#tmp} ] && tmp="$tmp2"
      CONTEXT="$tmp" ;; esac
    if [ -z "$CONTEXT" ]; then
      case "$INPUT" in *'"prompt":"'*)
        CONTEXT="${INPUT#*\"prompt\":\"}"
        tmp="${CONTEXT%%\",\"*}"; tmp2="${CONTEXT%%\"\}*}"
        [ ${#tmp2} -lt ${#tmp} ] && tmp="$tmp2"
        CONTEXT="$tmp" ;; esac
    fi
    [ ${#CONTEXT} -gt 80 ] && CONTEXT="${CONTEXT:0:77}..." ;;
  mcp__*)
    # MCP tool calls — extract first string-valued parameter as context
    # Try common field names in order of usefulness
    for field in operations patterns query prompt filePathOrNew topic skill tags name; do
      case "$INPUT" in *"\"${field}\":\""*)
        CONTEXT="${INPUT#*\"${field}\":\"}"
        CONTEXT="${CONTEXT%%\"*}"
        break ;; esac
    done
    # If no string field found, try to get the first key from tool_input
    if [ -z "$CONTEXT" ]; then
      case "$INPUT" in *'"tool_input":'*)
        CONTEXT="(structured input)" ;; esac
    fi
    [ ${#CONTEXT} -gt 80 ] && CONTEXT="${CONTEXT:0:77}..." ;;
  *)
    case "$INPUT" in *'"file_path":"'*)
      CONTEXT="${INPUT#*\"file_path\":\"}"
      CONTEXT="${CONTEXT%%\"*}" ;; esac
    if [ -z "$CONTEXT" ]; then
      case "$INPUT" in *'"command":"'*)
        CONTEXT="${INPUT#*\"command\":\"}"
        tmp="${CONTEXT%%\",\"*}"; tmp2="${CONTEXT%%\"\}*}"
        [ ${#tmp2} -lt ${#tmp} ] && tmp="$tmp2"
        CONTEXT="$tmp"
        CONTEXT="${CONTEXT//\\\"/\"}"
        ;; esac
    fi ;;
esac

# Sanitize: replace pipe delimiters, default to dash
CONTEXT="${CONTEXT//|//}"
[ -z "$CONTEXT" ] && CONTEXT="-"
[ ${#CONTEXT} -gt 120 ] && CONTEXT="${CONTEXT:0:117}..."
# Note: 80-char truncation for Bash/Agent already adds "..." (lines 56, 78)

# Ensure trace directory exists
TRACE_DIR="$PROJECT_DIR/.ai/traces"
[ ! -d "$TRACE_DIR" ] && mkdir -p "$TRACE_DIR" 2>/dev/null

# Log rotation — date-based (one read + conditional mv)
TRACE_FILE="${TRACE_DIR}/trace-light.log"
if [ -f "$TRACE_FILE" ]; then
  read -r FIRST_LINE < "$TRACE_FILE"
  FIRST_DATE="${FIRST_LINE%%T*}"
  TODAY="${TS%%T*}"
  if [ -n "$FIRST_DATE" ] && [ "$FIRST_DATE" != "$TODAY" ]; then
    mv "$TRACE_FILE" "${TRACE_DIR}/trace-light-${FIRST_DATE}.log" 2>/dev/null
  fi
fi

# Append trace entry
echo "${TS}|${TOOL}|${STATUS}|${CONTEXT}" >> "$TRACE_FILE" 2>/dev/null

exit 0
