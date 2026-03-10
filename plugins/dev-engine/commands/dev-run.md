---
name: dev-run
description: "Run the full dev-engine pipeline from task intake to verified completion"
argument-hint: "TASK_DESCRIPTION [--dry-run]"
---

# Dev Run

Runs the dev-engine-orchestrator skill — the full pipeline from task intake to verified completion.

## Steps

1. **Parse arguments**:
   - First argument is the task description (required).
   - If `--dry-run` flag is present, run in preview mode without dispatching agents.

2. **Check for active task** — if taskflow is installed and has an active task, use it as context. Otherwise use the provided description.

3. **Invoke dev-engine-orchestrator** skill with the task description and mode (execute or dry-run).

4. **In dry-run mode**, print:
   - Which pipeline stages would run vs. skip
   - Estimated subtask count and agent dispatch plan
   - Tier assignments for each subtask

5. **In execute mode**, print progress as each stage completes:
   - `[1/7] project-mapper: scanned (3 modules detected)`
   - `[2/7] taskflow-bridge: integrated (4 acceptance criteria mapped)`
   - ...through to completion gate verdict.

6. **On completion**, print the final gate result and any failing checks.
