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
   - Create `.ai/plans/<name>/artifacts/` directory if it doesn't exist
   - Check for unresolved errors from prior attempts
   - If errors exist → show them and ask whether to proceed or fix first

3. **Execute waves in order:**

   For each wave:
   a. Update state: wave status → `in_progress`, `current_phase` → wave name
   b. If `parallel: true` → dispatch tasks as parallel Agent subagents
      - Each agent writes findings to `.ai/plans/<name>/artifacts/<wave>-<task>-output.md`
      - See forward-message pattern in `resources/agent-orchestration.md`
   c. If `parallel: false` → execute tasks sequentially
      - Before starting each task: check if any `depends_on` tasks declared an `artifact`
        → read those artifact files before proceeding (forward-message pattern)
   d. After all tasks complete → **read artifact files directly** (never paraphrase agent responses)
      → run **plan-verifier** skill
   e. If verification type is `ab_benchmark`:
      - Run `run_ab_benchmark.py` for each skill in the wave
      - Run `run_eval.py` for trigger evaluation
      - Gate: `avg_delta >= 0.05`, trigger accuracy >= 0.7
      - If fail: attempt `improve_description.py` (max 3 iterations)
   f. If verification passes → update state: wave status → `completed`
   g. If verification fails → log errors, halt, suggest fixes
   h. **Phase checkpoint** (if `checkpoint: true` on the wave):
      - Display a summary of what the wave accomplished (tasks completed, files written, key outcomes)
      - Present three options to the user:
        1. **Continue** → proceed to the next wave
        2. **Revise** → user describes what to change, revise and re-verify the wave
        3. **Abort** → update state to `paused`, stop execution
      - Do NOT proceed to the next wave until the user explicitly selects Continue
      - If no `checkpoint` flag on the wave, proceed automatically (backward compatible)
   i. Update recovery_notes with progress summary

4. **Final wave:**
   - Always runs QA review (Stage 2)
   - Integration test if specified

5. **Completion:**
   - Update state: plan status → `completed`
   - Show summary: waves completed, tasks done, errors encountered
   - "Plan complete. All waves verified."

## Subagent-Per-Task Execution

For complex plans (3+ waves, high-risk implementation, or parallel agent work), dispatch each task as a fresh Agent subagent instead of executing inline. This prevents context accumulation from degrading quality on later tasks.

### When to use

- Plans with 3+ waves where later tasks need clean context
- Implementation tasks that shouldn't see the coordinator's reasoning
- Parallel waves where agents must not share context

### Implementer dispatch

Each task agent receives only what it needs:

```
Context package for task agent:
  1. Task spec: id, name, description, files_written, files_read, model_tier
  2. Plan rules: full plan.md content (implementation contract)
  3. Dependency artifacts: read .ai/plans/<name>/artifacts/ for any depends_on tasks
  4. Verification requirement: "Apply verification-gate before reporting done"

Prompt structure:
  "You are implementing task <id>: <name>.
   Rules: [plan.md content]
   Prior step outputs: [artifact file contents from depends_on tasks]
   Write your output to: .ai/plans/<name>/artifacts/<wave>-<task>-output.md
   Apply verification-gate before reporting complete."
```

### Reviewer loop (per task)

After the implementer writes its artifact, dispatch two reviewers:

```
Stage 1 — Spec Reviewer:
  Read: task spec + implementer artifact
  Check: does the output match the spec? Are files correct?
  Write: .ai/plans/<name>/artifacts/<wave>-<task>-spec-review.md

Stage 2 — Quality Reviewer (only if Stage 1 passes):
  Read: task spec + implementer artifact + spec-review artifact
  Check: content quality, completeness, edge cases
  Write: .ai/plans/<name>/artifacts/<wave>-<task>-quality-review.md
```

### Coordinator responsibility

The coordinator:
- Reads all artifact files directly (never paraphrases agent responses)
- Advances state based on review verdicts
- Retries failed tasks (max 3, then escalate)
- Never implements — only orchestrates

### Fallback

For simple single-wave plans, inline execution is fine. Use subagent dispatch when the plan's complexity warrants it.

## Error recovery

- On failure: state.yml records the exact failure point
- Use `/plan:resume` to pick up from where it stopped
- Use `--start-wave N` to restart a specific wave
- Errors are logged to state.yml and persist across sessions
