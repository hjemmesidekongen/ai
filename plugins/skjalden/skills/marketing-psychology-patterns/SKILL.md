---
name: marketing-psychology-patterns
description: >
  Marketing psychology and strategy patterns — PLFS scoring for behavioral models,
  MFS scoring for marketing ideas, journey-stage model selection, ethical guardrails,
  and stage-based prioritization (pre-launch through scale).
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "marketing psychology"
  - "marketing strategy"
  - "behavioral models"
  - "conversion psychology"
  - "marketing ideas"
  - "growth marketing"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "models_scored"
      verify: "Every recommended mental model has a PLFS score, every marketing idea has an MFS score"
      fail_action: "Score all recommendations before presenting them"
    - name: "max_five_recommendations"
      verify: "No more than 5 models or ideas recommended at once"
      fail_action: "Reduce to top 5 by score — eliminate lowest PLFS/MFS items"
    - name: "ethical_guardrails_checked"
      verify: "No dark patterns, false scarcity, hidden defaults, or exploitation of vulnerable users"
      fail_action: "Remove unethical recommendations — if ethical risk > leverage, do not recommend"
    - name: "behavior_mapped"
      verify: "Each model maps to a specific behavior and a real surface (page, CTA, flow)"
      fail_action: "Connect each model to where it applies — no abstract theory"
  on_fail: "Marketing recommendations lack scoring discipline or ethical checks"
  on_pass: "Marketing psychology applied with scoring, ethics, and specificity"
_source:
  origin: "smedjen"
  inspired_by: "antigravity-awesome-skills/marketing-psychology + marketing-ideas"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Combined psychology and strategy scoring into one knowledge skill"
---

# marketing-psychology-patterns

## PLFS — Psychological Leverage & Feasibility Score

Score every mental model before recommending. Five dimensions (1-5 each): **Behavioral Leverage** (influence strength), **Context Fit** (product/audience/stage match), **Implementation Ease** (cost to apply correctly), **Speed to Signal** (time to observe impact), **Ethical Safety** (manipulation risk). Formula: `PLFS = (Leverage + Fit + Speed + Ethics) - Implementation Cost`. Range: -5 to +15. Score 12-15: apply immediately. 8-11: prioritize. 4-7: test carefully. 1-3: defer. ≤0: do not recommend.

## MFS — Marketing Feasibility Score

Score every marketing idea. Five dimensions (1-5): **Impact**, **Fit**, **Speed to Signal** (higher = better) minus **Effort**, **Cost** (lower = better). Formula: `MFS = (Impact + Fit + Speed) - (Effort + Cost)`. Range: -7 to +13. Score 10-13: do now. 7-9: prioritize. 4-6: test selectively. 1-3: defer. ≤0: do not recommend.

## Journey-Stage Models

**Awareness**: Mere Exposure, Availability Heuristic, Authority Bias, Social Proof. **Consideration**: Framing Effect, Anchoring, Jobs to Be Done, Confirmation Bias. **Decision**: Loss Aversion, Paradox of Choice, Default Effect, Risk Reversal. **Retention**: Endowment Effect, IKEA Effect, Status-Quo Bias, Switching Costs.

## Stage Bias for Ideas

**Pre-Launch**: speed > impact, favor waitlists/early access/communities. **Early**: speed + cost sensitivity, favor SEO/founder-led/comparisons. **Growth**: impact > speed, favor paid acquisition/partnerships/PLG loops. **Scale**: impact + defensibility, favor brand/international/acquisitions.

## Ethical Guardrails (Non-Negotiable)

Forbidden: dark patterns, false scarcity, hidden defaults, exploiting vulnerable users. Required: transparency, reversibility, informed choice, user benefit alignment. If ethical risk exceeds leverage, do not recommend.

## Selection Rules

Never recommend more than 5 models or ideas. Never recommend PLFS ≤ 0 or MFS ≤ 0. Each model must map to a specific behavior and real surface. Prefer high-signal, low-effort tests first.

See `references/process.md` for the mental model library, output format templates, example scorings, and the 140-idea marketing library categories.
