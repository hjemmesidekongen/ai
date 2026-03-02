# Plugin Scaffolder — Process Detail

## Prerequisites

Before running this skill, read:
1. `plugins/[plugin-name]/design.yml` — the approved design (status must be "approved")
2. `docs/[plugin-name]-addendum.md` — Section c (Tools and Dependencies) for README prerequisites
3. `plugins/task-planner/resources/plugin-blueprint.md` — Section 2 (Required Plugin Structure) and Section 5 (Verification Profiles)

Also verify these exist (produced by upstream skills):
- `docs/[plugin-name]-implementation-plan.md`
- `docs/[plugin-name]-execution-guide.md`

## Process

### Step 1 — Validate Prerequisites

Read `plugins/[plugin-name]/design.yml`. Validate:

```
Required fields for scaffolding:
  - name                    (string, kebab-case)
  - description             (string)
  - needs_brand             (boolean)
  - commands                (array, at least 1 entry, each with name field)
  - skills                  (array, at least 2 entries, each with name field)
  - status                  (must be "approved")
```

If `status` is not `approved`, STOP. Do not scaffold unapproved designs.

Verify upstream artifacts exist:
- `docs/[plugin-name]-implementation-plan.md` — must exist
- `docs/[plugin-name]-addendum.md` — must exist
- `docs/[plugin-name]-execution-guide.md` — must exist

If any are missing, STOP and report which upstream skill needs to run first.

---

### Step 2 — Create Directory Structure

Create the full directory tree under `plugins/[plugin-name]/`:

```
plugins/[plugin-name]/
├── .claude-plugin/
├── commands/
├── skills/
├── resources/
│   ├── templates/
│   └── examples/
└── scripts/
```

**Conditional directory:** Only create `agents/` if design.yml defines agents or if the plugin's commands reference agent-based execution. Check `design.yml` — if there is no `agents` field or it is empty, skip the `agents/` directory.

**Skill directories with progressive disclosure:** For each skill in `design.yml.skills`, create a skill directory. Classify each skill as **complex** or **simple**:

- **Complex** — involves interviews, research, content generation, multi-step processes, or has 5+ process steps in the spec. Create:
  ```
  skills/[skill-name]/
    SKILL.md              # Lean format (≤80 lines)
    references/
      process.md          # Stub with template header
  ```

- **Simple** — procedural, mechanical, utility-focused (file-ownership, state-management type). Create:
  ```
  skills/[skill-name]/
    SKILL.md              # Lean format (≤80 lines), no references/
  ```

**Stub `references/process.md` template:**
```markdown
# [Skill Name]: Detailed Process

## Step-by-step Instructions
[To be filled during skill implementation]

## Output Format
[To be filled during skill implementation]

## Edge Cases
[To be filled during skill implementation]
```

**Lean SKILL.md template** (used for ALL scaffolded skills):
```yaml
---
name: [skill-name]
description: >
  [One sentence purpose]. Use when [trigger phrase 1],
  [trigger phrase 2], or [trigger phrase 3].
interactive: [true|false]
depends_on: [from design.yml]
reads: [from design.yml]
writes: [from design.yml]
checkpoint_type: [from design.yml]
---
```
```markdown
# [Skill Name]

[One-sentence purpose from design.yml]

## Context

- Reads: [from design.yml]
- Writes: [from design.yml]
- Checkpoint: [type] ([brief description of checks])
- Dependencies: [from design.yml or "none"]

## Process Summary

1. [Step one placeholder]
2. [Step two placeholder]
3. [Step three placeholder]

## Execution

Read `references/process.md` for detailed instructions, output formats,
and edge case handling.
```

For simple skills without `references/`, replace the Execution section with inline process steps.

**Rules:**
- Create all directories even if they will be empty initially
- Do NOT create placeholder files in empty directories (no .gitkeep, no empty files)
- Skill directories ARE pre-created with SKILL.md stubs — downstream `/plugin:build` fills in the content
- The `commands/` directory stays empty — command files are created during `/plugin:build`

---

### Step 3a — Generate plugin.json

Create `plugins/[plugin-name]/.claude-plugin/plugin.json` with only Claude Code schema fields:

