#!/usr/bin/env bash
set -euo pipefail
# claude-core — hardening sweep: validate all plugin components against conventions
# Usage: hardening-sweep.sh [plugin-root]
# Output: PASS/FAIL/WARN per component per check, totals at the end.

PLUGIN_ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
PASS=0; FAIL=0; WARN=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  WARN: $1"; WARN=$((WARN + 1)); }

# ============================================================
# SKILL CHECKS
# ============================================================
echo "=== Skills ==="
ECOSYSTEM="$PLUGIN_ROOT/.claude-plugin/ecosystem.json"

while IFS= read -r skill_dir; do
  skill_name=$(basename "$skill_dir")
  # Skip sub-agent directories (e.g. skill-creator/agents/)
  [ ! -f "$skill_dir/SKILL.md" ] && { fail "[$skill_name] SKILL.md not found"; continue; }

  echo "--- $skill_name ---"

  # 1. SKILL.md exists
  pass "SKILL.md exists"

  # 2. Line count <= 80
  LINES=$(wc -l < "$skill_dir/SKILL.md" | tr -d ' ')
  [ "$LINES" -le 80 ] && pass "Line count: $LINES <= 80" || fail "Line count: $LINES > 80"

  # 3-11. Frontmatter checks
  # Extract frontmatter (between first and second ---)
  FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$skill_dir/SKILL.md" | sed '1d;$d')

  # 3. Required frontmatter fields
  for field in name description user_invocable interactive depends_on reads writes checkpoint model_tier _source; do
    if echo "$FRONTMATTER" | grep -q "^${field}:"; then
      pass "Has field: $field"
    elif echo "$FRONTMATTER" | grep -q "^${field} :"; then
      pass "Has field: $field"
    else
      fail "Missing field: $field"
    fi
  done

  # 4. user_invocable uses underscore (not hyphen)
  if echo "$FRONTMATTER" | grep -q "^user-invocable:"; then
    fail "Uses 'user-invocable' (hyphen) — should be 'user_invocable' (underscore)"
  fi

  # 5. name matches directory name
  FM_NAME=$(echo "$FRONTMATTER" | grep "^name:" | head -1 | sed 's/^name: *//' | tr -d '"' | tr -d "'")
  if [ "$FM_NAME" = "$skill_name" ]; then
    pass "name matches directory: $skill_name"
  else
    fail "name '$FM_NAME' does not match directory '$skill_name'"
  fi

  # 6. checkpoint is object (not bare string)
  CHECKPOINT_LINE=$(echo "$FRONTMATTER" | grep "^checkpoint:" | head -1)
  if [ -n "$CHECKPOINT_LINE" ]; then
    CHECKPOINT_VALUE=$(echo "$CHECKPOINT_LINE" | sed 's/^checkpoint: *//')
    if echo "$CHECKPOINT_VALUE" | grep -qE '^[a-z_]+$'; then
      fail "checkpoint is bare string '$CHECKPOINT_VALUE' — should be object with required_checks"
    else
      # Check for required_checks
      if echo "$FRONTMATTER" | grep -q "required_checks:"; then
        pass "checkpoint has required_checks"
      else
        warn "checkpoint may be missing required_checks array"
      fi
    fi
  fi

  # 7. _source has required subfields
  if echo "$FRONTMATTER" | grep -q "^_source:"; then
    for subfield in origin ported_date iteration changes; do
      if echo "$FRONTMATTER" | grep -q "  ${subfield}:"; then
        pass "_source has: $subfield"
      else
        fail "_source missing: $subfield"
      fi
    done

    # 8. iteration is a number
    ITER=$(echo "$FRONTMATTER" | grep "  iteration:" | head -1 | sed 's/.*iteration: *//' | tr -d '"' | tr -d "'")
    if [ -n "$ITER" ]; then
      if echo "$ITER" | grep -qE '^[0-9]+$'; then
        pass "iteration is integer: $ITER"
      else
        fail "iteration is not integer: '$ITER'"
      fi
    fi
  fi

  # 9. Referenced files exist
  if [ -d "$skill_dir/references" ]; then
    # Check if SKILL.md references process.md and it exists
    if grep -q "references/process.md" "$skill_dir/SKILL.md" 2>/dev/null; then
      [ -f "$skill_dir/references/process.md" ] && pass "references/process.md exists" || fail "references/process.md referenced but missing"
    fi
  fi

  # 10. No second-person pronouns in description
  DESC=$(echo "$FRONTMATTER" | sed -n '/^description:/,/^[a-z_]*:/p' | head -20)
  if echo "$DESC" | grep -qiE '\byou\b|\byour\b|\byours\b'; then
    warn "Description contains second-person pronouns"
  else
    pass "No second-person pronouns in description"
  fi

  # 11. Registered in ecosystem.json
  if [ -f "$ECOSYSTEM" ]; then
    if grep -q "\"$skill_name\"" "$ECOSYSTEM"; then
      pass "Registered in ecosystem.json"
    else
      fail "Not registered in ecosystem.json"
    fi
  fi
