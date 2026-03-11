# Session Handoff — Process Detail

## Relationship to snapshot.yml

The automatic context system (`assemble-context.sh` → `snapshot.yml`) captures machine-readable state on SessionStart, PreCompact, and Stop hooks. Session handoffs complement this with:

1. **Human-readable narrative** — what happened, why, what to do next
2. **Chaining** — each handoff links to its predecessor, creating context lineage
3. **Staleness awareness** — explicit freshness classification before loading
4. **Quality validation** — no TODO placeholders, no secrets, all files exist

Use both: snapshot.yml for automatic recovery, handoffs for deliberate session transitions.

## Handoff Chaining Detail

### Creating a Chain

First handoff:
```yaml
Continues-from: none
```

Subsequent handoffs:
```yaml
Continues-from: .ai/handoffs/2026-03-09-143022-batch-4-wave-1.md
```

### Reading a Chain

When resuming from a chained handoff:
1. Read the most recent handoff completely
2. Check if predecessor context is needed (usually not — recent handoff should be self-contained)
3. Only read predecessors if the current handoff references specific decisions or patterns from earlier sessions

### Chain Length

Keep chains to 3-5 handoffs max. When a chain grows longer:
- Create a "consolidated" handoff that summarizes the full lineage
- Start a new chain from the consolidation

## Staleness Classification

### How to Check

```bash
# Count commits since handoff was created
git log --oneline --after="<handoff-timestamp>" | wc -l

# Check files changed since handoff
git diff --name-only <handoff-commit>..HEAD

# Check if branch has diverged
git log --oneline <branch-at-handoff>..HEAD
```

### Classification Table

| Level | Commits Since | Time Since | Files Changed | Recommendation |
|-------|--------------|------------|---------------|----------------|
| FRESH | 0-4 | <4 hours | <5 files | Resume directly |
| SLIGHTLY_STALE | 5-15 | 4-24 hours | 5-15 files | Skim git log, verify key assumptions |
| STALE | 16-30 | 1-7 days | 15-50 files | Check each key file for conflicts |
| VERY_STALE | >30 | >7 days | >50 files | Create fresh handoff instead |

### What Staleness Means

A stale handoff may have:
- Files that were moved, renamed, or deleted
- Decisions that were reversed
- Plans that were restructured
- Dependencies that changed

Loading stale context without knowing it's stale is worse than loading no context at all — it creates confident wrongness.

## Quality Scoring

A handoff quality score (0-100) based on:

| Criterion | Points | Check |
|-----------|--------|-------|
| No TODO placeholders | 20 | Grep for `[TODO` |
| No secrets detected | 20 | Grep for common patterns (API_KEY, password, token, secret) |
| All referenced files exist | 15 | Verify each path mentioned |
| Next steps are specific | 15 | Each step starts with a verb and names a file/function |
| Current state is clear | 15 | Can answer "what was happening?" in one read |
| Decisions include rationale | 15 | Not just "chose X" but "chose X because Y" |

Minimum acceptable score: 70/100

## Proactive Suggestion Triggers

Suggest creating a handoff when:
- 5+ file edits in the current session
- A major architectural decision was made
- A debugging session found the root cause
- A plan wave was completed
- Context window is >70% consumed
- User mentions ending their session

Suggestion format:
> "We've covered substantial ground this session. Want to create a handoff to preserve this context? Say 'create handoff' when ready."

## Storage and Naming

Location: `.ai/handoffs/`
Format: `YYYY-MM-DD-HHMMSS-<slug>.md`
Slug: kebab-case, descriptive (e.g., `batch-4-wave-3-complete`, `auth-debugging-root-cause`)

Create the `.ai/handoffs/` directory on first use if it doesn't exist.

## Handoff Template

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