```json
{
  "name": "[design.yml → name]",
  "version": "1.0.0",
  "description": "[design.yml → description]",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "cat state.yml 2>/dev/null | head -20 || true"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "echo '[plugin-name] File updated. If this completes a phase, update state.yml.'"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/session-recovery.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-wave-complete.sh"
          }
        ]
      }
    ]
  }
}
```

**Hook rules:**
- Replace `[plugin-name]` with the actual plugin name in the PostToolUse echo message prefix (e.g., `[seo-plugin]`)
- Use `${CLAUDE_PLUGIN_ROOT}` for script paths — Claude Code resolves this at runtime
- See Step 3c for the script contents

---

### Step 3b — Generate ecosystem.json

Create `plugins/[plugin-name]/.claude-plugin/ecosystem.json` with ecosystem metadata:

```json
{
  "commands": ["[design.yml → commands[].name, stripped of plugin prefix]"],
  "skills": ["[design.yml → skills[].name]"],
  "agents": ["[design.yml → agents if any, else empty array]"],
  "dependencies": ["task-planner"]
}
```

**Command name extraction:** Commands in design.yml use the format `plugin:command` (e.g., `seo:strategy`). In ecosystem.json, store only the command part without the plugin prefix (e.g., `strategy`). If the command name already excludes the prefix, use it as-is.

**Dependency rules:**
- `dependencies` ALWAYS includes `"task-planner"`
- If `design.yml → needs_brand` is `true`, add `"brand-guideline"` to dependencies
- If `design.yml → needs_brand` is `true`, also add: `"shared_skills": ["brand-context-loader"]`
- Do NOT add other plugins as dependencies — plugins communicate through shared data files, not direct dependencies

**Additional fields (if applicable):**
- If `needs_brand` is true: add `"brand_directory": "~/.claude/brands/"`
- Add `"data_directory"` using the storage path from `design.yml → output.yaml.storage_path`

---

### Step 3c — Generate Hook Scripts

Create two scripts in `plugins/[plugin-name]/scripts/`:

**`scripts/session-recovery.sh`:**

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "=== [Plugin Name] Session Recovery Check ==="

# Find state.yml — check plugin-specific data directory first, then current directory
STATE_FILE=""
# [Plugin-specific logic: for brand plugins, check ~/.claude/active-brand.yml;
#  for project-based plugins, check the plugin's active-project file;
#  fallback to state.yml in current directory]
if [ -f state.yml ]; then
  STATE_FILE="state.yml"
fi

if [ -n "$STATE_FILE" ]; then
  echo "State file: $STATE_FILE"
  echo "Current phase: $(grep '^current_phase:' "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"' || echo 'unknown')"
  echo "Status: $(grep '^status:' "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"' || echo 'unknown')"

  # Show last modified time (macOS and Linux compatible)
  if stat -f %Sm "$STATE_FILE" &>/dev/null; then
    echo "Last updated: $(stat -f '%Sm' "$STATE_FILE")"
  elif stat -c %y "$STATE_FILE" &>/dev/null; then
    echo "Last updated: $(stat -c '%y' "$STATE_FILE")"
  fi

  ERRORS=$(grep -c '  - timestamp:' "$STATE_FILE" 2>/dev/null || echo 0)
  echo "Logged errors: $ERRORS"

  COMPLETED=$(grep -B1 'status: completed' "$STATE_FILE" 2>/dev/null | grep 'name:' | awk '{print $3}' | tr -d '"' | tr '\n' ', ' || true)
  if [ -n "$COMPLETED" ]; then
    echo "Completed phases: $COMPLETED"
  fi

  # Check for findings.md
  FINDINGS_DIR=$(dirname "$STATE_FILE")
  if [ -f "$FINDINGS_DIR/findings.md" ]; then
    FINDINGS_LINES=$(wc -l < "$FINDINGS_DIR/findings.md" | tr -d ' ')
    echo "Findings file: $FINDINGS_DIR/findings.md ($FINDINGS_LINES lines)"
  fi

  echo "Git changes since last commit:"
  git diff --stat HEAD 2>/dev/null || echo "  (not a git repo)"
else
  echo "No state.yml found. Fresh start."
