#!/bin/bash
# Agency Plugin — Smoke Test Suite
# Tier 1: Structural Integrity (22 tests)
# Tier 2: Script Robustness (13 tests)
# Exit 0 = all pass, Exit 1 = failures found

set -uo pipefail

# ── Setup ──────────────────────────────────────────────────
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
ERRORS=()

pass() { ((PASS++)); echo "  ✓ $1"; }
fail() { ((FAIL++)); ERRORS+=("$1: $2"); echo "  ✗ $1 — $2"; }

# ── TIER 1: Structural Integrity ──────────────────────────

echo ""
echo "═══ TIER 1: Structural Integrity ═══"
echo ""

# T1-01: plugin.json valid JSON
echo "T1-01: plugin.json valid JSON"
if python3 -c "import json; json.load(open('$PLUGIN_ROOT/.claude-plugin/plugin.json'))" 2>/dev/null; then
  pass "plugin.json is valid JSON"
else
  fail "T1-01" "plugin.json is not valid JSON"
fi

# T1-02: ecosystem.json valid JSON
echo "T1-02: ecosystem.json valid JSON"
if python3 -c "import json; json.load(open('$PLUGIN_ROOT/.claude-plugin/ecosystem.json'))" 2>/dev/null; then
  pass "ecosystem.json is valid JSON"
else
  fail "T1-02" "ecosystem.json is not valid JSON"
fi

# T1-03: plugin.json has name, version, hooks
echo "T1-03: plugin.json has name, version, hooks"
MISSING=""
for field in name version hooks; do
  if ! python3 -c "import json; d=json.load(open('$PLUGIN_ROOT/.claude-plugin/plugin.json')); assert '$field' in d" 2>/dev/null; then
    MISSING="$MISSING $field"
  fi
done
if [ -z "$MISSING" ]; then
  pass "plugin.json has name, version, hooks"
else
  fail "T1-03" "Missing fields:$MISSING"
fi

# T1-04: All 4 hook event types defined
echo "T1-04: All 4 hook event types defined"
MISSING_HOOKS=""
for hook in PreToolUse PostToolUse SessionStart Stop; do
  if ! python3 -c "import json; d=json.load(open('$PLUGIN_ROOT/.claude-plugin/plugin.json')); assert '$hook' in d['hooks']" 2>/dev/null; then
    MISSING_HOOKS="$MISSING_HOOKS $hook"
  fi
done
if [ -z "$MISSING_HOOKS" ]; then
  pass "All 4 hook event types defined"
else
  fail "T1-04" "Missing hooks:$MISSING_HOOKS"
fi

# T1-05: All 8 command .md files exist
echo "T1-05: All 8 command .md files exist"
EXPECTED_CMDS=(init design content build deploy status switch scan)
MISSING_CMDS=""
for cmd in "${EXPECTED_CMDS[@]}"; do
  [ ! -f "$PLUGIN_ROOT/commands/$cmd.md" ] && MISSING_CMDS="$MISSING_CMDS $cmd"
done
if [ -z "$MISSING_CMDS" ]; then
  pass "All 8 command files exist"
else
  fail "T1-05" "Missing commands:$MISSING_CMDS"
fi

# T1-06: All 23 skills have SKILL.md + references/process.md
echo "T1-06: All 23 skills have SKILL.md + references/process.md"
EXPECTED_SKILLS=(
  brand/brand-loader
  design/logo-assets design/asset-registry design/design-tokens design/component-specs design/web-layout
  content/app-copy content/ux-writing
  dev/project-scanner dev/config-generator dev/storybook-generator dev/scaffold
  dev/feature-decomposer dev/team-planner dev/agent-dispatcher dev/completion-gate
  dev/code-review dev/qa-validation
  dev/brainstorm-session dev/brainstorm-decision-writer dev/decision-reader
  devops/deploy-config devops/deploy-execute
)
MISSING_SKILLS=""
for skill in "${EXPECTED_SKILLS[@]}"; do
  [ ! -f "$PLUGIN_ROOT/skills/$skill/SKILL.md" ] && MISSING_SKILLS="$MISSING_SKILLS $skill/SKILL.md"
  [ ! -f "$PLUGIN_ROOT/skills/$skill/references/process.md" ] && MISSING_SKILLS="$MISSING_SKILLS $skill/process.md"
