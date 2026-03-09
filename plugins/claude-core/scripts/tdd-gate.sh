#!/usr/bin/env bash
# tdd-gate.sh — Block production code writes without a corresponding test file
# claude-core PreToolUse hook (Write|Edit)
# Exits 2 (block) when no test file found for the target production file.
# Opt-out: set CLAUDE_NO_TDD_GATE=1 or create .claude/no-tdd-gate in project root.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LOG_FILE="$PROJECT_DIR/.ai/traces/hook-errors.log"

# Opt-out checks
[ "${CLAUDE_NO_TDD_GATE:-}" = "1" ] && exit 0
[ -f "$PROJECT_DIR/.claude/no-tdd-gate" ] && exit 0

INPUT=$(cat)

# Extract tool_name — jq with bash fallback
TOOL=""
if command -v jq &>/dev/null; then
  TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || true
else
  case "$INPUT" in *'"tool_name":"'*)
    TOOL="${INPUT#*\"tool_name\":\"}"
    TOOL="${TOOL%%\"*}" ;;
  esac
fi
case "$TOOL" in
  Edit|MultiEdit|Write) ;;
  *) exit 0 ;;
esac

# Extract file_path — jq with bash fallback
FILE_PATH=""
if command -v jq &>/dev/null; then
  FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || true
else
  case "$INPUT" in *'"file_path":"'*)
    FILE_PATH="${INPUT#*\"file_path\":\"}"
    FILE_PATH="${FILE_PATH%%\"*}" ;;
  esac
fi
[ -z "$FILE_PATH" ] && exit 0

EXT="${FILE_PATH##*.}"

# Only gate production code extensions
case "$EXT" in
  cs|py|ts|tsx|js|jsx|go|rs|rb|php|java|kt|swift|dart) ;;
  *) exit 0 ;;
esac

BASENAME=$(basename "$FILE_PATH")

# Skip test files and non-production patterns
case "$BASENAME" in
  *Test.${EXT}|*Tests.${EXT}|*_test.${EXT}|test_*.${EXT}) exit 0 ;;
  *.test.${EXT}|*.spec.${EXT}|*Spec.${EXT}|*Specs.${EXT}) exit 0 ;;
  *Migration*|*migration*|*.dto.*|*DTO*) exit 0 ;;
  *Program.cs|*Startup.cs|*appsettings*|*.csproj|*.sln) exit 0 ;;
  *.d.ts|*.config.ts|*.config.js|tsconfig*|package.json) exit 0 ;;
  Dockerfile|docker-compose*|*.tf|*.tfvars|*.yml|*.yaml) exit 0 ;;
  *.md|*.txt|*.json|*.xml|*.html|*.css|*.scss) exit 0 ;;
esac

# Skip test and infrastructure directories
case "$FILE_PATH" in
  */test/*|*/tests/*|*/Test/*|*/Tests/*|*/__tests__/*) exit 0 ;;
  */spec/*|*/specs/*|*/fixtures/*|*/mocks/*|*/stubs/*) exit 0 ;;
  */migrations/*|*/seeds/*|*/config/*|*/scripts/*) exit 0 ;;
esac

NAME_NO_EXT="${BASENAME%.*}"
FILE_DIR=$(dirname "$FILE_PATH")
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

# Search nearby directories first
TESTS_FOUND=$(find "$FILE_DIR" \
  "$FILE_DIR/../test" "$FILE_DIR/../tests" \
  "$FILE_DIR/../Test" "$FILE_DIR/../Tests" \
  "$FILE_DIR/../__tests__" \
  -maxdepth 2 -type f \( \
    -name "${NAME_NO_EXT}Test.*" -o \
    -name "${NAME_NO_EXT}Tests.*" -o \
    -name "${NAME_NO_EXT}.test.*" -o \
    -name "${NAME_NO_EXT}.spec.*" -o \
    -name "${NAME_NO_EXT}_test.*" -o \
    -name "test_${NAME_NO_EXT}.*" \
  \) 2>/dev/null | head -1) || true

# Fallback: project-wide search
if [ -z "$TESTS_FOUND" ]; then
  TESTS_FOUND=$(find "$PROJECT_ROOT" -maxdepth 6 -type f \( \
    -name "${NAME_NO_EXT}Test.*" -o \
    -name "${NAME_NO_EXT}Tests.*" -o \
    -name "${NAME_NO_EXT}.test.*" -o \
    -name "${NAME_NO_EXT}.spec.*" -o \
    -name "${NAME_NO_EXT}_test.*" -o \
    -name "test_${NAME_NO_EXT}.*" \
  \) 2>/dev/null | head -1) || true
fi

if [ -z "$TESTS_FOUND" ]; then
  # Log to hook-errors.log
  mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
  printf '%s|tdd-gate|block|%s|no test file found for %s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$FILE_PATH" "$BASENAME" >> "$LOG_FILE" 2>/dev/null || true
  # Stdout JSON for Claude Code visibility
  printf '{"decision":"block","reason":"TDD GATE: No test file found for %s. Create %s.test.%s or %s_test.%s. Opt-out: CLAUDE_NO_TDD_GATE=1"}\n' \
    "$BASENAME" "$NAME_NO_EXT" "$EXT" "$NAME_NO_EXT" "$EXT"
  exit 2
fi

exit 0
