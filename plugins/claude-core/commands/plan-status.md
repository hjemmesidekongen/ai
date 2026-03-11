---
name: plan-status
description: Show progress of a plan
user_invocable: true
arguments:
  - name: plan
    description: "Plan name or path (optional — shows most recent or all plans)"
    required: false
  - name: verbose
    description: "Show verification details, errors, and file ownership"
    required: false
---

# /plan:status

Show the current state of one or all plans.

## Steps

1. **Find plans:**
   - If `$ARGUMENTS` specifies a plan → show that plan's details
   - Otherwise → scan `.ai/plans/` and show summary of all plans

2. **Detect mode:** Read `mode` from state.yml. Default to `static` if absent.

3. **Summary mode** (no specific plan):
   - Static plans:
     ```
     Plans:
       claude-core-phase-2  in_progress  Wave 3/6  8/14 tasks done
       feature-auth         completed    Wave 4/4  12/12 tasks done
     ```
   - Dynamic plans:
     ```
     Plans:
       auth-migration       in_progress  Wave 2 of ??? (cycle 3)  4 tasks done
     ```

4. **Detail mode** (specific plan):
   - **Static plan:**
     ```
     Plan: claude-core-phase-2
     Status: in_progress
     Progress: 8/14 tasks, 3/6 waves

     Wave 1 [completed] t1, t2
       Verification: PASS (data_validation)
     Wave 2 [completed] t3
       Verification: PASS (ab_benchmark, avg_delta: +0.12)
     Wave 3 [in_progress] t4, t8
       t4: completed
       t8: in_progress
     Wave 4 [pending] t5, t6, t9, t10
     Wave 5 [pending] t7, t11, t12, t13
     Wave 6 [pending] t14

     Errors: 0 unresolved
     ```

   - **Dynamic plan** (`mode: dynamic`):
     ```
     Plan: auth-migration
     Mode: dynamic
     Goal: Migrate auth system from session-based to JWT without downtime
     Status: in_progress
     Cycle: 3 of 15 max
     Progress: Wave 2 of ??? (cycle 3)

     Remaining: Billing service integration and cutover sequence still pending.
     Learnings: 5 active, 2 superseded
     Replans: 1

     Wave 1 [completed] t1, t2
       Verification: PASS (data_validation)
     Wave 2 [in_progress] t5, t6
       t5: completed
       t6: in_progress

     Errors: 0 unresolved
     ```

     Dynamic-specific display rules:
     - Wave count shows `Wave N of ???` — total is unknown until the goal is met
     - `(cycle M)` appended to progress line
     - `Goal:` line always shown — the fixed goal from state.yml
     - `Remaining:` shows `remaining_goal` freeform summary
     - `Learnings:` shows count of `status: active` entries from `learnings.yml`, plus superseded/invalidated count
     - `Replans:` shown only when `replan_count > 0`
     - `Cycle:` shows `N of {max_cycles} max`

5. **Verbose mode** (`--verbose`):
   - Include verification check details
   - Show error history with attempted fixes
   - Show file ownership map
   - Show A/B benchmark results if available
   - **Dynamic plans only:**
     - List active learnings (type, content summary, cycle recorded)
     - Show open questions from learnings.yml
     - Show classification history (CONTINUE/ADJUST/REPLAN/ESCALATE per cycle)

6. **If failed:** suggest recovery options
   - `/plan:resume` to pick up from failure point
   - `/plan:execute --start-wave N` to restart a wave
   - **Dynamic plans:** also suggest `/plan:dynamic` to trigger a new cycle
