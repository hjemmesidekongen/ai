# Brainstorm Session — Detailed Process

## Step 1: Load Context

```
project_name = read agency.yml → active
brainstorm_dir = .ai/brainstorm/

# Scan for past decisions to inform the session
past_decisions = []
for topic_dir in brainstorm_dir/*/
  decisions_file = topic_dir/decisions.yml
  if exists(decisions_file):
    decisions = read_yaml(decisions_file)
    past_decisions.extend(decisions)

Report: "Loaded {len(past_decisions)} past decisions across {topic_count} topics"
```

## Step 1b: Classify Domain & Load Domain Context

After getting the brainstorm topic, classify it into one or more domains:

| Domain | Triggers | What to research |
|--------|----------|-----------------|
| **brand** | brand, identity, positioning, naming, values, voice, archetype | Competitor brands, positioning frameworks, brand case studies |
| **design** | UI, UX, design system, tokens, components, layout | Design trends, component patterns, accessibility standards |
| **technical** | architecture, stack, framework, API, database, performance | Framework comparisons, benchmarks, migration guides |
| **strategy** | business model, pricing, market, growth, differentiation | Market data, competitor strategies, industry benchmarks |
| **content** | copy, messaging, tone, SEO, landing page | Competitor messaging, conversion patterns, content strategy |
| **product** | features, roadmap, MVP, user stories | Competitor features, user research patterns, product-market fit |

Store the classification — it determines when and what to search during the session.

```
domain = classify(topic)  # may be multiple: ["brand", "strategy"]
```

## Step 2: Initialize Session

```
# Ask user for topic
topic = ask("What would you like to brainstorm about?")
topic_slug = slugify(topic)  # lowercase, hyphens, no spaces
date = today()  # YYYY-MM-DD format

# Create topic directory if needed
topic_dir = .ai/brainstorm/{topic_slug}/
mkdir -p topic_dir

# Initialize state
state = {
  topic: topic,
  status: "in_progress",
  started_at: now(),
  session_date: date,
  topics: [],
  open_questions: [],
  key_points: [],
  participants: ["user", "claude"]
}
```

## Step 3: Facilitate Discussion

The facilitator must follow these behavioral rules:

### Challenge Mode
- **Push back** on first-instinct answers — ask "what if the opposite were true?"
- **Explore trade-offs** for every proposal — "what do we give up?"
- **Question assumptions** — "why do we believe X? What evidence?"
- **Offer alternatives** — present 2-3 approaches the user hasn't considered
- **Steel-man objections** — argue the strongest case against the user's preference

### Structure
- Open with context setting (relevant past decisions, constraints)
- Explore the problem space before jumping to solutions
- For each sub-topic: diverge (generate options) → converge (evaluate)
- Capture explicit decisions with confidence levels
- End with open questions and next steps

### Grounded Pushback (Perplexity MCP)

Use Perplexity MCP tools to make challenges specific and evidence-based rather than generic.
Do NOT announce "let me search for that" — weave results into the conversation naturally.

**Which Perplexity tool to use:**

| Situation | Tool | Why |
|-----------|------|-----|
| Quick fact check, verify a claim | `perplexity_ask` | Fast, cheap, good for single data points |
| Find competitor URLs, recent news | `perplexity_search` | Returns ranked results with snippets |
| Compare approaches, evaluate trade-offs | `perplexity_reason` | Chain-of-thought reasoning with web data |
| Deep dive into a market/domain (use sparingly) | `perplexity_research` | Slow (30s+) but thorough — only for major topic shifts |

Default to `perplexity_ask` for most pushback. Use `perplexity_research` only when the user is exploring a major new direction and you need comprehensive grounding.

**When to search:**

