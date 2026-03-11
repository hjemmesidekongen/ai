#!/bin/bash
# Validates the structure of a .claude/plugin-name.local.md settings file.
# Usage: validate-settings.sh <path/to/settings.local.md>

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <path/to/settings.local.md>"
  echo ""
  echo "Validates:"
  echo "  - File exists and is readable"
  echo "  - YAML frontmatter markers present"
  echo "  - Frontmatter is non-empty"
  echo "  - Fields follow key: value format"
  echo "  - Boolean fields have true/false values"
  echo ""
  echo "Example: $0 .claude/my-plugin.local.md"
  exit 1
fi

SETTINGS_FILE="$1"
ERRORS=0

pass() { echo "  ok  $1"; }
fail() { echo "  FAIL  $1" >&2; ERRORS=$((ERRORS + 1)); }
warn() { echo "  warn  $1" >&2; }

echo "Validating: $SETTINGS_FILE"
echo ""

# Check 1: File exists
if [[ ! -f "$SETTINGS_FILE" ]]; then
  fail "File not found: $SETTINGS_FILE"
  exit 1
fi
pass "File exists"

# Check 2: File is readable
if [[ ! -r "$SETTINGS_FILE" ]]; then
  fail "File is not readable (check permissions)"
  exit 1
fi
pass "File is readable"

# Check 3: Frontmatter markers
MARKER_COUNT=$(grep -c '^---$' "$SETTINGS_FILE" 2>/dev/null || echo "0")
if [[ $MARKER_COUNT -lt 2 ]]; then
  fail "Frontmatter markers: found $MARKER_COUNT '---' lines (need at least 2)"
  echo "  Expected:" >&2
  echo "    ---" >&2
  echo "    field: value" >&2
  echo "    ---" >&2
  exit 1
fi
pass "Frontmatter markers present ($MARKER_COUNT '---' lines)"

# Check 4: Frontmatter is non-empty
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$SETTINGS_FILE")
if [[ -z "$FRONTMATTER" ]]; then
  fail "Frontmatter block is empty (nothing between --- markers)"
  exit 1
fi
pass "Frontmatter block is non-empty"

# Check 5: Fields have key: value format
if ! echo "$FRONTMATTER" | grep -q ':'; then
  warn "No key: value pairs found in frontmatter"
fi

# Check 6: List detected fields
echo ""
echo "Detected fields:"
echo "$FRONTMATTER" | grep '^[a-z_][a-z0-9_]*:' | while IFS=':' read -r key rest; do
  value=$(echo "$rest" | sed 's/^ *//')
  printf "  %-24s %s\n" "$key" "${value:0:60}"
done

# Check 7: Boolean field validation
echo ""
for field in enabled strict_mode debug verbose; do
  VALUE=$(echo "$FRONTMATTER" | grep "^${field}:" | sed "s/${field}: *//" 2>/dev/null || true)
  if [[ -n "$VALUE" ]]; then
    if [[ "$VALUE" != "true" ]] && [[ "$VALUE" != "false" ]]; then
      warn "Boolean field '$field' should be true or false, got: $VALUE"
    else
      pass "Boolean field '$field' = $VALUE"
    fi
  fi
done

# Check 8: Markdown body
BODY=$(awk '/^---$/{i++; next} i>=2' "$SETTINGS_FILE")
echo ""
if [[ -n "$BODY" ]]; then
  BODY_LINES=$(echo "$BODY" | wc -l | tr -d ' ')
  pass "Markdown body present ($BODY_LINES lines)"
else
  warn "No markdown body (frontmatter only — this is fine)"
fi

echo ""
if [[ $ERRORS -gt 0 ]]; then
  echo "FAILED: $ERRORS error(s) found" >&2
  exit 1
fi

echo "Valid — $SETTINGS_FILE is well-formed"
echo "Note: Changes to this file require restarting Claude Code."
exit 0
