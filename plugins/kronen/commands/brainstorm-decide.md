---
name: brainstorm-decide
description: Extract structured decisions from a brainstorm session
user_invocable: true
arguments:
  - name: topic
    description: "Brainstorm topic to extract decisions from (optional — uses active session)"
    required: false
---

# /brainstorm:decide

Extract and formalize decisions from a brainstorm session. Each decision is user-confirmed before writing.

## Steps

1. **Find the session:**
   - If `$ARGUMENTS` specifies a topic → use it
   - Otherwise → find the active session (where `active: true` in brainstorm-state.yml)
   - If no active session → "No active brainstorm. Run `/brainstorm:start` first."

2. **Load existing decisions** if `decisions.yml` exists — offer quick review:
   - "You have {N} prior decisions. Want to review them before adding new ones?"

3. **Activate brainstorm-decision-writer skill** — walks through the transcript, extracts candidates, confirms each with the user

4. **Write decisions.yml** with merge rules (append, never overwrite)

5. **Update brainstorm-state.yml** — mark session `active: false`, `decisions_extracted: true`

6. **Suggest next step:** "Decisions saved. When ready, use `/plan:create` to turn these into an execution plan."
