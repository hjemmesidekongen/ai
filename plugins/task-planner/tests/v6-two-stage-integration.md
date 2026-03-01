# V6: Two-Stage Verification Integration Test

Tests that the verification-runner correctly handles both Stage 1 FAIL
(Stage 2 skipped) and Stage 1 PASS → Stage 2 (quality review runs).

---

## Test Fixtures

### Minimal Test Plan

```yaml
# .plans/v6-test.yml
plan:
  name: "v6-two-stage-test"
  version: "1.0.0"
  verification_profile: "standard"

  tasks:
    - id: task-01
      name: "echo-interview"
      wave: 1
      model_tier: junior
      owns:
        - echo-data.yml
      reads: []
      depends_on: []
      status: "completed"

  waves:
    - number: 1
      name: "data collection"
      tasks: ["task-01"]
      parallel: false
      qa_review: true
      verification:
        type: "data_validation"
        checks:
          - "echo-data.yml root key present"
          - "echo-data.yml name field non-empty"
```

### Target Skill Frontmatter (echo-interview/SKILL.md)

```yaml
name: echo-interview
writes:
  - echo-data.yml
checkpoint:
  type: data_validation
  checks:
    - "echo-data.yml root key present"
    - "echo-data.yml name field non-empty"
```

### File Ownership Map

```yaml
# .plans/v6-test.ownership.yml
task-01:
  owns:
    - echo-data.yml
```

---

## Scenario A: Stage 1 FAIL — Stage 2 Must Be Skipped

### Setup

`echo-data.yml` is MISSING from disk (the skill failed to write it).

### Stage 1 Dispatch

verification-runner dispatches `spec-compliance-reviewer` (model_tier: junior) with:
- Target writes: `["echo-data.yml"]`
- Checkpoint type: `data_validation`
- Files on disk: `[]` (empty)
- state.yml: `{ status: "in_progress", current_wave: 1, errors: [] }`
- Ownership: task-01 owns echo-data.yml

### Expected Stage 1 Report

```yaml
spec_compliance:
  skill: "echo-interview"
  status: fail
  checks:
    file_existence:
      status: fail
      expected: ["echo-data.yml"]
      missing: ["echo-data.yml"]
    schema_presence:
      status: fail
      sections: {}
    non_empty:
      status: fail
      empty_files: ["echo-data.yml (missing)"]
    file_ownership:
      status: pass
      violations: []
    state_consistency:
      status: pass
      current_state: "in_progress"
  summary: "3 of 5 checks failed: file_existence, schema_presence, non_empty"
```

### Expected verification-runner Behavior

```
Stage 1 returns status: fail
  → Update state.yml: phase status → "failed_spec"
  → Append to state.yml errors array:
      - timestamp: "[now]"
        skill: "echo-interview"
        error: "file_existence: echo-data.yml missing"
        attempted_fix: "pending"
        result: "unresolved"
        next_approach: "Ensure echo-interview writes echo-data.yml before completing"
  → Return verdict: fail to plan-execute
  → DO NOT dispatch qa-agent
  → Stage 2 is NOT invoked
```

### Expected state.yml After Scenario A

```yaml
status: "in_progress"
current_wave: 1
errors:
  - timestamp: "2026-03-01T10:00:00Z"
    skill: "echo-interview"
    error: "file_existence: echo-data.yml missing"
    attempted_fix: "pending"
    result: "unresolved"
    next_approach: "Ensure echo-interview writes echo-data.yml before completing"
phases:
  wave_1:
    status: "failed_spec"
```

### Pass Criteria for Scenario A

- [ ] Stage 1 returns `status: fail`
- [ ] Phase status in state.yml is `failed_spec` (not `failed_quality`, not `complete`)
- [ ] Error logged to state.yml `errors` array with `result: "unresolved"`
- [ ] `qa-agent` is NOT invoked (no Stage 2 dispatch)
- [ ] plan-execute enters fix-and-retry loop (Step 5), NOT the next wave

---

## Scenario B: Stage 1 PASS → Stage 2 Runs

### Setup

`echo-data.yml` exists on disk with valid content:

```yaml
# echo-data.yml
echo:
  name: "Acme Echo Service"
  version: "1.0"
```

state.yml is reset: `{ status: "in_progress", current_wave: 1, errors: [] }`

### Stage 1 Dispatch

Same inputs as Scenario A, but echo-data.yml is now present.

### Expected Stage 1 Report

```yaml
spec_compliance:
  skill: "echo-interview"
  status: pass
  checks:
    file_existence:
      status: pass
      expected: ["echo-data.yml"]
      missing: []
    schema_presence:
      status: pass
      sections: { echo: present }
    non_empty:
      status: pass
      empty_files: []
    file_ownership:
      status: pass
      violations: []
    state_consistency:
      status: pass
      current_state: "in_progress"
  summary: "All 5 checks passed"
```

### Expected verification-runner Behavior After Stage 1 PASS

