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
user_invocable: false
interactive: false
depends_on: []
triggers:
  - "extract instincts"
  - "learning pipeline"
  - "process observations"
  - "update instinct confidence"
  - "pattern extraction"
reads:
  - ".ai/instincts/observations.jsonl"
  - ".ai/instincts/instincts.yml"
  - "plugins/claude-core/resources/instincts-schema.yml"
writes:
  - ".ai/instincts/instincts.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "schema_compliant"
      verify: "Each instinct has all required fields from instincts-schema.yml"
      fail_action: "Add missing fields before writing instincts.yml"
    - name: "instincts_updated"
      verify: "At least one instinct created, updated, or decayed"
      fail_action: "Re-run pattern identification with lower threshold"
  on_fail: "Fix schema issues before writing output."
  on_pass: "Report counts: new, updated, decayed, total active."
model_tier: junior
_source:
  origin: "claude-core"
  inspired_by: "observation-recorder.sh + instincts-schema.yml"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "New skill for learning pipeline. Reads observations, outputs structured instincts."
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

4. **Output** — Write updated `.ai/instincts/instincts.yml`. Report: new, updated, decayed, total active.

Output: `Instinct extraction complete. New: N | Updated: N | Decayed: N | Total active: N`
