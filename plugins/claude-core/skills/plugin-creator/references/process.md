# Plugin Creator — Full Reference

## Plugin anatomy

Every plugin lives under `plugins/<plugin-name>/` with this structure:

```
plugins/<plugin-name>/
  .claude-plugin/
    plugin.json          # Required — manifest with metadata and hooks
    ecosystem.json       # Required — component registry
  commands/              # Slash command .md files
  skills/                # Skill directories (each with SKILL.md)
  agents/                # Agent .md files
  scripts/               # Hook scripts and utility scripts
  resources/             # Templates, schemas, static assets
  README.md              # Optional — plugin documentation
```

The `.claude-plugin/` directory is the only hard requirement. Everything else depends
on what the plugin provides.

## plugin.json manifest

### Field reference

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `name` | string | Yes | Kebab-case, matches directory name |
| `version` | string | Yes | Semver format (`"1.0.0"`) |
| `description` | string | Yes | One-line summary of what the plugin does |
| `author` | object | Yes | `{ "name": "string" }`, optionally `"email"` |
| `repository` | string | No | Git URL |
| `license` | string | No | SPDX identifier (e.g., `"MIT"`) |
| `keywords` | array | No | Array of strings for discovery |
| `hooks` | object | No | Event-keyed hook definitions (see below) |

### Critical rules

- **Do NOT include** `agents`, `skills`, or `slashCommands` fields — components are
  discovered from the filesystem, not declared in plugin.json.
- **Name must match** the directory name exactly. `plugins/my-tool/` requires
  `"name": "my-tool"`.
- **Version is a string**, not a number. Always `"1.0.0"`, never `1.0`.