| Trigger | Example query | How to use the result |
|---------|---------------|----------------------|
| User claims market position | `perplexity_ask`: "How does [competitor] position itself in the [segment] market?" | "Actually, [competitor] already positions as [X]. How do you differentiate?" |
| User assumes best practice | `perplexity_ask`: "What are current best practices for [domain] in 2026?" | "The current thinking has shifted — [data]. Does that change your approach?" |
| User names a competitor | `perplexity_ask`: "What is [competitor]'s brand strategy and positioning?" | "Their brand is built around [Y]. You're either competing head-on or flanking. Which?" |
| User picks a framework/approach | `perplexity_reason`: "Compare [framework] vs alternatives for [use case]" | "Have you considered [Z]? It trades off [A] for [B], which fits your constraint about [C]" |
| User makes a bold claim | `perplexity_ask`: "[specific claim] — is this supported by data?" | Challenge or confirm — "that's backed up by [source]" or "the data suggests otherwise" |
| User exploring a new market | `perplexity_research`: "Comprehensive analysis of [market segment]" | Deep context for sustained pushback across multiple sub-topics |

**Rules for search behavior:**
- Search 1-3 times per major topic shift, not every exchange
- Prefer specific queries over broad ones — "SaaS project management tool brand positioning" not "brand strategy"
- Never dump raw search results — synthesize into a challenge or data point
- If search returns nothing useful, don't mention it — fall back to principle-based pushback
- Cite sources naturally: "Basecamp built their brand on being the anti-enterprise tool — is that a lane you want?"
- Search is a supporting tool, not the main event — conversation flow always takes priority
- **Log every search to findings.md immediately** — tool used, query, key data points, and how it was used (see below)

**Examples of grounded pushback (good):**
- "You said 'simple and clean' — I just checked, and Notion, Linear, and Coda all use those exact words. What makes your 'simple' different from theirs?"
- "The market data shows [segment] growing at [X]% — but the tools targeting it are all going premium. Your pricing undercuts that. Intentional or oversight?"
- "I looked at how [competitor] handles onboarding — they skip the setup wizard entirely. Worth considering whether your 'guided setup' is actually a friction point."