done
if [ -z "$MISSING_SKILLS" ]; then
  pass "All 23 skills have SKILL.md + process.md"
else
  fail "T1-06" "Missing:$MISSING_SKILLS"
fi

# T1-07: All 12 agent .md files exist
echo "T1-07: All 12 agent .md files exist"
EXPECTED_AGENTS=(
  project-manager software-architect frontend-tech-lead backend-tech-lead qa-lead
  frontend-worker backend-worker security-reviewer devops ux-qa design-ux documentation-specialist
)
MISSING_AGENTS=""
for agent in "${EXPECTED_AGENTS[@]}"; do
  [ ! -f "$PLUGIN_ROOT/agents/dev/$agent.md" ] && MISSING_AGENTS="$MISSING_AGENTS $agent"
done
if [ -z "$MISSING_AGENTS" ]; then
  pass "All 12 agent files exist"
else
  fail "T1-07" "Missing agents:$MISSING_AGENTS"
fi

# T1-08: All 3 scripts exist with shebang
echo "T1-08: All 3 scripts exist with shebang"
EXPECTED_SCRIPTS=(session-recovery.sh project-isolation-check.sh check-wave-complete.sh)
SCRIPT_ISSUES=""
for script in "${EXPECTED_SCRIPTS[@]}"; do
  if [ ! -f "$PLUGIN_ROOT/scripts/$script" ]; then
    SCRIPT_ISSUES="$SCRIPT_ISSUES $script(missing)"
  elif ! head -1 "$PLUGIN_ROOT/scripts/$script" | grep -q '^#!/bin/bash'; then
    SCRIPT_ISSUES="$SCRIPT_ISSUES $script(no-shebang)"
  fi
done
if [ -z "$SCRIPT_ISSUES" ]; then
  pass "All 3 scripts exist with shebang"
else
  fail "T1-08" "Issues:$SCRIPT_ISSUES"
fi

# T1-09: All 3 resource schemas exist
echo "T1-09: All 3 resource schemas exist"
EXPECTED_SCHEMAS=(agency-registry-schema.yml project-state-schema.yml asset-registry-schema.yml)
MISSING_SCHEMAS=""
for schema in "${EXPECTED_SCHEMAS[@]}"; do
  [ ! -f "$PLUGIN_ROOT/resources/templates/$schema" ] && MISSING_SCHEMAS="$MISSING_SCHEMAS $schema"
done
if [ -z "$MISSING_SCHEMAS" ]; then
  pass "All 3 resource schemas exist"
else
  fail "T1-09" "Missing schemas:$MISSING_SCHEMAS"
fi

# T1-10: verification-profile.yml + deferred-backlog.yml exist
echo "T1-10: verification-profile.yml + deferred-backlog.yml exist"
MISSING_RES=""
[ ! -f "$PLUGIN_ROOT/resources/verification-profile.yml" ] && MISSING_RES="$MISSING_RES verification-profile.yml"
[ ! -f "$PLUGIN_ROOT/resources/deferred-backlog.yml" ] && MISSING_RES="$MISSING_RES deferred-backlog.yml"
if [ -z "$MISSING_RES" ]; then
  pass "verification-profile.yml + deferred-backlog.yml exist"
else
  fail "T1-10" "Missing:$MISSING_RES"
fi

# T1-11: All SKILL.md ≤ 80 lines
echo "T1-11: All SKILL.md ≤ 80 lines"
OVER_LIMIT=""
for skill in "${EXPECTED_SKILLS[@]}"; do
  LINES=$(wc -l < "$PLUGIN_ROOT/skills/$skill/SKILL.md" 2>/dev/null || echo 0)
  if [ "$LINES" -gt 80 ]; then
    OVER_LIMIT="$OVER_LIMIT $skill($LINES)"
  fi
done
if [ -z "$OVER_LIMIT" ]; then
  pass "All SKILL.md files ≤ 80 lines"
else
  fail "T1-11" "Over 80 lines:$OVER_LIMIT"
fi

