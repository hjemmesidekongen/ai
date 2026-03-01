#!/usr/bin/env bash
#
# session-recovery.sh
#
# SessionStart hook for brand-guideline. Detects if this is a resumed
# session by checking for state.yml in the active brand directory,
# then reports current progress so Claude can orient before doing any work.
#
# Usage: bash packages/brand-guideline/scripts/session-recovery.sh
# Exit 0: Always (informational only — never blocks startup)

set -euo pipefail

echo "=== Brand Session Recovery Check ==="

# Determine brand directory from active-brand.yml or current directory
BRAND_DIR=""
if [ -f ~/.claude/active-brand.yml ]; then
  BRAND_NAME=$(grep '^brand_name:' ~/.claude/active-brand.yml 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"' || true)
  if [ -n "$BRAND_NAME" ]; then
    BRAND_DIR="$HOME/.claude/brands/$BRAND_NAME"
  fi
fi

# Fallback: check current directory for state.yml
STATE_FILE=""
if [ -n "$BRAND_DIR" ] && [ -f "$BRAND_DIR/state.yml" ]; then
  STATE_FILE="$BRAND_DIR/state.yml"
  echo "Active brand: $BRAND_NAME"
elif [ -f state.yml ]; then
  STATE_FILE="state.yml"
  echo "State file found in current directory."
fi

if [ -n "$STATE_FILE" ]; then
  echo "State file: $STATE_FILE"
  echo "Current phase: $(grep '^current_phase:' "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"' || echo 'unknown')"
  echo "Status: $(grep '^status:' "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"' || echo 'unknown')"

  # Report last modified time (macOS and Linux compatible)
  if stat -f %Sm "$STATE_FILE" &>/dev/null; then
    echo "Last updated: $(stat -f '%Sm' "$STATE_FILE")"
  elif stat -c %y "$STATE_FILE" &>/dev/null; then
    echo "Last updated: $(stat -c '%y' "$STATE_FILE")"
  fi

  # Count logged errors
  ERRORS=$(grep -c '  - timestamp:' "$STATE_FILE" 2>/dev/null || echo 0)
  echo "Logged errors: $ERRORS"

  # Show completed phases if available
  COMPLETED=$(grep -B1 'status: completed' "$STATE_FILE" 2>/dev/null | grep 'name:' | awk '{print $3}' | tr -d '"' | tr '\n' ', ' || true)
  if [ -n "$COMPLETED" ]; then
    echo "Completed phases: $COMPLETED"
  fi

  # Check for findings.md
  FINDINGS_DIR=$(dirname "$STATE_FILE")
  if [ -f "$FINDINGS_DIR/findings.md" ]; then
    FINDINGS_LINES=$(wc -l < "$FINDINGS_DIR/findings.md" | tr -d ' ')
    echo "Findings file: $FINDINGS_DIR/findings.md ($FINDINGS_LINES lines)"
  fi

  # Show git changes since last commit
  echo "Git changes since last commit:"
  git diff --stat HEAD 2>/dev/null || echo "  (not a git repo)"
else
  echo "No state.yml found. Fresh start."
fi