done < <(find "$PLUGIN_ROOT/skills" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort)

# ============================================================
# COMMAND CHECKS
# ============================================================
echo ""
echo "=== Commands ==="
CMD_DIR="$PLUGIN_ROOT/commands"
if [ -d "$CMD_DIR" ]; then
  for cmd_file in "$CMD_DIR"/*.md; do
    [ ! -f "$cmd_file" ] && continue
    cmd_name=$(basename "$cmd_file" .md)
    echo "--- $cmd_name ---"

    # COMMAND.md exists
    pass "Command file exists"

    # Has description
    if grep -q "^description:" "$cmd_file"; then
      pass "Has description"
    else
      fail "Missing description"
    fi
  done
else
  warn "No commands/ directory"
fi

# ============================================================
# SCRIPT CHECKS
# ============================================================
echo ""
echo "=== Scripts ==="
SCRIPT_DIR="$PLUGIN_ROOT/scripts"
if [ -d "$SCRIPT_DIR" ]; then
  for script in "$SCRIPT_DIR"/*.sh; do
    [ ! -f "$script" ] && continue
    script_name=$(basename "$script")
    echo "--- $script_name ---"

    # Has shebang
    FIRST_LINE=$(head -1 "$script")
    if echo "$FIRST_LINE" | grep -q '^#!'; then
      pass "Has shebang"
    else
      fail "Missing shebang"
    fi

    # Has set -euo pipefail
    if grep -q 'set -euo pipefail' "$script"; then
      pass "Has set -euo pipefail"
    else
      fail "Missing set -euo pipefail"
    fi

    # Passes bash -n syntax check
    if bash -n "$script" 2>/dev/null; then
      pass "Passes bash -n"
    else
      fail "Fails bash -n syntax check"
    fi
  done
else
  warn "No scripts/ directory"
fi

# ============================================================
# AGENT CHECKS
# ============================================================
echo ""
echo "=== Agents ==="
AGENT_DIR="$PLUGIN_ROOT/agents"
if [ -d "$AGENT_DIR" ]; then
  for agent_file in "$AGENT_DIR"/*.md; do
    [ ! -f "$agent_file" ] && continue
    agent_name=$(basename "$agent_file" .md)
    echo "--- $agent_name ---"

    pass "Agent file exists"

    # Has name in frontmatter
    if grep -q "^name:" "$agent_file"; then
      pass "Has name"
    else
      fail "Missing name"
    fi

    # Has description
    if grep -q "^description:" "$agent_file"; then
      pass "Has description"
    else
      fail "Missing description"
    fi

    # Has model
    if grep -q "^model:" "$agent_file"; then
      pass "Has model"
    else
      fail "Missing model"
    fi

    # Has color
    if grep -q "^color:" "$agent_file"; then
      pass "Has color"
    else
      fail "Missing color"
    fi

    # Registered in ecosystem.json
    if [ -f "$ECOSYSTEM" ] && grep -q "\"$agent_name\"" "$ECOSYSTEM"; then
      pass "Registered in ecosystem.json"
    else
      fail "Not registered in ecosystem.json"
    fi
  done
else
  warn "No agents/ directory"
fi

# ============================================================
# REGISTRY CHECKS
# ============================================================
echo ""
echo "=== Registry ==="
if [ -f "$ECOSYSTEM" ]; then
  # Valid JSON
  if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$ECOSYSTEM" 2>/dev/null; then
    pass "ecosystem.json is valid JSON"
  else
    fail "ecosystem.json is invalid JSON"
  fi

  # plugin.json valid JSON
  PLUGIN_JSON="$PLUGIN_ROOT/.claude-plugin/plugin.json"
  if [ -f "$PLUGIN_JSON" ]; then
    if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$PLUGIN_JSON" 2>/dev/null; then
      pass "plugin.json is valid JSON"
    else
      fail "plugin.json is invalid JSON"
    fi
  fi
else
  fail "ecosystem.json not found"
fi

# ============================================================
# TOTALS
# ============================================================
echo ""
echo "=== Summary ==="
TOTAL=$((PASS + FAIL + WARN))
echo "PASS: $PASS  FAIL: $FAIL  WARN: $WARN  TOTAL: $TOTAL"

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL ($FAIL issues to fix)"
  exit 1
else
  echo "RESULT: CLEAN"
  exit 0
fi