# T1-12: Command frontmatter: name + description
echo "T1-12: Command frontmatter: name + description"
CMD_ISSUES=""
for cmd in "${EXPECTED_CMDS[@]}"; do
  FILE="$PLUGIN_ROOT/commands/$cmd.md"
  # Extract frontmatter (between --- markers)
  FM=$(sed -n '/^---$/,/^---$/p' "$FILE" 2>/dev/null)
  if ! echo "$FM" | grep -q 'name:'; then
    CMD_ISSUES="$CMD_ISSUES $cmd(no-name)"
  fi
  if ! echo "$FM" | grep -q 'description:'; then
    CMD_ISSUES="$CMD_ISSUES $cmd(no-description)"
  fi
done
if [ -z "$CMD_ISSUES" ]; then
  pass "All commands have name + description in frontmatter"
else
  fail "T1-12" "Issues:$CMD_ISSUES"
fi

# T1-13: Skill frontmatter: name, depends_on, model_tier, checkpoint
echo "T1-13: Skill frontmatter: name, depends_on, model_tier, checkpoint"
SKILL_FM_ISSUES=""
for skill in "${EXPECTED_SKILLS[@]}"; do
  FILE="$PLUGIN_ROOT/skills/$skill/SKILL.md"
  FM=$(sed -n '/^---$/,/^---$/p' "$FILE" 2>/dev/null)
  for field in name depends_on model_tier checkpoint; do
    if ! echo "$FM" | grep -q "$field"; then
      SKILL_FM_ISSUES="$SKILL_FM_ISSUES $(basename "$skill")(no-$field)"
    fi
  done
done
if [ -z "$SKILL_FM_ISSUES" ]; then
  pass "All skills have required frontmatter fields"
else
  fail "T1-13" "Issues:$SKILL_FM_ISSUES"
fi

# T1-14: Agent frontmatter: name, model_tier, model, tools, capabilities, description, color
echo "T1-14: Agent frontmatter fields"
AGENT_FM_ISSUES=""
for agent in "${EXPECTED_AGENTS[@]}"; do
  FILE="$PLUGIN_ROOT/agents/dev/$agent.md"
  FM=$(sed -n '/^---$/,/^---$/p' "$FILE" 2>/dev/null)
  for field in name model_tier model tools capabilities description color; do
    if ! echo "$FM" | grep -q "$field"; then
      AGENT_FM_ISSUES="$AGENT_FM_ISSUES $agent(no-$field)"
    fi
  done
done
if [ -z "$AGENT_FM_ISSUES" ]; then
  pass "All agents have required frontmatter fields"
else
  fail "T1-14" "Issues:$AGENT_FM_ISSUES"
fi

