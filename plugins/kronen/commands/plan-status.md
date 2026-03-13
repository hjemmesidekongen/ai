---
name: plan-status
description: Show progress of one or all plans (read-only inspection)
user_invocable: true
argument-hint: "[PLAN-NAME] [--verbose]"
---

# /plan status

Read-only progress inspection for plans. Lightweight — no planning skill loaded.

## Steps

1. **Find plans:**
   - If `$ARGUMENTS` specifies a plan name → show that plan's details
   - Otherwise → scan `.ai/plans/` and show summary of all plans

2. **Summary mode** (no specific plan):
   ```
   Plans:
     auth-migration       in_progress  Wave 2 (cycle 3)  4 tasks done
     feature-api          done         Wave 4 (cycle 4)  12 tasks done
   ```

3. **Detail mode** (specific plan):
   ```
   Plan: auth-migration
   Goal: Migrate auth system from session-based to JWT without downtime
   Status: in_progress
   Cycle: 3 of 15 max

   Remaining: Billing service integration and cutover sequence still pending.
   Learnings: 5 active, 2 superseded
   Replans: 1

   Wave 1 [completed] t1, t2
     Verification: PASS
   Wave 2 [in_progress] t5, t6
     t5: completed
     t6: in_progress

   Errors: 0 unresolved
   ```

4. **Verbose mode** (`--verbose`):
   - Include verification check details per wave
   - Show error history with attempted fixes
   - Show file ownership map
   - List active learnings (type, content summary, cycle recorded)
   - Show open questions from learnings.yml
   - Show classification history (CONTINUE/ADJUST/REPLAN/ESCALATE per cycle)

5. **If failed:** suggest recovery options
   - Resume with a new `/plan` command referencing the existing plan directory
   - Start autopilot to pick up from where it left off

## Data sources

Read only — never modify:
- `.ai/plans/{name}/state.yml` — cycle, status, remaining_goal, errors
- `.ai/plans/{name}/learnings.yml` — entries, open_questions, cycle_metrics
- `.ai/plans/{name}/plan.yml` — wave definitions, verification results
