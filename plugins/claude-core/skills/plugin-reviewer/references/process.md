# Plugin Reviewer — Full Reference

## Review philosophy

Reviewers are read-only. Never modify the files under review. Produce a YAML verdict
documenting findings and recommendations. Enhancers (future) act on verdicts — reviewers
only judge.

## Two-stage review flow

```
Stage 1: Spec Compliance     →  All checks must pass  →  Stage 2: Quality Review
         (mechanical)                                           (judgment-based)
                                                                    ↓
                                                              YAML Verdict
```

If Stage 1 fails, stop and report. Do not proceed to Stage 2.

## Stage 1: Spec Compliance

Mechanical checks against the plugin-creator specification. Every check is binary
(pass/fail).

### Check 1: plugin.json required fields

| Field | Type | Validation |
|-------|------|------------|
| `name` | string | Kebab-case, matches directory name |
| `version` | string | Semver format (`"1.0.0"`, not `1.0`) |
| `description` | string | Non-empty |
| `author` | object | Must be `{ "name": "..." }`, not a plain string |

```bash
python3 -m json.tool plugins/<name>/.claude-plugin/plugin.json
```

### Check 2: plugin.json forbidden fields

These fields must NOT be present in plugin.json:
- `agents` — components are filesystem-discovered
- `skills` — components are filesystem-discovered
- `slashCommands` — components are filesystem-discovered

Their presence confuses component discovery and causes duplicate loading.

### Check 3: ecosystem.json valid

```bash
python3 -m json.tool plugins/<name>/.claude-plugin/ecosystem.json
```

Must have these top-level arrays (may be empty):
- `commands`
- `skills`
- `agents`
- `dependencies`

### Check 4: Component audit

Cross-check every file on disk against ecosystem.json entries:

```bash
# Commands on disk
ls plugins/<name>/commands/*.md 2>/dev/null | sed 's/.*\///' | sed 's/\.md$//'

# Skills on disk
ls plugins/<name>/skills/*/SKILL.md 2>/dev/null | sed 's|.*/skills/||' | sed 's|/SKILL.md||'

# Agents on disk
ls plugins/<name>/agents/*.md 2>/dev/null | sed 's/.*\///' | sed 's/\.md$//'
```

Every component on disk must have a corresponding ecosystem.json entry. Every
ecosystem.json entry must have a corresponding file on disk.

Flag:
- **Unregistered component**: file exists but not in ecosystem.json
- **Ghost entry**: ecosystem.json entry with no corresponding file

#### Component-level structural checks

For each component type found on disk, verify minimal structural validity:

**Commands** (`.md` files in `commands/`):
- File has YAML frontmatter (starts with `---`)
- Frontmatter contains `description` field (non-empty string)

**Agents** (`.md` files in `agents/`):
- File has YAML frontmatter
- Frontmatter contains `name` (3-50 chars, lowercase + hyphens), `description`, `model`, `color`

**Skills** (`SKILL.md` files in `skills/*/`):
- File has YAML frontmatter
- Frontmatter contains `name` and `description` (both non-empty)

These are structural sanity checks only — full content review is out of scope
for plugin-reviewer (use skill-reviewer, etc. for deep reviews).

### Check 5: Marketplace registration

Verify `plugins/.claude-plugin/marketplace.json` has an entry:
- `name` matches plugin.json `name` exactly
- `source` is relative (`"./<dir-name>"`)
- `description` present

Without marketplace entry, the plugin is invisible to `/plugin` browse.

### Check 6: Hook scripts exist

For each script referenced in plugin.json `hooks`:
- Extract the script path from the `command` field
- Verify the file exists on disk
- Run `bash -n <script>` to syntax-check

```bash
bash -n plugins/<name>/scripts/<hook>.sh
```

### Check 7: Version format

`version` must be a string in semver format:
- Valid: `"1.0.0"`, `"2.1.3"`, `"0.1.0"`
- Invalid: `1.0`, `"1.0"`, `"v1.0.0"`, `1`

### Check 8: Author format

`author` must be an object, not a string:
- Valid: `{ "name": "mvn" }`, `{ "name": "mvn", "email": "..." }`
- Invalid: `"mvn"`, `"mvn <email>"`

### Check 9: MCP configuration

Only applies if the plugin has `.mcp.json` at its root or `mcpServers` in plugin.json.
Skip this check if neither is present.

**JSON validity:**
```bash
python3 -m json.tool plugins/<name>/.mcp.json
```

**Server type validation:**

| Server type | Required fields | Check |
|-------------|----------------|-------|
| stdio (no `type` field) | `command` | `command` is a non-empty string |
| `sse` | `type`, `url` | `url` starts with `https://` |
| `http` | `type`, `url` | `url` starts with `https://` |
| `ws` | `type`, `url` | `url` starts with `wss://` |

**Portability:**
- All paths use `${CLAUDE_PLUGIN_ROOT}` — no hardcoded absolute paths (`/Users/`, `/home/`)
- Environment variables referenced via `${VAR}` — no inline secrets

