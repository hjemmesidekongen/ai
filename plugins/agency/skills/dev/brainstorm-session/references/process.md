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

### Real-time Tracking
After every 2 discussion rounds, update findings.md:

```markdown
## Brainstorm: {topic} — Session {date}

### Key Points So Far
- [point 1]
- [point 2]

### Trade-offs Explored
- Option A vs Option B: [trade-off summary]

### Open Questions
- [question 1]
```

## Step 4: Write Transcript

```
transcript_path = .ai/brainstorm/{topic_slug}/brainstorm-transcript-{date}.md

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
