---
name: task-done
description: "Complete the active task with QA handover"
argument-hint: "[--skip-jira]"
---

# Task Done

Completes the active task, generates a QA handover, and optionally transitions the Jira ticket.

## Steps

1. **Read active task** — read `.ai/tasks/active.yml` to get the current task KEY. If no active task, error: `No active task. Use /task:start KEY first.`

2. **Read task file** — load `.ai/tasks/KEY.yml` for context.

3. **Generate QA handover** — invoke `qa-handover-generator` skill:
   - Produces a handover document at `.ai/tasks/KEY-handover.md`
   - Includes: what was done, what to test, known risks, acceptance criteria status

4. **Update task status** — set `status: done` and `completed_at: <ISO timestamp>` in `.ai/tasks/KEY.yml`.

5. **Transition Jira ticket** (unless `--skip-jira`):
   - Check if Atlassian MCP server is available
   - If available, transition the ticket to the appropriate done/review status
   - If unavailable, print: `Jira transition skipped — Atlassian MCP not connected`

6. **Clear active task** — remove or empty `.ai/tasks/active.yml`.

7. **Print completion summary**:
   - Task KEY marked done
   - QA handover location: `.ai/tasks/KEY-handover.md`
   - Jira transition status
