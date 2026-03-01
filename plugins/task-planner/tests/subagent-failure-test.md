# SE13: Failure and Retry Integration Test

Tests that plan-execute correctly handles task failures, logs errors to
state.yml with context from subagent reports, dispatches retries with
error context, and respects the two-stage verification retry behavior
(Stage 1 re-runs on failed_spec; Stage 1 cached on failed_quality).

---

## Test Fixtures

### Plan With Deliberate Failure Point

```yaml
# .plans/se13-failure-test.yml
plan:
  name: "se13-failure-test"
  created_at: "2026-03-01T10:00:00Z"
  total_tasks: 2
  total_waves: 2
  status: pending
  verification_profile: "standard"
  execution_mode: subagent

  tasks:
    - id: t1
      name: "generate-profile"
      depends_on: []
      files_written:
        - profile.yml
      files_read: []
      status: pending
      model_tier: senior

    - id: t2
      name: "generate-report"
      depends_on: [t1]
      files_written:
        - report.yml
      files_read:
        - profile.yml
      status: pending
      model_tier: senior

  waves:
    - wave: 1
      parallel: false
      tasks: [t1]
      depends_on_waves: []
      rationale: "Profile must exist before report"
      status: pending
      verification:
        type: data_validation
        checks:
          - "profile.yml exists"
          - "profile.yml has 'profile' root key"
          - "profile.yml has non-empty 'name' field"
      qa_review: true

    - wave: 2
      parallel: false
      tasks: [t2]
      depends_on_waves: [1]
      rationale: "Report depends on profile"
      status: pending
      verification:
        type: data_validation
        checks:
          - "report.yml exists"
          - "report.yml has 'report' root key"
      qa_review: true
```

### Ownership Registry

```yaml
# .plans/se13-failure-test.ownership.yml
t1:
  owns:
    - profile.yml
  reads: []

t2:
  owns:
    - report.yml
  reads:
    - profile.yml
```

### Initial State

```yaml
# .plans/se13-failure-test.state.yml
command: "plan:execute"
project: "se13-failure-test"
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

## Scenario A: Task Reports Failure — Subagent Returns `status: failed`

### Setup

The t1 subagent fails during execution (e.g., cannot determine profile data)
and reports back with `status: failed`.

### Simulated Subagent Report

```yaml
task_complete:
  task_id: "t1"
  model_tier: "senior"
  status: failed
  commit_sha: ""
  artifacts_written: []
  decisions_made: []
  recovery_notes: |
    Attempted to generate profile but skill instructions reference
    a brand-reference.yml that does not exist in reads list.
  error: "Missing input: brand-reference.yml not available"
  needs: "brand-reference.yml should be added to reads list or provided inline"
```

### Expected Orchestrator Behavior

```
1. Collect task_complete report — status: failed
2. DO NOT attempt to record commit_sha (empty)
3. Update t1.status → "failed" in plan
4. Log error to state.yml:
   - timestamp: [now]
   - skill: "generate-profile"
   - error: "Missing input: brand-reference.yml not available"
   - attempted_fix: "pending"
   - result: "unresolved"
   - next_approach: "brand-reference.yml should be added to reads list or provided inline"
5. Check if t1 blocks later waves:
   - t2 depends_on: [t1] → t1 IS blocking
   - Mark wave as failed
6. Enter fix-and-retry (Step 5)
```

### Expected Fix-and-Retry (Round 1)

```
1. Read state.yml errors for generate-profile
2. Find unresolved error with next_approach
3. Re-dispatch t1 via Task() with error context:
   worker-dispatch.md template fills previous_errors section:
   - Error: "Missing input: brand-reference.yml not available"
   - What was tried: "pending"
   - Try instead: "brand-reference.yml should be added to reads list..."
4. t1 subagent retry gets fresh context PLUS error guidance
5. If t1 now succeeds:
   - Record commit_sha
   - Update error entry: result → "resolved"
   - Proceed to verification
```

### Expected State After Failure (Before Retry)

```yaml
status: "in_progress"
current_phase: "generate-profile"
current_phase_number: 1
phases:
  - name: "generate-profile"
    number: 1
    status: "failed"
errors:
  - timestamp: "2026-03-01T10:01:00Z"
    skill: "generate-profile"
    error: "Missing input: brand-reference.yml not available"
    attempted_fix: "pending"
    result: "unresolved"
    next_approach: "brand-reference.yml should be added to reads list or provided inline"
