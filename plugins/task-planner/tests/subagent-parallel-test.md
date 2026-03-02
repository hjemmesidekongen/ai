# SE12: Parallel Subagent Dispatch Integration Test

Tests that plan-execute correctly dispatches multiple tasks simultaneously
when `wave.parallel == true`, collects all task_complete reports, detects
file conflicts, and records a unified commit_range for the wave.

---

## Test Fixtures

### Parallel Wave Plan

```yaml
# .ai/plans/se12-parallel-test/plan.yml
plan:
  name: "se12-parallel-test"
  created_at: "2026-03-01T10:00:00Z"
  total_tasks: 3
  total_waves: 2
  status: pending
  verification_profile: "standard"
  execution_mode: subagent

  tasks:
    - id: t1
      name: "generate-colors"
      depends_on: []
      files_written:
        - colors.yml
      files_read: []
      status: pending
      model_tier: junior

    - id: t2
      name: "generate-typography"
      depends_on: []
      files_written:
        - typography.yml
      files_read: []
      status: pending
      model_tier: junior

    - id: t3
      name: "compile-theme"
      depends_on: [t1, t2]
      files_written:
        - theme.yml
      files_read:
        - colors.yml
        - typography.yml
      status: pending
      model_tier: senior

  waves:
    - wave: 1
      parallel: true
      tasks: [t1, t2]
      depends_on_waves: []
      rationale: "Colors and typography are independent — safe to parallelize"
      status: pending
      verification:
        type: data_validation
        checks:
          - "colors.yml exists with 'colors' root key"
          - "typography.yml exists with 'typography' root key"
      qa_review: false

    - wave: 2
      parallel: false
      tasks: [t3]
      depends_on_waves: [1]
      rationale: "Theme compilation depends on both color and typography data"
      status: pending
      verification:
        type: data_validation
        checks:
          - "theme.yml exists with 'theme' root key"
          - "theme.yml references colors and typography"
      qa_review: true
```

### Ownership Registry

```yaml
# .ai/plans/se12-parallel-test/ownership.yml
t1:
  owns:
    - colors.yml
  reads: []

t2:
  owns:
    - typography.yml
  reads: []

t3:
  owns:
    - theme.yml
  reads:
    - colors.yml
    - typography.yml
```

### Initial State

```yaml
# .ai/plans/se12-parallel-test/state.yml
command: "plan:execute"
project: "se12-parallel-test"
started_at: null
updated_at: null
status: pending
current_phase: null
current_phase_number: 0
total_phases: 2
phases: []
errors: []
```

---

## Scenario A: Parallel Dispatch (Happy Path)

### Pre-conditions

- Plan, ownership, and state files exist as above
- File ownership has no overlaps (t1 owns colors.yml, t2 owns typography.yml)
- Working directory is clean

### Execution

Run: `/plan:execute .ai/plans/se12-parallel-test/plan.yml --mode subagent`

### Expected Behavior — Wave 1 (Parallel)

#### Step 1: Pre-flight

```
1. Orchestrator reads plan, ownership, state
2. Detects wave 1 has parallel: true
3. Records wave_base_sha = current git HEAD
4. Reports: "Starting wave 1 of 2 (parallel): generate-colors, generate-typography"
```

#### Step 2: Build ALL Task() Calls

```
For t1 (generate-colors):
  - Fill worker-dispatch.md: task_id=t1, owns=[colors.yml], reads=[]
  - model: haiku (junior → haiku)
  - task_base_sha = wave_base_sha (shared for parallel tasks)

For t2 (generate-typography):
  - Fill worker-dispatch.md: task_id=t2, owns=[typography.yml], reads=[]
  - model: haiku (junior → haiku)
  - task_base_sha = wave_base_sha (shared for parallel tasks)
```

#### Step 3: Dispatch Simultaneously

```
Issue BOTH Task() calls in a single response:

Task(
  description: "Task t1: generate-colors",
  prompt: [filled t1 template],
  model: haiku,
  subagent_type: "general-purpose"
)

Task(
  description: "Task t2: generate-typography",
  prompt: [filled t2 template],
  model: haiku,
  subagent_type: "general-purpose"
)

Both dispatched in the SAME turn — Claude Code runs them concurrently.
```

#### Step 4: Collect All Reports

Wait for both subagents to return. Expected reports:

```yaml
# t1 report
task_complete:
  task_id: "t1"
  model_tier: "junior"
  status: completed
  commit_sha: "<sha-t1>"
  artifacts_written:
    - path: "colors.yml"
      description: "Color palette definitions"

# t2 report
task_complete:
  task_id: "t2"
  model_tier: "junior"
  status: completed
  commit_sha: "<sha-t2>"
  artifacts_written:
    - path: "typography.yml"
      description: "Typography system definitions"
```

#### Step 5: Post-Dispatch Conflict Check

```
1. Run check-file-conflicts.sh against actual files written
   - t1 wrote: colors.yml
   - t2 wrote: typography.yml
   - No overlap → pass
2. Record all base_sha/commit_sha in plan
3. Record wave_head_sha = current git HEAD
4. Write commit_range to state.yml phase entry
```

#### Step 6: Wave 1 Verification

