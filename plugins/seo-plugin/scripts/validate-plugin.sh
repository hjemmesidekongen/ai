#!/usr/bin/env bash
# validate-plugin.sh — End-to-end structural validation for seo-plugin
#
# Validates:
#   1. File existence (all skills, commands, resources, config)
#   2. Plugin.json integrity (skills/commands match actual files)
#   3. Skill frontmatter (required fields present)
#   4. Dependency chain (no missing deps, no cycles, correct phase order)
#   5. Read/write coverage (every schema section has a writer)
#   6. Command cross-references (commands reference existing skills)
#   7. Schema completeness (all 8 top-level sections defined)
#   8. Template sections match compile-and-export expectations
#   9. Verification profile registered in task-planner
#
# Usage: bash plugins/seo-plugin/scripts/validate-plugin.sh

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
export PLUGIN_DIR
ROOT_DIR="$(cd "$PLUGIN_DIR/../.." && pwd)"
PASS=0
FAIL=0
WARN=0

pass() { PASS=$((PASS + 1)); printf "  ✓ %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  ✗ %s\n" "$1"; }
warn() { WARN=$((WARN + 1)); printf "  ⚠ %s\n" "$1"; }
section() { printf "\n## %s\n\n" "$1"; }

# ─────────────────────────────────────────────────
section "1. File Existence"
# ─────────────────────────────────────────────────

EXPECTED_FILES=(
  ".claude-plugin/plugin.json"
  "README.md"
  "design.yml"
  "resources/templates/seo-strategy-schema.yml"
  "resources/templates/seo-strategy-template.md"
  "resources/templates/state-schema.yml"
  "skills/project-interview/SKILL.md"
  "skills/keyword-research/SKILL.md"
  "skills/competitor-analysis/SKILL.md"
  "skills/technical-seo/SKILL.md"
  "skills/on-page-optimization/SKILL.md"
  "skills/content-strategy/SKILL.md"
  "skills/link-building/SKILL.md"
  "skills/compile-and-export/SKILL.md"
  "commands/strategy.md"
  "commands/audit.md"
  "commands/content-brief.md"
  "commands/export.md"
)

for f in "${EXPECTED_FILES[@]}"; do
  if [[ -f "$PLUGIN_DIR/$f" ]]; then
    pass "$f exists"
  else
    fail "$f MISSING"
  fi
done

# ─────────────────────────────────────────────────
section "2. Plugin.json Integrity"
# ─────────────────────────────────────────────────

PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"

# Check required top-level keys
for key in name version description commands skills dependencies; do
  if grep -q "\"$key\"" "$PLUGIN_JSON"; then
    pass "plugin.json has '$key'"
  else
    fail "plugin.json missing '$key'"
  fi
done

# Check name is correct
if grep -q '"name": "seo-plugin"' "$PLUGIN_JSON"; then
  pass "plugin name is 'seo-plugin'"
else
  fail "plugin name should be 'seo-plugin'"
fi

# Check dependencies include task-planner and brand-guideline
for dep in task-planner brand-guideline; do
  if grep -q "\"$dep\"" "$PLUGIN_JSON"; then
    pass "dependency '$dep' declared"
  else
    fail "dependency '$dep' missing"
  fi
done

# Check shared_skills includes brand-context-loader
if grep -q '"brand-context-loader"' "$PLUGIN_JSON"; then
  pass "shared skill 'brand-context-loader' declared"
else
  fail "shared skill 'brand-context-loader' missing"
fi

# Verify every skill in plugin.json has a SKILL.md
# Use python for JSON parsing (available on macOS)
SKILLS_IN_JSON=$(python3 -c "import json; d=json.load(open('$PLUGIN_JSON')); print('\n'.join(d.get('skills',[])))")
for skill in $SKILLS_IN_JSON; do
  if [[ -f "$PLUGIN_DIR/skills/$skill/SKILL.md" ]]; then
    pass "skill '$skill' has SKILL.md"
  else
    fail "skill '$skill' listed in plugin.json but no SKILL.md found"
  fi
done

# Verify every command in plugin.json has a command file
COMMANDS_IN_JSON=$(python3 -c "import json; d=json.load(open('$PLUGIN_JSON')); print('\n'.join(d.get('commands',[])))")
for cmd in $COMMANDS_IN_JSON; do
  if [[ -f "$PLUGIN_DIR/commands/$cmd.md" ]]; then
    pass "command '$cmd' has $cmd.md"
  else
    fail "command '$cmd' listed in plugin.json but no $cmd.md found"
  fi