```

### Pass Criteria for Scenario A

- [ ] Failed subagent report correctly parsed
- [ ] Error logged to state.yml with all fields populated
- [ ] next_approach populated from subagent's `needs` field
- [ ] Wave marked failed (blocking dependency)
- [ ] Retry dispatch includes previous_errors in worker-dispatch template
- [ ] Retry subagent gets fresh context (no accumulated state)
- [ ] On successful retry: error updated to result: "resolved"

---

## Scenario B: Spec Compliance Failure — `failed_spec` Status

### Setup

t1 executes and commits, but produces an invalid output. The subagent
reports success, but spec compliance catches the issue.

### Simulated t1 Report (Claims Success)

```yaml
task_complete:
  task_id: "t1"
  model_tier: "senior"
  status: completed
  commit_sha: "<sha-t1>"
  artifacts_written:
    - path: "profile.yml"
      description: "Profile data"
```

### Actual File on Disk

```yaml
# profile.yml — MISSING required 'name' field
profile:
  version: "1.0"
  # name field is absent
```

### Expected Spec Review Report

```yaml
spec_compliance:
  scope: "wave-1-tasks"
  tasks:
    t1:
      status: fail
      checks:
        file_existence:
          status: pass
          missing: []
        non_empty:
          status: pass
          empty: []
        schema_presence:
          status: fail
          missing_sections: ["profile.name"]
        file_ownership:
          status: pass
          violations: []
      issues:
        - file: "profile.yml"
          issue: "Missing required 'name' field under 'profile' root key"
  overall: fail
  summary: "1 task failed spec compliance: t1 (missing profile.name)"
```

### Expected Orchestrator Behavior

```
1. Spec compliance returns overall: fail
2. Update phase status → "failed_spec"
3. Log error:
   - skill: "generate-profile"
   - error: "schema_presence: missing profile.name"
   - next_approach: "Add non-empty 'name' field to profile.yml"
4. DO NOT dispatch qa-agent (Stage 2 skipped on failed_spec)
5. Enter fix-and-retry:
   - Re-dispatch t1 with error context:
     "Previous attempt: profile.yml missing 'name' field. Add it."
   - t1 retry fixes the file, commits
   - Re-run spec compliance (Stage 1 re-runs on failed_spec)
   - If passes: proceed to Stage 2 gate
```

### Expected State After failed_spec

```yaml
phases:
  - name: "generate-profile"
    number: 1
    status: "failed_spec"
errors:
  - timestamp: "[now]"
    skill: "generate-profile"
    error: "schema_presence: missing profile.name"
    attempted_fix: "pending"
    result: "unresolved"
    next_approach: "Add non-empty 'name' field to profile.yml"
```

### Pass Criteria for Scenario B

- [ ] Spec review dispatched as Task(model: haiku)
- [ ] Phase status is `failed_spec` (not `failed_quality`)
- [ ] QA agent NOT invoked (Stage 2 skipped)
- [ ] Error logged with spec failure details
- [ ] Fix-and-retry re-dispatches t1 with error context
- [ ] After fix: Stage 1 RE-RUNS (not cached — this was a spec failure)
- [ ] After fix passes Stage 1: Stage 2 gate checked normally

---

## Scenario C: Quality Review Failure — `failed_quality` Status

### Setup

t1 executes and commits, spec compliance passes, but quality review
finds the content is generic/placeholder.

### Simulated QA Report

```yaml
qa_report:
  wave: 1
  review_round: 1
  base_sha: "<wave-base>"
  head_sha: "<wave-head>"
  checks:
    - name: "Content Coherence"
      status: pass
      notes: "Fields are internally consistent"
      fix_required: false
    - name: "Quality Floor"
      status: fail
      notes: "profile.name is 'Test Company' — generic placeholder, not real"
      fix_required: true
      severity: critical
      suggested_fix: "Use the actual company name from project context"
    - name: "Completeness"
      status: pass
      notes: "All required fields present"
      fix_required: false
  verdict: FAIL
  blocking_issues: 1
```

### Expected Orchestrator Behavior

```
1. QA report returns verdict: FAIL
2. Update phase status → "failed_quality"
3. Log error:
   - skill: "generate-profile"
   - error: "Quality Floor: profile.name is generic placeholder"
   - next_approach: "Use the actual company name from project context"
