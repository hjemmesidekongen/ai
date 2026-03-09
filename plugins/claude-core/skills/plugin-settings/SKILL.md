---
name: plugin-settings
description: >
  Documents the .claude/plugin-name.local.md pattern for storing plugin-specific
  configuration with YAML frontmatter and markdown content. Use when asking about
  plugin settings, storing plugin configuration, making plugin behavior configurable,
  working with .local.md files, reading YAML frontmatter from hooks, setting up
  per-project plugin state, or toggling plugin features with enabled/disabled flags.
user_invocable: true
interactive: false
depends_on: []
triggers:
  - "plugin settings"
  - "local.md config"
  - "plugin configuration"
  - "toggle plugin feature"
  - "per-project plugin state"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "pattern_applied"
      verify: "Settings file uses .claude/plugin-name.local.md path convention"
      fail_action: "Rename to .claude/{plugin-name}.local.md"
    - name: "frontmatter_valid"
      verify: "YAML frontmatter between --- markers parses correctly"
      fail_action: "Fix YAML syntax in frontmatter block"
    - name: "quick_exit_pattern"
      verify: "Hook checks file existence before parsing"
      fail_action: "Add file existence check as first line of hook"
model_tier: junior
_source:
  origin: "claude-core"
  inspired_by: "anthropic/plugin-dev/skills/plugin-settings"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Adapted from Anthropic's plugin-dev reference. Condensed to 80-line format."
---

# Plugin Settings

Per-project config via `.claude/{plugin-name}.local.md`. YAML frontmatter = structured
config. Markdown body = prompts or context. Add `.claude/*.local.md` to `.gitignore`.
Changes require Claude Code restart.

## File Template

```markdown
---
enabled: true
mode: standard
max_retries: 3
---

# Plugin Configuration

Optional body — prompts, task descriptions, or notes.
```

## Core Patterns

| Pattern | Use case |
|---|---|
| Quick-exit hook | `[[ ! -f "$FILE" ]] && exit 0` before any parsing |
| Temporarily-active hooks | `enabled: true/false` toggles without editing hooks.json |
| Agent state management | Frontmatter = metadata, body = task prompt |

## Reading from Hooks

```bash
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$FILE")
VALUE=$(echo "$FRONTMATTER" | grep '^field:' | sed 's/field: *//' | sed 's/^"\(.*\)"$/\1/')
BODY=$(awk '/^---$/{i++; next} i>=2' "$FILE")
```

Sanitize input before writing (`sed 's/"/\\"/g'`). Validate paths (reject `..`). No secrets — plaintext. Full detail: [references/process.md](references/process.md)
