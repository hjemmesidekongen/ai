# Brainstorm Decision Writer — Detailed Process

## Step 1: Locate Transcript

```
# Determine topic from argument or most recent session
if topic_arg provided:
  topic_dir = .ai/brainstorm/{topic_arg}/
else:
  # Find most recently modified brainstorm-state.yml
  topic_dir = most_recent(.ai/brainstorm/*/brainstorm-state.yml).parent

if not exists(topic_dir):
  ERROR: "No brainstorm topic directory found"
  STOP

# Find latest transcript
transcripts = glob(topic_dir/brainstorm-transcript-*.md)
if len(transcripts) == 0:
  ERROR: "No transcripts found in {topic_dir}"
  HINT: "Run brainstorm-session first"
  STOP

transcript_path = most_recent(transcripts)
Report: "Processing transcript: {transcript_path}"
```

## Step 2: Read Transcript and State

```
transcript = read(transcript_path)
state = read_yaml(topic_dir/brainstorm-state.yml)

# Extract frontmatter from transcript
topic = transcript.frontmatter.topic
date = transcript.frontmatter.date

Report: "Topic: {topic}, Date: {date}"
Report: "Key points in state: {len(state.key_points)}"
```

## Step 3: Extract Decisions

Scan the transcript for decision patterns:

```
# Decision indicators in transcript text:
# - Explicit: "Decision:", "We decided", "Let's go with", "The approach is"
# - Implicit: conclusions after trade-off analysis, final positions after debate
# - State-referenced: key_points that represent choices

decisions = []
for each decision_point found:
  decision = {
    id: "{topic_slug}-{NNN}",  # e.g., "auth-strategy-001"
    domain: [relevant_domains],  # e.g., ["dev", "security"]
    decision: "concise decision statement",
    confidence: "high|medium|low",
    context: "why this was decided, trade-offs considered",
    session_date: date
  }
  decisions.append(decision)
```

### Domain Classification

Map decisions to domains for later filtering by decision-reader:

| Domain | Applies When |
|--------|-------------|
| brand | Brand identity, voice, visual identity |
| design | UI/UX, components, layout, tokens |
| content | Copy, messaging, tone |
| dev | Architecture, tech stack, patterns |
| devops | Deployment, CI/CD, infrastructure |
| security | Auth, data protection, compliance |
| strategy | Business logic, product direction |

A decision can have multiple domains (e.g., `["dev", "security"]`).

### Confidence Levels

| Level | Criteria |
|-------|----------|
| high | Explicit agreement, clear rationale, no open concerns |
| medium | General agreement but with caveats or conditions |
| low | Tentative — needs validation, more data, or revisiting |

**Save to findings.md after every 2 decisions extracted (2-Action Rule):**

```markdown
## Decision Extraction Progress
- Decisions found so far: {count}
- Latest: {decision.id} — {decision.decision} (confidence: {confidence})
```

## Step 4: Write decisions.yml

```yaml
# decisions.yml — append to existing, never overwrite
# Existing entries preserved, new entries appended

- id: "auth-strategy-001"
  domain: [dev, security]
  decision: "Use JWT with httpOnly cookies for session management"
  confidence: "high"
  context: "Evaluated JWT vs session cookies vs OAuth. JWT chosen for statelessness and mobile support. httpOnly mitigates XSS."
  session_date: "2026-03-04"

- id: "auth-strategy-002"
  domain: [dev]
  decision: "Implement refresh token rotation"
  confidence: "medium"
  context: "Agreed on rotation for security but details on token lifetime TBD."
  session_date: "2026-03-04"
```

### Append Logic

```
existing = read_yaml(topic_dir/decisions.yml) or []
existing_ids = [d.id for d in existing]

for decision in new_decisions:
  if decision.id in existing_ids:
    # ID collision — regenerate
    decision.id = "{topic_slug}-{max_existing_num + 1}"
  existing.append(decision)

write_yaml(topic_dir/decisions.yml, existing)
```

## Step 5: Update Brainstorm State

```yaml
# Update brainstorm-state.yml
status: "decided"  # or keep "completed" if already set
decisions_count: {total count in decisions.yml}
last_extraction: "{now}"
```

## Step 6: Checkpoint Verification

```
# Check 1: decisions_yml_exists
assert exists(topic_dir/decisions.yml)

# Check 2: decision_fields_complete
decisions = read_yaml(topic_dir/decisions.yml)
for d in decisions:
  assert "id" in d and d.id is non-empty
  assert "domain" in d and isinstance(d.domain, list) and len(d.domain) >= 1
  assert "decision" in d and d.decision is non-empty
  assert "confidence" in d and d.confidence in ["high", "medium", "low"]
  assert "context" in d and d.context is non-empty
  assert "session_date" in d

# Check 3: no_duplicate_ids
ids = [d.id for d in decisions]
assert len(ids) == len(set(ids))
```

## Error Handling

| Error | Action |
|-------|--------|
| No transcript found | Error with hint to run brainstorm-session |
| Transcript has no decisions section | Scan full text for implicit decisions |
| decisions.yml parse error | Back up corrupted file, create fresh |
| ID collision after regeneration | Use UUID suffix |
| Empty extraction (0 decisions) | Warn user, suggest re-reading transcript |

Log all errors to `state.yml` errors array. Before retrying, check errors array for previous attempts — never repeat a failed approach.

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


## Trace Finalization (mandatory if tracing enabled)

Before completing, verify your trace file has:
1. All steps recorded (written every 2 steps per the 2-Action Rule)
2. `checkpoint_result` with pass/fail status
3. `quality_summary` with avg_uncertainty and recommendation
4. `reflections` section with at least one observation (REQUIRED — Stop hook enforces this)
5. Step-level `observation`, `improvement_idea`, or `design_decision` where applicable

The Stop hook will BLOCK completion if tracing is enabled and the trace file
is missing or has no `reflections:` section.
