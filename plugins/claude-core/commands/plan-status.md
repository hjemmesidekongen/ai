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

2. **Summary mode** (no specific plan):
   ```
   Plans:
     claude-core-phase-2  in_progress  Wave 3/6  8/14 tasks done
     feature-auth         completed    Wave 4/4  12/12 tasks done
   ```

3. **Detail mode** (specific plan):
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

4. **Verbose mode** (`--verbose`):
   - Include verification check details
   - Show error history with attempted fixes
   - Show file ownership map
   - Show A/B benchmark results if available

5. **If failed:** suggest recovery options
   - `/plan:resume` to pick up from failure point
   - `/plan:execute --start-wave N` to restart a wave
