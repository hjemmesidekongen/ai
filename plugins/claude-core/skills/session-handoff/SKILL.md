---
name: session-handoff
description: |
  Create and resume from handoff documents for cross-session context continuity.
  Use when: saving state before ending a session, context window approaching capacity,
  major milestone completed, resuming previous work ("continue where we left off"),
  or after 5+ file edits in a session. Complements snapshot.yml with human-readable
  chained handoffs and staleness awareness.
user_invocable: true
interactive: true
depends_on: []
reads:
  - ".ai/context/snapshot.yml"
  - ".ai/plans/*/state.yml"
  - ".ai/handoffs/*.md"
writes:
  - ".ai/handoffs/*.md"
triggers:
  - handoff
  - save state
  - session transfer
  - continue where we left off
  - resume from
  - context save
checkpoint:
  type: data_validation
  required_checks:
    - name: "handoff_written"
      verify: "Handoff document written to .ai/handoffs/ with all required sections"
      fail_action: "Fill missing sections before saving"
  on_fail: "Complete the handoff document"
  on_pass: "Handoff saved with context for next session"
model_tier: senior
_source:
  origin: original
  ported_date: "2026-03-09"
  iteration: 1
  changes: ["initial creation"]
---

# Session Handoff

Structured handoff documents for cross-session continuity. Complements automatic snapshot.yml with human-readable, chained context and staleness awareness.

## Mode Selection

**Creating?** Save state, pause, or context getting full → CREATE below
**Resuming?** Continue previous work → RESUME below
**Proactive?** After 5+ file edits or major decisions, suggest creating a handoff

## CREATE

1. **Gather**: Read snapshot.yml, active plan state.yml, `git log -10`, `git status`
2. **Write** handoff to `.ai/handoffs/YYYY-MM-DD-HHMMSS-<slug>.md`
   - Sections: Current State, Important Context, Key Files, Immediate Next Steps, Pending Work, Blockers
   - Include `Continues-from:` header linking to previous handoff or "none"
   - Full template: `references/process.md`
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
