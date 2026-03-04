---
name: brainstorm-status
command: "/brainstorm:status"
description: "(brainstorm) Show brainstorm session history and decision summary for a project"
arguments:
  - name: project-name
    type: string
    required: true
    description: "Project identifier to check status for"
---

# /brainstorm:status

Read-only command that shows the brainstorm history and decision summary for
a project. Useful for reviewing what was decided before starting new work.

## Usage

```
/brainstorm:status my-saas
/brainstorm:status acme-rebrand
```

## Execution Steps

### Step 1: Load Project State

Read `.ai/brainstorm/[project-name]/brainstorm-state.yml`.

If it doesn't exist:
```
"No brainstorm history for [project-name].
 Run /brainstorm:start [project-name] to begin."
```

---

### Step 2: Show Session Summary

Report session history:

```
Brainstorm History — [project-name]
===================================

Sessions: [N]
Status: [active / completed]

Session 1 — [date]
  Duration: ~[X] minutes
  Topics: [topic1], [topic2], [topic3]
  Decisions extracted: [yes/no]

Session 2 — [date]
  Duration: ~[X] minutes
  Topics: [topic1], [topic2]
  Decisions extracted: [yes/no]
```

---

### Step 3: Show Decision Summary

Read `.ai/brainstorm/[project-name]/decisions.yml`.

If it doesn't exist:
```
"No decisions extracted yet.
 Run /brainstorm:decide to extract decisions from your sessions."
```

If it exists, show decisions grouped by domain with confidence indicators:

```
Decisions — [N] total ([X] high, [Y] medium, [Z] low)
=====================================================

brand-identity
  [H] d1: Company name will be "Acme" — short, memorable, universal
  [M] d3: Position as premium but accessible — not luxury, not budget

brand-voice
  [H] d2: Tone is direct and confident — no hedging or corporate speak

seo
  [M] d5: Target long-tail keywords first — build authority before competing on head terms

technical
  [L] d4: Consider Next.js for the marketing site — revisit after MVP
```

Confidence indicators: `[H]` = high, `[M]` = medium, `[L]` = low.

---

### Step 4: Suggest Next Actions

Based on the current state, suggest what the user can do next:

**If active session exists (not yet decided):**
```
"Active session in progress.
 → /brainstorm:decide to extract decisions
 → /brainstorm:start [project-name] to continue brainstorming"
```

**If decisions exist but no active session:**
```
"→ /brainstorm:start [project-name] to brainstorm more
 → /brand:generate (will use brand-* decisions)
 → /seo:strategy (will use seo decisions)
 → /plugin:create (will use technical decisions)"
```

**If sessions exist but no decisions extracted:**
```
"→ /brainstorm:decide to extract decisions from your sessions"
```

---

## What This Command Does NOT Do

- It does NOT modify any files — purely read-only
- It does NOT start a brainstorm session
- It does NOT extract or edit decisions
