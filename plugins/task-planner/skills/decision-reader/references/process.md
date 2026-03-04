# Decision Reader — Full Process

## When This Skill Runs

1. **During interview skills** — identity-interview, audience-personas,
   project-interview, etc. call this skill to check if the user already
   made relevant decisions during brainstorming.
2. **Before asking a question** — an interview skill calls `check_decision`
   to see if a brainstorm decision already answers the question.
3. **At skill start** — an interview skill calls `load_decisions` once to
   get all relevant decisions for its domain, then uses them throughout.

## Input

Two modes of invocation:

### Mode 1: Load All Decisions for Domains

```yaml
project: "[project-name]"
domains:
  - "brand-identity"
  - "brand-voice"
```

### Mode 2: Check Single Decision

```yaml
project: "[project-name]"
field: "mission"
domains: ["brand-identity"]
```

---

## Step 1: Locate decisions.yml

Search for decisions in priority order:

1. `.ai/brainstorm/[project-name]/decisions.yml`
2. `.ai/brands/[project-name]/decisions.yml`

Use the first file found. If neither exists, return an empty result
immediately — this is NOT an error. Many projects won't have brainstorm
decisions, and that's fine.

## Step 2: Parse and Filter

Read the YAML file. Expected format:

```yaml
project: "[project-name]"
created_at: "[ISO timestamp]"
updated_at: "[ISO timestamp]"
source_sessions:
  - "brainstorm-transcript-[date].md"

decisions:
  - id: "d1"
    domain: ["brand-identity"]
    decision: "Company name will be Acme"
    confidence: "high"
    context: "Short, memorable, universal appeal"
    session_date: "[date]"
```

Filter the `decisions` array: keep only decisions where at least one entry
in the decision's `domain` list matches one of the requested domains.

## Step 3: Group by Confidence

Sort filtered decisions into confidence buckets:

```yaml
high: [decisions with confidence "high"]
medium: [decisions with confidence "medium"]
low: [decisions with confidence "low"]
```

Within each bucket, preserve the original order (by id).

---

## Output Formats

### Mode 1: Load All Decisions

```yaml
project: "[project-name]"
source: ".ai/brainstorm/[project-name]/decisions.yml"
decisions_found: true
total: 5
by_confidence:
  high:
    - id: "d1"
      domain: ["brand-identity"]
      decision: "Company name will be Acme"
      confidence: "high"
      context: "Short, memorable, universal appeal"
  medium:
    - id: "d3"
      domain: ["brand-identity"]
      decision: "Position as premium but accessible"
      confidence: "medium"
      context: "Not luxury, not budget — approachable quality"
  low: []
```

When no decisions exist:

```yaml
project: "[project-name]"
source: null
decisions_found: false
total: 0
by_confidence:
  high: []
  medium: []
  low: []
```

### Mode 2: Check Single Decision

```yaml
found: true
decision:
  id: "d1"
  domain: ["brand-identity"]
  decision: "Company name will be Acme"
  confidence: "high"
  context: "Short, memorable, universal appeal"
```

When no matching decision exists:

```yaml
found: false
decision: null
```

---

## check_decision: Field-to-Decision Matching

The `check_decision` method uses keyword matching to find a decision
relevant to a specific interview field. This is intentionally fuzzy —
decisions are written in natural language, not keyed to field names.

### Matching Strategy

1. **Domain filter first** — only consider decisions in the requested domains
2. **Keyword extraction** — extract keywords from the field name:
   - `"mission"` → keywords: `["mission", "purpose", "why"]`
   - `"target_audience"` → keywords: `["audience", "target", "customer", "user"]`
   - `"brand_name"` → keywords: `["name", "brand name", "company name"]`
   - `"tone"` → keywords: `["tone", "voice", "speak", "communicate"]`
   - `"colors"` → keywords: `["color", "palette", "hue"]`
   - `"typography"` → keywords: `["font", "typeface", "typography"]`
   - `"positioning"` → keywords: `["position", "differentiat", "compete", "stand out"]`
   - `"keywords"` → keywords: `["keyword", "search term", "SEO", "rank"]`
3. **Score each decision** — count how many keywords appear in the decision
   text (case-insensitive). Also check the `context` field.
4. **Return the best match** — the decision with the highest keyword score,
   if the score is >= 1. If no decision scores >= 1, return `found: false`.
5. **Tie-breaking** — if multiple decisions score equally, prefer higher
   confidence, then lower id number.

### Keyword Map

Interview skills can pass custom keywords to override the defaults:

```yaml
field: "mission"
domains: ["brand-identity"]
keywords: ["mission", "purpose", "why we exist", "reason"]
```

If `keywords` is provided, use those instead of the built-in map.

---

## How Calling Skills Should Use Results

The calling interview skill decides how to present the decision based on
confidence level:

### High Confidence

The decision is locked in. Present it as a confirmation:

```
"From your brainstorm: [decision text]

Confirm this? [Y/n]"
```

If confirmed, skip the question entirely and use the decision value.

### Medium Confidence

The user was leaning this way but left room for change:

```
"You were leaning toward: [decision text]

Use this, or do you want to explore further?"
```

If accepted, use it. If the user wants to explore, ask the question
normally with the decision as context.

### Low Confidence

Just an idea — use it as a conversation starter:

```
"You mentioned: [decision text]

Let's discuss this further. [proceed with normal question]"
```

### Not Found

No relevant decision exists. Ask the question from scratch — this is the
normal behavior without brainstorming.

---

## Checkpoint (full detail)

```
type: data_validation
required_checks:
  - name: "finds_existing_decisions"
    verify: "Returns decisions when decisions.yml exists at the expected path"
    fail_action: "Check file path resolution logic"
  - name: "empty_when_missing"
    verify: "Returns empty result (decisions_found: false) when no decisions.yml exists — NOT an error"
    fail_action: "Ensure missing file returns empty result, not error"
  - name: "domain_filtering"
    verify: "Only returns decisions matching the requested domains"
    fail_action: "Fix domain filter — check array intersection logic"
  - name: "multiple_per_domain"
    verify: "Returns all matching decisions per domain, not just the first"
    fail_action: "Remove any early-return logic in domain filtering"
  - name: "priority_order"
    verify: "Checks .ai/brainstorm/ before .ai/brands/ and uses the first found"
    fail_action: "Fix search order in Step 1"
on_fail: "Fix the failing check and re-validate."
on_pass: "Decision reader is working correctly."
```

## What This Skill Does NOT Do

- It does NOT write decisions.yml (that's brainstorm-decision-writer)
- It does NOT create or modify brainstorm-state.yml
- It does NOT make decisions for the user
- It does NOT skip questions automatically — it provides data, the calling skill decides
- It does NOT require a brainstorm to have happened — missing decisions is a normal case
