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