**Examples of bad search behavior (avoid):**
- "Let me search for that..." [breaks conversation flow]
- "According to my research, here are 5 findings:" [too formal, not sparring]
- Searching after every user message [disruptive]
- Presenting search results as authoritative truth [it's a conversation, not a report]

### Live Transcription

Append to `brainstorm-transcript-{date}.md` continuously during the session:
- Create the transcript file at session start (header + context section)
- **After each exchange**, append the user message and Claude's response
- At minimum, append every 2 exchanges (2-Action Rule) — but every exchange is preferred
- Include research results inline where they influenced the response
- On session end, append the closing sections (Decisions Made, Research Conducted, Open Questions, Next Steps)

This is non-negotiable. The transcript is the primary artifact. If context compresses mid-session, the transcript is how we recover.

### Real-time Tracking
After every 2 discussion rounds, update findings.md:

```markdown
## Brainstorm: {topic} — Session {date}

### Key Points So Far
- [point 1]
- [point 2]

### Trade-offs Explored
- Option A vs Option B: [trade-off summary]

### Research Log
- **Tool:** perplexity_ask | **Query:** "[query]"
  **Found:** [key data point or insight]
  **Used as:** [how it shaped the pushback]
- **Tool:** perplexity_reason | **Query:** "[query]"
  **Found:** [key data point or insight]
  **Used as:** [confirmed/challenged user's claim about X]

### Open Questions
- [question 1]
```

**Research Log rule:** Every Perplexity call gets an entry in findings.md — tool used, query, what was found, and how it was used. This preserves research across `/compact` and makes it available to `brainstorm-decision-writer` later.

## Step 4: Live Transcript (continuous, not end-of-session)

The transcript is written **during** the brainstorm, not after it ends.
This protects against context compression (`/compact`) and long sessions where early exchanges would be lost.

```
transcript_path = .ai/brainstorm/{topic_slug}/brainstorm-transcript-{date}.md

# Create the file at session start with the header.
# Append each exchange as it happens — every user message + claude response gets appended immediately.
# The 2-Action Rule applies: append at least every 2 exchanges, but preferably after each one.

# Transcript format:
---

## Step 0: Initialize Trace (mandatory if tracing enabled)

Read `state.yml` and check `trace.enabled`. If `true`:

1. Create trace file: `.ai/projects/[name]/traces/{skill-name}-{ISO-timestamp}.yml`
2. Write `_meta` block: schema `"trace"`, version `"1.1.0"`, skill, module, project, started_at, trace_mode
3. Initialize empty `steps: []`, `checkpoint_result: {}`, `quality_summary: {}`, `reflections: {}`

**Schema v1.1.0 — required fields per step:**
- `decision`, `reasoning`, `uncertainty` (always required)
- `observation` — what happened vs expected; surprises, gaps, confirmations
- `improvement_idea` — actionable suggestion for the skill/pipeline (if any)
- `design_decision` — lasting choice beyond this run (if any)

**Trace-level `reflections` section (REQUIRED — Stop hook enforces):**
```yaml
reflections:
  observations: ["at least one observation about the run"]
  improvement_ideas: []   # optional but encouraged
  design_decisions: []    # optional, only for lasting choices
```

The Stop hook will BLOCK completion if reflections section is missing.

---

topic: "{topic}"
date: "{date}"
project: "{project_name}"
participants: [user, claude]
---

# Brainstorm: {topic}

## Context
[Summary of relevant past decisions and constraints]

## Discussion

### {Sub-topic 1}
**User:** [user's point]
**Claude:** [response/challenge]
**User:** [follow-up]
...

### {Sub-topic 2}
...

## Research Conducted
| Query | Key Finding | Impact on Discussion |
|-------|------------|---------------------|
| [search query] | [what was found] | [how it changed/confirmed the direction] |

## Decisions Made
- [Decision 1]: [rationale] (confidence: high/medium/low)
- [Decision 2]: [rationale] (confidence: high/medium/low)

## Open Questions
- [Question 1]
- [Question 2]

## Next Steps
- [Action 1]
- [Action 2]
```

## Step 5: Update State

```yaml
# brainstorm-state.yml
topic: "{topic}"
status: "completed"  # or "paused" if user wants to continue later
started_at: "{start_time}"
completed_at: "{end_time}"
session_date: "{date}"
transcript: "brainstorm-transcript-{date}.md"
topics:
  - name: "{sub-topic-1}"
    status: "decided"  # decided | open | deferred
  - name: "{sub-topic-2}"
    status: "open"
open_questions:
  - "{question 1}"
key_points:
  - "{point 1}"
  - "{point 2}"
decisions_count: 0  # actual count, decisions are in decisions.yml
next_steps:
  - "Run brainstorm-decision-writer to extract formal decisions"
```

## Step 6: Checkpoint Verification

```
# Check 1: transcript_written
assert exists(.ai/brainstorm/{topic_slug}/brainstorm-transcript-{date}.md)
assert file_size > 0

# Check 2: state_updated
state = read_yaml(.ai/brainstorm/{topic_slug}/brainstorm-state.yml)
assert "status" in state
assert "topics" in state
assert "open_questions" in state

# Check 3: topics_captured
assert len(state.topics) >= 1
```

## Error Handling

| Error | Action |
|-------|--------|
| .ai/brainstorm/ doesn't exist | Create directory |
| Past decisions.yml parse error | Warn and continue without that topic's decisions |
| User ends session abruptly | Save transcript so far, set state to "paused" |
| Topic slug collision | Append session date to make unique |
| Write permission error | Log to state.yml errors, report to user |

Log all errors to `state.yml` errors array. Before retrying, check errors array for previous attempts — never repeat a failed approach.

---

## Trace Finalization (mandatory if tracing enabled)

Before completing, verify your trace file has:
1. All steps recorded (written every 2 steps per the 2-Action Rule)
2. `checkpoint_result` with pass/fail status
3. `quality_summary` with avg_uncertainty and recommendation
4. `reflections` section with at least one observation (REQUIRED — Stop hook enforces this)
5. Step-level `observation`, `improvement_idea`, or `design_decision` where applicable

The Stop hook will BLOCK completion if tracing is enabled and the trace file
is missing or has no `reflections:` section.