```
Stage 1: spec-compliance-reviewer (haiku) covers BOTH tasks:
  - colors.yml exists with colors root key → pass
  - typography.yml exists with typography root key → pass
  - File ownership: no violations → pass
  - Overall: pass

Stage 2 gate: qa_review is false, not final wave → SKIP
Phase status → "complete"
```

### Expected State After Wave 1

```yaml
status: "in_progress"
current_phase_number: 1
phases:
  - name: "wave-1-parallel"
    number: 1
    status: "complete"
    commit_range:
      base_sha: "<wave-base>"
      head_sha: "<wave-head>"    # after BOTH t1 and t2 commits
completed_waves: [1]
errors: []
```

### Expected Behavior — Wave 2 (Sequential, Depends on Wave 1)

```
1. t3 dispatched as Task(model: sonnet) — senior tier
2. t3 subagent receives reads: [colors.yml, typography.yml]
3. t3 reads both files (committed by parallel wave 1)
4. t3 creates theme.yml, commits
5. Stage 1 + Stage 2 verification (final wave, qa_review: true)
6. Plan marked complete
```

---

## Scenario B: Partial Failure in Parallel Wave

### Setup

Same plan, but t2 fails (e.g., the generate-typography subagent encounters
an error and cannot produce typography.yml).

### Expected Behavior

```
1. t1 and t2 dispatched in parallel
2. t1 returns: status: completed, commit_sha: <sha>
3. t2 returns: status: failed, error: "Could not determine font stack"
4. Orchestrator processes both reports:
   - t1: mark completed, record SHA
   - t2: mark failed
5. Check if t2 blocks later waves:
   - t3 depends_on: [t1, t2] → t2 IS blocking
   - Result: wave 1 fails
6. Log error to state.yml:
   - skill: "generate-typography"
   - error: "Could not determine font stack"
   - result: "unresolved"
7. Enter fix-and-retry (Step 5):
   - Re-dispatch ONLY t2 (t1 already completed)
   - t2 retry receives error context in worker-dispatch template
```

### Expected State After Partial Failure

```yaml
status: "in_progress"
phases:
  - name: "wave-1-parallel"
    number: 1
    status: "failed"
errors:
  - timestamp: "[now]"
    skill: "generate-typography"
    error: "Could not determine font stack"
    attempted_fix: "pending"
    result: "unresolved"
    next_approach: "Use system font stack as fallback"
```

### Pass Criteria for Scenario B

- [ ] Both tasks dispatched in same turn (not sequentially)
- [ ] t1 success is preserved (not rolled back or re-dispatched)
- [ ] t2 failure logged to state.yml errors
- [ ] Wave marked as failed (because t2 blocks t3)
- [ ] Fix-and-retry dispatches ONLY t2, not t1
- [ ] t2 retry prompt includes error context from state.yml

---

## Scenario C: Non-Blocking Failure

### Setup

Modified plan where t3 does NOT depend on t2:

```yaml
# Modified t3:
- id: t3
  depends_on: [t1]    # only depends on t1, not t2
```

### Expected Behavior

```
1. t1 and t2 dispatched in parallel
2. t1 succeeds, t2 fails
3. Check if t2 blocks later waves:
   - t3 depends_on: [t1] — t2 is NOT a dependency
   - Result: t2 failure is non-blocking
4. Proceed to verification:
   - Spec review reports t2 failure
   - Log error for t2
5. Advance to wave 2:
   - t3 can proceed (only depends on t1)
   - t2 failure reported at wave end
```

### Pass Criteria for Scenario C

- [ ] t2 failure does NOT block wave 2
- [ ] t3 dispatched successfully after wave 1
- [ ] t2 failure is logged and reported but does not halt execution
- [ ] Final plan status reflects t2 failure (partial completion)

---

## Pass Criteria — Full Test

### Parallel Dispatch Mechanics

- [ ] Both t1 and t2 dispatched in a SINGLE Task() turn (not sequential)
- [ ] Both subagents run concurrently
- [ ] Orchestrator waits for ALL to return before proceeding
- [ ] Both task_complete reports collected

### File Ownership in Parallel

- [ ] check-file-conflicts.sh runs after parallel completion
- [ ] No ownership violations detected (t1 and t2 write to different files)
- [ ] Each subagent only writes to its own files

### Commit Tracking

- [ ] Both t1 and t2 have separate commits
- [ ] Both commit SHAs recorded in plan (base_sha, commit_sha per task)
- [ ] Wave commit_range spans from wave_base_sha to wave_head_sha
- [ ] wave_head_sha is AFTER both t1 and t2 commits

### State Consistency

- [ ] State.yml updated once after wave completes (not per-task)
- [ ] Single commit_range covers the entire parallel wave
- [ ] completed_waves updated atomically: [] → [1]

### Downstream Dependency

- [ ] Wave 2 task (t3) can read outputs from BOTH parallel tasks
- [ ] t3 subagent prompt includes both colors.yml and typography.yml in reads

### Spec Review Coverage

- [ ] Spec review covers ALL tasks in the parallel wave (not just one)
- [ ] Spec review receives all task_complete reports

---

## Decision Matrix

| Scenario | t1 | t2 | t2 Blocks t3? | Wave Status | Next Action |
|----------|----|----|---------------|-------------|-------------|
| A        | pass | pass | n/a        | complete    | Wave 2      |
| B        | pass | fail | Yes        | failed      | Retry t2    |
| C        | pass | fail | No         | partial     | Wave 2 (report t2) |