**Tool naming:**
- If commands reference MCP tools, names follow `mcp__plugin_<name>_<server>__<tool>` pattern

Flag:
- **Invalid JSON**: `.mcp.json` or `mcpServers` block doesn't parse
- **Missing required field**: Server entry lacks `command` (stdio) or `url` (sse/http/ws)
- **Insecure URL**: URL uses `http://` or `ws://` instead of `https://`/`wss://`
- **Hardcoded path**: Absolute path without `${CLAUDE_PLUGIN_ROOT}`
- **Inline secret**: Literal token/key instead of `${VAR}` reference

### Stage 1 output

```yaml
spec_compliance:
  status: pass | fail
  checks:
    required_fields: { status: pass|fail, missing: [] }
    forbidden_fields: { status: pass|fail, present: [] }
    ecosystem_valid: { status: pass|fail, detail: "" }
    component_audit: { status: pass|fail, unregistered: [], ghosts: [], structural_issues: [] }
    marketplace: { status: pass|fail, detail: "" }
    hook_scripts: { status: pass|fail, missing: [], syntax_errors: [] }
    version_format: { status: pass|fail, detail: "" }
    author_format: { status: pass|fail, detail: "" }
    mcp_config: { status: pass|fail|skipped, issues: [] }
  failed_count: 0
```

## Stage 2: Quality Review

Judgment-based evaluation. Only runs after Stage 1 passes.

### Directory organization

| Check | What to look for |
|-------|-----------------|
| Clean structure | Components in expected directories (commands/, skills/, agents/, scripts/) |
| No stray files | Top-level files are intentional (README.md, CHANGELOG.md) |
| Consistent naming | All kebab-case, verb-based commands, topic-based skills |
| Logical grouping | Related components near each other |

### Portability

| Check | What to look for |
|-------|-----------------|
| `${CLAUDE_PLUGIN_ROOT}` | All plugin.json script paths use this variable |
| `${CLAUDE_PROJECT_DIR}` | All scripts use this for project-level paths |
| No hardcoded paths | No absolute paths (`/Users/...`, `/home/...`) |
| No machine-specific deps | No commands that only work on specific OS |
| Relative marketplace source | `"./<dir-name>"` not absolute path |

### Hook configuration quality

| Check | What to look for |
|-------|-----------------|
| Explicit timeouts | Every hook entry has `timeout` set |
| Error suppression | Advisory hooks have `2>/dev/null \|\| true` |
| Matchers appropriate | Matchers target correct tools/events (not too broad/narrow) |
| statusMessage | Hooks >2s have `statusMessage` for user feedback |
| Parallel safety | Hooks in same group don't conflict |

### Settings pattern

Plugins that need per-user or per-project configuration should follow the settings
pattern from plugin-settings:

#### Location
```
~/.claude/<plugin-name>.local.md
```

#### Format
```markdown
---
setting_one: value
setting_two: value
---

# Optional notes or overrides
```

#### Implementation in hooks

```bash
#!/usr/bin/env bash
set -euo pipefail

SETTINGS_FILE="${HOME}/.claude/$(basename "${CLAUDE_PLUGIN_ROOT}").local.md"

# Quick-exit if no settings file
[[ -f "$SETTINGS_FILE" ]] || exit 0

# Extract YAML frontmatter value
VALUE=$(sed -n '/^---$/,/^---$/p' "$SETTINGS_FILE" | grep 'setting_one:' | awk '{print $2}' | tr -d '"') || true
```

#### Validation checks

- Settings file location follows convention (`~/.claude/<plugin-name>.local.md`)
- YAML frontmatter is used for structured settings (not free-form text)
- Quick-exit pattern if settings file doesn't exist
- `.local.md` is in `.gitignore` (per-user, not committed)
- Fallback defaults when settings are missing

### Cache clearing documentation

Check if the plugin's README or documentation mentions:
- When to clear the plugin cache
- The cache clear command (`rm -rf ~/.claude/plugins/cache/local-workspace/`)
- That restart is required after clearing

### Auto-discovery compatibility

Verify the plugin works with Claude Code's component discovery:
- All `.md` component files have YAML frontmatter with `description`
- Skill SKILL.md files have all required frontmatter fields
- Agent `.md` files have frontmatter with at minimum `description`
- Command `.md` files have frontmatter with `description`

Without frontmatter, components are silently skipped during discovery.

### Security

| Check | What to look for |
|-------|-----------------|
| No hardcoded credentials | Scan scripts and configs for API keys, tokens, passwords (literal strings that look like secrets) |
| HTTPS/WSS only | All MCP server URLs use secure protocols — no `http://` or `ws://` |
| No secrets in committed files | `.env` and credential files are in `.gitignore`, not tracked |
| Env var references | Tokens passed via `${VAR}`, never as inline literal values |
| `allowedEnvVars` scoping | HTTP hooks limit environment variable access to only needed vars |
| No secrets in examples | Example configs and template files use `${VAR}` placeholders, not real tokens |

### Stage 2 output