fi
```

**`scripts/check-wave-complete.sh`:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Find state.yml — same lookup logic as session-recovery.sh
STATE_FILE=""
if [ -f state.yml ]; then
  STATE_FILE="state.yml"
fi

if [ -z "$STATE_FILE" ]; then
  echo "No state.yml found. Nothing to verify."
  exit 0
fi

STATUS=$(grep '^status:' "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"')
SKILL=$(grep '^current_phase:' "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"')

if [ "$STATUS" != "completed" ] && [ "$STATUS" != "verified" ]; then
  echo "Current skill '$SKILL' is not complete (status: $STATUS)."
  echo "Please complete the current skill and run verification before stopping."
  exit 1
fi

echo "Current skill complete. Safe to stop."
exit 0
```

**Customization rules:**
- Replace `[Plugin Name]` in the echo header with the actual plugin name
- If the plugin uses a project-specific data directory (like `~/.claude/seo/[project-name]/`), add lookup logic to find state.yml via an active-project file (see `plugins/seo-plugin/scripts/session-recovery.sh` for an example)
- If the plugin uses brand data directory (`~/.claude/brands/[brand-name]/`), add lookup logic via `~/.claude/active-brand.yml` (see `plugins/brand-guideline/scripts/session-recovery.sh` for an example)
- Make both scripts executable: `chmod +x plugins/[plugin-name]/scripts/session-recovery.sh plugins/[plugin-name]/scripts/check-wave-complete.sh`

---

### Step 4 — Generate README.md

Create `plugins/[plugin-name]/README.md` with this structure:

```markdown
# [Plugin Name]

[design.yml → description]

## Overview

**What it does:** [description, expanded to 2-3 sentences using context from design.yml]
**Who it's for:** [persona.role] ([persona.technical_level]) — cares about [persona.cares_about]
**Dependencies:** [list from ecosystem.json dependencies]

## Prerequisites

- Claude Code with task-planner plugin installed
[If needs_brand:]
- Brand guidelines generated via `/brand:generate` (provides brand-reference.yml)
[For each tool from addendum Section c "Tools and Dependencies" marked as Required:]
- [Tool name] — [purpose] (`[install command]`)

## Commands

| Command | Purpose |
|---------|---------|
[For each command in design.yml:]
| `/[command.name]` | [command.purpose] |

## Output

This plugin produces:

1. **[output.yaml.name]** — Machine-readable YAML stored at `[output.yaml.storage_path]`
2. **[Plugin name] document** — Human-readable [output.document.format] document
[If output.assets is non-empty:]
3. **Assets** — [summary of asset types from output.assets]

## How It Works

[Brief explanation of the wave structure from design.yml.wave_plan:]
1. [Wave 1 description — which skills, sequential/parallel]
2. [Wave 2 description]
...

[If needs_brand:]
## Brand Data Usage

This plugin reads the following sections from `brand-reference.yml`:
[For each entry in brand_sections_needed:]
- **[skill-name]** uses: [list of sections]

## Installation

This plugin is part of the claude-plugins ecosystem. Ensure `task-planner` is installed first.
[If needs_brand:]
Also requires `brand-guideline` to be installed and at least one brand generated.

## Data Storage

[Describe where data is stored:]
- YAML output: `[output.yaml.storage_path][output.yaml.name]`
- Documents: `[output.yaml.storage_path]`
- State tracking: `[output.yaml.storage_path]state.yml`
```

**Rules for README:**
- Use actual values from design.yml — no placeholders in the final output
- Keep it concise — this is a reference, not a tutorial
- Every command gets a one-line description
- Prerequisites list only Required tools, not Optional ones

---

### Step 5 — Verify Brand Context Loader (if needs_brand)

If `design.yml → needs_brand` is `true`:

1. Check that `shared/brand-context-loader/SKILL.md` exists
2. If it exists: no action needed — the loader is already available
3. If it does NOT exist: STOP and report. The brand-context-loader should have been created during the brand-guideline build. This is a critical dependency.

If `needs_brand` is `false`: skip this step entirely.

---

### Step 6 — Document Storage Path Convention

Record the data storage convention for this plugin:

**If needs_brand is true:**
- Data directory: `~/.claude/brands/[brand-name]/` (shared with brand-guideline)
- Plugin-specific data: stored as sections within brand-reference.yml or as separate YAML files in the same directory
- State file: `~/.claude/brands/[brand-name]/state.yml`

