# Brainstorm Decision Writer — Full Process

## Prerequisites

- A brainstorm session must exist for this project (brainstorm-state.yml
  with at least one session entry)
- The session transcript must be readable

---

## Step 1: Load Context

When the user invokes `/brainstorm:decide [project-name]`:

1. Load `~/.claude/projects/[project-name]/brainstorm-state.yml`
2. Find the most recent session (or the session with `active: true`)
3. Read the transcript file for that session
4. Check if `decisions.yml` already exists (for merge handling)

If no brainstorm session exists:
```
"No brainstorm sessions found for [project-name].
 Run /brainstorm:start [project-name] first."
```

If the session already has `decisions_extracted: true`:
```
"Decisions were already extracted from the [date] session.
 Want to review and update existing decisions? (yes/no)"
```

---

## Step 2: Check for Existing Decisions

If `decisions.yml` already exists from a previous session:

```
"You have [N] existing decisions from previous sessions.
 Want to review them before adding new ones?"
```

- If yes → walk through each existing decision:
  - Show the decision text and current confidence
  - User can: confirm (keep as-is), update confidence, revise wording, or remove
- If no → skip to candidate extraction

---

## Step 3: Extract Candidate Decisions

Read through the transcript and identify **landing points** — moments where
the conversation shifted from exploration to conviction. Look for:

- Explicit statements: "we should definitely...", "let's go with..."
- Resolved tensions: "okay so X over Y because..."
- Repeated conclusions: the same point surfaced 3+ times
- Narrowed options: "between A and B, I think A"

Present candidates **one at a time**:

```
"I think we landed on this:
 [candidate decision — written as a clear, actionable statement]

 Is this a decision we should write down?"
```

For each candidate:

**a) User confirms** → ask for confidence:
```
"How confident are you?
 - High — locked in, build on this
 - Medium — leaning this way, but open to change
 - Low — just an idea, might revisit"
```

**b) User adjusts** → rewrite together:
```
"How would you phrase it? I'll clean it up."
```
Iterate until the user is happy with the wording.

**c) User rejects** → skip it:
```
"Got it — that was just exploration. Moving on."
```

---

## Step 4: Catch Stragglers

After exhausting Claude's candidates:

```
"Any other decisions from this session that I missed?"
```

The user can add decisions Claude didn't catch. For each:
- User states the decision
- Claude suggests a cleaned-up version
- User confirms or adjusts
- Confidence and domain tagging follow the same flow

---

## Step 5: Domain Tagging

Each decision gets tagged with one or more domains. Claude suggests the domain
based on the decision content. The user confirms or changes.

Standard domains:

| Domain | Covers | Consumed By |
|--------|--------|-------------|
| `brand-identity` | Name, mission, values, positioning | brand-guideline (identity-interview) |
| `brand-audience` | Personas, segments, markets | brand-guideline (audience-personas) |
| `brand-voice` | Tone, messaging, vocabulary | brand-guideline (tone-of-voice) |
| `brand-visual` | Colors, typography, imagery, logo direction | brand-guideline (visual-identity, typography-color, logo-design) |
| `seo` | Keywords, positioning, content approach | seo-plugin (project-interview, keyword-research) |
| `website` | Tech stack, features, architecture | website-builder (future) |
| `content` | Content types, editorial approach | content-plugin (future) |
| `business` | Pricing, revenue model, partnerships | general planning |
| `technical` | Architecture, tools, infrastructure | plugin-create, technical planning |
| `general` | Doesn't map to a specific plugin | general reference |

Domain tagging happens inline as each decision is confirmed:

```
"This feels like a brand-identity decision. Sound right?"
```

A decision can have multiple domains if it spans concerns.

---

## Step 6: Write decisions.yml

After all decisions are confirmed, write the file:

```yaml
project: "[project-name]"
created_at: "[ISO timestamp]"
updated_at: "[ISO timestamp]"
source_sessions:
  - "brainstorm-transcript-[date].md"

decisions:
  - id: "d1"
    domain: ["brand-identity"]
    decision: "[the decision in natural language]"
    confidence: "high"
    context: "[brief note on why — what reasoning led here]"
    session_date: "[date of the brainstorm session]"

  - id: "d2"
    domain: ["brand-voice", "content"]
    decision: "[decision text]"
    confidence: "medium"
    context: "[reasoning]"
    session_date: "[date]"
```

**ID format:** Sequential `d1`, `d2`, `d3`, etc. When merging with existing
decisions, continue from the highest existing ID.

**Merge rules (when decisions.yml already exists):**
- Preserve all existing decisions (updated ones keep their original ID)
- Append new decisions with new IDs
- Update `updated_at` timestamp
- Add current transcript to `source_sessions` list
- Removed decisions are deleted from the file entirely

---

## Step 7: Update brainstorm-state.yml

After writing decisions.yml:

```yaml
sessions:
  - date: "[date]"
    transcript: "brainstorm-transcript-[date].md"
    duration_minutes: [estimated]
    topics_explored: [...]
    decisions_extracted: true    # ← set to true
active: false                   # ← brainstorm complete
```

---

## Step 8: Final Summary

```
Wrote [N] decisions ([X] high confidence, [Y] medium, [Z] low).
Stored at ~/.claude/projects/[project-name]/decisions.yml

These will be picked up automatically when you run:
- /brand:generate (reads brand-* domains)
- /seo:strategy (reads seo domain)
- /plugin:create (reads technical domain)

To brainstorm more later: /brainstorm:start [project-name]
```

---

## Output

- `~/.claude/projects/[project-name]/decisions.yml` — structured decisions
- `~/.claude/projects/[project-name]/brainstorm-state.yml` — updated state

## Checkpoint (full detail)

```
type: data_validation
required_checks:
  - decisions.yml exists with at least 1 decision
  - Every decision has: id, domain (list), decision (non-empty string), confidence, context
  - If prior decisions existed: they are preserved, not overwritten
  - brainstorm-state.yml updated with decisions_extracted: true
  - source_sessions list includes current transcript
on_fail: Fix the failing check and re-validate.
on_pass: Report decision count and suggest next steps.
```

## What This Skill Does NOT Do

- It does NOT run the brainstorm itself (that's brainstorm-session)
- It does NOT read decisions downstream (that's decision-reader)
- It does NOT modify brand-reference.yml or seo-strategy.yml
- It does NOT have predefined decisions — everything comes from the conversation
- It does NOT auto-extract without user confirmation — every decision is co-authored
