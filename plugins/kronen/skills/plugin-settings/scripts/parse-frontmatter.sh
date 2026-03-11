#!/bin/bash
# Extracts YAML frontmatter or individual fields from a .local.md settings file.
# Usage: parse-frontmatter.sh <file> [field]
#   No field argument: prints full frontmatter block
#   With field argument: prints the value of that field (strips surrounding quotes)

set -euo pipefail

show_usage() {
  echo "Usage: $0 <settings-file.md> [field-name]"
  echo ""
  echo "  No field:    print full frontmatter block"
  echo "  With field:  print value of that field"
  echo ""
  echo "Examples:"
  echo "  $0 .claude/my-plugin.local.md"
  echo "  $0 .claude/my-plugin.local.md enabled"
  echo "  ENABLED=\$($0 .claude/my-plugin.local.md enabled)"
  exit 0
}

if [[ $# -eq 0 ]] || [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
  show_usage
fi

FILE="$1"
FIELD="${2:-}"

# Validate file
if [[ ! -f "$FILE" ]]; then
  echo "Error: File not found: $FILE" >&2
  exit 1
fi

if [[ ! -r "$FILE" ]]; then
  echo "Error: File not readable: $FILE" >&2
  exit 1
fi

# Validate frontmatter markers exist
MARKER_COUNT=$(grep -c '^---$' "$FILE" 2>/dev/null || echo "0")
if [[ $MARKER_COUNT -lt 2 ]]; then
  echo "Error: No valid frontmatter found in $FILE (need at least two '---' markers)" >&2
  exit 1
fi

# Extract frontmatter block
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$FILE")

if [[ -z "$FRONTMATTER" ]]; then
  echo "Error: Frontmatter block is empty in $FILE" >&2
  exit 1
fi

# No field specified — print all frontmatter
if [[ -z "$FIELD" ]]; then
  echo "$FRONTMATTER"
  exit 0
fi

# Extract specific field (handles both quoted and unquoted YAML values)
VALUE=$(echo "$FRONTMATTER" \
  | grep "^${FIELD}:" \
  | sed "s/${FIELD}: *//" \
  | sed 's/^"\(.*\)"$/\1/' \
  | sed "s/^'\\(.*\\)'$/\\1/")

if [[ -z "$VALUE" ]]; then
  echo "Error: Field '$FIELD' not found in frontmatter of $FILE" >&2
  exit 1
fi

echo "$VALUE"
exit 0
