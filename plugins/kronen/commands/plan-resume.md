---
name: plan-resume
description: Resume an interrupted plan from where it left off
user_invocable: true
arguments:
  - name: plan
    description: "Plan name or path (optional — uses most recent active plan)"
    required: false
---

# /plan:resume

Resume an interrupted plan from the exact stopping point. Handles session breaks, /compact, and crash recovery.

## Steps

1. **Find the plan:**
   - If `$ARGUMENTS` specifies a plan → load it
   - Otherwise → find the most recent `in_progress` plan in `.ai/plans/`
   - If multiple active → list them and ask which to resume
   - If none active → "No active plans. Use `/plan:create` to start one."

2. **Detect plan mode:**
   - Check state.yml for `mode: dynamic` (presence of `cycle`, `remaining_goal`, or `max_cycles`)
   - If dynamic → follow dynamic resume path (step 2b)
   - If static → follow standard resume path (step 2a)

2a. **Reconstruct context (static):**
   - Read plan.yml, state.yml, and **plan.md** (implementation rules)
   - plan.md contains the standards for this plan — load it before doing anything
   - Read recovery_notes for progress summary
   - Identify: last completed wave, current wave, any partial progress

2b. **Reconstruct context (dynamic):**
   - Read state.yml, learnings.yml, and **plan.md**
   - For dynamic plans, read learnings.yml and state.yml to reconstruct situational awareness before proceeding
   - Load active learnings (status: active) — these are the accumulated knowledge from prior cycles
   - Identify: current cycle number, remaining_goal, last classification, any partial wave progress
   - Determine position: **mid-wave** (current wave has in_progress/pending tasks) or **between waves** (last wave completed, next cycle not started)

3. **Validate completed work:**
   - Quick spot-check that completed waves' outputs still exist on disk
   - Not a full re-verification — just confirm files aren't missing
   - If files are missing → report and suggest re-running the affected wave

4. **Handle partial waves:**
   - Tasks with status `completed` → keep as-is
   - Tasks with status `in_progress` → mark for re-run (might have been interrupted)
   - Tasks with status `pending` → normal execution

5. **Resume execution:**
   - **Static mode:** Hand off to `/plan:execute` logic starting from the current wave
   - Show: "Resuming plan '{name}' from Wave {N}. {M} tasks remaining."
   - **Dynamic mode (mid-wave):** Resume current wave execution via plan-execute, then continue the dynamic loop (build → learn → orient → ...)
   - Show: "Resuming dynamic plan '{name}' — cycle {C}, Wave {N} in progress. {M} tasks remaining."
   - **Dynamic mode (between waves):** Run orient phase from dynamic-planner to assess position, then continue the loop (orient → reflect → plan → build → learn → ...)
   - Show: "Resuming dynamic plan '{name}' — starting cycle {C+1}. Remaining goal: {remaining_goal}"

6. **Update state:**
   - `updated_at` → now
   - `recovery_notes` → updated with resume context
   - Dynamic plans: preserve `cycle`, `remaining_goal`, and `replan_count` — do not reset

## Recovery scenarios

| Scenario | What happens |
|----------|-------------|
| Clean stop (user quit) | Resume from next pending wave |
| Mid-task interrupt | Re-run the interrupted task |
| Verification failure | Show errors, suggest fixes, resume after fix |
| Session /compact | State persists in files, full resume |
| Missing output files | Report missing files, suggest re-running wave |
| Dynamic plan mid-wave | Resume wave execution, then continue learn → orient loop |
| Dynamic plan between waves | Run orient phase to reassess, then continue the cycle |
| Dynamic plan with stale learnings | Load active learnings, flag any that reference missing files |
