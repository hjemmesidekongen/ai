---
name: plan-execute
command: "/plan:execute"
description: "Execute a wave plan, running tasks with verification and QA gates"
arguments:
  - name: plan_file
    type: string
    required: true
    description: "Path to the plan YAML file (e.g., .plans/brand-generate-acme-corp.yml)"
  - name: mode
    type: string
    required: false
    enum: [single, multi, auto]
    default: auto
    description: "Execution mode. 'auto' checks for CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS."
  - name: start_wave
    type: integer
    required: false
    description: "Wave number to start from. Defaults to the first pending wave."
  - name: dry_run
    type: boolean
    required: false
    default: false
    description: "Validate the plan and show what would execute without running anything."
---

# /plan:execute

Executes a wave plan produced by `/plan:create`. Runs tasks wave by wave with verification gates and QA review.

## Usage

```
/plan:execute .plans/brand-generate-acme-corp.yml
/plan:execute .plans/site-build.yml --mode single
/plan:execute .plans/brand-generate-acme-corp.yml --start-wave 3
/plan:execute .plans/brand-generate-acme-corp.yml --dry-run
```

## Execution Steps

### Step 1: Load and Validate Plan

1. Read the plan file. If it doesn't exist or is invalid YAML, abort with error.
2. Read the ownership registry (`[plan-name].ownership.yml`). If missing, re-generate it by calling the file-ownership skill.
3. Read the state file (`[plan-name].state.yml`). If missing, create it.
4. Run `scripts/check-file-conflicts.sh` as a pre-flight check. If conflicts found, abort.
5. Display the plan summary to the user (same format as `/plan:create` output).

**Dry run:** If `--dry-run`, stop here after showing what would execute. Do not run any tasks.

### Step 2: Determine Execution Mode

```
if --mode is "single":
  mode = single_agent
elif --mode is "multi":
  mode = multi_agent
elif --mode is "auto":
  if CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS is set:
    mode = multi_agent
  else:
    mode = single_agent
```

Report the selected mode to the user:
- Single-agent: "Running in single-agent mode. Tasks execute sequentially."
- Multi-agent: "Running in multi-agent mode. Parallel tasks will spawn separate agents."

### Step 3: Determine Starting Wave

```
if --start-wave is provided:
  start from that wave (skip completed waves before it)
elif state.yml has a current_wave:
  start from current_wave (resume interrupted execution)
else:
  start from wave 1
```

Verify that all waves before the starting wave are marked `completed` in state. If a previous wave is `failed` or `in_progress`, warn the user and ask whether to re-run it or skip.

### Step 4: Execute Waves

For each wave from the starting wave to the final wave:

#### 4a. Update State

```yaml
# Update state file
status: "in_progress"
started_at: "[now]"       # only set on first wave (preserve original value after that)
current_wave: [wave number]
updated_at: "[now]"
```

If this is the first wave (`started_at` is null), set `started_at` to the current timestamp. For subsequent waves, leave `started_at` unchanged.

Report to user: `"Starting wave [N] of [total]: [task names]"`

#### 4b. Run Tasks

**Single-agent mode:**

Execute tasks within the wave sequentially, one at a time:

```
for each task_id in wave.tasks:
  1. Read the task definition from the plan
  2. Read the ownership entry for this task
  3. Load domain instructions (if provided by consuming plugin)
  4. Execute the task:
     - Read input files (from "reads" list)
     - Perform the work described in the task name
     - Write output files (to "owns" list only)
  5. Update the task status in the plan: status → "completed"
  6. Report: "Task [id]: [name] — completed"
```

**Multi-agent mode:**

Spawn parallel agents for tasks in the wave:

```
for each task_id in wave.tasks (in parallel):
  1. Spawn a worker agent (based on worker-agent.md template)
  2. Pass: task definition, ownership entry, domain instructions
  3. The agent executes independently
  4. Collect the agent's task_complete report
```

Wait for all agents in the wave to complete before proceeding.

If any agent reports `status: "failed"`:
- Log the failure
- Mark the task as `failed` in the plan
- Decide whether to abort the wave or continue with remaining tasks:
  - If the failed task is a dependency for later waves: abort wave
  - If the failed task is independent: continue, report failure at wave end

#### 4c. Run Verification

After all tasks in the wave complete (or after each task in single-agent mode if the profile specifies):

1. Read the wave's `verification` block from the plan
2. Call the `verification-runner` skill with the type and checks
3. Process the result:

```
if verdict == "pass":
  Update wave status → "completed"
  Update verification.passed → true
  Continue to next wave

elif verdict == "pass_with_warnings":
  Update wave status → "completed"
  Update verification.passed → true
  Log warnings for final report
  Continue to next wave

elif verdict == "fail":
  Log blocking issues
  Enter fix-and-retry loop (see Step 5)
```