```yaml
quality_review:
  status: pass | pass_with_notes | fail
  findings:
    - area: "organization|portability|hooks|settings|cache|discovery"
      severity: info | warning | critical
      detail: "Description of finding"
      fix_required: true | false
  summary: "Brief overall assessment"
```

## Portability checklist

Run through these checks for any plugin intended to work across machines:

- [ ] All plugin.json `command` values use `${CLAUDE_PLUGIN_ROOT}`
- [ ] All script paths use `$CLAUDE_PROJECT_DIR` for project files
- [ ] No absolute paths anywhere in scripts or configuration
- [ ] No machine-specific commands (check `uname` if OS-dependent)
- [ ] Marketplace `source` is relative (`"./<dir-name>"`)
- [ ] Settings use `~/.claude/<plugin-name>.local.md` convention
- [ ] `.local.md` files are in `.gitignore`
- [ ] No hardcoded usernames or home directories
- [ ] `bash -n` passes on all scripts (syntax-valid across bash versions)

## Verdict format

```yaml
plugin_review:
  plugin: "<plugin-name>"
  reviewed_at: "<timestamp>"
  status: pass | pass_with_notes | fail
  spec_compliance:
    status: pass | fail
    checks: { ... }
    failed_count: 0
  quality_review:
    status: pass | pass_with_notes | fail
    findings: []
    summary: ""
  recommendations:
    - severity: critical | warning | info
      area: ""
      detail: ""
      file: ""
      effort: trivial | moderate | significant
  portability_score: "high|medium|low"
```

## Common findings

| Finding | Severity | Category | Fix |
|---------|----------|----------|-----|
| Missing plugin.json required field | critical | spec | Add the field per plugin-creator spec |
| `agents`/`skills`/`slashCommands` in plugin.json | critical | spec | Remove — filesystem discovery only |
| Version as number (not string) | critical | spec | Change to string `"1.0.0"` |
| Author as string (not object) | critical | spec | Change to `{ "name": "..." }` |
| Unregistered component (on disk, not in ecosystem.json) | critical | spec | Add to ecosystem.json |
| Ghost ecosystem entry (in registry, not on disk) | critical | spec | Remove from ecosystem.json or create file |
| Missing marketplace entry | warning | spec | Add to marketplace.json |
| Hook script fails `bash -n` | critical | spec | Fix syntax errors |
| Missing hook timeout | warning | hooks | Set explicit timeout |
| Hardcoded absolute path | critical | portability | Use `${CLAUDE_PLUGIN_ROOT}` or `$CLAUDE_PROJECT_DIR` |
| Missing `2>/dev/null \|\| true` on advisory hook | warning | hooks | Add error suppression |
| No frontmatter on component .md | critical | discovery | Add YAML frontmatter with description |
| Settings not in `~/.claude/` | info | settings | Follow settings pattern convention |
| No cache clearing docs | info | docs | Document cache clear process |
| Stray files in plugin root | info | organization | Move or remove |
| Marketplace source as absolute path | warning | portability | Change to relative `"./<name>"` |
| No .gitignore for .local.md files | info | settings | Add to .gitignore |
| MCP config invalid JSON | critical | mcp | Fix JSON syntax in `.mcp.json` or `mcpServers` |
| MCP server missing required field | critical | mcp | Add `command` (stdio) or `url` (sse/http/ws) |
| MCP URL uses HTTP instead of HTTPS | critical | security | Switch to `https://` or `wss://` |
| Hardcoded credentials in config/scripts | critical | security | Replace with `${VAR}` environment variable reference |
| Secrets in example/template files | warning | security | Replace real values with `${VAR}` placeholders |

## Review checklist

Quick-reference for manual reviews:

- [ ] plugin.json has name, version, description, author (all required)
- [ ] `name` matches directory name
- [ ] `version` is semver string (not number)
- [ ] `author` is object (not string)
- [ ] No `agents`/`skills`/`slashCommands` in plugin.json
- [ ] ecosystem.json has commands, skills, agents, dependencies arrays
- [ ] Every component on disk is in ecosystem.json
- [ ] Every ecosystem.json entry has a file on disk
- [ ] Marketplace entry exists with matching name
- [ ] Marketplace `source` is relative
- [ ] All hook scripts exist and pass `bash -n`
- [ ] All hook entries have explicit `timeout`
- [ ] Advisory hooks have `2>/dev/null || true`
- [ ] All paths use `${CLAUDE_PLUGIN_ROOT}` or `$CLAUDE_PROJECT_DIR`
- [ ] No hardcoded absolute paths
- [ ] All `.md` component files have YAML frontmatter
- [ ] Settings follow `~/.claude/<plugin-name>.local.md` pattern
- [ ] `.local.md` in `.gitignore`
- [ ] Cache clearing documented
- [ ] MCP config (if present) is valid JSON
- [ ] MCP servers have correct required fields per type
- [ ] MCP URLs use HTTPS/WSS (not HTTP/WS)
- [ ] No hardcoded credentials in scripts, configs, or examples
- [ ] Both JSON files pass `python3 -m json.tool`