**If needs_brand is false:**
- Data directory: derived from `design.yml → output.yaml.storage_path`
  - Pattern: `~/.claude/[domain]/[project-name]/`
  - Example: `~/.claude/seo/my-project/` or `~/.claude/sites/my-site/`
- The `[project-name]` is provided at runtime when the user runs the main command
- State file: `[storage_path]state.yml`

This information is already captured in ecosystem.json's `data_directory` field and in the README. No additional files are created — this step documents the convention for downstream skills.

---

### Step 7 — Update CLAUDE.md Progress Checklist

Read `CLAUDE.md`. Find the plugin's progress section (generated by the execution-guide-generator). If the checklist doesn't exist yet in CLAUDE.md, this step will be handled by the `/plugin:create` command instead.

If the checklist exists:
- Check off the scaffold step (typically Step 1 in the execution guide)
- Set "Next step" to the schema/templates step (typically Step 2)

---

## Checkpoint

```
type: file_validation
required_checks:
  - plugins/[plugin-name]/.claude-plugin/plugin.json exists and is valid JSON
  - plugin.json contains only Claude Code fields: name, version, description, hooks
  - plugin.json "name" matches design.yml "name"
  - plugins/[plugin-name]/.claude-plugin/ecosystem.json exists and is valid JSON
  - ecosystem.json contains: commands, skills, dependencies
  - ecosystem.json "dependencies" includes "task-planner"
  - If needs_brand is true: ecosystem.json "dependencies" includes "brand-guideline"
  - If needs_brand is true: ecosystem.json contains "shared_skills" with "brand-context-loader"
  - plugins/[plugin-name]/commands/ directory exists
  - plugins/[plugin-name]/skills/ directory exists with one subdirectory per skill from design.yml
  - Each skill directory contains a lean SKILL.md (≤80 lines) using the template format
  - Complex skills have a references/ subdirectory with a stub process.md
  - Simple/utility skills have SKILL.md only (no references/ directory)
  - plugins/[plugin-name]/resources/templates/ directory exists
  - plugins/[plugin-name]/resources/examples/ directory exists
  - plugins/[plugin-name]/scripts/ directory exists
  - plugins/[plugin-name]/scripts/session-recovery.sh exists and is executable
  - plugins/[plugin-name]/scripts/check-wave-complete.sh exists and is executable
  - plugin.json contains "hooks" with PreToolUse, PostToolUse, SessionStart, and Stop entries
  - plugins/[plugin-name]/README.md exists and is non-empty
  - README.md contains all required sections:
    Overview, Prerequisites, Commands, Output, How It Works, Installation, Data Storage
  - README.md lists every command from design.yml with its purpose
  - If needs_brand is true: README.md has "Brand Data Usage" section
  - No placeholder text remains in generated files
    (no "[plugin-name]", no "[from design.yml]", no "TODO")
on_fail: >
  Report which checks failed. For missing directories, create them.
  For missing fields in plugin.json, add them from design.yml.
  For placeholder text in README, replace with actual values.
  Re-run validation after fixes.
on_pass: >
  Update state.yml: mark plugin-scaffolder as completed.
  Report: "Plugin scaffolded. Ready for schema and template creation."
```

## Quality Rules

1. **design.yml is the source of truth.** Every value in plugin.json, ecosystem.json, and README.md comes from design.yml. Never invent names, descriptions, or dependencies.
2. **No placeholder text in output.** The final plugin.json and README.md must contain real values, not template variables like `[plugin-name]`.
3. **Blueprint compliance.** The directory structure must exactly match `plugin-blueprint.md` Section 2. No extra directories, no missing directories.
4. **Command names are stripped.** In plugin.json, commands use the short form (e.g., `"strategy"`) not the prefixed form (e.g., `"seo:strategy"`).
5. **Dependencies are minimal.** Only `task-planner` and optionally `brand-guideline`. Never add other plugins as dependencies.
6. **Empty directories stay empty.** No .gitkeep files, no placeholder READMEs inside empty directories. Git tracks them when files are added later.
7. **README is actionable.** A developer reading the README should understand what the plugin does, what it needs, and what commands are available — without reading any other file.
8. **Upstream validation is strict.** If design.yml is not approved or upstream artifacts are missing, STOP. Never scaffold from incomplete designs.
