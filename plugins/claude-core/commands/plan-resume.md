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

2. **Reconstruct context:**
   - Read plan.yml, state.yml, and **plan.md** (implementation rules)
   - plan.md contains the standards for this plan — load it before doing anything
   - Read recovery_notes for progress summary
   - Identify: last completed wave, current wave, any partial progress

3. **Validate completed work:**
   - Quick spot-check that completed waves' outputs still exist on disk
   - Not a full re-verification — just confirm files aren't missing
   - If files are missing → report and suggest re-running the affected wave

4. **Handle partial waves:**
   - Tasks with status `completed` → keep as-is
   - Tasks with status `in_progress` → mark for re-run (might have been interrupted)
   - Tasks with status `pending` → normal execution

5. **Resume execution:**
   - Hand off to `/plan:execute` logic starting from the current wave
   - Show: "Resuming plan '{name}' from Wave {N}. {M} tasks remaining."

6. **Update state:**
   - `updated_at` → now
   - `recovery_notes` → updated with resume context

## Recovery scenarios

| Scenario | What happens |
|----------|-------------|
| Clean stop (user quit) | Resume from next pending wave |
| Mid-task interrupt | Re-run the interrupted task |
| Verification failure | Show errors, suggest fixes, resume after fix |
| Session /compact | State persists in files, full resume |
| Missing output files | Report missing files, suggest re-running wave |
