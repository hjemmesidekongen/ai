---
name: plan-execute
command: "/plan:execute"
description: "Execute a wave plan, running tasks with verification and QA gates"
arguments:
  - name: plan_file
    type: string
    required: true
    description: "Path to the plan YAML file (e.g., .ai/plans/brand-generate-acme-corp/plan.yml)"
  - name: mode
    type: string
    required: false
    enum: [single, subagent, auto]
    default: auto
    description: "Execution mode. 'single' runs inline. 'subagent' dispatches each task via Task(). 'auto' defaults to subagent."
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
/plan:execute .ai/plans/brand-generate-acme-corp/plan.yml
/plan:execute .ai/plans/site-build/plan.yml --mode single    # inline, no subagents
/plan:execute .ai/plans/brand-generate-acme-corp/plan.yml --start-wave 3
/plan:execute .ai/plans/brand-generate-acme-corp/plan.yml --dry-run
```

## Execution Steps

### Step 1: Load and Validate Plan

1. Read the plan file. If it doesn't exist or is invalid YAML, abort with error.
2. Read the ownership registry (`ownership.yml` in the same directory as the plan). If missing, re-generate it by calling the file-ownership skill.
3. Read the state file (`state.yml` in the same directory as the plan). If missing, create it.
4. Run `scripts/check-file-conflicts.sh` as a pre-flight check. If conflicts found, abort.
5. Display the plan summary to the user (same format as `/plan:create` output).

**Dry run:** If `--dry-run`, stop here after showing what would execute. Do not run any tasks.

### Step 2: Determine Execution Mode

```
if --mode is "single":
  mode = inline
elif --mode is "subagent":
  mode = subagent
elif --mode is "auto":
  mode = subagent    # subagent is the default
```

Write `execution_mode` to the plan file (if not already set).

Report the selected mode to the user:
- Inline: "Running in inline mode. Tasks execute sequentially in this session."
- Subagent: "Running in subagent mode. Each task dispatches as an isolated subagent via Task()."

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

#### State Ownership Rule

**The orchestrator is the sole writer of state.yml and the plan file.** Subagents
never read or write state.yml — they receive context via their prompt and return
structured reports. The orchestrator extracts information from reports and writes
it to state. This prevents race conditions in parallel dispatch and keeps state
management centralized.

#### 4a. Update State

```yaml
# Update state file
status: "in_progress"
started_at: "[now]"       # only set on first wave (preserve original value after that)
current_wave: [wave number]
updated_at: "[now]"
```

If this is the first wave (`started_at` is null), set `started_at` to the current timestamp. For subsequent waves, leave `started_at` unchanged.

In subagent mode:
- Record the current git HEAD as the wave's `base_sha` (for quality review scoping)
- Before dispatching each task, update task status → `in_progress` in the plan

Report to user: `"Starting wave [N] of [total]: [task names]"`

#### 4b. Run Tasks

**Inline mode** (`--mode single`):

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

**Subagent mode** (default):

Dispatch each task as an isolated subagent via `Task()`. The orchestrator never
does domain work — it reads the plan, fills templates, dispatches, and collects
reports.

```
1. Record wave_base_sha = current git HEAD

2. For each task in wave.tasks:
   a. Read task definition from plan
   b. Read ownership entry (owns/reads) from ownership registry
   c. Read the task's SKILL.md content (≤80 lines from progressive disclosure)
   d. Check state.yml errors array for previous attempts on this task
   e. Build the read_list — files the subagent should read before starting:
      - references/process.md (if skill has one)
      - Files from the task's "reads" list (prior wave outputs)
      - findings.md (if skill uses research persistence)
   f. Fill worker-dispatch.md template (from resources/prompts/) with:
      - task_id, task_name, task_definition_from_plan
      - SKILL_MD_content (the lean SKILL.md)
      - owns, reads (from ownership entry)
      - read_list (assembled in step e)
      - previous_errors (from state.yml, if retry)
      - plan_name, model_tier
   g. Record task_base_sha = current git HEAD
   h. Dispatch via Task() tool:
      - description: "Task {task_id}: {task_name}"
      - prompt: the filled worker-dispatch.md template
      - model: model_tier_map[task.model_tier]
        (junior → haiku, senior → sonnet, principal → opus)
      - subagent_type: "general-purpose"
   i. Collect task_complete YAML report from subagent output
   j. Record task.base_sha and task.commit_sha in the plan
   k. Update task status in plan (completed | failed | blocked)
   l. Report: "Task [id]: [name] — [status]"

