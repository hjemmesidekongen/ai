---
name: plan-dynamic
description: Create a goal-oriented iterative plan that adapts as it learns
user_invocable: true
arguments:
  - name: goal
    description: "The goal to achieve — what the end state should be"
    required: true
  - name: max_cycles
    description: "Maximum iteration cycles before escalating (default: 15)"
    required: false
---

# /plan:dynamic

Create an iterative plan that plans one wave at a time and learns between waves. Unlike `/plan:create` which defines all waves upfront, this plans the first wave, executes it, reflects on what was learned, then plans the next wave.

## Steps

1. **Parse goal** from `$ARGUMENTS`:
   - Extract the goal description
   - Extract `--max-cycles N` if provided (default: 15)
   - Derive plan name from goal (lowercase, hyphens, concise)

2. **Create plan directory** at `.ai/plans/{plan-name}/`

3. **Orient phase** (cycle 1):
   - Scan the codebase for current state relevant to the goal
   - Check if related brainstorm decisions exist (`.ai/brainstorm/*/decisions.yml`)
   - Identify what already exists vs what needs to be built
   - Assess the scope: what's known vs what's uncertain

4. **Initialize state.yml** with dynamic mode fields:
   ```yaml
   plan: {plan-name}
   status: in_progress
   mode: dynamic
   goal: "{goal}"
   cycle: 1
   planned_waves: []
   remaining_goal: "{initial assessment of full scope}"
   max_cycles: {N}
   replan_count: 0
   ```

5. **Initialize learnings.yml** from `resources/learnings-schema.yml`:
   ```yaml
   goal: "{goal}"
   cycle: 1
   entries: []
   open_questions: []
   next_orientation: "First cycle — no prior learnings."
   ```

6. **Generate plan.md** — implementation contract (same as `/plan:create`):
   - Ask user for standards, constraints, sync rules
   - Include the critical context recovery instruction:
     "This is a dynamic plan. After any context loss, read state.yml and learnings.yml, then continue the loop from the current cycle."

7. **Plan first wave** using plan-engine:
   - Define tasks for just the first wave of work
   - File-ownership, tier assignment, verification setup
   - Append wave ID to planned_waves

8. **Present and hand off:**
   ```
   Dynamic plan: {name}
   Goal: {goal}
   Cycle 1 — first wave planned ({N} tasks)
   Remaining: {remaining_goal summary}

   Run /plan:execute to build wave 1.
   After completion, the dynamic planner will reflect, learn, and plan wave 2.
   ```

## After wave 1 completes

The dynamic-planner skill takes over. Each subsequent cycle:
Orient → Reflect → (Research) → Plan → Build → Learn → Loop

This happens automatically if running under autopilot. For manual execution, run `/plan:resume` after each wave — it detects dynamic mode and triggers the next cycle.

## Notes

- Goal is fixed at creation time — it never changes during execution
- Use `/plan:create` instead when the full scope is known upfront
- Use `/plan:status` to see progress ("Wave N of ???, Cycle M")
- ESCALATE decisions always pause for human input
