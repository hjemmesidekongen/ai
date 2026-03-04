---
name: plan-resume
command: "/plan:resume"
description: "(plan) Resume an interrupted plan from where it left off"
arguments:
  - name: plan_file
    type: string
    required: false
    description: "Path to the plan file. If omitted, resumes the most recently active plan."
---

# /plan:resume

Resumes execution of a plan that was interrupted — by a session end, crash, context compaction, or manual pause. Reads persisted state to reconstruct context and continues from exactly where work stopped.

## Usage

```
/plan:resume                                                       # resume most recent active plan
/plan:resume .ai/plans/brand-generate-acme-corp/plan.yml           # resume specific plan
```

## When to Use

- **New session** — User starts a new Claude Code session and wants to continue previous work
- **After compaction** — Context was compressed and execution state was lost from the conversation
- **After crash** — Session ended unexpectedly mid-execution
- **After manual pause** — User interrupted execution with Ctrl+C or Escape

## Execution Steps

### Step 1: Find the Plan

**If plan_file provided:** Use that plan.

**If no plan_file:** Scan `.ai/plans/` for all `*/state.yml` files. Find the most recently updated one with `status: "in_progress"`:

```
for each state file in .ai/plans/:
  if status == "in_progress":
    candidates.append(file, updated_at)

if candidates is empty:
  "No active plans found. All plans are either completed or not yet started."
  "Run `/plan:status` to see all plans, or `/plan:create` to start a new one."
  STOP

resume the candidate with the most recent updated_at
```

If multiple active plans exist, list them and ask the user which to resume:

```
Multiple active plans found:

  1. brand-generate-acme-corp — wave 3 in progress (updated 10 min ago)
  2. site-build-marketing — wave 2 in progress (updated 2 hours ago)

Which plan should I resume?
```

### Step 2: Read State

Load three files:

1. **State file** (`state.yml` in the plan directory) — primary resume source:
   - `current_wave` — which wave was in progress
   - `completed_waves` — which waves are done
   - `status` — should be `in_progress`
   - `recovery_notes` — free-text context about where things stand
   - `last_session_id` — which session last touched this plan

2. **Plan file** (`plan.yml` in the plan directory) — backup and full definitions:
   - Full task and wave definitions
   - Task statuses (which tasks completed, which were in progress)
   - `recovery_notes` — fallback if state file recovery_notes are missing

3. **Ownership registry** (`ownership.yml` in the plan directory):
   - File ownership assignments
   - Any conflict resolutions from plan creation

### Step 3: Reconstruct Context

Report the current state to the user clearly:

```
## Resuming: brand-generate-acme-corp

**Last active:** 42 minutes ago
**Progress:** 2 of 4 waves completed

### Completed Work
  Wave 1 ✓ — color palette, typography system
  Wave 2 ✓ — logo concepts, icon library

### Current State
  Wave 3 was in progress:
    ├─ t5: Generate favicons ✓ completed
    ├─ t6: Generate app icons ● was in progress
    └─ t7: Generate social images ○ not started

### Recovery Context
  Wave 3 started generating derived assets. Favicons completed
  with dark mode variant. App icons were being generated when
  session ended — iOS sizes done, Android pending.

### What Happens Next
  1. Re-verify t5 output (favicons) — quick check since it was marked complete
  2. Re-run t6 (app icons) from scratch — partial output is unreliable
  3. Run t7 (social images)
  4. Run file_validation for wave 3
  5. Continue to wave 4
```

### Step 4: Validate Completed Work

Before continuing, verify that previously completed waves are still intact:

```
for each completed wave:
  1. Check that output files still exist on disk
     (files could have been deleted between sessions)
  2. If files missing: mark wave as "needs_rerun" and warn user
  3. If files present: trust the previous verification result
```

This is a lightweight check — not a full re-verification. Just confirm artifacts exist.

If completed work is missing:

```
⚠ Warning: Outputs from wave 2 are partially missing.
  Missing: assets/icons/arrow-left.svg, assets/icons/arrow-right.svg

  Options:
  1. Re-run wave 2 to regenerate missing files
  2. Continue anyway (wave 3 may fail if it depends on these files)
  3. Abort and investigate
```

### Step 5: Handle Partially Completed Wave

The current wave may have been interrupted mid-execution. Determine what to do with each task:

```
for each task in current_wave:
  if task.status == "completed":
    # Quick-verify output exists
    if output files exist:
      keep as completed
    else:
      mark for re-run

  elif task.status == "in_progress":
    # Was interrupted — partial output is unreliable
    mark for re-run from scratch
    delete any partial output files

  elif task.status == "pending":
    # Never started — run normally
    keep as pending
```

Report the decision:

```
Wave 3 recovery plan:
  t5: Keep (completed, output verified)
  t6: Re-run (was in progress when interrupted)
  t7: Run (not yet started)
```

### Step 6: Continue Execution

Hand off to the `/plan:execute` logic, starting from the current wave:

1. Execute remaining tasks in the current wave
2. Run verification for the current wave
3. Run QA if required
4. Continue with subsequent waves
5. All the same gates, retries, and reporting as `/plan:execute`

This is equivalent to calling:

```
/plan:execute [plan-file] --start-wave [current_wave]
```

But with the additional context reconstruction from steps 2-5.

### Step 7: Update State

After resumption begins, update the state file:

```yaml
status: "in_progress"
current_wave: [wave number]
updated_at: "[now]"
last_session_id: "[current session]"
```

The `recovery_notes` are preserved until new notes are written after the next wave completes.

## Edge Cases

### Plan Already Completed

```
Plan "brand-generate-acme-corp" is already completed (finished 2 hours ago).

  Options:
  1. View results: `/plan:status .ai/plans/brand-generate-acme-corp/plan.yml --verbose`
  2. Re-run the entire plan: `/plan:execute .ai/plans/brand-generate-acme-corp/plan.yml`
```

### Plan Failed (Not Interrupted)

If the plan's status is `failed` (verification or QA failure, not an interruption):

```
Plan "seo-audit-homepage" failed at wave 2 (verification: data_validation).

Blocking issues:
  ✗ Structured data missing @type field in 3 entries

Options:
  1. Retry from wave 2: `/plan:execute .ai/plans/seo-audit-homepage/plan.yml --start-wave 2`
  2. View full status: `/plan:status .ai/plans/seo-audit-homepage/plan.yml --verbose`
```

### No State File

If the plan file exists but no state file:

```
Plan "brand-generate-acme-corp" exists but has never been executed.
Run `/plan:execute .ai/plans/brand-generate-acme-corp/plan.yml` to start.
```

### Stale Recovery Notes

If `recovery_notes` reference a session that's very old (> 24 hours), flag it:

```
⚠ Recovery notes are from 3 days ago. The working directory may have
  changed since then. Recommend verifying completed waves before continuing.
```
