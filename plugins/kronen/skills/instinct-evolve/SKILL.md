---
name: instinct-evolve
description: >
  Review qualified instincts and propose evolution into skills, rules, or
  memory entries. Reads .ai/instincts/instincts.yml and promotes high-confidence
  patterns to durable artifacts. Human approves each promotion.
  Use when: promoting instincts to skills, promoting patterns to CLAUDE.md rules,
  running the evolution phase of the learning pipeline, reviewing which instincts
  qualify for evolution, or closing out the instinct review cycle.
user_invocable: false
interactive: true
depends_on: [instinct-extractor]
triggers:
  - "promote instinct"
  - "evolve instinct"
  - "instinct to skill"
  - "instinct to rule"
  - "instinct review cycle"
reads:
  - ".ai/instincts/instincts.yml"
writes:
  - ".ai/instincts/instincts.yml"
  - "MEMORY.md (conditional)"
  - "CLAUDE.md (conditional)"
checkpoint:
  type: data_validation
  required_checks:
    - name: "evolved_to_set"
      verify: "All approved instincts have evolved_to field set"
      fail_action: "Set evolved_to on each approved promotion"
    - name: "human_approved"
      verify: "Each promotion was presented to and approved by user"
      fail_action: "Present proposals before applying changes"
  on_fail: "Do not apply promotions without user approval."
  on_pass: "Report counts: qualified, proposed, approved, rejected."
model_tier: senior
_source:
  origin: "kronen"
  inspired_by: "instinct-extractor + skill-creator promotion flow"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "New skill for learning pipeline. Promotes qualified instincts to durable artifacts."
---

# instinct-evolve

Reviews instincts that meet the evolution threshold and proposes promotion
to durable artifacts. Requires human approval for each promotion.

## Evolution criteria (from instincts-schema.yml)

- `confidence >= 0.75`
- `evidence_count >= 3`
- `status: active`
- `evolved_to: null`

## Steps

1. **Load instincts**
   - Read `.ai/instincts/instincts.yml`
   - Filter to qualifying instincts (criteria above)
   - If none qualify: report count + highest-confidence instinct. Stop.

2. **Propose evolution targets** (see `references/process.md` for rules)
   - MEMORY.md entry — facts, counts, paths
   - CLAUDE.md rule — behavioral patterns
   - New skill/command — multi-step workflows
   - Discard — if not generalizable

3. **Present proposals** — show each instinct with target and draft artifact. Wait for approval.

4. **Apply approved promotions** — write artifacts, set `status: evolved`, `evolved_to: <target>`.

Output: `Instinct evolution complete. Qualified: N | Proposed: N | Approved: N | Rejected: N`