# T1-15: Command names match ecosystem.json
echo "T1-15: Command names match ecosystem.json"
ECO_CMDS=$(python3 -c "
import json
d = json.load(open('$PLUGIN_ROOT/.claude-plugin/ecosystem.json'))
for c in d['commands']:
    print(c.replace('agency:', ''))
" 2>/dev/null | sort)
FS_CMDS=$(ls "$PLUGIN_ROOT/commands/" 2>/dev/null | sed 's/\.md$//' | sort)
if [ "$ECO_CMDS" = "$FS_CMDS" ]; then
  pass "Command names match ecosystem.json"
else
  fail "T1-15" "Mismatch — ecosystem: [$ECO_CMDS] vs filesystem: [$FS_CMDS]"
fi

# T1-16: Skill names match ecosystem.json
echo "T1-16: Skill names match ecosystem.json"
ECO_SKILLS=$(python3 -c "
import json
d = json.load(open('$PLUGIN_ROOT/.claude-plugin/ecosystem.json'))
skills = []
for module, names in d['skills'].items():
    skills.extend(names)
for s in sorted(skills):
    print(s)
" 2>/dev/null)
FS_SKILLS=$(for skill in "${EXPECTED_SKILLS[@]}"; do basename "$skill"; done | sort)
if [ "$ECO_SKILLS" = "$FS_SKILLS" ]; then
  pass "Skill names match ecosystem.json"
else
  fail "T1-16" "Mismatch between ecosystem.json skills and filesystem"
fi

# T1-17: Agent names match ecosystem.json
echo "T1-17: Agent names match ecosystem.json"
ECO_AGENTS=$(python3 -c "
import json
d = json.load(open('$PLUGIN_ROOT/.claude-plugin/ecosystem.json'))
agents = []
for role, names in d['agents']['dev'].items():
    agents.extend(names)
for a in sorted(agents):
    print(a)
" 2>/dev/null)
FS_AGENTS=$(ls "$PLUGIN_ROOT/agents/dev/" 2>/dev/null | sed 's/\.md$//' | sort)
if [ "$ECO_AGENTS" = "$FS_AGENTS" ]; then
  pass "Agent names match ecosystem.json"
else
  fail "T1-17" "Mismatch between ecosystem.json agents and filesystem"
fi

# T1-18: verification-profile.yml covers all 23 skills
echo "T1-18: verification-profile.yml covers all 23 skills"
UNCOVERED=""
for skill in "${EXPECTED_SKILLS[@]}"; do
  SKILL_NAME=$(basename "$skill")
  if ! grep -q "^  $SKILL_NAME:" "$PLUGIN_ROOT/resources/verification-profile.yml" 2>/dev/null; then
    UNCOVERED="$UNCOVERED $SKILL_NAME"
  fi
done
if [ -z "$UNCOVERED" ]; then
  pass "verification-profile.yml covers all 23 skills"
else
  fail "T1-18" "Uncovered skills:$UNCOVERED"
fi

# T1-19: All depends_on reference valid skill names
echo "T1-19: All depends_on reference valid skill names"
ALL_SKILL_NAMES=""
for skill in "${EXPECTED_SKILLS[@]}"; do
  ALL_SKILL_NAMES="$ALL_SKILL_NAMES $(basename "$skill")"
done
INVALID_DEPS=""
for skill in "${EXPECTED_SKILLS[@]}"; do
  FILE="$PLUGIN_ROOT/skills/$skill/SKILL.md"
  # Extract depends_on line, parse values
  DEPS=$(sed -n '/^---$/,/^---$/p' "$FILE" 2>/dev/null | grep 'depends_on:' | sed 's/.*\[//;s/\].*//;s/,/ /g;s/"//g' | tr -s ' ')
  for dep in $DEPS; do
    dep=$(echo "$dep" | tr -d ' ')
    [ -z "$dep" ] && continue
    if ! echo "$ALL_SKILL_NAMES" | grep -qw "$dep"; then
      INVALID_DEPS="$INVALID_DEPS $(basename "$skill")->$dep"
    fi
  done
done
if [ -z "$INVALID_DEPS" ]; then
  pass "All depends_on reference valid skill names"
else
  fail "T1-19" "Invalid deps:$INVALID_DEPS"
fi

# T1-20: Hook script paths resolve to real files
echo "T1-20: Hook script paths resolve"
HOOK_SCRIPTS=$(python3 -c "
import json, re
d = json.load(open('$PLUGIN_ROOT/.claude-plugin/plugin.json'))
for event, entries in d['hooks'].items():
    for entry in entries:
        hooks = entry.get('hooks', [entry]) if 'hooks' in entry else [entry]
        for h in hooks:
            cmd = h.get('command', '')
            # Extract script paths with \${CLAUDE_PLUGIN_ROOT}
            match = re.search(r'bash \\\$\{CLAUDE_PLUGIN_ROOT\}/(.+?)(?:\s|$)', cmd)
            if match:
                print(match.group(1))
" 2>/dev/null)
BROKEN_HOOKS=""
while IFS= read -r script_path; do
  [ -z "$script_path" ] && continue
  if [ ! -f "$PLUGIN_ROOT/$script_path" ]; then
    BROKEN_HOOKS="$BROKEN_HOOKS $script_path"
  fi
done <<< "$HOOK_SCRIPTS"
if [ -z "$BROKEN_HOOKS" ]; then
  pass "All hook script paths resolve"
else
  fail "T1-20" "Broken paths:$BROKEN_HOOKS"
fi

# T1-21: deferred-backlog.yml has 20 entries
echo "T1-21: deferred-backlog.yml has 20 entries"
DEFER_COUNT=$(grep -c '^\s*- id: "defer-' "$PLUGIN_ROOT/resources/deferred-backlog.yml" 2>/dev/null || echo 0)
if [ "$DEFER_COUNT" -eq 20 ]; then
  pass "deferred-backlog.yml has 20 entries"
else
  fail "T1-21" "Expected 20, found $DEFER_COUNT"
fi

# T1-22: No dependency cycles (DAG check)
echo "T1-22: No dependency cycles"
CYCLE_CHECK=$(python3 << 'PYEOF'
import os, sys, re

plugin_root = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("PLUGIN_ROOT", ".")
skills_dir = os.path.join(plugin_root, "skills")

graph = {}
for root, dirs, files in os.walk(skills_dir):
    if "SKILL.md" in files:
        skill_name = os.path.basename(root)
        filepath = os.path.join(root, "SKILL.md")
        with open(filepath) as f:
            content = f.read()
        # Extract frontmatter
        parts = content.split("---")
        if len(parts) >= 3:
            fm = parts[1]
            match = re.search(r'depends_on:\s*\[([^\]]*)\]', fm)
            if match:
                deps_str = match.group(1).strip()
                if deps_str:
                    deps = [d.strip().strip('"').strip("'") for d in deps_str.split(",")]
                    graph[skill_name] = [d for d in deps if d]
                else:
                    graph[skill_name] = []
            else:
                graph[skill_name] = []

# Topological sort to detect cycles
visited = set()
in_stack = set()
has_cycle = False

def dfs(node):
    global has_cycle
    if node in in_stack:
        has_cycle = True
        return
    if node in visited:
        return
    visited.add(node)
    in_stack.add(node)
    for dep in graph.get(node, []):
        if dep in graph:
            dfs(dep)
    in_stack.discard(node)

for node in graph:
    dfs(node)

if has_cycle:
    print("CYCLE_DETECTED")
else:
    print("NO_CYCLES")
PYEOF
)
# Pass PLUGIN_ROOT as argument
CYCLE_CHECK=$(python3 -c "
import os, sys, re

plugin_root = '$PLUGIN_ROOT'
skills_dir = os.path.join(plugin_root, 'skills')

graph = {}
for root, dirs, files in os.walk(skills_dir):
    if 'SKILL.md' in files:
        skill_name = os.path.basename(root)
        filepath = os.path.join(root, 'SKILL.md')
        with open(filepath) as f:
            content = f.read()
        parts = content.split('---')
        if len(parts) >= 3:
            fm = parts[1]
            match = re.search(r'depends_on:\s*\[([^\]]*)\]', fm)
            if match:
                deps_str = match.group(1).strip()
                if deps_str:
                    deps = [d.strip().strip('\"').strip(\"'\") for d in deps_str.split(',')]
                    graph[skill_name] = [d for d in deps if d]
                else:
                    graph[skill_name] = []
            else:
                graph[skill_name] = []

visited = set()
in_stack = set()
has_cycle = False

def dfs(node):
    global has_cycle
    if node in in_stack:
        has_cycle = True
        return
    if node in visited:
        return
    visited.add(node)
    in_stack.add(node)
    for dep in graph.get(node, []):
        if dep in graph:
            dfs(dep)
    in_stack.discard(node)

for node in graph:
    dfs(node)

if has_cycle:
    print('CYCLE_DETECTED')
else:
    print('NO_CYCLES')
" 2>/dev/null)

if [ "$CYCLE_CHECK" = "NO_CYCLES" ]; then
  pass "No dependency cycles detected"
else
  fail "T1-22" "Dependency cycle detected in skill graph"
fi

# ── TIER 2: Script Robustness ─────────────────────────────

echo ""
echo "═══ TIER 2: Script Robustness ═══"
echo ""

# Create temp directory for controlled tests
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# Helper: run script in isolated temp dir
run_in_tmp() {
  local script="$1"
  local exit_expected="$2"
  shift 2
  # Run from temp dir with stdin if provided
  (cd "$TMPDIR" && bash "$PLUGIN_ROOT/scripts/$script" "$@" 2>&1)
  return $?
}

# T2-01: session-recovery.sh — No agency.yml
echo "T2-01: session-recovery.sh — No agency.yml"
rm -rf "$TMPDIR" && TMPDIR=$(mktemp -d)
OUTPUT=$(cd "$TMPDIR" && bash "$PLUGIN_ROOT/scripts/session-recovery.sh" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  pass "session-recovery exits 0 with no agency.yml"
else
  fail "T2-01" "Expected exit 0, got $EXIT_CODE"
fi

# T2-02: session-recovery.sh — Empty agency.yml
echo "T2-02: session-recovery.sh — Empty agency.yml"
rm -rf "$TMPDIR" && TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.ai"
touch "$TMPDIR/.ai/agency.yml"
OUTPUT=$(cd "$TMPDIR" && bash "$PLUGIN_ROOT/scripts/session-recovery.sh" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  pass "session-recovery exits 0 with empty agency.yml"
else
  fail "T2-02" "Expected exit 0, got $EXIT_CODE"
fi

# T2-03: session-recovery.sh — Valid yml, no state.yml
echo "T2-03: session-recovery.sh — Valid yml, no state.yml"
rm -rf "$TMPDIR" && TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.ai"
echo 'active: test-project' > "$TMPDIR/.ai/agency.yml"
OUTPUT=$(cd "$TMPDIR" && bash "$PLUGIN_ROOT/scripts/session-recovery.sh" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  pass "session-recovery exits 0 with no state.yml"
else
  fail "T2-03" "Expected exit 0, got $EXIT_CODE"
fi

# T2-04: session-recovery.sh — Valid yml + state.yml
echo "T2-04: session-recovery.sh — Valid yml + state.yml"
rm -rf "$TMPDIR" && TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.ai/projects/test-project"
echo 'active: test-project' > "$TMPDIR/.ai/agency.yml"
cat > "$TMPDIR/.ai/projects/test-project/state.yml" << 'EOF'
project: test-project
status: in_progress
current_module: design
current_skill: design-tokens
EOF
OUTPUT=$(cd "$TMPDIR" && bash "$PLUGIN_ROOT/scripts/session-recovery.sh" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ] && echo "$OUTPUT" | grep -q "test-project"; then
  pass "session-recovery shows state with valid config"
else
  fail "T2-04" "Exit: $EXIT_CODE, output missing project name"
fi

# T2-05: project-isolation-check.sh — No agency.yml
echo "T2-05: project-isolation-check.sh — No agency.yml"
rm -rf "$TMPDIR" && TMPDIR=$(mktemp -d)
OUTPUT=$(echo '{"file_path": ".ai/projects/other/file.yml"}' | (cd "$TMPDIR" && bash "$PLUGIN_ROOT/scripts/project-isolation-check.sh") 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  pass "isolation-check allows all with no agency.yml"
else
  fail "T2-05" "Expected exit 0, got $EXIT_CODE"
fi

# T2-06: project-isolation-check.sh — Same-project write
echo "T2-06: project-isolation-check.sh — Same-project write"
rm -rf "$TMPDIR" && TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.ai"
echo 'active: myproject' > "$TMPDIR/.ai/agency.yml"
OUTPUT=$(echo '.ai/projects/myproject/state.yml' | (cd "$TMPDIR" && bash "$PLUGIN_ROOT/scripts/project-isolation-check.sh") 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  pass "isolation-check allows same-project write"
else
  fail "T2-06" "Expected exit 0 (allowed), got $EXIT_CODE"
fi

# T2-07: project-isolation-check.sh — Cross-project write
echo "T2-07: project-isolation-check.sh — Cross-project write"
rm -rf "$TMPDIR" && TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.ai"
echo 'active: myproject' > "$TMPDIR/.ai/agency.yml"
OUTPUT=$(echo '.ai/projects/otherproject/state.yml' | (cd "$TMPDIR" && bash "$PLUGIN_ROOT/scripts/project-isolation-check.sh") 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 1 ] && echo "$OUTPUT" | grep -q "BLOCKED"; then
  pass "isolation-check blocks cross-project write"
else
  fail "T2-07" "Expected exit 1 + BLOCKED, got exit $EXIT_CODE"
fi

# T2-08: project-isolation-check.sh — Cross-brand write
echo "T2-08: project-isolation-check.sh — Cross-brand write"
rm -rf "$TMPDIR" && TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.ai"
echo 'active: myproject' > "$TMPDIR/.ai/agency.yml"
OUTPUT=$(echo 'packages/brand/otherproject/tokens.css' | (cd "$TMPDIR" && bash "$PLUGIN_ROOT/scripts/project-isolation-check.sh") 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 1 ] && echo "$OUTPUT" | grep -q "BLOCKED"; then
  pass "isolation-check blocks cross-brand write"
else
  fail "T2-08" "Expected exit 1 + BLOCKED, got exit $EXIT_CODE"
fi

# T2-09: project-isolation-check.sh — Non-project path
echo "T2-09: project-isolation-check.sh — Non-project path"
rm -rf "$TMPDIR" && TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.ai"
echo 'active: myproject' > "$TMPDIR/.ai/agency.yml"
OUTPUT=$(echo 'src/components/Button.tsx' | (cd "$TMPDIR" && bash "$PLUGIN_ROOT/scripts/project-isolation-check.sh") 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  pass "isolation-check allows non-project path"
else
  fail "T2-09" "Expected exit 0, got $EXIT_CODE"
fi

# T2-10: check-wave-complete.sh — No agency.yml
echo "T2-10: check-wave-complete.sh — No agency.yml"
rm -rf "$TMPDIR" && TMPDIR=$(mktemp -d)
OUTPUT=$(cd "$TMPDIR" && bash "$PLUGIN_ROOT/scripts/check-wave-complete.sh" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  pass "check-wave-complete exits 0 with no agency.yml"
else
  fail "T2-10" "Expected exit 0, got $EXIT_CODE"
fi

# T2-11: check-wave-complete.sh — Status: completed
echo "T2-11: check-wave-complete.sh — Status: completed"
rm -rf "$TMPDIR" && TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.ai/projects/test-project"
echo 'active: test-project' > "$TMPDIR/.ai/agency.yml"
cat > "$TMPDIR/.ai/projects/test-project/state.yml" << 'EOF'
project: test-project
status: completed
EOF
OUTPUT=$(cd "$TMPDIR" && bash "$PLUGIN_ROOT/scripts/check-wave-complete.sh" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ] && ! echo "$OUTPUT" | grep -q "WARNING"; then
  pass "check-wave-complete silent on completed status"
else
  fail "T2-11" "Expected exit 0 without WARNING"
fi

# T2-12: check-wave-complete.sh — Status: in_progress
echo "T2-12: check-wave-complete.sh — Status: in_progress"
rm -rf "$TMPDIR" && TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.ai/projects/test-project"
echo 'active: test-project' > "$TMPDIR/.ai/agency.yml"
cat > "$TMPDIR/.ai/projects/test-project/state.yml" << 'EOF'
project: test-project
status: in_progress
current_module: dev
current_skill: scaffold
EOF
OUTPUT=$(cd "$TMPDIR" && bash "$PLUGIN_ROOT/scripts/check-wave-complete.sh" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ] && echo "$OUTPUT" | grep -q "WARNING"; then
  pass "check-wave-complete warns on in_progress status"
else
  fail "T2-12" "Expected exit 0 + WARNING message"
fi

# T2-13: All scripts have set -euo pipefail
echo "T2-13: All scripts have set -euo pipefail"
PIPEFAIL_ISSUES=""
for script in "${EXPECTED_SCRIPTS[@]}"; do
  if ! grep -q 'set -euo pipefail' "$PLUGIN_ROOT/scripts/$script" 2>/dev/null; then
    PIPEFAIL_ISSUES="$PIPEFAIL_ISSUES $script"
  fi
done
if [ -z "$PIPEFAIL_ISSUES" ]; then
  pass "All scripts have set -euo pipefail"
else
  fail "T2-13" "Missing pipefail:$PIPEFAIL_ISSUES"
fi

# ── Summary ───────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed ($(($PASS + $FAIL)) total)"
echo "═══════════════════════════════════════"

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo ""
  echo "Failures:"
  for err in "${ERRORS[@]}"; do
    echo "  • $err"
  done
  echo ""
  exit 1
fi

echo ""
echo "All tests passed!"
exit 0
