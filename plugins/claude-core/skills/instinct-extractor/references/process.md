# instinct-extractor: Process Reference

## Pattern identification methodology

### Step 1: Group by sequence_key

Observations with the same `sequence_key` (hash of the last 3 tools in order) represent
a repeated workflow. High-frequency sequence keys are the strongest signal.

```
sequence_key → count of observations → candidate if count >= 3
```

### Step 2: Group by context_type

Within each sequence group, look at `context_type` distribution. A sequence that
appears consistently in one context type is more specific (and more useful) than a
cross-context one.

### Step 3: Success vs. error split

For each candidate sequence:
- success_count = observations where outcome = "success"
- error_count = observations where outcome = "error"
- If error_count >= 2 and follows same sequence: **contradiction candidate**

### Step 4: Extract instinct text

For each qualifying pattern, write a one-sentence `pattern_description`:
- Subject: "When [context]"
- Action: "the pattern [tool sequence] [consistently/often]"
- Outcome: "[succeeds/fails/produces X]"

Example:
> "When debugging (context_type=debug), a Grep → Read → Bash sequence consistently
> resolves errors without requiring multiple retries."

### Step 5: Assign initial confidence

| Signal | Starting confidence |
|--------|-------------------|
| evidence_count >= 10, no contradictions | 0.9 |
| evidence_count 5–9, <= 1 contradiction | 0.8 |
| evidence_count 3–4, no contradictions | 0.75 |
| evidence_count 3–4, 1+ contradiction | 0.65 |

### Step 6: Apply confidence decay for contradictions

For existing instincts being updated:
```
new_confidence = old_confidence - (new_contradictions * 0.1)
if new_confidence < 0.2: status = decayed
```

### Instinct ID convention

`{domain}-{3-word-slug}` — e.g., `debug-grep-read-bash`, `plan-artifact-handoff`, `skill-tdd-baseline`

Domain values: `debug | plan | git | skill | hook | agent | context | general`

## instincts.yml format

```yaml
instincts:
  - id: debug-grep-read-bash
    domain: debug
    pattern_description: >
      When debugging, a Grep → Read → Bash tool sequence resolves errors
      without requiring retries.
    confidence: 0.85
    evidence_count: 12
    contradiction_count: 1
    first_seen: "2026-03-09T10:00:00Z"
    last_seen: "2026-03-09T14:00:00Z"
    status: active
    evolved_to: null
```

## What NOT to extract

- One-off patterns (single observation) — noise
- Patterns that span domains with no clear signal — too vague
- Error observations with no sequence pattern — can't form an instinct from a single failure
- Instincts already marked `evolved` — skip, don't re-extract

## Preservation rule

When updating instincts.yml, always preserve instincts not covered by the current
observation window. Absence of evidence is not contradicting evidence.
