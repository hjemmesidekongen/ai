# brainstorm-decision-writer — Process

## Extraction workflow

### 1. Load context

1. Read `brainstorm-state.yml` — find the active session
2. Read the transcript(s) for the active session
3. If `decisions.yml` exists — load existing decisions for merge and contradiction detection

### 2. Identify candidate landing points

Scan the transcript for:
- **Conviction shifts** — "actually, let's go with X"
- **Resolved tensions** — "okay so the tradeoff is worth it because..."
- **Repeated conclusions** — same point made multiple times = strong signal
- **Narrowed options** — "between A and B, definitely B"
- **Explicit decisions** — "let's decide on X"

Don't extract:
- Open questions that weren't resolved
- Thinking-out-loud that didn't land anywhere
- Options that were explored but not chosen

### 3. Present candidates one at a time

For each candidate:
1. State the decision in natural language
2. Quote the relevant part of the transcript
3. Ask: "Is this a decision? If yes, how confident? (high/medium/low)"
4. If yes → add to the list
5. If no → skip, move to next

### 4. Catch stragglers

After presenting all candidates:
- "Any decisions I missed?"
- Let the user add decisions that aren't in the transcript

### 5. Domain tagging

For each confirmed decision:
- Suggest domain tags based on the content (e.g., `architecture`, `ux`, `technical`, `process`)
- Don't limit to a fixed set — domains are freeform strings
- Multiple domains per decision are fine
- Let the user confirm or adjust tags

### 6. Contradiction detection

Before writing, check each new decision against existing ones:
- Extract keywords from both decisions
- If >50% keyword overlap and the conclusions differ → flag:
  "This may contradict D-{N}: '{existing_decision}'. Keep both, replace, or skip?"
- Let the user resolve the contradiction

### 7. Write decisions.yml

**Merge rules:**
- If `decisions.yml` exists: read it, append new decisions, preserve existing ones
- If it doesn't exist: create it fresh
- ID format: `D-{NNN}` (zero-padded, sequential)
- Never overwrite or reorder existing decisions

**Schema:**
```yaml
topic: "{topic-name}"
created_at: "{first session timestamp}"
updated_at: "{now}"
source_sessions:
  - "brainstorm-transcript-{date}.md"

decisions:
  - id: "D-001"
    domain: ["architecture", "technical"]
    decision: "Use a hub-and-spoke plugin model with kronen as the only shared dependency."
    confidence: "high"
    context: "Explored monolithic vs modular approaches. Monolithic created coupling issues."
    session_date: "{date}"
```

### 8. Port to roadmap

After decisions are written, cross-reference against `.ai/roadmap.yml`:

1. For each decision, check if a roadmap item already covers it:
   - **Exact match** → update the existing item's description with richer context from the decision
   - **Partial match** → update the item and note the relationship
   - **No match** → create a new roadmap item with appropriate priority

2. New roadmap items from brainstorm decisions get:
   - `source: "brainstorm/{topic}"`
   - `added: "{today}"`
   - Priority: `next` if actionable soon, `later` if dependent on other work, `backlog` if deferred

3. Mark each decision in `decisions.yml` with its roadmap item:
   ```yaml
   roadmap_item: RL-079           # single item
   roadmap_item: "RL-080, RL-081" # multiple items
   roadmap_item: "implemented (description)"  # already done
   roadmap_item: "RL-082 (design context only — no standalone build item)"  # design-only
   ```

4. Add to `decisions.yml` header:
   ```yaml
   roadmap_ported: true
   roadmap_ported_date: "{today}"
   ```

5. Update roadmap STATS comment at the bottom of `roadmap.yml`.

**Why this step exists:** Research and brainstorming is expensive — tokens, paid tools, and time. The decisions are worthless if they don't survive into the build queue. Porting ensures every concluded brainstorm either extends the roadmap or confirms what's already there. When the user resumes this brainstorm topic later, they can see exactly which decisions are already queued.

### 9. Update state

Update `brainstorm-state.yml`:
- Set `decisions_extracted: true` for the current session
- Set `roadmap_ported: true` if porting was completed
- Set `active: false` — brainstorm is formally closed
- The topic can be re-opened with `/brainstorm:start {topic}` for a new session

## Edge cases

- **No clear decisions in transcript**: tell the user honestly — "I didn't find strong landing points. The discussion seems still open. Want to continue brainstorming?"
- **User disagrees with a candidate**: skip it without argument. Their judgment is final.
- **Multiple sessions on same topic**: merge decisions from all sessions. Show prior decisions for review before adding new ones.
- **User wants to update an existing decision**: allow direct edit to the decision text and re-tag if needed. Don't create a new entry — update in place.
