---
name: bitbucket-pr-workflow
description: >
  Create PRs from the active task with structured description auto-populated
  from the task key, summary, acceptance criteria, and test plan. Checks
  pipeline status after creation and links back to Jira with a comment.
  Falls back gracefully when Bitbucket or Jira MCP is unavailable.
user_invocable: true
interactive: false
model_tier: senior
depends_on:
  - "kronen:bitbucket-basics"
triggers:
  - "create pr"
  - "pr workflow"
  - "submit for review"
  - "bitbucket pr"
  - "open pr"
  - "pull request"
reads:
  - ".ai/tasks/<KEY>.yml"
writes:
  - ".ai/tasks/<KEY>.yml"  # appends pr_url after creation
checkpoint:
  type: data_validation
  required_checks:
    - name: "task_file_present"
      verify: "Active task file .ai/tasks/<KEY>.yml exists with key, summary, and acceptance_criteria"
      fail_action: "Run jira-ingestion to fetch the task before creating a PR"
    - name: "branch_exists"
      verify: "Git branch matching the task key pattern exists locally or on remote"
      fail_action: "Prompt user to create branch or confirm correct branch name"
    - name: "pr_created"
      verify: "PR URL is present and accessible; pr_url written back to task YAML"
      fail_action: "Retry PR creation — check Bitbucket MCP connectivity"
    - name: "jira_linked"
      verify: "Jira comment with PR URL posted to the task (or skipped with warning if MCP unavailable)"
      fail_action: "Post comment manually or re-run with Jira MCP connected"
  on_fail: "Report which step failed and the specific error. Do not mark task as in-review until PR exists."
  on_pass: "Report: PR created at <url>. Pipeline status: <status>. Jira comment posted."
_source:
  origin: "herold"
  inspired_by: "D-014 decisions"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Task-aware PR creation orchestration"
---

# bitbucket-pr-workflow

Orchestrates PR creation from the active task. Reads the task file, builds a
structured PR description, creates the PR via Bitbucket MCP, polls the pipeline,
and posts a Jira comment linking back. Uses bitbucket-basics conventions from
kronen for branch naming and API interaction.

## Steps

1. **Load task** — read `.ai/tasks/<KEY>.yml`. Require: key, summary, acceptance_criteria
2. **Resolve branch** — derive branch name from task key (see `references/process.md §2`)
3. **Build description** — populate PR template with summary, AC, test plan, task link
4. **Create PR** — call Bitbucket MCP. Support draft mode if requested
5. **Assign reviewers** — apply reviewer list from project profile or prompt user
6. **Poll pipeline** — check CI status up to 3 times with 10s delay; report final state
7. **Write back** — append `pr_url` to `.ai/tasks/<KEY>.yml`
8. **Link Jira** — post Bitbucket PR URL as comment on the Jira ticket; transition status if configured
9. **Report** — PR URL, pipeline status, reviewer list, Jira comment status

## Fallback behavior

- **Bitbucket MCP unavailable**: output the PR description as formatted text for manual submission
- **Jira MCP unavailable**: skip comment step, warn user to link manually
- **No task file**: abort with actionable error — do not proceed with empty description

## Never

- Never create a PR without a task file — empty descriptions waste reviewer time
- Never force-push or modify existing PRs without user confirmation
- Never skip the Jira link step silently — warn if MCP is unavailable