3. Record wave_head_sha = current git HEAD
4. Write commit_range { base_sha: wave_base_sha, head_sha: wave_head_sha }
   to the current phase in state.yml
```

**Parallel dispatch** (when `wave.parallel == true` and mode is subagent):

```
Instead of sequential step 2:
  1. Record wave_base_sha = current git HEAD
  2. Build ALL Task() calls for every task in the wave (steps 2a–2f above)
     - All tasks share the same wave_base_sha as their task_base_sha
  3. Issue ALL Task() calls in a single response
     (Claude Code dispatches them concurrently)
  4. Wait for ALL to return
  5. Collect all task_complete reports
  6. Post-dispatch conflict check:
     - Run check-file-conflicts.sh against actual files written by all tasks
     - If conflict detected: log error to state.yml, mark wave failed,
       fall through to Step 5 (fix-and-retry)
  7. Record all base_sha/commit_sha values in plan
  8. Record wave_head_sha = current git HEAD
  9. Write commit_range { base_sha: wave_base_sha, head_sha: wave_head_sha }
```

**Parallel failure handling:**

```
After all parallel tasks return:
  - If ALL succeeded: proceed to verification (step 4c)
  - If ONE failed, others succeeded:
    - Mark the failed task in the plan
    - Log error to state.yml from its task_complete report
    - Check if it blocks later waves:
      - Blocking: fail the wave, fix-and-retry for the failed task only
      - Non-blocking: proceed to verification, report failure at wave end
  - If MULTIPLE failed:
    - Mark all failed tasks
    - Log all errors to state.yml
    - Fail the wave, report all failures, fall through to Step 5
```

**Failure handling** (both modes):

```
If any task reports status == "failed" or "blocked":
  1. Mark the task as failed/blocked in the plan
  2. Extract error context from the task_complete report and append to
     state.yml errors array:
       - timestamp: [now]
       - skill: [task_name from report]
       - error: [error field from task_complete]
       - attempted_fix: "pending"
       - result: "unresolved"
       - next_approach: [recovery_notes from task_complete, if any]
  3. Check if the failed task blocks later waves:
     - If blocking:
       a. Run cascading failure analysis (see Step 5: Cascading Failure Analysis):
          - Walk dependency graph forward to find direct and transitive dependents
          - Identify tasks with no dependency path from the failed task
       b. Log the full impact chain to the error entry in state.yml:
            blocked_tasks: [all blocked task IDs — direct + transitive]
            independent_tasks: [task IDs that can still proceed safely]
       c. Mark wave as failed, fall through to Step 5 (fix-and-retry)
     - If non-blocking: continue with remaining tasks, report failure at wave end
  4. Update state.yml updated_at
```

**Model tier mapping reference:**

| model_tier | Task() model | Typical use |
|-----------|-------------|-------------|
| `junior`  | `haiku`     | Scaffolding, templated output, spec compliance review |
| `senior`  | `sonnet`    | Content generation, implementation, reasoning |
| `principal` | `opus`    | Architecture, QA review, cross-cutting decisions |

#### 4c. Two-Stage Verification

After all tasks in the wave complete, run two-stage verification. Stage 1
(mechanical) gates Stage 2 (quality). This saves cost by catching structural
failures before invoking a principal-tier quality reviewer.

**Stage 1: Spec Compliance** (model_tier: junior)

1. Dispatch `spec-compliance-reviewer`:
   - **Subagent mode:** Fill `resources/prompts/spec-review-dispatch.md` template
     with task definitions, `task_complete` reports, and per-task git SHAs.
     Dispatch via `Task(model: haiku)`.
   - **Inline mode:** Run `spec-compliance-reviewer` directly with target skill's
     SKILL.md frontmatter, output files, state.yml, and file-ownership map.
2. Process the spec compliance report:

```
if status == "fail":
  Update phase status → "failed_spec"
  Log blocking issues to state.yml errors
  Enter fix-and-retry loop (see Step 5)
  DO NOT proceed to Stage 2
