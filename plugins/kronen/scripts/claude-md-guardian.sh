#!/usr/bin/env bash
set -euo pipefail
# kronen — CLAUDE.md guardian hook (PostToolUse)
# Fires when Write or Edit targets a file containing "CLAUDE.md" in the name.
# Outputs advisory guidance for Claude to self-validate the change.
# Never blocks — always exits 0.

# Read hook input JSON from stdin
INPUT=$(cat)

# Extract file_path from tool_input
if command -v jq &>/dev/null; then
  FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  FILE=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | sed 's/"file_path":"//;s/"$//')
fi

# No file_path — nothing to check
[ -z "$FILE" ] && exit 0

# Case-insensitive check: does the filename contain "CLAUDE.md"?
FILE_UPPER=$(echo "$FILE" | tr '[:lower:]' '[:upper:]')
case "$FILE_UPPER" in
  *CLAUDE.MD*) ;;
  *) exit 0 ;;
esac

# CLAUDE.md was modified — output advisory guidance
printf '%s\n' '{"systemMessage": "CLAUDE.md guardian: You just modified a CLAUDE.md file. Before continuing, validate this change:\n1. Contradictions — does this conflict with any existing rule in CLAUDE.md or MEMORY.md?\n2. Redundancy — is this already stated elsewhere? If so, consolidate rather than duplicate.\n3. Consequences — what downstream behavior does this change? Could it break existing workflows?\n4. Simplicity — is there a simpler alternative (a pointer instead of inline content, a skill instead of a rule)?\nIf the change fails any of these checks, revert or revise it now."}'

exit 0
