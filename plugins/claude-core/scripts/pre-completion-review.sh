#!/usr/bin/env bash
set -euo pipefail
# claude-core — pre-completion trace review
# Reads trace log, filters today's errors/warnings, outputs summary as systemMessage JSON.
# Called before marking a task complete (manually or via plan:execute).
# Performance target: <200ms. Always exits 0.

TRACE_DIR=".ai/traces"
TRACE_LOG="${TRACE_DIR}/trace-light.log"
TRACE_CONFIG="${TRACE_DIR}/trace-config.yml"
TODAY=$(date -u +%Y-%m-%d)

# ── Counters ──
CRITICAL_COUNT=0
WARNING_COUNT=0
INFO_COUNT=0
CRITICAL_LINES=""
WARNING_LINES=""

# ── Step 1: Read light trace log ──
if [ -f "$TRACE_LOG" ]; then
  while IFS='|' read -r ts tool status context severity summary rest; do
    # Only today's entries
    case "$ts" in
      "${TODAY}"*) ;;
      *) continue ;;
    esac

    # Error-annotated lines: status == "error" AND has severity + summary (field_count >= 6)
    [ "$status" != "error" ] && continue
    [ -z "$severity" ] && continue
    [ -z "$summary" ] && continue

    case "$severity" in
      critical)
        CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
        CRITICAL_LINES="${CRITICAL_LINES}  - [${tool}] ${summary}\n"
        ;;
      warning)
        WARNING_COUNT=$((WARNING_COUNT + 1))
        WARNING_LINES="${WARNING_LINES}  - [${tool}] ${summary}\n"
        ;;
      info)
        INFO_COUNT=$((INFO_COUNT + 1))
        ;;
    esac
  done < "$TRACE_LOG"
fi

# ── Step 2: Check full trace session errors ──
FULL_ERRORS=""
FULL_ERROR_COUNT=0

if [ -f "$TRACE_CONFIG" ]; then
  # Extract level — pure bash, no YAML parser needed for one field
  LEVEL=""
  while IFS=': ' read -r key val rest; do
    case "$key" in
      level) LEVEL="${val//\"/}" ; LEVEL="${LEVEL// /}" ;;
    esac
  done < "$TRACE_CONFIG"

  if [ "$LEVEL" = "full" ]; then
    SESSION_FILE=""
    while IFS=': ' read -r key val rest; do
      case "$key" in
        session_file) SESSION_FILE="${val//\"/}" ; SESSION_FILE="${SESSION_FILE// /}" ;;
      esac
    done < "$TRACE_CONFIG"

    SESSION_PATH="${TRACE_DIR}/sessions/${SESSION_FILE}"
    if [ -n "$SESSION_FILE" ] && [ -f "$SESSION_PATH" ]; then
      # Parse errors array from session YAML — look for severity lines under errors:
      IN_ERRORS=0
      CURRENT_SEVERITY=""
      CURRENT_SUMMARY=""
      while IFS= read -r line; do
        case "$line" in
          "errors:"*) IN_ERRORS=1 ; continue ;;
        esac
        [ "$IN_ERRORS" -eq 0 ] && continue

        # Exit errors block on non-indented line (new top-level key)
        case "$line" in
          "  "* | "    "*| "-"*) ;; # still in errors block
          "") continue ;;
          *) IN_ERRORS=0 ; continue ;;
        esac

        # Extract severity
        stripped="${line#"${line%%[! ]*}"}"  # strip leading spaces
        case "$stripped" in
          "severity:"*)
            CURRENT_SEVERITY="${stripped#severity:}"
            CURRENT_SEVERITY="${CURRENT_SEVERITY#"${CURRENT_SEVERITY%%[! ]*}"}"
            CURRENT_SEVERITY="${CURRENT_SEVERITY//\"/}"
            ;;
          "error_summary:"*)
            CURRENT_SUMMARY="${stripped#error_summary:}"
            CURRENT_SUMMARY="${CURRENT_SUMMARY#"${CURRENT_SUMMARY%%[! ]*}"}"
            CURRENT_SUMMARY="${CURRENT_SUMMARY//\"/}"
            ;;
        esac

        # When we have both fields, record
        if [ -n "$CURRENT_SEVERITY" ] && [ -n "$CURRENT_SUMMARY" ]; then
          FULL_ERROR_COUNT=$((FULL_ERROR_COUNT + 1))
          case "$CURRENT_SEVERITY" in
            critical)
              CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
              CRITICAL_LINES="${CRITICAL_LINES}  - [full-trace] ${CURRENT_SUMMARY}\n"
              ;;
            warning)
              WARNING_COUNT=$((WARNING_COUNT + 1))
              WARNING_LINES="${WARNING_LINES}  - [full-trace] ${CURRENT_SUMMARY}\n"
              ;;
            info)
              INFO_COUNT=$((INFO_COUNT + 1))
              ;;
          esac
          CURRENT_SEVERITY=""
          CURRENT_SUMMARY=""
        fi
      done < "$SESSION_PATH"
    fi
  fi
fi

# ── Step 3: Build output message ──
if [ "$CRITICAL_COUNT" -gt 0 ]; then
  MSG="BLOCK — ${CRITICAL_COUNT} critical error(s) found during this session. Review required before completion:\\n${CRITICAL_LINES}"
  if [ "$WARNING_COUNT" -gt 0 ]; then
    MSG="${MSG}\\nAlso: ${WARNING_COUNT} warning(s):\\n${WARNING_LINES}"
  fi
elif [ "$WARNING_COUNT" -gt 0 ]; then
  MSG="ADVISORY — ${WARNING_COUNT} warning(s) during this session. Review or accept:\\n${WARNING_LINES}"
else
  MSG="CLEAN — No errors or warnings in trace. Ready to complete."
fi

# Escape for JSON: replace actual newlines, backslashes, quotes
# (MSG already uses \\n literals for line breaks, which is valid JSON)
MSG="${MSG//\"/\\\"}"

printf '{"systemMessage": "%s"}\n' "$MSG"

exit 0
