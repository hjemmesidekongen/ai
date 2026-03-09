---
name: session-handoff
description: |
  Create and resume from handoff documents for cross-session context continuity.
  Use when: saving state before ending a session, context window approaching capacity,
  major milestone completed, resuming previous work ("continue where we left off"),
  or after 5+ file edits in a session. Complements snapshot.yml with human-readable
  chained handoffs and staleness awareness.
triggers:
  - handoff
  - save state
  - session transfer
  - continue where we left off
  - resume from
  - context save
---

# Session Handoff

Structured handoff documents for cross-session continuity. Complements automatic snapshot.yml with human-readable, chained context and staleness awareness.

## Mode Selection

**Creating?** Save state, pause, or context getting full → CREATE below
**Resuming?** Continue previous work → RESUME below
**Proactive?** After 5+ file edits or major decisions, suggest creating a handoff

## CREATE

1. **Gather**: Read snapshot.yml, active plan state.yml, `git log -10`, `git status`
2. **Write** handoff to `.ai/handoffs/YYYY-MM-DD-HHMMSS-<slug>.md` using template:

```markdown
# Handoff: <title>
Created: <timestamp> | Branch: <branch>
Continues-from: <previous handoff path or "none">

## Current State
<What's happening now. Last thing completed.>

## Important Context
<Critical info next session MUST know. Decisions with rationale.>

## Key Files
<Most important files with brief notes.>

## Immediate Next Steps
1. <Specific, actionable first step>
2. <Second step>

## Pending Work
- [ ] <Remaining tasks>

## Blockers
<Issues needing resolution, or "None">
```

3. **Validate**: No TODO placeholders, no secrets, referenced files exist, next steps are actionable
4. **Report**: File location, what was captured, first next step

## RESUME

1. **Find**: `ls .ai/handoffs/`
2. **Check staleness**: `git log --oneline --after="<date>" | wc -l`
   - FRESH (<5 commits): resume directly
   - SLIGHTLY_STALE (5-15): review git log first
   - STALE (15-30): verify assumptions, check for conflicts
   - VERY_STALE (>30 or >7 days): create fresh handoff instead
3. **Load**: Read handoff. If chained, read predecessor too
4. **Verify**: Branch matches, blockers resolved, assumptions hold
5. **Begin**: Start with "Immediate Next Steps" item #1

## Handoff Chaining

Chain handoffs via `Continues-from` for context lineage across sessions. Keep chains to 3-5 max; consolidate longer chains. Full detail: `references/process.md`.
