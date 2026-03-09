---
name: instinct-extractor
description: >
  Extract atomic instincts from raw interaction observations. Reads
  .ai/instincts/observations.jsonl, identifies recurring patterns,
  and writes structured instincts to .ai/instincts/instincts.yml.
  Updates confidence scores and marks contradictions.
  Use when: reviewing accumulated observations, running the learning
  pipeline, updating instinct confidence, extracting patterns from recent
  session data, or seeding new instincts before instinct-evolve.
model_tier: junior
depends_on: []
---

# instinct-extractor

Reads raw tool call observations and extracts recurring behavioral patterns
as atomic instincts with confidence weights.

## When to run

- After 50+ new observations have accumulated
- Before running instinct-evolve
- When a new domain of work has been active for several sessions

## Steps

1. **Load observations**
   - Read `.ai/instincts/observations.jsonl` (last 200 lines)
   - Read existing `.ai/instincts/instincts.yml` (to update vs. create)
   - Read schema: `plugins/claude-core/resources/instincts-schema.yml`

2. **Identify patterns** (see `references/process.md` for methodology)
   - Group observations by `context_type` and `sequence_key`
   - Find sequences that appear 3+ times → candidate instincts
   - Find error outcomes that follow the same sequence → contradiction candidates

3. **Update instincts.yml**
   - For each candidate: create new instinct or increment `evidence_count`
   - For contradictions: increment `contradiction_count`, apply confidence decay
   - Set `status: decayed` for instincts below 0.2 confidence
   - Preserve existing instincts not in current observation window

4. **Checkpoint**
   Before writing: verify each instinct has all required fields from schema.
   Verdict: `instincts_updated: N` or `instincts_decayed: N`.

5. **Output**
   - Write updated `.ai/instincts/instincts.yml`
   - Report: new instincts added, updated, decayed, total active

## Output format

```
Instinct extraction complete.
New: N | Updated: N | Decayed: N | Total active: N
Ready for instinct-evolve (N qualify for evolution).
```