4. Enter fix-and-retry:
   - Re-dispatch t1 with error context pointing to quality issue
   - t1 retry fixes the placeholder
   - Stage 1 is CACHED (already passed — DO NOT re-run)
   - Re-run Stage 2 only (quality review)
```

### Expected State After failed_quality

```yaml
phases:
  - name: "generate-profile"
    number: 1
    status: "failed_quality"
errors:
  - timestamp: "[now]"
    skill: "generate-profile"
    error: "Quality Floor: profile.name is generic placeholder"
    attempted_fix: "pending"
    result: "unresolved"
    next_approach: "Use the actual company name from project context"
```

### Pass Criteria for Scenario C

- [ ] Phase status is `failed_quality` (not `failed_spec`)
- [ ] Error logged with quality failure details
- [ ] Fix-and-retry re-dispatches t1 with quality error context
- [ ] After fix: Stage 1 does NOT re-run (cached from first pass)
- [ ] After fix: Stage 2 re-runs with updated commit range
- [ ] On Stage 2 pass: phase status → "complete"

---

## Scenario D: Exhausted Retries — Escalation to Manual Approval

### Setup

t1 fails spec compliance 3 times in a row (different errors each time).

### Simulated Retry History

```yaml
errors:
  # Round 1
  - timestamp: "2026-03-01T10:01:00Z"
    skill: "generate-profile"
    error: "file_existence: profile.yml missing"
    attempted_fix: "Dispatched retry with instruction to create file"
    result: "partial"
    next_approach: "File created but missing root key"

  # Round 2
  - timestamp: "2026-03-01T10:02:00Z"
    skill: "generate-profile"
    error: "schema_presence: missing profile root key"
    attempted_fix: "Dispatched retry with instruction to add root key"
    result: "partial"
    next_approach: "Root key present but name field empty"

  # Round 3
  - timestamp: "2026-03-01T10:03:00Z"
    skill: "generate-profile"
    error: "non_empty: profile.name is empty string"
    attempted_fix: "Dispatched retry with instruction to populate name"
    result: "unresolved"
    next_approach: "Manual intervention required"
```

### Expected Behavior After Round 3

```
1. round > 3 → escalate to manual approval
2. Present to user:
   "Unable to resolve 1 issue after 3 attempts. Presenting for manual review."
3. Show the 3 error entries with attempted fixes
4. User decides: fix manually, skip wave, or abort plan
```

### Pass Criteria for Scenario D

- [ ] All 3 retry rounds dispatched with distinct error context
- [ ] Each round checks previous errors before dispatching
- [ ] No approach is repeated (each retry uses next_approach from prior error)
- [ ] After 3 failures: escalation to manual_approval
- [ ] User presented with full error history
- [ ] User given 3 options: fix, skip, abort

---

## Pass Criteria — Full Test

### Error Context Flow

- [ ] Failed subagent `error` field → state.yml `error` field
- [ ] Failed subagent `needs` field → state.yml `next_approach` field
- [ ] Failed subagent `recovery_notes` → used to build retry context
- [ ] Retry dispatch includes previous_errors section in template
- [ ] Each retry gets FRESH context (no accumulated state from prior attempt)

### Two-Stage Retry Behavior

- [ ] failed_spec: Stage 1 re-runs, Stage 2 gate checked after
- [ ] failed_quality: Stage 1 cached, Stage 2 re-runs only
- [ ] Spec review dispatched as haiku subagent
- [ ] Quality review dispatched as opus subagent

### State Persistence

- [ ] Errors array grows (never shrinks) — entries marked resolved, not deleted
- [ ] Phase status transitions: pending → in_progress → failed_spec → in_progress → complete
- [ ] Resolved errors have `result: "resolved"` (not removed from array)
- [ ] Unresolved errors preserve `next_approach` for next retry

### Escalation

- [ ] Maximum 3 retry rounds enforced
- [ ] Round count tracked per-skill (not global)
- [ ] Escalation message includes full error history
- [ ] User can manually fix and resume

---

## Decision Matrix

| Failure Type | Phase Status | Stage 1 on Retry | Stage 2 on Retry | Max Retries |
|-------------|--------------|-------------------|-------------------|-------------|
| Task failed | failed | re-run task + Stage 1 | gate check | 3 |
| Spec fail   | failed_spec  | re-run | gate check | 3 |
| Quality fail | failed_quality | cached (skip) | re-run | 3 |
| 3x failure  | failed | — | — | escalate |
