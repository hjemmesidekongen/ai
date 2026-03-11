---
name: brainstorm-start
description: Start an open-ended brainstorm session
user_invocable: true
arguments:
  - name: topic
    description: "Topic or question to brainstorm about"
    required: true
---

# /brainstorm:start

Start a brainstorm session on the given topic. Claude acts as a sparring partner — challenging assumptions, probing weak reasoning, and following the user's lead.

## Steps

1. **Sanitize topic** — convert to directory-safe name (lowercase, hyphens)
2. **Create directory** — `.ai/brainstorm/{topic}/`
3. **Check existing state** at `brainstorm-state.yml`:
   - If exists and `active: true` → resume: load transcript, recap topics explored
   - If exists and `active: false` → new session: reference prior decisions
   - If missing → fresh start: create state file
4. **Optional context loading** — ask if the user wants to load related files:
   - `.ai/roadmap.yml` (relevant items for this topic)
   - `.ai/brainstorm/{topic}/decisions.yml` (prior decisions)
   - Any project files the user mentions
5. **Begin session** — activate the `brainstorm-session` skill
6. **On session end** — save transcript, update state with topics explored

## Important

- No structured output during the session. Structure comes later via `/brainstorm:decide`.
- The session stays `active: true` until `/brainstorm:decide` is run.
- If the session is interrupted by `/compact` or session restart, the active flag ensures resumption.
