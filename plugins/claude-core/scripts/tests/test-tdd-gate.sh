#!/usr/bin/env bash
# test-tdd-gate.sh — Unit tests for tdd-gate.sh hook
# Run: bash plugins/claude-core/scripts/tests/test-tdd-gate.sh
# Exit 0 = all pass, Exit 1 = any fail

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../tdd-gate.sh"
PASS=0
FAIL=0
TMPDIR=$(mktemp -d)

cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

run_hook() {
  local input="$1"
  local env_vars="${2:-}"
  local exit_code=0
  local output
  output=$(eval "$env_vars" bash "$HOOK" <<< "$input" 2>/dev/null) || exit_code=$?
  printf '%s' "$output"
  return $exit_code
}

assert_exit() {
  local test_name="$1" expected="$2" actual="$3"
  if [ "$expected" -eq "$actual" ]; then
    printf "  PASS: %s (exit %d)\n" "$test_name" "$actual"
    PASS=$((PASS + 1))
  else
    printf "  FAIL: %s (expected exit %d, got %d)\n" "$test_name" "$expected" "$actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local test_name="$1" output="$2" pattern="$3"
  if printf '%s' "$output" | grep -q "$pattern"; then
    printf "  PASS: %s (output contains '%s')\n" "$test_name" "$pattern"
    PASS=$((PASS + 1))
  else
    printf "  FAIL: %s (output missing '%s')\n" "$test_name" "$pattern"
    FAIL=$((FAIL + 1))
  fi
}

# Setup: create a project dir with .ai/traces for logging
PROJECT="$TMPDIR/project"
mkdir -p "$PROJECT/.ai/traces"
mkdir -p "$PROJECT/src/auth"
ENV="CLAUDE_PROJECT_DIR=$PROJECT"

printf "=== tdd-gate.sh tests ===\n\n"

# --- Test 1: Non-code file (.md) passes through ---
printf "Test 1: Non-code file passthrough\n"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"docs/README.md"}}' "$ENV") && EC=$? || EC=$?
assert_exit "md file exits 0" 0 "$EC"

# --- Test 2: Test file itself passes through ---
printf "\nTest 2: Test file passthrough\n"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"src/auth/handler.test.ts"}}' "$ENV") && EC=$? || EC=$?
assert_exit "test file exits 0" 0 "$EC"

OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"src/auth/HandlerTest.cs"}}' "$ENV") && EC=$? || EC=$?
assert_exit "Test.cs file exits 0" 0 "$EC"

OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"src/auth/handler_test.go"}}' "$ENV") && EC=$? || EC=$?
assert_exit "_test.go file exits 0" 0 "$EC"

# --- Test 3: Code file with test nearby passes ---
printf "\nTest 3: Code file with nearby test\n"
touch "$PROJECT/src/auth/handler.ts"
touch "$PROJECT/src/auth/handler.test.ts"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"'"$PROJECT"'/src/auth/handler.ts"}}' "$ENV") && EC=$? || EC=$?
assert_exit "code + nearby test exits 0" 0 "$EC"
rm -f "$PROJECT/src/auth/handler.test.ts"

# --- Test 4: Code file with NO test → block ---
printf "\nTest 4: Code file without test blocks\n"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"'"$PROJECT"'/src/auth/handler.ts"}}' "$ENV") && EC=$? || EC=$?
assert_exit "no test exits 2" 2 "$EC"
assert_contains "outputs JSON" "$OUTPUT" '"decision":"block"'
assert_contains "outputs reason" "$OUTPUT" 'TDD GATE'

# --- Test 5: Opt-out via env var ---
printf "\nTest 5: Opt-out via CLAUDE_NO_TDD_GATE\n"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"'"$PROJECT"'/src/auth/handler.ts"}}' "$ENV CLAUDE_NO_TDD_GATE=1") && EC=$? || EC=$?
assert_exit "opt-out exits 0" 0 "$EC"

# --- Test 6: Opt-out via sentinel file ---
printf "\nTest 6: Opt-out via sentinel file\n"
mkdir -p "$PROJECT/.claude"
touch "$PROJECT/.claude/no-tdd-gate"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"'"$PROJECT"'/src/auth/handler.ts"}}' "$ENV") && EC=$? || EC=$?
assert_exit "sentinel file exits 0" 0 "$EC"
rm -f "$PROJECT/.claude/no-tdd-gate"

# --- Test 7: Non-Write tool passes through ---
printf "\nTest 7: Non-Write tool passthrough\n"
OUTPUT=$(run_hook '{"tool_name":"Read","tool_input":{"file_path":"src/auth/handler.ts"}}' "$ENV") && EC=$? || EC=$?
assert_exit "Read tool exits 0" 0 "$EC"

# --- Test 8: Infrastructure directory passes through ---
printf "\nTest 8: Infrastructure directory passthrough\n"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"src/scripts/deploy.ts"}}' "$ENV") && EC=$? || EC=$?
assert_exit "scripts/ dir exits 0" 0 "$EC"

# --- Test 9: Hook-errors.log is written on block ---
printf "\nTest 9: Hook-errors.log written on block\n"
> "$PROJECT/.ai/traces/hook-errors.log"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"'"$PROJECT"'/src/auth/handler.ts"}}' "$ENV") && EC=$? || EC=$?
LOG_CONTENT=$(cat "$PROJECT/.ai/traces/hook-errors.log" 2>/dev/null || echo "")
assert_contains "log file has entry" "$LOG_CONTENT" "tdd-gate|block"

# --- Test 10: Config files pass through ---
printf "\nTest 10: Config file passthrough\n"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"src/tsconfig.json"}}' "$ENV") && EC=$? || EC=$?
assert_exit ".json file exits 0" 0 "$EC"

OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"src/app.config.ts"}}' "$ENV") && EC=$? || EC=$?
assert_exit ".config.ts file exits 0" 0 "$EC"

# --- Summary ---
printf "\n=== Results: %d passed, %d failed ===\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
