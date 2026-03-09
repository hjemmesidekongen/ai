#!/usr/bin/env bash
# test-scope-guard.sh — Unit tests for scope-guard.sh hook
# Run: bash plugins/claude-core/scripts/tests/test-scope-guard.sh
# Exit 0 = all pass, Exit 1 = any fail

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../scope-guard.sh"
PASS=0
FAIL=0
TMPDIR=$(mktemp -d)

cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

run_hook() {
  local input="$1" project_dir="$2"
  local exit_code=0
  local output
  output=$(CLAUDE_PROJECT_DIR="$project_dir" bash "$HOOK" <<< "$input" 2>/dev/null) || exit_code=$?
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
    printf "  PASS: %s (contains '%s')\n" "$test_name" "$pattern"
    PASS=$((PASS + 1))
  else
    printf "  FAIL: %s (missing '%s')\n" "$test_name" "$pattern"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local test_name="$1" output="$2" pattern="$3"
  if ! printf '%s' "$output" | grep -q "$pattern"; then
    printf "  PASS: %s (does not contain '%s')\n" "$test_name" "$pattern"
    PASS=$((PASS + 1))
  else
    printf "  FAIL: %s (unexpectedly contains '%s')\n" "$test_name" "$pattern"
    FAIL=$((FAIL + 1))
  fi
}

PROJECT="$TMPDIR/project"
mkdir -p "$PROJECT/.ai/traces"

printf "=== scope-guard.sh tests ===\n\n"

# --- Test 1: No active plan → exits 0, no output ---
printf "Test 1: No active plan\n"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"src/handler.ts"}}' "$PROJECT") && EC=$? || EC=$?
assert_exit "no plan exits 0" 0 "$EC"

# --- Test 2: Active plan + file IS in task writes → exits 0 ---
printf "\nTest 2: File in declared writes\n"
mkdir -p "$PROJECT/.ai/plans/test-plan"
cat > "$PROJECT/.ai/plans/test-plan/state.yml" << 'YAML'
plan_name: test-plan
status: in_progress
current_wave: wave-1

waves:
  wave-1:
    name: "Test Wave"
    status: in_progress
    tasks: [t1]

tasks:
  t1:
    name: "Test task"
    status: in_progress
    wave: wave-1
    writes:
      - src/handler.ts
      - src/utils.ts
YAML
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"src/handler.ts"}}' "$PROJECT") && EC=$? || EC=$?
assert_exit "file in writes exits 0" 0 "$EC"

# --- Test 3: Active plan + writes empty → exits 0 (cannot verify scope) ---
printf "\nTest 3: Empty writes arrays\n"
cat > "$PROJECT/.ai/plans/test-plan/state.yml" << 'YAML'
plan_name: test-plan
status: in_progress
current_wave: wave-1

waves:
  wave-1:
    name: "Test Wave"
    status: in_progress
    tasks: [t1]

tasks:
  t1:
    name: "Test task"
    status: in_progress
    wave: wave-1
    writes: []
YAML
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"src/unknown-file.ts"}}' "$PROJECT") && EC=$? || EC=$?
assert_exit "empty writes exits 0" 0 "$EC"

# --- Test 4: Active plan + file NOT in writes → exits 0 with warning + log ---
printf "\nTest 4: File not in declared writes\n"
cat > "$PROJECT/.ai/plans/test-plan/state.yml" << 'YAML'
plan_name: test-plan
status: in_progress
current_wave: wave-1

waves:
  wave-1:
    name: "Test Wave"
    status: in_progress
    tasks: [t1]

tasks:
  t1:
    name: "Test task"
    status: in_progress
    wave: wave-1
    writes:
      - src/handler.ts
YAML
> "$PROJECT/.ai/traces/hook-errors.log"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"src/other-file.ts"}}' "$PROJECT") && EC=$? || EC=$?
assert_exit "out-of-scope exits 0 (advisory)" 0 "$EC"
LOG_CONTENT=$(cat "$PROJECT/.ai/traces/hook-errors.log" 2>/dev/null || echo "")
assert_contains "log has scope-guard entry" "$LOG_CONTENT" "scope-guard|warn"

# --- Test 5: Meta file (SKILL.md) always allowed ---
printf "\nTest 5: Meta file bypass\n"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"plugins/claude-core/skills/foo/SKILL.md"}}' "$PROJECT") && EC=$? || EC=$?
assert_exit "SKILL.md exits 0" 0 "$EC"

# --- Test 6: Log file always allowed ---
printf "\nTest 6: Log file bypass\n"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":".ai/traces/trace-light.log"}}' "$PROJECT") && EC=$? || EC=$?
assert_exit ".log file exits 0" 0 "$EC"

# --- Test 7: state.yml always allowed ---
printf "\nTest 7: state.yml bypass\n"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":".ai/plans/my-plan/state.yml"}}' "$PROJECT") && EC=$? || EC=$?
assert_exit "state.yml exits 0" 0 "$EC"

# Cleanup plan
rm -rf "$PROJECT/.ai/plans/test-plan"

# --- Summary ---
printf "\n=== Results: %d passed, %d failed ===\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
