---
name: plan-engine
description: >
  Goal-driven iterative planning engine. OODA loop that plans one wave at a time,
  executes via multi-agent dispatch, and accumulates learnings across cycles.
  Always iterative, always goal-driven. Use when breaking work into waves,
  planning multi-file changes, or running structured execution.
user_invocable: false
interactive: false
depends_on:
  - file-ownership
triggers:
  - "create plan"
  - "create a plan"
  - "plan this"
  - "break this down"
  - "break down"
  - "wave plan"
  - "goal-oriented plan"
  - "organize tasks"
  - "organize into waves"
  - "dynamic plan"
  - "iterate on plan"
  - "resume plan"
  - "continue plan"
  - "next wave"
  - "execute plan"
  - "execute this plan"
  - "multi-step task"
reads:
  - ".ai/plans/{name}/state.yml"
  - ".ai/plans/{name}/learnings.yml"
  - ".ai/plans/{name}/plan.md"
  - ".ai/plans/{name}/plan.yml"
writes:
  - ".ai/plans/{name}/state.yml"
  - ".ai/plans/{name}/learnings.yml"
  - ".ai/plans/{name}/plan.yml"
  - ".ai/plans/{name}/plan.md"
  - ".ai/plans/{name}/artifacts/"
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
    - name: "no_file_conflicts"
      verify: "No two tasks in the same wave write to the same file"
      fail_action: "Re-run file-ownership conflict resolution"
    - name: "verification_contract"
      verify: "Wave has concrete verification requirements in plan.yml"
      fail_action: "Generate verification contract before execution"
  on_fail: "Fix issues and re-run checkpoint"
  on_pass: "Report cycle number, classification, wave count, and active learnings count"
model_tier: principal
_source:
  origin: "kronen"
  inspired_by: "Reflexion, AdaPlanner, GoalAct + plan-engine + dynamic-planner"
  ported_date: "2026-03-13"
  iteration: 1
  changes: "Consolidated from plan-engine + dynamic-planner. Single iterative-only planning mode."
---

# plan-engine

Goal-driven iterative planning. Plans one wave, executes, learns, loops. Goal fixed, path adapts.

## OODA Cycle (7 phases)

1. **Orient** — read learnings (active only), scan codebase, assess position vs goal. Cycle 1: run 5-point goal clarity gate (blocks if <3/5 pass). Cycle 2+: re-enforce, ESCALATE on regression.
2. **Reflect** — dispatch plan-classifier agent for unbiased classification: CONTINUE / ADJUST / REPLAN / ESCALATE. Skip on cycle 1. Fallback: inline classification if agent fails.
3. **Research** — optional. Triggered when reflect finds knowledge gaps. Scoped, time-boxed.
4. **Plan** — decompose next wave: topological sort, file-ownership isolation, model-tier assignment, verification contract. ONE wave only.
5. **Build** — dispatch task agents via context-manager. Parallel where file-ownership allows. Each agent gets: task spec, plan.md rules, dependency artifacts, verification contract.
6. **Verify** — dispatch plan-verifier agent (isolated, no build context). Checks against upfront verification contract. Stage 1: mechanical. Stage 2: quality review.
7. **Learn** — record typed entries (observation/constraint/correction/discovery) to learnings.yml. Error patterns become instinct entries. Update remaining_goal. Increment cycle.

## Safety guards

- Goal clarity gate: 5-point mechanical checklist before cycle 1. Blocks on <3/5 pass.
- Goal immutability: goal + acceptance_criteria frozen after cycle 1. Changes → ESCALATE.
- Max 2 replans per goal → then ESCALATE
- max_cycles (default 15) → then ESCALATE
- ESCALATE always surfaces — never silently skipped
- Completed waves never undone on replan

## Key rules

- Goal fixed at creation — never changes. Autopilot by default.
- ONE wave at a time. Only active learnings loaded. Verification contract upfront.

## References

- `references/process.md` — full algorithm. Load when executing the OODA loop.
- `references/reflect-prompts.md` — adversarial templates. Load during Reflect phase only.
- Schemas: `plugins/kronen/resources/plan-schema.yml`, `plugins/kronen/resources/state-schema.yml`, `plugins/kronen/resources/learnings-schema.yml`
