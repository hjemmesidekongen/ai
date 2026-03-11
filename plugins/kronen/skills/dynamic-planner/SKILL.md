---
name: dynamic-planner
description: >
  Goal-oriented iterative planning with learning accumulation. Runs an
  orient-reflect-plan-build-learn loop that plans one wave at a time and
  accumulates episodic memory across cycles. Use when the full scope is
  uncertain or the plan should evolve based on execution learnings.
user_invocable: false
interactive: false
depends_on:
  - plan-engine
  - plan-verifier
triggers:
  - "dynamic plan"
  - "iterative planning"
  - "goal-oriented plan"
  - "adaptive plan"
  - "plan one wave at a time"
reads:
  - ".ai/plans/{name}/state.yml"
  - ".ai/plans/{name}/learnings.yml"
  - ".ai/plans/{name}/plan.md"
writes:
  - ".ai/plans/{name}/state.yml"
  - ".ai/plans/{name}/learnings.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "cycle_advanced"
      verify: "state.yml cycle incremented and remaining_goal updated"
      fail_action: "Run learn phase to record what happened"
    - name: "learnings_recorded"
      verify: "learnings.yml has at least one new entry for this cycle"
      fail_action: "Run learn phase — every cycle must produce learnings"
    - name: "classification_produced"
      verify: "Reflect step produced CONTINUE, ADJUST, REPLAN, or ESCALATE"
      fail_action: "Re-run reflect with adversarial framing"
  on_fail: "Fix the missing phase output and re-run checkpoint"
  on_pass: "Report cycle number, classification, and active learnings count"
model_tier: principal
_source:
  origin: "kronen"
  inspired_by: "Reflexion, AdaPlanner, GoalAct (see research-findings.md)"
  ported_date: "2026-03-11"
  iteration: 1
  changes: "Initial creation"
---

# dynamic-planner

Plans one wave at a time. Learns between waves. Goal fixed, path adapts.

## Cycle (7 phases)

1. **Orient** — read learnings (active only), current state, goal. Assess position.
2. **Reflect** — classify: CONTINUE / ADJUST / REPLAN / ESCALATE. Skip on cycle 1.
3. **Research** — optional. Triggered when reflect finds knowledge gaps.
4. **Plan** — one wave only, using plan-engine. Append to planned_waves.
5. **Build** — execute the wave via plan-execute.
6. **Learn** — record entries to learnings.yml. Update remaining_goal.
7. **Loop** — back to orient, or done if goal met.

## Classification (D-004)

| Signal | When | Action |
|--------|------|--------|
| CONTINUE | Wave passed, learnings are observations | Plan next wave |
| ADJUST | Next wave needs different approach | Modify plan direction |
| REPLAN | Wave failed or assumptions invalidated | Replan remaining work |
| ESCALATE | Scope change, cost impact, goal revision | Pause for human |

## Safety guards

- Max 2 replans per goal — then ESCALATE (D-008)
- max_cycles in state.yml (default 15) — then ESCALATE (D-012)
- ESCALATE always surfaces — never silently skipped

## References: `references/process.md` | `references/reflect-prompts.md` | `resources/learnings-schema.yml`
