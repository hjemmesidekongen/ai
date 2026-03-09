---
name: instinct-evolve
description: >
  Review qualified instincts and propose evolution into skills, rules, or
  memory entries. Reads .ai/instincts/instincts.yml and promotes high-confidence
  patterns to durable artifacts. Human approves each promotion.
  Use when: promoting instincts to skills, promoting patterns to CLAUDE.md rules,
  running the evolution phase of the learning pipeline, reviewing which instincts
  qualify for evolution, or closing out the instinct review cycle.
model_tier: senior
depends_on: [instinct-extractor]
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

2. **For each qualifying instinct, propose evolution target**
   (see `references/process.md` for target selection rules)
   - MEMORY.md entry — for facts, counts, version numbers, file paths
   - CLAUDE.md rule — for behavioral patterns that should always apply
   - New skill — for multi-step workflows worth capturing
   - New command — for user-invocable workflows
   - Discard — if the instinct isn't generalizable

3. **Present proposals to user**
   Show each instinct with its proposed target and a draft of the artifact.
   Wait for approval/rejection/modification per instinct.

4. **Apply approved promotions**
   - MEMORY.md / CLAUDE.md: append the entry at the appropriate section
   - New skill: create the skeleton SKILL.md (use skill-creator)
   - New command: note for command-creator
   - Update instinct: set `status: evolved`, `evolved_to: <target>`

5. **Checkpoint**
   Verify `evolved_to` is set on all approved instincts before reporting done.

## Output format

```
Instinct evolution complete.
Qualified: N | Proposed: N | Approved: N | Rejected: N
Evolved to: [MEMORY.md x2] [CLAUDE.md x1] [new skill x1]
```