#### 4d. Run QA Review (If Required)

Check if this wave requires QA review:

```
if wave.qa_review is true:
  run QA
elif verification_profile.qa_frequency == "every_wave":
  run QA
elif this is the final wave:
  run QA (always required for final wave)
else:
  skip QA for this wave
```

When running QA:

1. Spawn the `qa-agent` (from `agents/qa-agent.md`)
2. Pass: the plan file, the wave number, the working directory
3. The QA agent runs its 4-check protocol and returns a `qa_report`
4. Process the report:

```
if verdict == "pass":
  Continue to next wave

elif verdict == "pass_with_warnings":
  Log warnings
  Continue to next wave

elif verdict == "fail":
  Enter fix-and-retry loop with QA issues (see Step 5)
```

#### 4e. Write Recovery Notes

After each wave completes (pass or pass_with_warnings), write recovery context to **both** files:

**State file** (`[plan-name].state.yml`) — the resume point:

```yaml
current_wave: [wave number]
completed_waves: [1, 2, ...]    # append this wave
updated_at: "[now]"
last_session_id: "[current session]"
recovery_notes: |
  Wave [N] completed at [timestamp].
  Tasks completed: [list].
  Key outputs: [list of artifacts].
  Decisions made: [from worker reports].
  Warnings: [any pass_with_warnings notes].
  Next: Wave [N+1] with tasks [list].
```

**Plan file** (`[plan-name].yml`) — the persistent record:

```yaml
recovery_notes: <same content as above>
last_session_id: "[current session]"
```

Both files get the same `recovery_notes` content. The state file is the primary source for `/plan:resume`; the plan file is the backup in case the state file is lost.

### Step 5: Fix-and-Retry Loop

When verification or QA fails:

```
for round in 1..3:
  0. Read state.yml errors array for this skill/wave.
     For each blocking issue, check if a previous error entry exists
     with the same skill + error text:
       - If result is "unresolved" and next_approach is set:
         USE next_approach instead of suggested_fix (avoid repeating failures)
       - If the same approach was already tried and failed:
         SKIP it and try an alternative strategy

  1. Report failures to user:
     "Verification failed for wave [N]. [count] blocking issues found."
     If previous errors exist: "Previous attempts logged — using alternative approach."

  2. For each blocking issue:
     - Show the issue and the fix to apply (next_approach from errors, or suggested_fix if first attempt)
     - Route back to the implementing task/agent

  3. Apply fixes:
     - Single-agent: re-execute the failed task with the fix guidance
     - Multi-agent: re-spawn the worker agent with the fix guidance

  4. Re-run verification (only failed checks)

  5. If QA was the failing gate: re-run QA (only failed checks)

  6. If all pass: break out of loop, continue to next wave

  7. If still failing: increment round, try again
     The verification-runner logs the failure to state.yml errors automatically.

if round > 3:
  Escalate to human:
  "Unable to resolve [N] issues after 3 attempts. Presenting for manual review."

  Run manual_approval verification type:
  - Present unresolved issues to user
  - User decides: fix manually, skip wave, or abort plan
```

### Step 6: Plan Completion

After the final wave completes and passes QA:

1. Update state:
   ```yaml
   status: "completed"
   current_wave: null
   completed_waves: [1, 2, ..., N]    # all wave numbers
   updated_at: "[now]"
   ```

2. Update all task statuses in the plan to `completed`.

3. Collect all warnings from all waves.

4. Report to user:

```
## Plan Complete: brand-generate-acme-corp

All 4 waves completed. All verifications passed. QA approved.

### Summary
  Wave 1: ✓ color palette, typography system
  Wave 2: ✓ logo concepts, icon library
  Wave 3: ✓ favicons, app icons, social images
  Wave 4: ✓ brand manual compiled

### Warnings (non-blocking)
  - logo-mark-full.svg is 87KB — consider optimizing
  - Colorblind notes for tertiary orange are brief

### Artifacts
  - brand-reference.yml (complete)
  - brand-manual.md
  - assets/logo/svg/ (3 variants)
  - assets/icons/ (24 icons)
  - assets/favicons/ (6 sizes)
  - assets/app-icons/ (4 sizes)
  - assets/social/ (3 templates)
```

## Error Handling

| Error | Action |
|-------|--------|
| Plan file not found | Abort. Suggest running `/plan:create` first. |
| Plan already completed | Report status. Ask if user wants to re-run. |
| Previous wave not completed | Warn user. Suggest `/plan:resume` or `--start-wave`. |
| Agent spawn fails (multi-agent) | Fall back to single-agent mode for this wave. |
| Task produces no output | Mark task as failed. Enter fix-and-retry. |
| Session interrupted mid-wave | State is preserved. `/plan:resume` picks up from current wave. |
