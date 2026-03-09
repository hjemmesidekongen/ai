# Command Creator — Full Reference

## What commands are

Commands are Markdown files containing instructions that Claude executes when a user
invokes a slash command. Commands are prompts FOR Claude — they tell Claude what to do.
They are not messages displayed to users.

## Command locations

| Scope | Directory | Prefix | Discovery |
|-------|-----------|--------|-----------|
| **Project** | `.claude/commands/` | none | Auto-discovered for all project users |
| **Personal** | `~/.claude/commands/` | none | Auto-discovered for current user only |
| **Plugin** | `plugins/<name>/commands/` | `plugin-name:` | Auto-discovered from plugin `commands/` dir |

- File extension: `.md` (required)
- File name becomes the command name: `lint.md` = `/lint`
- Subdirectories create namespaces: `dev/lint.md` = `/dev:lint`

## File format

Every command is a Markdown file with an optional YAML frontmatter block:

```markdown
---
description: Run lint checks on staged files
allowed-tools: Bash, Read, Glob
argument-hint: "[file-pattern]"
---

Check the following files for lint errors and report results.

$ARGUMENTS
```

## Frontmatter fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `description` | string | — | Short description shown in `/help`. Keep under 60 characters. |
| `allowed-tools` | string (CSV) | all tools | Comma-separated tool names Claude can use during execution |
| `model` | string | — | Model override for this command (e.g., `claude-sonnet-4-20250514`) |
| `argument-hint` | string | — | Hint shown after command name in `/help` (e.g., `"<file> [options]"`) |
| `disable-model-invocation` | boolean | `false` | If `true`, run as pure template expansion — no LLM call |

All fields are optional. A command with no frontmatter is valid.

## Dynamic arguments

### $ARGUMENTS

Captures everything the user types after the command name:

```markdown
---
description: Search codebase for a pattern
---

Search the codebase for the following pattern and summarize findings:

$ARGUMENTS
```

Invocation: `/search error handling in auth module`
Claude sees: `Search the codebase for the following pattern and summarize findings:\n\nerror handling in auth module`

### Positional arguments ($1, $2, $3...)

Split user input by spaces for structured commands:

```markdown
---
description: Compare two branches
argument-hint: "<base-branch> <compare-branch>"
---

Compare branch $2 against branch $1. Show:
- Files changed
- Key differences
- Potential conflicts
```

Invocation: `/compare main feature/auth`
Result: `$1` = `main`, `$2` = `feature/auth`

### Combined usage

Use `$ARGUMENTS` alongside positional args when needed:

```markdown
---
description: Create a component
argument-hint: "<component-name> [options]"
---

Create a new React component named $1.

Additional requirements:
$ARGUMENTS
```

### Argument edge cases

- Missing positional args resolve to empty string — handle gracefully in prompt text
- `$ARGUMENTS` is empty if user provides no input — design commands to work without args when possible
- Quoted strings are NOT treated as single arguments — `"two words"` splits into `$1=two` and `$2=words`

## File references

The `@` prefix injects file contents into the command prompt. Claude uses the Read tool
to load the referenced file at invocation time.

### Static file reference

```markdown
---
description: Review against coding standards
allowed-tools: Read, Grep
---

Review the current file against our coding standards.

Standards:
@.eslintrc.json
@docs/code-standards.md
```

### Dynamic file reference with arguments

```markdown
---
description: Review a specific file
argument-hint: "<file-path>"
---

Review this file for issues:
@$1
```

Invocation: `/review src/auth/login.ts`
Claude reads `src/auth/login.ts` and includes its contents.

### Multiple file references

```markdown
Review these configuration files for consistency:
@package.json
@tsconfig.json
@.eslintrc.json
```

### File reference rules

- Path is relative to project root
- File must exist at invocation time (Read tool will error otherwise)
- Each `@` reference becomes a separate Read tool call
- `@$1`, `@$2` etc. use positional argument values as file paths
- No glob support — each file must be referenced explicitly

## Bash execution

Wrap shell commands in backticks with a `!` prefix to inject dynamic system context:

### Basic usage

```markdown
---
description: Summarize recent changes
allowed-tools: Bash
---

Here are the recent git changes:
`! git log --oneline -10`

Summarize what changed and highlight anything risky.
```

### Combining with allowed-tools

