---
name: task-start
description: "Set a task as active and load its context"
argument-hint: "KEY"
---

# Task Start

Activates a task for work and loads its full context.

## Steps

1. **Verify task exists** — confirm `.ai/tasks/KEY.yml` is present. If not, error: `Task KEY not found. Run /task:ingest KEY first.`

2. **Set active task** — write the KEY to `.ai/tasks/active.yml`:
   ```yaml
   active: KEY
   started_at: <ISO timestamp>
   ```

3. **Update task status** — set `status: in_progress` in `.ai/tasks/KEY.yml` if currently `pending`.

4. **Load project profile** — invoke `project-profile-loader` skill to load relevant project context, tech stack, and conventions.

5. **Print task summary**:
   - Key, summary, description
   - Acceptance criteria (if present)
   - Linked tickets (if present)

6. **Print contradictions** (if any exist):
   - List each contradiction with a warning prefix
   - Example: `WARNING: 2 contradictions detected — review before starting work`

7. **Confirm** — print `Ready to work on KEY`
