---
name: brainstorm-start
command: "/brainstorm:start"
description: "Start an open-ended brainstorm session where Claude acts as a sparring partner"
arguments:
  - name: project-name
    type: string
    required: true
    description: "Project identifier — used to namespace brainstorm state and transcripts"
---

# /brainstorm:start

Starts (or resumes) a brainstorm session. Claude switches into sparring-partner
mode — no structured questions, no premature formalization. The user leads,
Claude pushes back.

## Usage

```
/brainstorm:start my-saas
/brainstorm:start acme-rebrand
```

## Prerequisites

None. A brainstorm can happen before any plugin exists.

## Execution Steps

### Step 1: Create Project Directory

Create `~/.claude/projects/[project-name]/` if it doesn't exist.

---

### Step 2: Check Existing State

Read `~/.claude/projects/[project-name]/brainstorm-state.yml` if it exists.

**If it exists with `active: true`:**

Resume the previous session. Load the most recent session's `topics_explored`
and report:

```
"Picking up where we left off. Last session explored: [topics_explored].
 Where do you want to go today?"
```

Skip to Step 4 (activate brainstorm mode).

**If it exists with `active: false` (previous sessions completed):**

Count sessions and check for decisions.yml:

```
"You've brainstormed about [project-name] before ([N] sessions,
 [M] decisions). Want to review existing decisions first, or
 just dive in?"
```

- If the user wants to review → show a brief summary of existing decisions
  grouped by domain, then proceed to Step 3
- If the user wants to dive in → proceed to Step 3

**If it doesn't exist:**

Fresh start — proceed to Step 3.

---

### Step 3: Initialize Session State

Create or append to `brainstorm-state.yml`:

```yaml
project: "[project-name]"
sessions:
  - date: "[ISO date]"
    transcript: "brainstorm-transcript-[date].md"
    duration_minutes: null
    topics_explored: []
    decisions_extracted: false
active: true
```

If sessions already exist, append the new session entry — never overwrite
previous sessions.

---

### Step 4: Activate Brainstorm Mode

Load the brainstorm-session skill
(`plugins/task-planner/skills/brainstorm-session/SKILL.md`).

This changes Claude's behavior:
- Sparring partner, not interviewer
- Push back on weak reasoning, challenge assumptions
- Follow the user's lead — no predefined questions
- No premature formalization — no structured output until `/brainstorm:decide`
- Track shifts from exploration to conviction, contradictions, recurring themes

Open with:

```
"I'm here to spar. Push back, challenge, explore.
 When you're ready to lock in decisions: /brainstorm:decide

 What are you thinking about? Give me the raw idea — messy is fine."
```

---

### Step 5: End Session (when the user signals they're done)

When the user says they're done (or calls `/brainstorm:decide`):

1. **Save transcript** to `~/.claude/projects/[project-name]/brainstorm-transcript-[date].md`:

   ```markdown
   # Brainstorm Session — [project-name]
   **Date:** [ISO date]
   **Duration:** ~[estimated] minutes

   ---

   **User:** [first message]

   **Claude:** [first response]

   **User:** [second message]

   **Claude:** [second response]

   ...
   ```

2. **Update brainstorm-state.yml** with session details:

   ```yaml
   sessions:
     - date: "[ISO date]"
       transcript: "brainstorm-transcript-[date].md"
       duration_minutes: [estimated from conversation length]
       topics_explored:
         - "[topic 1 — short phrase]"
         - "[topic 2 — short phrase]"
       decisions_extracted: false
   active: true   # stays true until /brainstorm:decide completes
   ```

3. **Report:**

   ```
   "Session saved to brainstorm-transcript-[date].md
    Topics explored: [list]

    When you're ready to extract decisions: /brainstorm:decide"
   ```

If the user called `/brainstorm:decide`, hand off to that command instead of
reporting the above — the decide command handles its own flow.

---

## What This Command Does NOT Do

- It does NOT extract decisions (that's `/brainstorm:decide`)
- It does NOT produce structured output during the session
- It does NOT use the task-planner for wave execution
- It does NOT require brand context or any other plugin