### Example

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Brief description of what this plugin does.",
  "author": { "name": "mvn" },
  "repository": "https://github.com/mvn/claude-local-workspace",
  "license": "MIT",
  "keywords": ["category", "purpose"],
  "hooks": {}
}
```

## ecosystem.json

The ecosystem file is a documentation-and-registry hybrid. It lists all components
the plugin provides so humans and tooling can enumerate them without crawling the
filesystem.

### Format

```json
{
  "commands": ["command-one", "command-two"],
  "skills": ["skill-one", "skill-two"],
  "agents": [],
  "dependencies": []
}
```

### Rules

- **Every component must appear** in the relevant array. Unlisted components are
  invisible to audits and tooling.
- **commands**: list the command name (not the filename). Namespaced commands use
  the colon format: `"plugin:command"`.
- **skills**: list the skill directory name (matching the SKILL.md's `name` field).
- **agents**: list the agent filename without extension.
- **dependencies**: list other plugins this one requires (e.g., `["claude-core"]`).
- Skills can be a flat array or grouped by category (object with arrays). Flat is
  preferred for small plugins; grouped for plugins with 10+ skills.

## Component types

Each component type has a dedicated creator skill with full specifications.

| Type | Directory | File pattern | Creator skill | Invocation |
|------|-----------|-------------|---------------|------------|
| **Command** | `commands/` | `name.md` | command-creator | `/plugin:name` |
| **Skill** | `skills/name/` | `SKILL.md` | skill-creator | Auto-loaded by description match |
| **Agent** | `agents/` | `name.md` | agent-creator | Auto-triggered by intent match |
| **Hook** | `scripts/` | `name.sh` | hook-creator | Event-driven via plugin.json |

Do not duplicate component-level guidance here. Load the relevant creator skill for
frontmatter fields, content structure, testing protocols, and checklists specific
to that component type.

## Plugin creation workflow

### Step 1: Detect context

Check what already exists:
- Does `plugins/<name>/` already exist? (Adding to existing vs. creating new)
- What plugins are in the marketplace? (Avoid name collisions)
- What does the plugin need to do? (Determines which component types to scaffold)

### Step 2: Create directory structure

```bash
mkdir -p plugins/<name>/.claude-plugin
mkdir -p plugins/<name>/commands
mkdir -p plugins/<name>/skills
mkdir -p plugins/<name>/agents
mkdir -p plugins/<name>/scripts
mkdir -p plugins/<name>/resources
```

Only create directories for component types the plugin will actually use.

### Step 3: Create plugin.json

Write the manifest with all required fields. Start with an empty hooks object
and add hooks as scripts are created.

### Step 4: Create ecosystem.json

Start with empty arrays:
```json
{
  "commands": [],
  "skills": [],
  "agents": [],
  "dependencies": []
}
```

Populate arrays as components are added.

### Step 5: Create components

Use the relevant creator skill for each component type:
- Commands: load command-creator
- Skills: load skill-creator
- Agents: load agent-creator
- Hooks: load hook-creator

### Step 6: Register in marketplace

Add entry to `plugins/.claude-plugin/marketplace.json` (see Marketplace section).

### Step 7: Clear plugin cache

```bash
rm -rf ~/.claude/plugins/cache/local-workspace/
```

Always clear cache after any plugin changes. Stale cache causes hooks and skills
to use old versions silently.

### Step 8: Verify

Restart Claude Code and confirm:
- Plugin appears in the system (no load errors)
- Commands show in `/help`
- Skills load when relevant topics arise
- Hooks fire on expected events

## Naming conventions

| Element | Convention | Examples |
|---------|-----------|----------|
| Plugin directory | kebab-case | `claude-core`, `my-plugin` |
| plugin.json `name` | kebab-case, matches directory | `"claude-core"` |
| Commands | verb-based kebab-case | `init`, `build`, `scan` |
| Skills | topic-based kebab-case | `brand-loader`, `hook-creator` |
| Agents | role-based kebab-case | `project-manager`, `qa-lead` |
| Hook scripts | descriptive kebab-case | `trace-light.sh`, `project-isolation-check.sh` |

Plugin names must be globally unique within the workspace. Check marketplace.json
before choosing a name.

## Marketplace registration

### Location

`plugins/.claude-plugin/marketplace.json` — this is the workspace-level registry,
not repo root.

### Format

```json
{
  "name": "local-workspace",
  "owner": { "name": "mvn" },
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./my-plugin",
      "description": "Same description as plugin.json"
    }
  ]
}
```

### Rules

- `name` must match plugin.json `name` exactly.
- `source` is relative to the `plugins/` directory — always `"./<dir-name>"`.
- `description` should match or closely mirror plugin.json `description`.
- Without a marketplace entry, the plugin is invisible to `/plugin` browse.

## ${CLAUDE_PLUGIN_ROOT}

This variable resolves to the plugin's root directory at runtime.

### Usage rules

- **Always use** `${CLAUDE_PLUGIN_ROOT}` for script paths in plugin.json commands.
- **Never hardcode** absolute paths like `/Users/mvn/Personal/...`.
- **Never use** relative paths like `scripts/my-hook.sh` — they break if cwd differs.

### Example in plugin.json

```json
{
  "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/my-hook.sh 2>/dev/null || true"
}
```

### In scripts

Use `$CLAUDE_PROJECT_DIR` (not `$CLAUDE_PLUGIN_ROOT`) for project-level paths:
```bash
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STATE_FILE="$PROJECT_DIR/.ai/state.yml"
```

## Plugin cache

### Location

```
~/.claude/plugins/cache/local-workspace/
```

### When to clear

Clear the cache after ANY of these changes:
- Creating or deleting a plugin
- Modifying plugin.json (hooks, metadata, version)
- Adding, removing, or renaming commands
- Adding, removing, or modifying skills (SKILL.md frontmatter or body)
- Adding, removing, or modifying agents
- Modifying hook scripts

### Why stale cache matters

Claude Code caches plugin metadata at startup. Without clearing:
- New hooks silently do not fire
- Modified skills load old versions
- New commands are invisible to `/help`
- Deleted components still appear active

### Clear command

```bash
rm -rf ~/.claude/plugins/cache/local-workspace/
```

Run this, then restart Claude Code.

## Hooks in plugin.json

Hooks are registered directly in plugin.json under the `hooks` key — not in a
separate `hooks.json` file. This is our convention; some Anthropic examples use
a separate file, but we keep everything in plugin.json.

### Structure

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolPattern",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/hook.sh 2>/dev/null || true",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### Key points

- `matcher` is optional — omit to match all tools/events.
- Hooks in the same group run in parallel — design for independence.
- Use `2>/dev/null || true` for advisory hooks (never block on failure).
- Use `2>/dev/null` (without `|| true`) for hooks that signal via exit codes.
- Always set `timeout` explicitly.
- For full hook specification (events, exit codes, input/output schemas), load
  hook-creator.

## YAML frontmatter requirement

All `.md` files consumed by Claude Code (commands, skills, agents) MUST have YAML
frontmatter with at minimum a `description` field. Without frontmatter, the file
will not load.

```markdown
---
description: What this component does
---

