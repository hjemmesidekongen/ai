---
name: brainstorm-decide
command: "/brainstorm:decide"
description: "Extract and co-author structured decisions from the current brainstorm session"
arguments:
  - name: project-name
    type: string
    required: false
    description: "Project identifier. If omitted, uses the project from the active brainstorm session."
---

# /brainstorm:decide

Transitions from brainstorm exploration to structured decision extraction.
Saves the current conversation as a transcript, then activates the
brainstorm-decision-writer skill to walk through decisions one at a time.

## Usage

```
/brainstorm:decide
/brainstorm:decide my-saas
```

## Prerequisites

- An active brainstorm session must exist (brainstorm-state.yml with
  `active: true`) — either from the current conversation or a previous one
- If no active session exists, report:
  ```
  "No active brainstorm session. Run /brainstorm:start [project-name] first."
  ```

## Execution Steps

### Step 1: Resolve Project

Determine which project to extract decisions for:

1. If `project-name` argument is provided, use it
2. If not, check if a brainstorm session is active in the current conversation
   — use that project
3. If neither, scan `~/.claude/projects/` for any brainstorm-state.yml with
   `active: true`
4. If multiple active sessions exist, ask which one
5. If none found, report the error and stop

---

### Step 2: Save Transcript

If a brainstorm was running in the current conversation, save the transcript
before starting decision extraction:

1. Write the brainstorm conversation to
   `~/.claude/projects/[project-name]/brainstorm-transcript-[date].md`

2. Update `brainstorm-state.yml` with session details:
   - `duration_minutes` — estimated from conversation length
   - `topics_explored` — extracted from the conversation themes

If the transcript was already saved (session ended before calling decide),
skip this step.

---

### Step 3: Load Context for Decision Writer

Gather everything the brainstorm-decision-writer skill needs:

1. Read `brainstorm-state.yml` — find the most recent session (or `active: true`)
2. Read the transcript file for that session
3. Check if `decisions.yml` already exists (for merge handling)
4. Count existing decisions if any

---

### Step 4: Activate Decision Writer

Load the brainstorm-decision-writer skill
(`packages/task-planner/skills/brainstorm-decision-writer/SKILL.md`).

The skill handles:
- Reviewing existing decisions (if any)
- Extracting candidate decisions from the transcript
- Presenting each candidate one at a time for user confirmation
- Domain tagging (brand-identity, seo, technical, etc.)
- Confidence levels (high, medium, low)
- Catching stragglers the user wants to add
- Writing decisions.yml with proper merge handling
- Updating brainstorm-state.yml

Claude's behavior shifts from sparring partner to collaborative editor —
methodical, structured, but still conversational.

---

### Step 5: Finalize

After the decision writer completes:

1. Set `active: false` in brainstorm-state.yml — the brainstorm is complete
2. Set `decisions_extracted: true` on the session entry
3. The decision writer's final summary reports:

   ```
   "Wrote [N] decisions ([X] high confidence, [Y] medium, [Z] low).
    Stored at ~/.claude/projects/[project-name]/decisions.yml

    These will be picked up automatically when you run:
    - /brand:generate (reads brand-* domains)
    - /seo:strategy (reads seo domain)
    - /plugin:create (reads technical domain)

    To brainstorm more later: /brainstorm:start [project-name]"
   ```

---

## Error Handling

| Error | Action |
|-------|--------|
| No active brainstorm session | Report error, suggest `/brainstorm:start` |
| Transcript file missing | Attempt to reconstruct from conversation history, or warn user |
| decisions.yml is malformed | Report parse error, offer to create a fresh file (preserving backup) |
| User cancels mid-extraction | Save whatever decisions were confirmed so far, keep session active |

## What This Command Does NOT Do

- It does NOT run the brainstorm itself (that's `/brainstorm:start`)
- It does NOT auto-extract decisions without user confirmation
- It does NOT modify brand-reference.yml or any downstream plugin files
- It does NOT use the task-planner for wave execution
