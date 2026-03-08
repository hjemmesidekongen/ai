# brainstorm-session — Process

## Session lifecycle

### 1. Initialize

1. Receive the topic from the user or from `/brainstorm:start {topic}`
2. Sanitize topic to a directory-safe name (lowercase, hyphens, no spaces)
3. Create `.ai/brainstorm/{topic}/` if it doesn't exist
4. Check for existing `brainstorm-state.yml`:
   - **Exists, active: true** → resume: "Picking up where we left off. Last time we explored: {topics_explored}"
   - **Exists, active: false** → new session on same topic: "Starting a fresh session. Previous sessions decided: {summary}"
   - **Missing** → fresh start: create state file

### 2. Optional context loading

Before diving in, offer to load relevant context if available:
- `.ai/roadmap.yml` — see what's already tracked
- `.ai/brainstorm/{topic}/decisions.yml` — prior decisions on this topic
- Project-specific files the user mentions

Record what was loaded in `context_loaded` array in state.

### 3. The session

**Core behavior:**
- Respond to the user's ideas with substance, not agreement
- When the user proposes something, stress-test it: "What breaks if...?", "What's the cost of...?"
- Track tensions and contradictions without calling them out immediately — let them surface naturally
- If the user is going in circles, name it: "You keep coming back to X. That might be the real question."
- If an idea is strong, say so — don't challenge for the sake of challenging
- Match the user's energy and depth — short thoughts get short responses, deep dives get deep responses

**Don't do:**
- Don't ask a list of questions at the start
- Don't structure the conversation into phases
- Don't produce YAML, tables, or any structured output
- Don't try to "wrap up" or "summarize" — that's what `/brainstorm:decide` is for
- Don't switch to solution mode unless the user explicitly asks

**Research integration:**
- If a factual question comes up during brainstorming, use available tools (web search, codebase search) to ground the discussion
- Save key findings to prevent loss during `/compact`
- Use the 2-Action Rule: every 2 research operations, save findings to the transcript

### 4. End session

When the user signals they're done (explicitly or by context):
1. Save the transcript to `brainstorm-transcript-{date}.md`
2. Update `brainstorm-state.yml`:
   - Add session entry with date, transcript filename, topics_explored
   - Keep `active: true` (stays true until `/brainstorm:decide`)
3. Suggest next step: "When you're ready to extract decisions, run `/brainstorm:decide`"

## State format

```yaml
topic: "topic-name"
active: true
sessions:
  - date: "2026-03-08T19:00:00Z"
    transcript: "brainstorm-transcript-2026-03-08.md"
    topics_explored:
      - "topic one"
      - "topic two"
    decisions_extracted: false
context_loaded:
  - ".ai/roadmap.yml"
```

## Transcript format

Freeform markdown. Record the conversation naturally — no special formatting, no metadata inline. The transcript should read like a conversation between colleagues, not a meeting minutes template.

## Edge cases

- **Multiple sessions on same topic**: each adds a new entry to the sessions array
- **Session interrupted by /compact**: the active flag in state ensures the session can resume
- **User asks for structure mid-brainstorm**: gently redirect — "Let's keep exploring. Structure comes later with /brainstorm:decide"
- **Topic already has decisions**: load and reference them, but don't treat them as constraints — the user may want to revisit