The `allowed-tools` field controls what Claude can use DURING execution, not what the
command template itself runs. Bash in backtick-! blocks runs during template expansion
before Claude processes the prompt.

```markdown
---
description: Check deployment status
allowed-tools: Read, Bash
---

Current branch: `! git branch --show-current`
Last deploy: `! cat .deploy-timestamp 2>/dev/null || echo "never"`

Analyze the deployment status and recommend next steps.
```

### Practical examples

**Inject environment context:**
```markdown
Node version: `! node --version`
Current directory: `! pwd`
Disk usage: `! df -h . | tail -1`
```

**Inject project state:**
```markdown
Active project: `! grep 'active:' .ai/agency.yml | awk '{print $2}'`
Open TODOs: `! grep -r 'TODO' src/ --count 2>/dev/null || echo "0"`
```

### Bash execution rules

- Commands run in the project root directory
- Stdout is injected into the prompt where the backtick block appears
- Stderr is suppressed — add `2>/dev/null` for commands that may fail
- Failed commands inject empty string — always handle missing output gracefully
- Keep commands fast — they run synchronously during template expansion
- No interactive commands (no `read`, no `vim`, no prompts)

## Command organization

### Flat structure (up to ~15 commands)

```
.claude/commands/
  lint.md
  test.md
  review.md
  deploy.md
  status.md
```

### Namespaced structure (15+ commands)

```
.claude/commands/
  dev/
    lint.md        → /dev:lint
    test.md        → /dev:test
    scaffold.md    → /dev:scaffold
  ops/
    deploy.md      → /ops:deploy
    status.md      → /ops:status
    rollback.md    → /ops:rollback
  docs/
    generate.md    → /docs:generate
    review.md      → /docs:review
```

### Naming conventions

- Use **verb-noun** format: `create-component`, `run-tests`, `check-deps`
- Use hyphens, not underscores or camelCase
- Keep names short but descriptive: `lint` over `run-eslint-on-all-files`
- Avoid generic names: `do`, `run`, `go`, `execute`

## Plugin-specific features

### ${CLAUDE_PLUGIN_ROOT}

In plugin commands, reference plugin-local files using `${CLAUDE_PLUGIN_ROOT}`:

```markdown
---
description: Initialize project with plugin defaults
allowed-tools: Bash, Read, Write
---

Read the template from the plugin:
@${CLAUDE_PLUGIN_ROOT}/resources/templates/project-state.yml

Use it to initialize a new project state file.
```

This variable resolves to the plugin's root directory at runtime, making commands
portable across installations.

### Auto-discovery

Plugin commands are auto-discovered from the `commands/` directory within the plugin.
No explicit registration in plugin.json is needed — just place `.md` files in the
`commands/` directory.

### ecosystem.json registration

While auto-discovery handles runtime, always register commands in `ecosystem.json`
for documentation and tooling:

```json
{
  "commands": [
    "init",
    "status",
    "dev/lint",
    "dev/test"
  ],
  "skills": [...],
  "agents": [...]
}
```

The command name in ecosystem.json matches the file path relative to `commands/`,
without the `.md` extension.

### Plugin cache

After creating or modifying any plugin command, clear the cache:
```bash
rm -rf ~/.claude/plugins/cache/local-workspace/
```

Then restart Claude Code. Stale cache causes commands to use old versions or remain
invisible.

## Best practices

| Practice | Detail |
|----------|--------|
| **Single responsibility** | One command = one task. Split multi-step workflows into separate commands. |
| **Description under 60 chars** | Keeps `/help` output readable. |
| **Scope allowed-tools** | List only what the command needs. Reduces accidental side effects. |
| **Explicit argument-hint** | Shows users what to provide. Use `<required>` and `[optional]` syntax. |
| **Graceful empty args** | Design commands to produce useful output even without arguments. |
| **Instructions, not output** | Write what Claude should DO, not what it should SAY. |
| **Imperative mood** | "Analyze the file" not "You should analyze the file". |
| **Avoid hardcoded paths** | Use `$ARGUMENTS`, `@$1`, `${CLAUDE_PLUGIN_ROOT}` for portability. |

## Testing protocol

Before marking any command complete, run this sequence:

### 1. Syntax check

Verify frontmatter is valid YAML:
```bash
head -20 commands/my-command.md  # Inspect frontmatter block
```

Confirm the `---` delimiters are present and properly closed.

### 2. Visibility check

