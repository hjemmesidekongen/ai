---
name: plan-execute
description: Execute a wave plan with verification gates
user_invocable: true
arguments:
  - name: plan
    description: "Plan name or path to plan.yml (optional — uses most recent plan)"
    required: false
  - name: start-wave
    description: "Start from a specific wave number (for resuming)"
    required: false
---

# /plan:execute

Execute a wave plan sequentially. Each wave completes and passes verification before the next wave starts.

## Steps

1. **Load the plan:**
   - If `$ARGUMENTS` specifies a plan → load it
   - Otherwise → find the most recent plan in `.ai/plans/`
   - If `--start-wave N` → skip to wave N (for resuming after failures)

2. **Pre-flight check:**
   - Verify plan.yml and state.yml exist
   - **Read plan.md** — this contains the implementation rules for this plan.
     These rules apply to every task. Load them into context now.
   - Check for unresolved errors from prior attempts
   - If errors exist → show them and ask whether to proceed or fix first

3. **Execute waves in order:**

   For each wave:
   a. Update state: wave status → `in_progress`, `current_phase` → wave name
   b. If `parallel: true` → dispatch tasks as parallel Agent subagents
      - Each agent writes findings to `.ai/plans/<name>/artifacts/<wave>-<task>-findings.md`
      - See forward-message pattern in `resources/agent-orchestration.md`
   c. If `parallel: false` → execute tasks sequentially
   d. After all tasks complete → **read artifact files directly** (never paraphrase agent responses)
      → run **plan-verifier** skill
   e. If verification type is `ab_benchmark`:
      - Run `run_ab_benchmark.py` for each skill in the wave
      - Run `run_eval.py` for trigger evaluation
      - Gate: `avg_delta >= 0.05`, trigger accuracy >= 0.7
      - If fail: attempt `improve_description.py` (max 3 iterations)
   f. If verification passes → update state: wave status → `completed`
   g. If verification fails → log errors, halt, suggest fixes
   h. Update recovery_notes with progress summary

4. **Final wave:**
   - Always runs QA review (Stage 2)
   - Integration test if specified

5. **Completion:**
   - Update state: plan status → `completed`
   - Show summary: waves completed, tasks done, errors encountered
   - "Plan complete. All waves verified."

## Error recovery

- On failure: state.yml records the exact failure point
- Use `/plan:resume` to pick up from where it stopped
- Use `--start-wave N` to restart a specific wave
- Errors are logged to state.yml and persist across sessions
