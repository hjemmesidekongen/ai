---
name: project-profile-loader
description: >
  Load project-level configuration from rules.yml (project root or .ai/rules.yml).
  Provides project name, context (work/personal), git conventions, QA format,
  dev commands, and MCP server list. Determines which completion gate checks
  are relevant for the active project. Loaded at session start or task switch.
user_invocable: true
interactive: false
model_tier: junior
depends_on: []
triggers:
  - "load profile"
  - "project profile"
  - "load rules"
reads:
  - "rules.yml"
  - ".ai/rules.yml"
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "profile_loaded"
      verify: "Profile object contains project name and context"
      fail_action: "Check both rules.yml and .ai/rules.yml — at least one must exist"
    - name: "schema_valid"
      verify: "All present fields match the expected schema types"
      fail_action: "Report invalid fields and use defaults for them"
  on_fail: "Report which fields are missing or invalid. Use defaults where possible."
  on_pass: "Report: loaded profile for <project_name> (context: <context>)."
_source:
  origin: "taskflow"
  inspired_by: "D-008 project-level config decision"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "New skill. Loads project rules.yml and exposes config to other skills."
---

# project-profile-loader

Reads `rules.yml` from the project root or `.ai/rules.yml` and makes the
project configuration available to downstream skills (qa-handover-generator,
completion gates, jira-ingestion).

## Steps

1. **Locate config** — check `rules.yml` in project root first, fall back to `.ai/rules.yml`. If neither exists, use all defaults.
2. **Parse and validate** — read YAML, validate against schema (see `references/process.md`)
3. **Apply defaults** — fill missing fields with sensible defaults
4. **Expose config** — return the profile object for use by other skills

## Config file schema (summary)

```yaml
project_name: "my-project"
context: "work"                    # work | personal
git:
  branch_prefix: "feature/"
  commit_style: "conventional"     # conventional | imperative | freeform
qa:
  format: "jira-comment"           # jira-comment | github-pr | markdown
  require_screenshots: true
dev:
  test_command: "npm test"
  build_command: "npm run build"
  lint_command: "npm run lint"
mcp_servers:
  - "atlassian"
  - "github"
```

## Defaults

When no config file exists, the profile uses: context `personal`, commit style
`imperative`, QA format `markdown`, no MCP servers, no dev commands. This
allows all downstream skills to function without requiring explicit setup.

Output: `Profile loaded: <project_name> (context: <context>, QA: <format>)`
