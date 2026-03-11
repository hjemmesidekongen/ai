---
name: tier-assignment
description: >
  Evaluates decomposed subtasks using a weighted 5-factor risk matrix and assigns
  model tiers (junior/senior/principal). Produces per-subtask justifications
  to support dispatch decisions and cost optimization.
user_invocable: false
interactive: false
model_tier: senior
depends_on:
  - task-decomposer
triggers:
  - "assign tier"
  - "tier assignment"
  - "model tier"
  - "risk assessment"
reads:
  - ".ai/tasks/decomposed/*.yml"
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "tier_assigned"
      verify: "Every subtask has a tier (junior, senior, or principal) and justification"
      fail_action: "Re-evaluate subtasks missing tier assignment"
    - name: "score_bounds"
      verify: "Weighted score falls within valid range (5.0 - 25.0)"
      fail_action: "Recheck factor values — each must be 1-5"
    - name: "cost_sanity"
      verify: "No more than 30% of subtasks assigned to principal tier"
      fail_action: "Review principal assignments — split complex subtasks to reduce tier"
  on_fail: "Tier assignments invalid — correct before dispatch"
  on_pass: "Tier assignments valid — ready for agent-dispatcher"
_source:
  origin: "smedjen"
  inspired_by: "agents-main tier model + agency agent-dispatcher"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Weighted risk matrix with explicit factor weights and tier thresholds"
---

# Tier Assignment

Maps each decomposed subtask to a model tier using a weighted 5-factor risk score.

## Risk Matrix

| Factor | Weight | What it measures |
|--------|--------|-----------------|
| Scope | 1.0 | How many files/modules touched |
| Reversibility | 0.8 | How hard to undo if wrong |
| Ambiguity | 1.2 | How unclear the requirements are |
| Impact | 1.0 | Blast radius of a mistake |
| Dependencies | 1.0 | Coupling to other subtasks |

Each factor scored 1-5. Weighted sum determines tier:

| Score Range | Tier | Model |
|-------------|------|-------|
| 5.0 - 10.0 | junior | haiku |
| 10.1 - 18.0 | senior | sonnet |
| 18.1 - 25.0 | principal | opus |

## Rules

- Tier is a recommendation, not a constraint. Dispatcher may escalate on failure.
- If a subtask touches security-sensitive files (auth, crypto, secrets), floor the tier at senior.
- If a subtask has 3+ downstream dependents, floor the tier at senior (high-impact node).
- Justification must reference the dominant risk factor driving the assignment.
- Attach the tier + justification directly to the subtask in the decomposition YAML.

## Override Triggers

Some patterns auto-escalate regardless of score:
- Database migrations: principal
- Public API changes: senior minimum
- Deletion of shared modules: principal

See `references/process.md` for scoring algorithm, examples, and edge cases.
