---
name: task-status
description: "Show current active task details and progress"
argument-hint: ""
---

# Task Status

Displays full details of the currently active task.

## Steps

1. **Read active task** — read `.ai/tasks/active.yml`. If file is missing or empty, print: `No active task. Use /task:start KEY` and stop.

2. **Load task file** — read `.ai/tasks/KEY.yml`.

3. **Print task details**:
   - **Key**: the Jira ticket key
   - **Summary**: one-line description
   - **Status**: current local status
   - **Started**: when `/task:start` was run
   - **Description**: full description (truncated to 10 lines if long)

4. **Print contradictions** (if any):
   - List each with index and description
   - Example: `[1] AC says "must support IE11" but tech constraints say "modern browsers only"`

5. **Print attachments** (if any):
   - List linked files, screenshots, or referenced documents from the task file

6. **Show dev-engine progress** (if applicable):
   - Check if dev-engine plugin is tracking subtasks for this KEY
   - If yes, print subtask breakdown: `Subtasks: 3/5 done (feature-decomposer)`
   - If no, skip this section
