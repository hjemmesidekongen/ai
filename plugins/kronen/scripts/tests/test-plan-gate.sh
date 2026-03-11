#!/usr/bin/env bash
# test-plan-gate.sh — Unit tests for plan-gate.sh hook
# Run: bash plugins/kronen/scripts/tests/test-plan-gate.sh
# Exit 0 = all pass, Exit 1 = any fail

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../plan-gate.sh"
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

PROJECT="$TMPDIR/project"
mkdir -p "$PROJECT/.ai/traces"

printf "=== plan-gate.sh tests ===\n\n"

# --- Test 1: No active plan + non-plugin file → exits 0, no warning ---
printf "Test 1: Non-plugin file without plan\n"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"src/app.ts"}}' "$PROJECT") && EC=$? || EC=$?
assert_exit "non-plugin file exits 0" 0 "$EC"

# --- Test 2: No active plan + plugin skill file → exits 0 with warning + log ---
printf "\nTest 2: Plugin file without plan warns\n"
> "$PROJECT/.ai/traces/hook-errors.log"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"/home/user/project/plugins/kronen/skills/foo/SKILL.md"}}' "$PROJECT") && EC=$? || EC=$?
assert_exit "plugin file exits 0 (advisory)" 0 "$EC"
LOG_CONTENT=$(cat "$PROJECT/.ai/traces/hook-errors.log" 2>/dev/null || echo "")
assert_contains "log has plan-gate entry" "$LOG_CONTENT" "plan-gate|warn"

# --- Test 3: Active plan + plugin skill file → exits 0, no warning ---
printf "\nTest 3: Plugin file with active plan\n"
mkdir -p "$PROJECT/.ai/plans/test-plan"
cat > "$PROJECT/.ai/plans/test-plan/state.yml" << 'YAML'
plan_name: test-plan
status: in_progress
current_wave: wave-1
YAML
> "$PROJECT/.ai/traces/hook-errors.log"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"/home/user/project/plugins/kronen/skills/foo/SKILL.md"}}' "$PROJECT") && EC=$? || EC=$?
assert_exit "with plan exits 0" 0 "$EC"
LOG_CONTENT=$(cat "$PROJECT/.ai/traces/hook-errors.log" 2>/dev/null || echo "")
if [ -z "$LOG_CONTENT" ]; then
  printf "  PASS: no log entry when plan active\n"
  PASS=$((PASS + 1))
else
  printf "  FAIL: unexpected log entry when plan active\n"
  FAIL=$((FAIL + 1))
fi
rm -rf "$PROJECT/.ai/plans/test-plan"

# --- Test 4: Config file (ecosystem.json) without plan → exits 0, no warning ---
printf "\nTest 4: Config file excluded\n"
> "$PROJECT/.ai/traces/hook-errors.log"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"/home/user/project/plugins/kronen/.claude-plugin/ecosystem.json"}}' "$PROJECT") && EC=$? || EC=$?
assert_exit "ecosystem.json exits 0" 0 "$EC"
LOG_CONTENT=$(cat "$PROJECT/.ai/traces/hook-errors.log" 2>/dev/null || echo "")
if [ -z "$LOG_CONTENT" ]; then
  printf "  PASS: no log for excluded config file\n"
  PASS=$((PASS + 1))
else
  printf "  FAIL: unexpected log for excluded config file\n"
  FAIL=$((FAIL + 1))
fi

# --- Test 5: YAML file in plugin dir → exits 0, no warning (excluded by extension) ---
printf "\nTest 5: YAML file excluded\n"
> "$PROJECT/.ai/traces/hook-errors.log"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"/home/user/project/plugins/kronen/resources/schema.yml"}}' "$PROJECT") && EC=$? || EC=$?
assert_exit "yml file exits 0" 0 "$EC"
LOG_CONTENT=$(cat "$PROJECT/.ai/traces/hook-errors.log" 2>/dev/null || echo "")
if [ -z "$LOG_CONTENT" ]; then
  printf "  PASS: no log for excluded yml file\n"
  PASS=$((PASS + 1))
else
  printf "  FAIL: unexpected log for excluded yml file\n"
  FAIL=$((FAIL + 1))
fi

# --- Test 6: Script file in plugin dir without plan → warns ---
printf "\nTest 6: Script file without plan warns\n"
> "$PROJECT/.ai/traces/hook-errors.log"
OUTPUT=$(run_hook '{"tool_name":"Write","tool_input":{"file_path":"/home/user/project/plugins/kronen/scripts/new-hook.sh"}}' "$PROJECT") && EC=$? || EC=$?
assert_exit "script file exits 0 (advisory)" 0 "$EC"
LOG_CONTENT=$(cat "$PROJECT/.ai/traces/hook-errors.log" 2>/dev/null || echo "")
assert_contains "log has entry for script file" "$LOG_CONTENT" "plan-gate|warn"

# --- Summary ---
printf "\n=== Results: %d passed, %d failed ===\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