done

# Verify no orphan skills (SKILL.md exists but not in plugin.json)
for skill_dir in "$PLUGIN_DIR"/skills/*/; do
  skill_name=$(basename "$skill_dir")
  if echo "$SKILLS_IN_JSON" | grep -qx "$skill_name"; then
    pass "skill '$skill_name' registered in plugin.json"
  else
    fail "skill '$skill_name' has SKILL.md but is NOT in plugin.json"
  fi
done

# Verify no orphan commands
for cmd_file in "$PLUGIN_DIR"/commands/*.md; do
  cmd_name=$(basename "$cmd_file" .md)
  if echo "$COMMANDS_IN_JSON" | grep -qx "$cmd_name"; then
    pass "command '$cmd_name' registered in plugin.json"
  else
    fail "command '$cmd_name' has file but is NOT in plugin.json"
  fi
done

# ─────────────────────────────────────────────────
section "3. Skill Frontmatter Validation"
# ─────────────────────────────────────────────────

REQUIRED_SKILL_FIELDS=("name" "description" "phase" "depends_on" "writes" "checkpoint")

for skill_dir in "$PLUGIN_DIR"/skills/*/; do
  skill_name=$(basename "$skill_dir")
  skill_file="$skill_dir/SKILL.md"

  # Extract frontmatter (between --- markers)
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$skill_file")

  for field in "${REQUIRED_SKILL_FIELDS[@]}"; do
    if echo "$frontmatter" | grep -q "^${field}:"; then
      pass "$skill_name: has '$field'"
    else
      fail "$skill_name: missing '$field' in frontmatter"
    fi
  done

  # Check checkpoint has type
  if echo "$frontmatter" | grep -q "type:"; then
    pass "$skill_name: checkpoint has 'type'"
  else
    fail "$skill_name: checkpoint missing 'type'"
  fi

  # Check checkpoint has required_checks
  if echo "$frontmatter" | grep -q "required_checks:"; then
    pass "$skill_name: checkpoint has 'required_checks'"
  else
    fail "$skill_name: checkpoint missing 'required_checks'"
  fi
done

# ─────────────────────────────────────────────────
section "4. Dependency Chain Validation"
# ─────────────────────────────────────────────────

# Use Python to validate dependency chain (bash 3.2 lacks associative arrays)
DEP_RESULT=$(python3 << 'PYEOF'
import os, re, sys

plugin_dir = os.environ.get("PLUGIN_DIR", "")
if not plugin_dir:
    plugin_dir = sys.argv[1] if len(sys.argv) > 1 else "."

skills_dir = os.path.join(plugin_dir, "skills")
skills = {}

# Parse all skill frontmatters
for skill_name in sorted(os.listdir(skills_dir)):
    skill_file = os.path.join(skills_dir, skill_name, "SKILL.md")
    if not os.path.isfile(skill_file):
        continue
    with open(skill_file) as f:
        content = f.read()
    # Extract frontmatter
    fm_match = re.search(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not fm_match:
        continue
    fm = fm_match.group(1)
    phase_m = re.search(r'^phase:\s*(\d+)', fm, re.MULTILINE)
    deps_m = re.search(r'^depends_on:\s*\[([^\]]*)\]', fm, re.MULTILINE)
    phase = int(phase_m.group(1)) if phase_m else 0
    deps = [d.strip() for d in deps_m.group(1).split(",") if d.strip()] if deps_m else []
    skills[skill_name] = {"phase": phase, "deps": deps}

expected_phases = {
    "project-interview": 1, "keyword-research": 2,
    "competitor-analysis": 3, "technical-seo": 3,
    "on-page-optimization": 4, "content-strategy": 5,
    "link-building": 6, "compile-and-export": 7,
}

# Check deps exist
for name, info in sorted(skills.items()):
    if not info["deps"]:
        print(f"PASS|{name}: no dependencies (root skill)")
        continue
    for dep in info["deps"]:
        if dep in skills:
            print(f"PASS|{name}: depends on '{dep}' (exists)")
        else:
            print(f"FAIL|{name}: depends on '{dep}' but skill does NOT exist")

# Check phase ordering
for name, info in sorted(skills.items()):
    for dep in info["deps"]:
        if dep not in skills:
            continue
        dep_phase = skills[dep]["phase"]
        if dep_phase < info["phase"]:
            print(f"PASS|{name} (phase {info['phase']}): dep '{dep}' is phase {dep_phase} (correct order)")
        elif dep_phase == info["phase"]:
            print(f"WARN|{name} (phase {info['phase']}): dep '{dep}' is same phase {dep_phase} (parallel)")
        else:
            print(f"FAIL|{name} (phase {info['phase']}): dep '{dep}' is phase {dep_phase} (WRONG ORDER)")

# Check expected phases
for name, expected in sorted(expected_phases.items()):
    actual = skills.get(name, {}).get("phase", "?")
    if actual == expected:
        print(f"PASS|{name}: phase {actual} (correct)")
    else:
        print(f"FAIL|{name}: phase {actual} but expected {expected}")
PYEOF
)

while IFS='|' read -r level msg; do
  case "$level" in
    PASS) pass "$msg" ;;
    FAIL) fail "$msg" ;;
    WARN) warn "$msg" ;;
  esac
