---
name: plan
description: Create and run an iterative plan from a goal
user_invocable: true
argument-hint: "GOAL [--max-cycles N] [--manual]"
---

# /plan

Create a goal-driven iterative plan and start executing it. Plans one wave at a time, executes, learns, and loops until the goal is met.

## Steps

1. **Parse goal** from `$ARGUMENTS`:
   - Extract the goal description (everything that isn't a flag)
   - Extract `--max-cycles N` if provided (default: 15)
   - Extract `--manual` flag if present (disables autopilot — user runs `/plan resume` after each cycle)
   - Derive plan name from goal (lowercase, hyphens, concise)

2. **Orient** (cycle 1):
   - Scan the codebase for current state relevant to the goal
   - Check if related brainstorm decisions exist (`.ai/brainstorm/*/decisions.yml`)
   - Assess the scope: what's known vs what needs to be built
   - Run goal clarity gate (advisory on cycle 1)

3. **Create plan directory** at `.ai/plans/{plan-name}/`

4. **Initialize state.yml:**
   ```yaml
   plan: {plan-name}
   status: in_progress
   mode: dynamic
   goal: "{goal}"
   acceptance_criteria:
     - "{criterion 1}"
     - "{criterion 2}"
   cycle: 1
   planned_waves: []
   remaining_goal: "{initial assessment of full scope}"
   max_cycles: {N}
   replan_count: 0
   started_at: "{timestamp}"
   updated_at: "{timestamp}"
   errors: []
   recovery_notes: "{initial context summary}"
   ```

5. **Initialize learnings.yml:**
   ```yaml
   goal: "{goal}"
   cycle: 1
   entries: []
   open_questions: []
   cycle_metrics: []
   next_orientation: "First cycle — no prior learnings."
   ```

6. **Generate plan.md** — implementation contract:
   - Ask user for standards, constraints, sync rules
   - Include context recovery instruction

7. **Plan first wave** using plan-engine skill:
   - Define tasks for the first wave of work
   - File-ownership isolation, tier assignment, verification contract
   - Append wave ID to planned_waves

8. **Execute:**
   - **Default (autopilot):** Start autopilot loop with `--dynamic-plan .ai/plans/{name}` and `--completion-promise` matching the acceptance criteria
   - **Manual (`--manual` flag):** Execute wave 1, then tell user to run `/plan resume` for subsequent cycles

## After first wave

Each subsequent cycle runs the full OODA loop: Orient → Reflect → (Research) → Plan → Build → Verify → Learn → Loop

Load `plugins/kronen/skills/plan-engine/references/process.md` for the full algorithm.

## Notes

- Goal is fixed at creation — never changes
- Autopilot is the default execution mode (PC-D09)
- Use `/plan status` to check progress
- ESCALATE decisions always pause for human input
