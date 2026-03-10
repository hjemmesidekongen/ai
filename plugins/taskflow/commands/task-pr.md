---
name: task-pr
description: "Create a PR from the active task context"
argument-hint: "[--draft] [--target BRANCH]"
---

# Task PR

Creates a pull request for the active task with a structured description pulled from the task context.

## Steps

1. **Check active task** — read `.ai/tasks/active.yml` to get the current task key. Fail if no active task.

2. **Detect git state** — verify there are committed changes on a branch. The branch name should contain the task key.

3. **Invoke bitbucket-pr-workflow skill** with:
   - Task key and summary from active task
   - `--draft` flag if provided
   - `--target` branch (default: main)

4. **Print result**:
   - PR URL
   - Pipeline status (if available)
   - Whether Jira was updated
   - Example: `PR created: https://bitbucket.org/team/repo/pull-requests/42 | Pipeline: running | Jira PROJ-123: transitioned to "In Review"`