```

If Stage 1 passes, proceed to Stage 2.

**Stage 2: Quality Review** (model_tier: principal)

Only runs after Stage 1 passes. Check if this wave requires quality review:

```
if wave.qa_review is true:
  run Stage 2
elif verification_profile.qa_frequency == "every_wave":
  run Stage 2
elif this is the final wave:
  run Stage 2 (always required for final wave)
else:
  skip Stage 2 — mark phase "complete", continue to next wave
```

When running Stage 2:

1. Dispatch `qa-agent` (model: opus):
   - **Subagent mode:** Fill `resources/prompts/quality-review-dispatch.md`
     template with wave summary, `commit_range` (base_sha..head_sha), and
     Stage 1 report. Dispatch via `Task(model: opus)`.
   - **Inline mode:** Spawn `qa-agent` directly with plan file, wave number,
     working directory, and Stage 1 report.
2. The QA agent runs its 5-check quality protocol and returns a `qa_report`
3. Process the report:

```
if verdict == "PASS":
  Update phase status → "complete"
  Continue to next wave

elif verdict == "PASS_WITH_NOTES":
  Update phase status → "passed_with_notes"
  Log notes for final report
  Continue to next wave

elif verdict == "FAIL":
  Update phase status → "failed_quality"
  Log blocking issues to state.yml errors
  Enter fix-and-retry loop (see Step 5)
```

**Combined flow summary:**

```
Skill completes
  → Stage 1: spec-compliance-reviewer (junior/Haiku)
    → FAIL → mark failed_spec, fix-and-retry, skip Stage 2
    → PASS → check if Stage 2 required
      → Not required → mark complete, next wave
      → Required → Stage 2: qa-agent (principal/Opus)
        → FAIL → mark failed_quality, fix-and-retry
        → PASS_WITH_NOTES → mark passed_with_notes, continue
        → PASS → mark complete, continue
```

#### 4e. Write Recovery Notes

After each wave completes (pass or pass_with_warnings), write recovery context to **both** files:

**State file** (`state.yml` in the plan directory) — the resume point:

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

In subagent mode, also write the `commit_range` to the phase entry (if not already written in step 4b):

```yaml
# Phase entry in state.yml
phases:
  - name: "[phase name]"
    commit_range:
      base_sha: "[wave_base_sha from step 4b]"
      head_sha: "[wave_head_sha from step 4b]"
```

**Plan file** (`plan.yml` in the plan directory) — the persistent record:

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
     - Inline mode: re-execute the failed task with the fix guidance
     - Subagent mode: re-dispatch Task() with error context populated
       (worker-dispatch.md template fills previous_errors section)

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

#### Cascading Failure Analysis

When escalation to human occurs (`round > 3`), OR when a task fails and blocks later waves:

```
1. Walk the dependency graph forward from the failed task:
   - Direct dependents: tasks where failed_task_id is in their depends_on
   - Transitive dependents: tasks that depend on direct dependents (recursively)

2. Identify independent work:
   - Tasks in current and future waves that have NO path from the failed task
   - These can proceed safely

3. Present cascading impact to user:
   "Task [id] failed. Impact analysis:
    - Directly blocked: [list of task names]
    - Transitively blocked: [list of task names]
    - Independent (can proceed): [list of task names]

   Options:
   a) Continue with independent tasks only (skip [N] blocked tasks)
   b) Full halt — stop execution, preserve state for /plan:resume
   c) Propose alternative — describe a workaround for the blocked path"

4. Log the user's choice and full impact chain to state.yml:
   - blocked_tasks: [list of all blocked task IDs]
   - independent_tasks: [list of safe task IDs]
   - user_choice: "continue_independent" | "full_halt" | "alternative"

5. The orchestrator NEVER silently skips a blocked task. Every skip must be
   user-approved and logged in state.yml.
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
| Task() dispatch fails (subagent) | Fall back to inline mode for this task. Log error to state.yml. |
| Task produces no output | Mark task as failed. Enter fix-and-retry. |
| Session interrupted mid-wave | State is preserved. `/plan:resume` picks up from current wave. |
