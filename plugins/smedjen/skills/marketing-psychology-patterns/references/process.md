# Marketing Psychology Patterns — Detailed Reference

## PLFS Scoring Template

### Dimensions (1-5 each)

| Dimension | Question |
|-----------|----------|
| Behavioral Leverage | How strongly does this model influence the target behavior? |
| Context Fit | How well does it fit the product, audience, and stage? |
| Implementation Ease | How easy is it to apply correctly? (inverted: high = easy) |
| Speed to Signal | How quickly can we observe impact? |
| Ethical Safety | Low risk of manipulation or backlash? |

### Formula
```
PLFS = (Leverage + Fit + Speed + Ethics) - Implementation Cost
Range: -5 to +15
```

### Interpretation
| PLFS | Meaning | Action |
|------|---------|--------|
| 12-15 | High-confidence lever | Apply immediately |
| 8-11 | Strong | Prioritize |
| 4-7 | Situational | Test carefully |
| 1-3 | Weak | Defer |
| ≤ 0 | Risky / low value | Do not recommend |

### Example: Paradox of Choice (Pricing Page)
| Factor | Score |
|--------|-------|
| Leverage | 5 |
| Fit | 5 |
| Speed | 4 |
| Ethics | 5 |
| Implementation Cost | 2 |

PLFS = (5 + 5 + 4 + 5) - 2 = 17 (capped at 15)
Action: Extremely high-leverage, low-risk. Apply immediately.

## MFS Scoring Template

### Dimensions (1-5 each)

| Dimension | Question | Direction |
|-----------|----------|-----------|
| Impact | If this works, how meaningful is the upside? | Higher = better |
| Fit | How well does it match product, ICP, and stage? | Higher = better |
| Speed to Signal | How quickly will we know if it's working? | Higher = better |
| Effort | How much execution time/complexity? | Lower = better |
| Cost | How much cash to test meaningfully? | Lower = better |

### Formula
```
MFS = (Impact + Fit + Speed) - (Effort + Cost)
Range: -7 to +13
```

### Interpretation
| MFS | Meaning | Action |
|-----|---------|--------|
| 10-13 | Extremely high leverage | Do now |
| 7-9 | Strong opportunity | Prioritize |
| 4-6 | Viable but situational | Test selectively |
| 1-3 | Marginal | Defer |
| ≤ 0 | Poor fit | Do not recommend |

### Example: Programmatic SEO (Early-stage SaaS)
| Factor | Score |
|--------|-------|
| Impact | 5 |
| Fit | 4 |
| Speed | 2 |
| Effort | 4 |
| Cost | 3 |

MFS = (5 + 4 + 2) - (4 + 3) = 4
Action: Viable, but not a short-term win. Test selectively.

## Mental Model Library by Journey Stage

### Awareness Stage
| Model | Application | Typical PLFS |
|-------|------------|-------------|
| Mere Exposure | Repeated brand visibility across channels | 8-10 |
| Availability Heuristic | Make your solution top-of-mind via content | 7-9 |
| Authority Bias | Expert endorsements, credentials, certifications | 9-12 |
| Social Proof | Usage numbers, testimonials, logos, reviews | 10-14 |

### Consideration Stage
| Model | Application | Typical PLFS |
|-------|------------|-------------|
| Framing Effect | Position features as gains vs competitor losses | 8-11 |
| Anchoring | Show higher-priced option first, making target seem reasonable | 9-13 |
| Jobs to Be Done | Frame messaging around the job, not the product | 10-13 |
| Confirmation Bias | Align messaging with what prospects already believe | 7-10 |

### Decision Stage
| Model | Application | Typical PLFS |
|-------|------------|-------------|
| Loss Aversion | Show what they'll miss without the product | 9-12 |
| Paradox of Choice | Reduce options to 3 tiers, highlight recommended | 11-15 |
| Default Effect | Pre-select the recommended option | 10-13 |
| Risk Reversal | Free trials, money-back guarantees, no-contract | 11-14 |

### Retention Stage
| Model | Application | Typical PLFS |
|-------|------------|-------------|
| Endowment Effect | Personalization makes the product "theirs" | 8-11 |
| IKEA Effect | User-created content, custom configurations | 9-12 |
| Status-Quo Bias | Make switching feel harder than staying | 7-10 |
| Switching Costs | Data lock-in, integrations, team habits | 8-11 |

## Output Format Template

When applying psychology, use this structure:

```
### Mental Model: [Name]

**PLFS:** +[score] ([interpretation])

- **Why it works (psychology)**
  [1-2 sentence explanation of the mechanism]

- **Behavior targeted**
  [Specific action at specific journey stage]

- **Where to apply**
  - [Surface 1: page, CTA, flow]
  - [Surface 2]

- **How to implement**
  1. [Step 1]
  2. [Step 2]
  3. [Step 3]

- **What to test**
  - [Variation A vs B]

- **Ethical guardrail**
  [Specific ethical boundary for this application]
```

When recommending marketing ideas, use this structure:

```
### Idea: [Name]

**MFS:** +[score] ([interpretation])

- **Why it fits**
  [1-2 sentence rationale]

- **How to start**
  1. [First step]
  2. [Validation step]
  3. [Scale step]

- **Expected outcome**
  [Timeframe and result]

- **Resources required**
  [People, tools, budget]

- **Primary risk**
  [What could go wrong]
```

## Stage-Based Idea Priorities

### Pre-Launch
- Speed > Impact, Fit > Scale
- Favor: waitlists, early access, content, communities
- Avoid: paid acquisition, heavy infrastructure

### Early Stage
- Speed + Cost sensitivity
- Favor: SEO, founder-led distribution, comparisons, community building
- Avoid: broad paid campaigns, expensive partnerships

### Growth
- Impact > Speed
- Favor: paid acquisition, strategic partnerships, PLG loops, referral programs
- Avoid: manual processes that don't scale

### Scale
- Impact + Defensibility
- Favor: brand building, international expansion, acquisitions, platform plays
- Avoid: tactics without compounding returns

## Ethical Guardrails Checklist

Before any recommendation:
- [ ] No dark patterns (hidden costs, trick wording, forced actions)
- [ ] No false scarcity (fake countdown timers, invented stock limits)
- [ ] No hidden defaults (pre-checked boxes, opt-out traps)
- [ ] No exploitation of vulnerable users
- [ ] Transparency: user can understand what's happening
- [ ] Reversibility: user can undo their action
- [ ] Informed choice: user has the information to decide
- [ ] User benefit alignment: recommendation helps the user, not just the business

Rule: If ethical risk > leverage, do not recommend the model or idea.

## Operator Checklist

Before presenting recommendations:
- [ ] Behavior clearly defined
- [ ] Models/ideas scored (PLFS or MFS)
- [ ] No more than 5 recommendations
- [ ] Each maps to a real surface (page, CTA, flow)
- [ ] Ethical implications addressed
- [ ] Stage-appropriate for the business