```
Stage 1 returns status: pass
  → Check Stage 2 gate:
      wave.qa_review is true → run Stage 2
  → Dispatch qa-agent (model_tier: principal) with:
      plan: ".plans/v6-test.yml"
      wave: 1
      working_directory: "."
      stage_1_report: [compliance report above]
```

### Scenario B1: Stage 2 Returns PASS

```yaml
qa_report:
  plan: "v6-two-stage-test"
  wave_reviewed: 1
  reviewed_at: "2026-03-01T10:05:00Z"
  review_round: 1
  stage: 2
  checks:
    - name: "Content Coherence"
      status: "pass"
      notes: "echo-data.yml fields are consistent"
      fix_required: false
    - name: "Brand/Domain Consistency"
      status: "pass"
      notes: "No prior skills to cross-reference"
      fix_required: false
    - name: "Completeness"
      status: "pass"
      notes: "All declared fields present"
      fix_required: false
    - name: "Quality Floor"
      status: "pass"
      notes: "name field is specific and non-generic"
      fix_required: false
    - name: "Cross-Skill Alignment"
      status: "pass"
      notes: "Wave 1 is the first wave — no alignment checks needed"
      fix_required: false
  verdict: "PASS"
  blocking_issues: 0
  notes_count: 0
```

**Expected state.yml after B1:**

```yaml
phases:
  wave_1:
    status: "complete"
errors: []
```

**Pass criteria for B1:**
- [ ] Phase status is `complete`
- [ ] No errors logged
- [ ] plan-execute advances to next wave (or marks plan complete)

### Scenario B2: Stage 2 Returns PASS_WITH_NOTES

```yaml
qa_report:
  verdict: "PASS_WITH_NOTES"
  blocking_issues: 0
  notes_count: 1
  checks:
    - name: "Quality Floor"
      status: "pass_with_notes"
      notes: "name field is fine but version field is a string — consider semantic versioning"
      fix_required: false
```

**Expected state.yml after B2:**

```yaml
phases:
  wave_1:
    status: "passed_with_notes"
```

**Pass criteria for B2:**
- [ ] Phase status is `passed_with_notes` (not `complete`, not `failed_quality`)
- [ ] plan-execute continues to next wave (non-blocking)
- [ ] Notes are logged to the final plan report

### Scenario B3: Stage 2 Returns FAIL

```yaml
qa_report:
  verdict: "FAIL"
  blocking_issues: 1
  checks:
    - name: "Quality Floor"
      status: "fail"
      notes: "name field is 'test' — generic placeholder, not a real value"
      fix_required: true
      suggested_fix: "Replace 'test' with a meaningful service name"
```

**Expected state.yml after B3:**

```yaml
phases:
  wave_1:
    status: "failed_quality"
errors:
  - timestamp: "[now]"
    skill: "echo-interview"
    error: "Quality Floor: name field is generic placeholder"
    attempted_fix: "pending"
    result: "unresolved"
    next_approach: "Replace 'test' with a meaningful service name"
```

**Pass criteria for B3:**
- [ ] Phase status is `failed_quality` (NOT `failed_spec` — Stage 1 passed)
- [ ] Error logged with `result: "unresolved"`
- [ ] plan-execute enters fix-and-retry loop, re-runs ONLY Stage 2 on retry
  (Stage 1 does NOT re-run — its result is cached as pass)

---

## Stage 2 Gate: When Stage 2 Is Skipped

When `wave.qa_review` is false AND `qa_frequency` is not `every_wave`
AND this is not the final wave — Stage 2 should be skipped even after
Stage 1 passes.

### Setup

Same as Scenario B, but wave has `qa_review: false`.

### Expected Behavior

```
Stage 1 returns status: pass
  → Check Stage 2 gate:
      wave.qa_review is false
      qa_frequency is not "every_wave"
      this is not the final wave
      → SKIP Stage 2
  → Update phase status → "complete"
  → Continue to next wave without invoking qa-agent
```

**Pass criteria:**
- [ ] Phase status is `complete` (Stage 1 pass is sufficient)
- [ ] `qa-agent` is NOT invoked
- [ ] plan-execute advances to next wave

---

## Decision Matrix Summary

| Stage 1 | Stage 2 Required? | Stage 2 Verdict | Phase Status | Next Action |
|---------|-------------------|-----------------|--------------|-------------|
| FAIL | — (skipped) | — | `failed_spec` | Fix-and-retry |
| PASS | No | — | `complete` | Next wave |
| PASS | Yes | PASS | `complete` | Next wave |
| PASS | Yes | PASS_WITH_NOTES | `passed_with_notes` | Next wave |
| PASS | Yes | FAIL | `failed_quality` | Fix-and-retry (Stage 2 only) |

---

## Retry Behavior

When re-running after a Stage 1 failure (`failed_spec`):
- Re-run Stage 1 first
- If Stage 1 now passes: proceed to Stage 2 gate normally

When re-running after a Stage 2 failure (`failed_quality`):
- Stage 1 result is CACHED — do NOT re-dispatch spec-compliance-reviewer
- Re-run Stage 2 only with the fix guidance from state.yml errors
- Maximum 3 rounds before escalating to `manual_approval`
