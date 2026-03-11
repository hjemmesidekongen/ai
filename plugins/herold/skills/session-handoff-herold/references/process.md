# session-handoff-herold — Process Detail

## Relationship to kronen session-handoff

The kronen `session-handoff` skill handles general work context: plans, recent edits,
decisions, branch state. This skill adds a herold-specific layer on top:

| Layer | Written by | Content |
|-------|-----------|---------|
| General handoff | kronen session-handoff | Plans, files, decisions, branch state |
| Task handoff | session-handoff-herold | Active task, subtasks, blockers, open questions |

You can run both in the same session. The task handoff complements the general one — it
does not replace it. The task handoff writes to `.ai/tasks/handoff.yml` (YAML, structured
for machine resume). The general handoff writes to `.ai/handoffs/<timestamp>.md` (Markdown,
for human reading).

## handoff.yml Schema

```yaml
created_at: "2026-03-10T16:45:00Z"
branch: "feature/PROJ-123-auth-refactor"
continues_from: "none"            # path to previous handoff.yml or "none"

active_task:
  key: "PROJ-123"
  title: "Refactor auth module to use JWT"
  status: "in_progress"           # pending | in_progress | blocked | review
  acceptance_criteria:
    total: 5
    met: 3
    unmet:
      - "AC-4: All existing tests pass"
      - "AC-5: Performance regression < 5%"

subtasks:
  - id: "ST-1"
    title: "Extract token validation logic"
    status: "done"
    notes: "Moved to auth/validators.ts"
  - id: "ST-2"
    title: "Update middleware to use new validator"
    status: "in_progress"
    notes: "50% done — middleware.ts updated, tests failing on edge case"
  - id: "ST-3"
    title: "Write integration tests"
    status: "pending"
    notes: ""

blockers:
  - id: "B-1"
    description: "Waiting for PROJ-118 to merge — it modifies auth/config.ts which conflicts"
    owner: "external"             # self | external | unknown
    since: "2026-03-10"
  - id: "B-2"
    description: "Need clarification on token expiry behavior from @alex"
    owner: "external"
    since: "2026-03-10"

open_questions:
  - "Should the refresh token rotation be handled in middleware or in the service layer?"
  - "Is 15-minute access token TTL a hard requirement or a default?"

immediate_next_step: "Fix failing edge case in middleware.ts line 84 — null token input not handled"

context_notes: |
  The main complication here is that auth/config.ts is being modified by two tickets
  simultaneously (PROJ-118 and this one). Watch for merge conflict in that file.
  Pattern used for token parsing follows RFC 7519 — see docs/auth-decisions.md.
```

## Task State Capture

Read from `.ai/tasks/active.yml` for the current task key. Then load the full
`.ai/tasks/<KEY>.yml` to capture acceptance criteria and subtask state.

If `active.yml` is missing or empty, ask the user which task is active before proceeding.
Do not guess.

## Subtask Progress Snapshot

For each subtask in the task file:
- Copy title, status, and any notes verbatim
- If a subtask has `status: in_progress`, add a brief note about what specifically is mid-flight
- Do not restructure or summarize subtask descriptions — copy them as-is

## Blocker Recording

A blocker is anything that cannot be resolved within the current session. Common types:
- External dependency (waiting on another ticket, PR, person)
- Missing information (requirement unclear, spec not written)
- Decision needed (architectural choice not made)

For each blocker, record: what it is, who owns it, when it was first noticed.

## Open Question List

Capture questions that need answering before the task can be completed. These are
different from blockers — they don't block current progress but must be resolved
before the task closes.

Keep questions specific. "How should we handle token expiry?" is too vague.
"Should refresh token rotation be in middleware.ts or auth-service.ts?" is useful.

## Resume Detection

On session start, check for `.ai/tasks/handoff.yml`. If it exists:

1. Read `active_task.key` and verify `.ai/tasks/<KEY>.yml` still exists
2. Check if `active_task.status` in the task file matches the handoff — if not, warn
3. Classify staleness (same thresholds as kronen session-handoff):

| Level | Commits Since | Time | Recommendation |
|-------|--------------|------|----------------|
| FRESH | 0-4 | <4h | Resume directly |
| SLIGHTLY_STALE | 5-15 | 4-24h | Skim git log, verify subtask states |
| STALE | 16-30 | 1-7d | Re-read task file, check for status changes |
| VERY_STALE | >30 | >7d | Re-ingest task from Jira; create fresh handoff |

## Cross-Session Context Assembly

When resuming, load in this order:
1. `.ai/tasks/handoff.yml` — task-specific state
2. `.ai/tasks/<KEY>.yml` — current task file (may have been updated externally)
3. `.ai/context/snapshot.yml` — general session state
4. Most recent `.ai/handoffs/*.md` — general narrative context (from kronen)

Reconcile conflicts between handoff.yml and task file by trusting the task file for
status (it's the source of truth) and the handoff for in-progress notes and questions.

## continues_from Chaining

When creating a second handoff for the same task:
- Set `continues_from` to the path of the previous `handoff.yml`
- Back up the previous handoff to `.ai/tasks/handoff-<timestamp>.yml` before overwriting
- Only keep the 3 most recent backups — older ones can be deleted

## Anti-Patterns

- **Do not create a handoff if no task is active** — ask the user what they are working on first.
- **Do not copy the entire task description into context_notes** — summarize the tricky parts only.
- **Do not mark blockers as resolved in the handoff** — only remove them if the user confirms resolution.
- **Do not list every file edited as a subtask** — subtasks come from the task spec, not from git status.
- **Do not skip the staleness check on resume** — stale task context is worse than no context.
- **Do not overwrite handoff.yml mid-session without backing up the previous one first.**
