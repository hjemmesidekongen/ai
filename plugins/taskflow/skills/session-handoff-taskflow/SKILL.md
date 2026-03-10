---
name: session-handoff-taskflow
description: >
  Save active task context for cross-session continuity — captures task state,
  subtask progress, blockers, and open questions. Extends claude-core session-handoff
  with taskflow-specific fields. Detects prior handoffs on resume.
user_invocable: true
interactive: false
model_tier: senior
depends_on: []
# Complements claude-core:session-handoff — operates independently, not a call chain
triggers:
  - "handoff"
  - "save progress"
  - "session end"
  - "task handoff"
reads:
  - ".ai/tasks/active.yml"
  - ".ai/tasks/*.yml"
  - ".ai/context/snapshot.yml"
writes:
  - ".ai/tasks/handoff.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "handoff_written"
      verify: ".ai/tasks/handoff.yml exists with active_task, subtasks, blockers, and open_questions"
      fail_action: "Re-run capture; check if active.yml is missing"
    - name: "no_placeholders"
      verify: "No TODO or <placeholder> strings in handoff.yml"
      fail_action: "Fill or remove placeholder fields before writing"
    - name: "next_step_actionable"
      verify: "immediate_next_step starts with a verb and names a file or task key"
      fail_action: "Rewrite next step to be specific and actionable"
  on_fail: "Report which check failed. Do not mark handoff complete until all pass."
  on_pass: "Report: handoff written, task key, subtask progress summary, blocker count."
_source:
  origin: "taskflow"
  inspired_by: "claude-core session-handoff"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New skill. Taskflow-specific handoff layer on top of claude-core session-handoff."
---

# session-handoff-taskflow

Saves active task context before ending a session. Extends the claude-core
`session-handoff` pattern with taskflow-specific fields: active task, subtask progress,
blockers, and open questions. Written to `.ai/tasks/handoff.yml` for quick resume.

## CREATE

1. **Read context** — load `.ai/tasks/active.yml`, relevant `<KEY>.yml` files, and `snapshot.yml`
2. **Capture task state** — active task key, title, current status, acceptance criteria completion
3. **Snapshot subtasks** — each subtask: title, status (pending/in_progress/done), notes
4. **Record blockers** — anything preventing progress (missing info, dependencies, decisions)
5. **List open questions** — unresolved questions that the next session needs to answer
6. **Write** `.ai/tasks/handoff.yml` using the schema in `references/process.md`
7. **Validate** — no placeholders, next step is actionable, all task keys exist
8. **Report** — task key, subtask counts, blocker count, first next step

## RESUME

1. **Detect** — check for `.ai/tasks/handoff.yml` at session start
2. **Classify staleness** — same thresholds as claude-core session-handoff (see process.md)
3. **Load** — read handoff, cross-reference with current `.ai/tasks/active.yml`
4. **Verify** — confirm task is still active, blockers haven't been resolved silently
5. **Begin** — start from `immediate_next_step`

## Proactive suggestion

Suggest a handoff when 5+ task files were edited or a subtask was completed.

## Never

- Never write placeholders (TODO, TBD, `<placeholder>`) in handoff.yml
- Never leave open_questions empty if blockers exist — they imply questions

Full process detail: `references/process.md`
