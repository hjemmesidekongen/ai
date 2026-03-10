# project-profile-loader — Process Reference

## 1. File Location Priority

The loader checks two paths in order:

1. `./rules.yml` (project root)
2. `./.ai/rules.yml`

First file found wins. If both exist, the project root version takes precedence.
If neither exists, log `No rules.yml found — using all defaults` and return the
default profile.

---

## 2. Full Schema

```yaml
# rules.yml — Project profile configuration
project_name: "my-project"         # Required. Used in reports and handover docs.
context: "work"                    # Optional. "work" or "personal". Default: "personal"

git:                               # Optional block. All sub-fields optional.
  branch_prefix: "feature/"        # Prefix for new branches. Default: none
  commit_style: "conventional"     # "conventional" | "imperative" | "freeform". Default: "imperative"
  main_branch: "main"              # Default: "main"
  require_pr: true                 # Whether direct push is allowed. Default: true

qa:                                # Optional block. All sub-fields optional.
  format: "jira-comment"           # "jira-comment" | "github-pr" | "markdown". Default: "markdown"
  require_screenshots: true        # Whether UI changes need screenshots. Default: false
  checklist_template: |            # Custom QA checklist. Default: built-in template
    - [ ] Functional testing
    - [ ] Edge cases
    - [ ] Regression check

dev:                               # Optional block. All sub-fields optional.
  test_command: "npm test"         # Command to run tests. Default: null
  build_command: "npm run build"   # Command to build. Default: null
  lint_command: "npm run lint"     # Command to lint. Default: null
  start_command: "npm start"       # Command to start dev server. Default: null
  language: "typescript"           # Primary language. Default: inferred from files
  framework: "react"               # Primary framework. Default: inferred from files

mcp_servers:                       # Optional. List of MCP servers expected to be connected.
  - "atlassian"                    # Used by jira-ingestion
  - "github"                       # Used by qa-handover-generator (PR mode)

completion_gates:                  # Optional. Override which checks run at task completion.
  - "tests_pass"                   # Run test_command, verify exit 0
  - "build_succeeds"              # Run build_command, verify exit 0
  - "lint_clean"                   # Run lint_command, verify exit 0
  - "no_blockers"                  # No blocker-severity contradictions remain
```

---

## 3. Default Profile

When no config file exists, return this profile:

```yaml
project_name: "<directory-name>"   # Inferred from cwd basename
context: "personal"
git:
  branch_prefix: ""
  commit_style: "imperative"
  main_branch: "main"
  require_pr: false
qa:
  format: "markdown"
  require_screenshots: false
  checklist_template: null
dev:
  test_command: null
  build_command: null
  lint_command: null
  start_command: null
  language: null
  framework: null
mcp_servers: []
completion_gates:
  - "no_blockers"
```

---

## 4. Validation Rules

### Type validation
| Field | Type | Valid values |
|-------|------|-------------|
| project_name | string | non-empty |
| context | string | "work", "personal" |
| git.commit_style | string | "conventional", "imperative", "freeform" |
| qa.format | string | "jira-comment", "github-pr", "markdown" |
| qa.require_screenshots | boolean | true, false |
| mcp_servers | array of strings | any |
| completion_gates | array of strings | "tests_pass", "build_succeeds", "lint_clean", "no_blockers" |

### Validation behavior
- Unknown fields: ignore (forward compatibility)
- Wrong type: warn and use default for that field
- Missing optional block: use all defaults for that block
- Missing project_name: infer from directory name, warn

---

## 5. Downstream Consumers

### qa-handover-generator
Reads: `qa.format`, `qa.require_screenshots`, `qa.checklist_template`, `project_name`

### jira-ingestion
Reads: `mcp_servers` (to check if "atlassian" is expected), `project_name`

### contradiction-detection
Reads: `completion_gates` (to determine if `no_blockers` gate is active)

### Completion gates (future)
Reads: `dev.test_command`, `dev.build_command`, `dev.lint_command`, `completion_gates`

---

## 6. Loading at Session Start

When loaded as part of session initialization:
1. Check for rules.yml
2. Parse and validate
3. Store the profile in session context (not persisted — re-read each session)
4. Log which MCP servers are expected vs. actually connected

---

## 7. Loading on Task Switch

When the user switches active task context:
1. Re-read rules.yml (it may have changed)
2. Re-validate
3. Update session context with fresh profile
4. Report any changes from previous load

---

## 8. Error Handling

| Error | Action |
|-------|--------|
| rules.yml not found | Use defaults, log info message |
| YAML parse error | Report syntax error with line number, use defaults |
| Unknown context value | Warn, default to "personal" |
| Unknown qa.format | Warn, default to "markdown" |
| dev command contains shell injection patterns | Warn, set to null |
| File is empty | Treat as missing, use defaults |

---

## 9. Example: Work Project

```yaml
# rules.yml
project_name: "customer-portal"
context: "work"
git:
  branch_prefix: "feature/"
  commit_style: "conventional"
  main_branch: "develop"
  require_pr: true
qa:
  format: "jira-comment"
  require_screenshots: true
dev:
  test_command: "yarn test --coverage"
  build_command: "yarn build"
  lint_command: "yarn lint"
  language: "typescript"
  framework: "next"
mcp_servers:
  - "atlassian"
  - "github"
completion_gates:
  - "tests_pass"
  - "build_succeeds"
  - "lint_clean"
  - "no_blockers"
```

Loader output: `Profile loaded: customer-portal (context: work, QA: jira-comment)`

---

## 10. Example: Personal Project (No Config)

No `rules.yml` or `.ai/rules.yml` found.

Loader output: `Profile loaded: my-side-project (context: personal, QA: markdown) [defaults]`

The directory name `my-side-project` is used as the project name.
All completion gates default to `no_blockers` only.