done <<< "$DEP_RESULT"

# ─────────────────────────────────────────────────
section "5. Read/Write Coverage"
# ─────────────────────────────────────────────────

# All 8 schema sections that must be written by exactly one skill
SCHEMA_SECTIONS=("meta" "project_context" "keywords" "competitors" "on_page" "technical" "content_plan" "link_building")

for schema_section in "${SCHEMA_SECTIONS[@]}"; do
  writer_count=0
  writers=""
  for skill_dir in "$PLUGIN_DIR"/skills/*/; do
    skill_name=$(basename "$skill_dir")
    skill_file="$skill_dir/SKILL.md"
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$skill_file")

    # Check if this skill writes to this section
    if echo "$frontmatter" | grep -q "#${schema_section}"; then
      writer_count=$((writer_count + 1))
      writers="$writers $skill_name"
    fi
  done

  if [[ $writer_count -eq 0 ]]; then
    fail "schema section '$schema_section': NO skill writes to it"
  elif [[ $writer_count -eq 1 ]]; then
    pass "schema section '$schema_section': written by$writers"
  else
    # meta is written by both project-interview and compile-and-export (different sub-fields)
    if [[ "$schema_section" == "meta" ]]; then
      pass "schema section '$schema_section': written by$writers (expected — different sub-fields)"
    else
      warn "schema section '$schema_section': written by$writers ($writer_count writers — verify no conflicts)"
    fi
  fi
done

# ─────────────────────────────────────────────────
section "6. Command Cross-References"
# ─────────────────────────────────────────────────

# strategy.md should reference all 8 skills
STRATEGY_CMD="$PLUGIN_DIR/commands/strategy.md"
STRATEGY_SKILLS=("project-interview" "keyword-research" "competitor-analysis" "technical-seo" "on-page-optimization" "content-strategy" "link-building" "compile-and-export")

for skill in "${STRATEGY_SKILLS[@]}"; do
  if grep -qi "$skill" "$STRATEGY_CMD"; then
    pass "strategy.md references skill '$skill'"
  else
    fail "strategy.md does NOT reference skill '$skill'"
  fi
done

# strategy.md should reference /plan:create and /plan:execute
for plan_cmd in "/plan:create" "/plan:execute"; do
  if grep -q "$plan_cmd" "$STRATEGY_CMD"; then
    pass "strategy.md references '$plan_cmd'"
  else
    fail "strategy.md does NOT reference '$plan_cmd'"
  fi
done

# strategy.md should reference seo_plugin_profile
if grep -q "seo_plugin_profile" "$STRATEGY_CMD"; then
  pass "strategy.md references verification profile 'seo_plugin_profile'"
else
  fail "strategy.md does NOT reference verification profile 'seo_plugin_profile'"
fi

# audit.md should reference seo-strategy.yml sections
AUDIT_CMD="$PLUGIN_DIR/commands/audit.md"
for section_check in "title" "meta" "heading" "schema" "HTTPS"; do
  if grep -qi "$section_check" "$AUDIT_CMD"; then
    pass "audit.md covers '$section_check'"
  else
    fail "audit.md does NOT cover '$section_check'"
  fi
done

# content-brief.md should reference content types
BRIEF_CMD="$PLUGIN_DIR/commands/content-brief.md"
for content_type in "guide" "how-to" "listicle" "case study" "comparison" "tutorial"; do
  if grep -qi "$content_type" "$BRIEF_CMD"; then
    pass "content-brief.md references content type '$content_type'"
  else
    fail "content-brief.md does NOT reference content type '$content_type'"
  fi
done

# export.md should reference pandoc and format options
EXPORT_CMD="$PLUGIN_DIR/commands/export.md"
for export_check in "pandoc" "docx" "seo-strategy.yml"; do
  if grep -qi "$export_check" "$EXPORT_CMD"; then
    pass "export.md references '$export_check'"
  else
    fail "export.md does NOT reference '$export_check'"
  fi
done

# ─────────────────────────────────────────────────
section "7. Schema Completeness"
# ─────────────────────────────────────────────────

SCHEMA_FILE="$PLUGIN_DIR/resources/templates/seo-strategy-schema.yml"

# Check all 8 top-level sections exist
for schema_section in "${SCHEMA_SECTIONS[@]}"; do
  if grep -q "^${schema_section}:" "$SCHEMA_FILE"; then
    pass "schema defines '$schema_section'"
  else
    fail "schema missing '$schema_section'"
  fi
done

# Check key nested properties exist
NESTED_CHECKS=(
  "meta:plugin_name"
  "meta:project_name"
  "meta:created_at"
  "meta:updated_at"
  "meta:version"
  "project_context:website_url"
  "project_context:industry"
  "project_context:goals"
  "project_context:target_audience"
  "project_context:current_status"
  "keywords:primary"
  "keywords:secondary"
  "keywords:long_tail"
  "competitors:analyzed"
  "competitors:content_gaps"
  "on_page:title_tag"
  "on_page:meta_description"
  "on_page:heading_hierarchy"
  "on_page:internal_linking"
  "on_page:schema_markup"
  "technical:core_web_vitals"
  "technical:checklist"
  "technical:mobile_requirements"
  "content_plan:topic_clusters"
  "content_plan:content_types"
  "content_plan:calendar"
  "link_building:strategies"
  "link_building:outreach_targets"
  "link_building:content_promotion"
)

for check in "${NESTED_CHECKS[@]}"; do
  IFS=':' read -r parent child <<< "$check"
  if grep -q "$child:" "$SCHEMA_FILE"; then
    pass "schema has '$parent.$child'"
  else
    fail "schema missing '$parent.$child'"
  fi
done

# ─────────────────────────────────────────────────
section "8. Template Sections"
# ─────────────────────────────────────────────────

TEMPLATE_FILE="$PLUGIN_DIR/resources/templates/seo-strategy-template.md"

TEMPLATE_SECTIONS=(
  "Executive Summary"
  "Keyword Strategy"
  "Competitor Landscape"
  "On-Page Optimization Rules"
  "Technical SEO Checklist"
  "Content Plan"
  "Link-Building Strategy"
)

for tmpl_section in "${TEMPLATE_SECTIONS[@]}"; do
  if grep -qi "$tmpl_section" "$TEMPLATE_FILE"; then
    pass "template has section '$tmpl_section'"
  else
    fail "template missing section '$tmpl_section'"
  fi
done

# Check template has table of contents
if grep -qi "table of contents" "$TEMPLATE_FILE"; then
  pass "template has Table of Contents"
else
  fail "template missing Table of Contents"
fi

# Check template has placeholder markers (these get replaced during generation)
if grep -q '\[Project Name\]' "$TEMPLATE_FILE"; then
  pass "template has [Project Name] placeholder"
else
  fail "template missing [Project Name] placeholder"
fi

# ─────────────────────────────────────────────────
section "9. State Schema"
# ─────────────────────────────────────────────────

STATE_SCHEMA="$PLUGIN_DIR/resources/templates/state-schema.yml"

STATE_FIELDS=("command" "project_name" "started_at" "updated_at" "current_phase" "current_phase_number" "total_phases" "phases")

for field in "${STATE_FIELDS[@]}"; do
  if grep -q "^${field}:" "$STATE_SCHEMA"; then
    pass "state schema defines '$field'"
  else
    fail "state schema missing '$field'"
  fi
done

# Check phase item has required sub-fields
for sub_field in "name" "status" "checkpoint"; do
  if grep -q "${sub_field}:" "$STATE_SCHEMA"; then
    pass "state schema phase item has '$sub_field'"
  else
    fail "state schema phase item missing '$sub_field'"
  fi
done

# ─────────────────────────────────────────────────
section "10. Verification Profile"
# ─────────────────────────────────────────────────

REGISTRY_FILE="$ROOT_DIR/plugins/task-planner/resources/verification-registry.yml"

if [[ -f "$REGISTRY_FILE" ]]; then
  if grep -q "seo_plugin_profile:" "$REGISTRY_FILE"; then
    pass "seo_plugin_profile registered in verification-registry.yml"

    # Check it has the expected verification types
    for vtype in "data_validation" "schema_validation" "seo_audit"; do
      if grep -A 20 "seo_plugin_profile:" "$REGISTRY_FILE" | grep -q "$vtype"; then
        pass "profile includes '$vtype'"
      else
        fail "profile missing '$vtype'"
      fi
    done

    # Check qa_frequency
    if grep -A 20 "seo_plugin_profile:" "$REGISTRY_FILE" | grep -q 'qa_frequency.*every_wave'; then
      pass "profile has qa_frequency: every_wave"
    else
      fail "profile missing qa_frequency: every_wave"
    fi
  else
    fail "seo_plugin_profile NOT found in verification-registry.yml"
  fi
else
  fail "verification-registry.yml not found at $REGISTRY_FILE"
fi

# ─────────────────────────────────────────────────
section "11. Compile-and-Export Completeness"
# ─────────────────────────────────────────────────

COMPILE_SKILL="$PLUGIN_DIR/skills/compile-and-export/SKILL.md"

# Check it depends on ALL other skills
ALL_OTHER_SKILLS=("project-interview" "keyword-research" "competitor-analysis" "on-page-optimization" "technical-seo" "content-strategy" "link-building")
compile_frontmatter=$(sed -n '/^---$/,/^---$/p' "$COMPILE_SKILL")
compile_deps=$(echo "$compile_frontmatter" | grep "^depends_on:" | head -1)

for skill in "${ALL_OTHER_SKILLS[@]}"; do
  if echo "$compile_deps" | grep -q "$skill"; then
    pass "compile-and-export depends on '$skill'"
  else
    fail "compile-and-export does NOT depend on '$skill'"
  fi
done

# Check it has qa_review: mandatory
if grep -q "qa_review.*mandatory" "$COMPILE_SKILL"; then
  pass "compile-and-export has qa_review: mandatory"
else
  fail "compile-and-export missing qa_review: mandatory"
fi

# Check checkpoint type is file_validation
if echo "$compile_frontmatter" | grep -q "file_validation"; then
  pass "compile-and-export checkpoint type is file_validation"
else
  fail "compile-and-export checkpoint should be file_validation"
fi

# ─────────────────────────────────────────────────
section "12. Command Frontmatter"
# ─────────────────────────────────────────────────

REQUIRED_CMD_FIELDS=("name" "command" "description" "arguments")

for cmd_file in "$PLUGIN_DIR"/commands/*.md; do
  cmd_name=$(basename "$cmd_file" .md)
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$cmd_file")

  for field in "${REQUIRED_CMD_FIELDS[@]}"; do
    if echo "$frontmatter" | grep -q "^${field}\b"; then
      pass "$cmd_name: has '$field'"
    else
      # arguments might be indented under the --- block
      if echo "$frontmatter" | grep -q "${field}:"; then
        pass "$cmd_name: has '$field'"
      else
        fail "$cmd_name: missing '$field' in frontmatter"
      fi
    fi
  done

  # Verify command prefix is /seo:
  if echo "$frontmatter" | grep -q '"/seo:'; then
    pass "$cmd_name: command starts with /seo:"
  else
    fail "$cmd_name: command should start with /seo:"
  fi
done

# ─────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────

printf "\n═══════════════════════════════════════════\n"
printf "  Results: %d passed, %d failed, %d warnings\n" "$PASS" "$FAIL" "$WARN"
printf "═══════════════════════════════════════════\n"

if [[ $FAIL -gt 0 ]]; then
  printf "\n  ✗ VALIDATION FAILED — fix %d issue(s) before proceeding\n\n" "$FAIL"
  exit 1
else
  printf "\n  ✓ ALL CHECKS PASSED\n\n"
  exit 0
fi
