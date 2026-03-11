# Reflect Phase — Prompt Templates

## Purpose
These templates are used during the Reflect phase (Phase 2) of the dynamic planning loop. They force adversarial self-examination to overcome sunk-cost bias and surface genuine issues.

## Primary reflect prompt

Use this at the start of every reflect phase (after cycle 1):

```
Review the last wave's results against the original goal.

1. What did this wave actually accomplish vs what was planned?
2. Were there any surprises — things that worked unexpectedly well or failed unexpectedly?
3. What would you do differently if you were starting this wave over right now?
4. Is the remaining approach still the best path to the goal, or has something changed?
5. Are there knowledge gaps that need research before the next wave?

Based on your answers, classify: CONTINUE, ADJUST, REPLAN, or ESCALATE.
Justify your classification in one sentence.
```

## Adversarial challenge prompt

Use this after the primary reflect if the classification is CONTINUE — it forces a second look to catch complacency:

```
You classified CONTINUE. Challenge that:
- Is there something you're avoiding because it would mean rework?
- Are you continuing because it's genuinely the right path, or because it's the path you already started?
- If a fresh person looked at the goal and the current state, would they take the same next step?

If your classification changes, update it. If it holds, proceed with higher confidence.
```

## Replan justification prompt

Use this when classification is REPLAN — prevents oscillation:

```
You classified REPLAN. Before proceeding:
1. What specific assumption was invalidated? (Be concrete — not "things aren't working")
2. What evidence supports this conclusion?
3. How does the new approach differ from the old one?
4. Why will the new approach succeed where the old one failed?
5. What completed work is preserved? (REPLAN never undoes verified work)

Current replan_count: {N}. If this would be replan #3 or higher, you MUST escalate instead.
```

## Escalation format

When ESCALATE is triggered, present to the user:

```
ESCALATE — Human decision needed

What happened: [one sentence describing the discovery or blocker]
Why it can't be resolved autonomously: [specific reason from D-010 boundaries]
Options I see:
  A) [option with tradeoffs]
  B) [option with tradeoffs]
  C) [abandon/descope option if applicable]

Recommendation: [which option and why]
```

## Research trigger prompt

Use when reflect identifies a knowledge gap:

```
The reflect phase identified a gap: [specific question]
This needs investigation before planning the next wave because: [why it blocks planning]

Research scope: [what to look for]
Research boundary: [what is NOT in scope — prevent scope creep]
Time limit: one focused investigation. If it doesn't converge, plan around the uncertainty.
```
