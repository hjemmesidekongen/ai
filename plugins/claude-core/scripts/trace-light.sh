#!/usr/bin/env bash
# claude-core — light tracing hook (PostToolUse, always-on)
# Appends one line per tool invocation to .ai/traces/trace-light.log
# Format: timestamp|tool_name|status|duration|context
# Optimized for <30ms — minimal subprocesses, bash builtins where possible.
# Always exits 0.

# Read hook input JSON from stdin
INPUT=$(cat)

# Timestamp (UTC ISO 8601)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# --- Extract fields using bash builtins (avoid subshells) ---

# tool_name
TOOL="${INPUT#*\"tool_name\":\"}"
[ "$TOOL" = "$INPUT" ] && exit 0
TOOL="${TOOL%%\"*}"
[ -z "$TOOL" ] && exit 0

# status — check for error signals in one grep call
STATUS="success"
if echo "$INPUT" | grep -qi '"is_error": *true\|"error":\|"not found"\|"No such file"\|Permission denied\|command not found\|ENOENT\|EACCES' 2>/dev/null; then
  STATUS="error"
fi

# duration_ms (optional field)
DURATION="-"
case "$INPUT" in
  *'"duration_ms":'*)
    D="${INPUT#*\"duration_ms\":}"
    D="${D%%[,\}]*}"
    D="${D%%[^0-9]*}"
    [ -n "$D" ] && DURATION="${D}ms"
    ;;
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

# Ensure trace directory exists
TRACE_DIR=".ai/traces"
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
echo "${TS}|${TOOL}|${STATUS}|${DURATION}|${CONTEXT}" >> "$TRACE_FILE" 2>/dev/null

exit 0
