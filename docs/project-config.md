# project.yml schema reference

`project.yml` is the unified configuration file for the hjemmesidekongen plugin ecosystem. It lives at the project root and replaces the previous three-system setup (rules.yml, .local.md, profile presets) with a single file.

It tells the plugin system three things: which profile to use, basic project metadata, and any per-project overrides.

## Field reference

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `profile` | string | _(required)_ | Preset to load. `"work"`, `"personal"`, or omit to define config inline. |
| `project_name` | string | `null` | Human-readable project name. |
| `git.branch_prefix` | string | `"feature/"` | Prefix for feature branches. |
| `git.commit_style` | string | `"imperative"` | Commit message style. `"imperative"` or `"conventional"`. |
| `qa.format` | string | `"markdown"` | QA handover format. `"jira-comment"`, `"github-pr"`, or `"markdown"`. |
| `qa.require_screenshots` | boolean | `false` | Whether QA handover requires screenshots. |
| `dev.test` | string | `null` | Test command. |
| `dev.build` | string | `null` | Build command. |
| `dev.lint` | string | `null` | Lint command. |
| `mcp_servers` | string[] | `[]` | MCP server names expected for this project. Metadata only — does not configure connections. |
| `overrides.hooks.tdd_gate` | string | _(from profile)_ | `"enabled"` or `"disabled"`. |
| `overrides.hooks.tracing` | string | _(from profile)_ | `"full"`, `"light"`, or `"disabled"`. |
| `overrides.hooks.doc_checkpoint` | string | _(from profile)_ | `"enabled"` or `"disabled"`. |
| `overrides.hooks.verification` | string | _(from profile)_ | `"strict"` or `"light"`. |
| `overrides.qa.*` | — | — | Overrides for `qa.format` and `qa.require_screenshots`. |
| `overrides.dev.*` | — | — | Overrides for `dev.test`, `dev.build`, `dev.lint`. |

## Resolution order

Configuration is compiled in four steps, each layer overriding the previous:

```
1. Load profile preset (work.yml or personal.yml)     → base flags
2. Apply overrides from project.yml                    → per-project customization
3. Force safety flags to enabled                       → scope_guard, push_protection always on
4. Compile to .ai/context/kronen-profile-cache         → flat KEY=VALUE for hook consumption
```

When `project.yml` is absent, all hooks default to enabled. This is the secure default and matches the behavior of having no configuration at all.

## Security

### Dev command validation

All values under `dev` (`test`, `build`, `lint`) are validated against:

```
/^[a-zA-Z0-9_./ -]+$/
```

Shell metacharacters (`|`, `;`, `&`, `$`, backticks, etc.) are rejected. This prevents command injection through the config file — dev commands are executed by hooks and must not allow arbitrary shell expansion.

### Safety hook non-overridability

`scope_guard` and `push_protection` are safety hooks. They cannot be disabled through `overrides.hooks` or any other mechanism. Any attempt to override them is silently ignored with a warning logged to the hook trace.

This is enforced at the resolution step (step 3 above) — safety flags are forced to `enabled` after all overrides are applied.

## Examples

### Work project with Jira integration

```yaml
# Which preset to load — "work" enables stricter hooks and Jira-oriented defaults
profile: work

# Human-readable name, used in QA handover docs and PR titles
project_name: client-webapp

git:
  branch_prefix: feature/       # prepended to branch names by task-start
  commit_style: imperative      # "fix the bug" not "fix: the bug"

qa:
  format: jira-comment          # QA handover writes directly to Jira
  require_screenshots: true     # handover gate blocks without screenshots

dev:
  test: pnpm test               # run by tdd-gate hook before commits
  build: pnpm build             # run by verification-gate
  lint: pnpm lint               # run by verification-gate

# MCP servers this project expects — metadata only, does not configure connections
mcp_servers:
  - jira
  - confluence
  - bitbucket

overrides:
  hooks:
    tdd_gate: disabled          # this project has no test suite yet
```

### Personal project with minimal config

```yaml
# Personal profile uses lighter defaults — fewer gates, less ceremony
profile: personal

project_name: side-project

git:
  commit_style: conventional    # "feat: add thing" style

dev:
  test: npm test                # only command needed — no build or lint step

overrides:
  hooks:
    tracing: full               # opt into full tracing despite personal profile default
```