```bash
# Start Claude Code and run:
/help
# Verify command appears with correct description
```

If the command does not appear:
- Check file extension is `.md`
- Check file is in the correct directory
- Check frontmatter syntax (unclosed quotes, bad YAML)
- Clear plugin cache if plugin-bundled

### 3. Argument resolution

```bash
# Invoke with test arguments:
/my-command test-arg-1 test-arg-2
# Verify $1, $2, $ARGUMENTS resolve correctly in Claude's behavior
```

### 4. File reference verification

If the command uses `@` references:
- Verify referenced files exist
- Invoke and confirm Claude reads the correct files
- Test with `@$1` using a valid file path as argument

### 5. Bash execution verification

If the command uses `` `! ...` `` blocks:
- Run the shell command manually to confirm output
- Invoke the command and verify injected context is correct
- Test with commands that might fail (ensure graceful handling)

### 6. Edge cases

- Invoke with no arguments (should not crash or produce garbage)
- Invoke with extra arguments (should handle gracefully)
- Test file references to non-existent files (should produce clear error)

## Common mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| Writing output text instead of instructions | Claude echoes it verbatim instead of acting | Rewrite as instructions: "Analyze X" not "Here is the analysis of X" |
| Missing `.md` extension | Command is invisible | Rename to `.md` |
| Unclosed frontmatter (`---` missing) | Entire file treated as prompt, no metadata | Add closing `---` |
| `$ARGUMENTS` in frontmatter | Variable not expanded in YAML | Only use `$ARGUMENTS` in the Markdown body |
| Hardcoded absolute paths | Breaks on other machines | Use relative paths, `@$1`, or `${CLAUDE_PLUGIN_ROOT}` |
| `allowed-tools` with wrong names | Tools silently unavailable | Check exact tool names: `Bash`, `Read`, `Write`, `Edit`, `Glob`, `Grep` |
| Forgetting ecosystem.json registration | Command works but is undocumented | Add entry to ecosystem.json after creating |
| Not clearing plugin cache | Old command version runs | `rm -rf ~/.claude/plugins/cache/local-workspace/` |
| Using `@` with glob patterns | Read tool does not support globs | List each file explicitly |
| Interactive bash in `` `! ...` `` | Template expansion hangs | Only use non-interactive commands |

## Troubleshooting

### Command invisible in /help

1. Check file is in correct directory (`.claude/commands/`, `~/.claude/commands/`, or `plugins/<name>/commands/`)
2. Check file extension is `.md`
3. Check frontmatter syntax — run `python3 -c "import yaml; yaml.safe_load(open('command.md'))"` (strip body first)
4. Clear plugin cache: `rm -rf ~/.claude/plugins/cache/local-workspace/`
5. Restart Claude Code

### Arguments not resolving

1. Confirm using `$ARGUMENTS` (not `$arguments` or `${ARGUMENTS}`)
2. Confirm positional args use `$1`, `$2` etc. (not `$arg1`)
3. Check that arguments are in the Markdown body, not frontmatter
4. Test with simple single-word arguments first

### Bash execution fails

1. Run the command manually in terminal to verify output
2. Add `2>/dev/null` to suppress stderr from failing commands
3. Check for interactive commands that expect stdin
4. Verify the command is available in the shell environment

### File references not loading

1. Verify the file exists at the referenced path
2. Paths are relative to project root, not the command file location
3. Check for typos in file names
4. `@$1` requires the user to provide the file path as the first argument

## Checklist

Before committing any command:

- [ ] File has `.md` extension
- [ ] File is in the correct directory for its scope
- [ ] Frontmatter has opening and closing `---` delimiters
- [ ] `description` is under 60 characters
- [ ] `allowed-tools` lists only needed tools (or omitted for all)
- [ ] `argument-hint` uses `<required>` / `[optional]` syntax
- [ ] `$ARGUMENTS` / `$1` / `$2` are in Markdown body, not frontmatter
- [ ] `@` file references point to existing files
- [ ] Bash `` `! ...` `` blocks are non-interactive and handle failure
- [ ] Command works with no arguments (graceful behavior)
- [ ] Command works with expected arguments
- [ ] Command appears in `/help` with correct description
- [ ] COMMAND.md has `description` field in frontmatter
- [ ] Registered in ecosystem.json if plugin-bundled
- [ ] Plugin cache cleared after changes