# Content here
```

Skill SKILL.md files have additional required frontmatter fields — see skill-creator
for the complete field table.

## Cross-references

| Task | Load this skill |
|------|----------------|
| Creating or fixing a command | command-creator |
| Creating or fixing a skill | skill-creator |
| Creating or fixing an agent | agent-creator |
| Creating or fixing a hook | hook-creator |
| Plugin structure, manifest, or registration | (this skill — plugin-creator) |

When building a plugin from scratch, start with plugin-creator for scaffolding and
manifest, then load the appropriate creator skill for each component.

## Testing protocol

### 1. Structural validation

Verify all required files exist:
```bash
ls plugins/<name>/.claude-plugin/plugin.json
ls plugins/<name>/.claude-plugin/ecosystem.json
```

### 2. JSON validation

```bash
python3 -m json.tool plugins/<name>/.claude-plugin/plugin.json
python3 -m json.tool plugins/<name>/.claude-plugin/ecosystem.json
```

### 3. Name consistency

Confirm `name` in plugin.json matches the directory name and the marketplace entry.

### 4. Component audit

Cross-check ecosystem.json arrays against actual files on disk:
```bash
# Commands
ls plugins/<name>/commands/*.md 2>/dev/null

# Skills
ls plugins/<name>/skills/*/SKILL.md 2>/dev/null

# Agents
ls plugins/<name>/agents/*.md 2>/dev/null
```

Every file found should have a corresponding ecosystem.json entry.

### 5. Hook scripts

For each script referenced in plugin.json hooks:
```bash
bash -n plugins/<name>/scripts/<hook>.sh   # Syntax check
```

### 6. Cache clear and restart

```bash
rm -rf ~/.claude/plugins/cache/local-workspace/
```

Restart Claude Code, then verify:
- No plugin load errors in output
- Commands appear in `/help`
- A test invocation of each command works

### 7. Marketplace visibility

After restart, confirm the plugin appears in `/plugin` browse.

## Common mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| Including `agents`/`skills`/`slashCommands` in plugin.json | Confuses component discovery | Remove — components are filesystem-discovered |
| Version as number (`1.0` instead of `"1.0.0"`) | Invalid manifest | Use string in semver format |
| `name` mismatch between plugin.json and directory | Plugin fails to load | Match exactly (kebab-case) |
| Hardcoded paths in hook commands | Breaks on other machines | Use `${CLAUDE_PLUGIN_ROOT}` |
| Missing YAML frontmatter on .md files | Component not discovered | Add frontmatter with `description` |
| Not clearing plugin cache after changes | Old version loads silently | `rm -rf ~/.claude/plugins/cache/local-workspace/` |
| Missing marketplace.json entry | Plugin invisible to `/plugin` browse | Add entry to `plugins/.claude-plugin/marketplace.json` |
| Marketplace `source` as absolute path | Breaks portability | Use relative: `"./plugin-name"` |
| ecosystem.json missing components | Audit tools miss components | List every command, skill, agent |
| Hooks in separate hooks.json file | Hooks not recognized | Put hooks in plugin.json directly |
| Duplicate plugin names in marketplace | Unpredictable loading | Check marketplace.json before naming |
| No `timeout` on hook entries | Uses default (may be too long/short) | Set explicit timeout per hook |
| Using `"author": "name"` instead of object | Invalid field type | Use `{ "name": "..." }` |

## Checklist

Before committing any new or modified plugin:

- [ ] `plugin.json` has all required fields (name, version, description, author)
- [ ] `name` in plugin.json matches directory name exactly
- [ ] `version` is a string in semver format
- [ ] `author` is an object with `name` key
- [ ] No `agents`/`skills`/`slashCommands` fields in plugin.json
- [ ] `ecosystem.json` exists with commands, skills, agents, dependencies arrays
- [ ] Every component on disk is listed in ecosystem.json
- [ ] All `.md` files have YAML frontmatter with `description`
- [ ] Hook commands use `${CLAUDE_PLUGIN_ROOT}` (no hardcoded paths)
- [ ] Hook entries have explicit `timeout`
- [ ] Marketplace entry exists in `plugins/.claude-plugin/marketplace.json`
- [ ] Marketplace `name` matches plugin.json `name`
- [ ] Marketplace `source` is relative (`"./plugin-name"`)
- [ ] Both JSON files pass `python3 -m json.tool` validation
- [ ] Hook scripts pass `bash -n` syntax check
- [ ] `hardening-sweep.sh` passes clean on all plugin components
- [ ] Plugin cache cleared: `rm -rf ~/.claude/plugins/cache/local-workspace/`
- [ ] Claude Code restarted and plugin loads without errors
- [ ] Commands visible in `/help`
