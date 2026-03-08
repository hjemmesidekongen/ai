#!/usr/bin/env bash
# claude-core — MEMORY.md health check (daily cron / manual)
# Reads MEMORY.md, counts lines, flags stale entries and graduation candidates.
# Outputs a readable report. Never modifies files. Always exits 0.
# Target: <500ms execution.

set -euo pipefail

# ── Locate MEMORY.md ──────────────────────────────────────────────────

# Derive the project-specific memory path from the workspace root.
# Claude Code stores per-project memory at:
#   ~/.claude/projects/-<workspace-path-with-dashes>/memory/MEMORY.md
WORKSPACE_ROOT="${CLAUDE_WORKSPACE:-$(pwd)}"
ENCODED_PATH=$(echo "$WORKSPACE_ROOT" | sed 's|/|-|g')
MEMORY_FILE="$HOME/.claude/projects/${ENCODED_PATH}/memory/MEMORY.md"

if [ ! -f "$MEMORY_FILE" ]; then
  # Try without leading dash (some versions omit it)
  ENCODED_ALT=$(echo "$WORKSPACE_ROOT" | sed 's|^/||;s|/|-|g')
  ALT_FILE="$HOME/.claude/projects/${ENCODED_ALT}/memory/MEMORY.md"
  if [ -f "$ALT_FILE" ]; then
    MEMORY_FILE="$ALT_FILE"
  fi
fi

# ── Header ────────────────────────────────────────────────────────────

echo ""
echo "Memory Health Report"
echo "═══════════════════"

if [ ! -f "$MEMORY_FILE" ]; then
  echo "File: not found"
  echo ""
  echo "Searched:"
  echo "  $MEMORY_FILE"
  echo ""
  echo "Status: No MEMORY.md found. Nothing to check."
  echo ""
  exit 0
fi

echo "File: $MEMORY_FILE"

# ── Line count + status ──────────────────────────────────────────────

LINE_CAP=150
LINE_COUNT=$(wc -l < "$MEMORY_FILE" | tr -d ' ')

if [ "$LINE_COUNT" -lt 100 ]; then
  STATUS_ICON="✅"
  STATUS_MSG="healthy"
elif [ "$LINE_COUNT" -le 130 ]; then
  STATUS_ICON="📋"
  STATUS_MSG="growing — consider pruning"
elif [ "$LINE_COUNT" -lt "$LINE_CAP" ]; then
  STATUS_ICON="⚠️"
  STATUS_MSG="near limit — prune soon"
else
  STATUS_ICON="🚨"
  STATUS_MSG="OVER LIMIT — must prune now"
fi

echo "Lines: ${LINE_COUNT}/${LINE_CAP} — ${STATUS_ICON} ${STATUS_MSG}"
echo ""

# ── Stale entry detection (>30 days old) ──────────────────────────────

# Build list of year-month prefixes that are >30 days old.
# Current date components.
CURRENT_EPOCH=$(date +%s)
THIRTY_DAYS=$((30 * 86400))
CUTOFF_EPOCH=$((CURRENT_EPOCH - THIRTY_DAYS))

# Generate a pattern for dates that are definitely old.
# We look for YYYY-MM-DD patterns and check if they predate the cutoff.
STALE_LINES=""
STALE_COUNT=0

while IFS= read -r line; do
  LINENO_VAL="${line%%:*}"
  CONTENT="${line#*:}"

  # Extract all YYYY-MM-DD dates from the line
  DATES=$(echo "$CONTENT" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' 2>/dev/null || true)
  [ -z "$DATES" ] && continue

  IS_STALE=false
  for d in $DATES; do
    # Parse date to epoch — macOS date -j, fallback to GNU date
    if DATE_EPOCH=$(date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null) || \
       DATE_EPOCH=$(date -d "$d" +%s 2>/dev/null); then
      if [ "$DATE_EPOCH" -lt "$CUTOFF_EPOCH" ]; then
        IS_STALE=true
        break
      fi
    fi
  done

  if $IS_STALE; then
    # Trim leading/trailing whitespace from content for display
    TRIMMED=$(echo "$CONTENT" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    STALE_LINES="${STALE_LINES}  Line ${LINENO_VAL}: \"${TRIMMED}\"\n"
    STALE_COUNT=$((STALE_COUNT + 1))
  fi
done < <(grep -n '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}' "$MEMORY_FILE" 2>/dev/null || true)

if [ "$STALE_COUNT" -gt 0 ]; then
  echo "Potentially stale (>30 days old):"
  printf '%b' "$STALE_LINES"
  echo ""
else
  echo "Potentially stale: none found"
  echo ""
fi

# ── Graduation candidates ────────────────────────────────────────────

GRAD_LINES=""
GRAD_COUNT=0

LINENO_VAL=0
while IFS= read -r CONTENT; do
  LINENO_VAL=$((LINENO_VAL + 1))
  TRIMMED=$(echo "$CONTENT" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  REASON=""

  # Skip empty lines and section headers
  [ -z "$TRIMMED" ] && continue
  case "$TRIMMED" in '#'*) continue ;; esac

  # Skip the standard CLAUDE.md pointer that is expected in MEMORY.md
  case "$TRIMMED" in '(Instruction preferences stored in'*) continue ;; esac

  # Check for rule-like patterns: lines starting with "- " containing always/never/prefer
  if echo "$CONTENT" | grep -qE '^[[:space:]]*-[[:space:]]' 2>/dev/null; then
    if echo "$CONTENT" | grep -qiE '\b(always|never|prefer)\b' 2>/dev/null; then
      REASON="could be a CLAUDE.md rule"
    fi
  fi

  # Check for mentions of skills, rules, or CLAUDE.md (potential graduated entries)
  if [ -z "$REASON" ]; then
    if echo "$CONTENT" | grep -qiE '\b(skill|CLAUDE\.md|rule)\b' 2>/dev/null; then
      REASON="mentions skill/rule/CLAUDE.md — may have graduated"
    fi
  fi

  if [ -n "$REASON" ]; then
    GRAD_LINES="${GRAD_LINES}  Line ${LINENO_VAL}: \"${TRIMMED}\" → ${REASON}\n"
    GRAD_COUNT=$((GRAD_COUNT + 1))
  fi
done < "$MEMORY_FILE"

if [ "$GRAD_COUNT" -gt 0 ]; then
  echo "Possible graduation candidates:"
  printf '%b' "$GRAD_LINES"
  echo ""
else
  echo "Graduation candidates: none found"
  echo ""
fi

# ── Action summary ───────────────────────────────────────────────────

if [ "$STALE_COUNT" -gt 0 ] || [ "$GRAD_COUNT" -gt 0 ] || [ "$LINE_COUNT" -ge 100 ]; then
  echo "Action needed: Review flagged lines. Delete stale entries, graduate rules to CLAUDE.md."
else
  echo "No action needed. Memory is clean."
fi

echo ""
exit 0
