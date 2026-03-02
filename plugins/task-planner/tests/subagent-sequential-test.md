# SE11: Sequential Subagent Dispatch Integration Test

Tests that plan-execute correctly dispatches tasks as isolated subagents in
sequential mode (wave.parallel == false), collects task_complete reports,
records commit SHAs, and advances through a 2-wave plan.

---

## Test Fixtures

### Minimal 2-Wave Plan

```yaml
# .ai/plans/se11-sequential-test/plan.yml
plan:
  name: "se11-sequential-test"
  created_at: "2026-03-01T10:00:00Z"
  total_tasks: 2
  total_waves: 2
  status: pending
  verification_profile: "standard"
  execution_mode: subagent

  tasks:
    - id: t1
      name: "generate-config"
      depends_on: []
      files_written:
        - config-data.yml
      files_read: []
      status: pending
      model_tier: senior

    - id: t2
      name: "generate-summary"
      depends_on: [t1]
      files_written:
        - summary.yml
      files_read:
        - config-data.yml
      status: pending
      model_tier: senior

  waves:
    - wave: 1
      parallel: false
      tasks: [t1]
      depends_on_waves: []
      rationale: "Config must exist before summary"
      status: pending
      verification:
        type: data_validation
        checks:
          - "config-data.yml exists"
          - "config-data.yml has root 'config' key"
      qa_review: false

    - wave: 2
      parallel: false
      tasks: [t2]
      depends_on_waves: [1]
      rationale: "Summary reads config output"
      status: pending
      verification:
        type: data_validation
        checks:
          - "summary.yml exists"
          - "summary.yml has root 'summary' key"
      qa_review: true
```

### Ownership Registry

```yaml
# .ai/plans/se11-sequential-test/ownership.yml
t1:
  owns:
    - config-data.yml
  reads: []

t2:
  owns:
    - summary.yml
  reads:
    - config-data.yml
```

### Stub Skill (generate-config/SKILL.md)

```yaml
---
name: generate-config
description: "Generate a configuration YAML file with project settings"
writes:
  - config-data.yml
checkpoint:
  type: data_validation
  checks:
    - "config-data.yml exists"
    - "config-data.yml has root 'config' key"
---

# generate-config

Write a `config-data.yml` file with a `config:` root key containing
a `name` and `version` field.
```

### Stub Skill (generate-summary/SKILL.md)

```yaml
---
name: generate-summary
description: "Generate a summary YAML from config data"
writes:
  - summary.yml
reads:
  - config-data.yml
checkpoint:
  type: data_validation
  checks:
    - "summary.yml exists"
    - "summary.yml has root 'summary' key"
---

# generate-summary

Read `config-data.yml` and write a `summary.yml` file with a `summary:`
root key that references the config name and version.
```

---

## Initial State

```yaml
# .ai/plans/se11-sequential-test/state.yml
command: "plan:execute"
project: "se11-sequential-test"
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

## Scenario A: Full Sequential Execution (Happy Path)

### Pre-conditions

- Plan file, ownership file, and state file exist as above
- No prior commits related to this test
- Working directory is clean (`git status` shows no changes)

### Execution

Run: `/plan:execute .ai/plans/se11-sequential-test/plan.yml --mode subagent`

### Expected Behavior — Wave 1

#### Step 1: Mode and State Setup

```
1. Orchestrator reads plan, ownership, state
2. Sets execution_mode = subagent in plan file
3. Reports: "Running in subagent mode."
4. Records wave_base_sha = current git HEAD
5. Updates state.yml:
   status: "in_progress"
   started_at: "[now]"
   current_phase: "generate-config"
   current_phase_number: 1
```

#### Step 2: Task t1 Dispatch

```
1. Reads t1 definition from plan
2. Reads t1 ownership entry (owns: [config-data.yml], reads: [])
3. Reads generate-config/SKILL.md (≤80 lines)
4. Checks state.yml errors — empty (first attempt)
5. Fills worker-dispatch.md template with:
   - task_id: t1
   - task_name: generate-config
   - SKILL_MD_content: [skill content]
   - owns: [config-data.yml]
   - reads: []
   - read_list: [] (no references/process.md, no reads)
   - previous_errors: none
   - plan_name: se11-sequential-test
   - model_tier: senior
6. Records task_base_sha = current git HEAD
7. Dispatches Task():
   - description: "Task t1: generate-config"
   - prompt: [filled template]
   - model: sonnet (senior → sonnet)
   - subagent_type: "general-purpose"
```

#### Step 3: Task t1 Subagent Execution

The subagent:
1. Reads the prompt (worker-dispatch template)
2. Creates `config-data.yml` with valid content
3. Stages and commits: `se11-sequential-test: generate-config [t1]`
4. Returns structured report

#### Expected task_complete Report from t1

```yaml
task_complete:
  task_id: "t1"
  model_tier: "senior"
  status: completed
  commit_sha: "<sha-of-t1-commit>"
  artifacts_written:
    - path: "config-data.yml"
      description: "Configuration file with project settings"
  decisions_made:
    - "Used simple key-value structure for config"
  recovery_notes: |
    Created config-data.yml with config root key.
    Contains name and version fields.
```

#### Step 4: Orchestrator Processes t1 Report

```
1. Collects task_complete report
2. Records t1.base_sha and t1.commit_sha in plan
3. Updates t1.status → "completed" in plan
4. Reports: "Task t1: generate-config — completed"
5. Records wave_head_sha = current git HEAD
```

#### Step 5: Wave 1 Verification (Stage 1 Only)

```
1. Fills spec-review-dispatch.md template with:
   - t1 definition and expected outputs
   - t1 task_complete report
   - base_sha and commit_sha
2. Dispatches spec-compliance-reviewer via Task(model: haiku)
3. Spec review passes (config-data.yml exists with correct structure)
4. Stage 2 gate: wave.qa_review is false, not final wave → SKIP Stage 2
5. Updates phase status → "complete"
```

#### Expected State After Wave 1

```yaml
status: "in_progress"
current_phase: "generate-config"
current_phase_number: 1
phases:
  - name: "generate-config"
    number: 1
    status: "complete"
    commit_range:
      base_sha: "<wave-1-base>"
      head_sha: "<wave-1-head>"
completed_waves: [1]
errors: []
```

### Expected Behavior — Wave 2

#### Step 6: Wave 2 Setup

```
1. Updates state.yml:
   current_phase: "generate-summary"
   current_phase_number: 2
   current_wave: 2
2. Records wave_base_sha = current git HEAD (after t1's commit)
```

#### Step 7: Task t2 Dispatch

```
1. Reads t2 definition from plan
2. Reads t2 ownership entry (owns: [summary.yml], reads: [config-data.yml])
3. Reads generate-summary/SKILL.md
4. Checks state.yml errors — empty
5. Fills worker-dispatch.md template:
   - task_id: t2
   - owns: [summary.yml]
   - reads: [config-data.yml]
   - read_list:
     - config-data.yml — "Output from task t1 (dependency)"
   - model_tier: senior
6. Dispatches Task(model: sonnet)
```

Key: The t2 subagent receives `config-data.yml` in its reads list because
t2.depends_on includes t1, and t1 wrote config-data.yml. The subagent
reads this file to generate the summary.

#### Step 8: Task t2 Subagent Execution

The subagent:
1. Reads config-data.yml (written by t1)
2. Creates summary.yml referencing config values
3. Commits: `se11-sequential-test: generate-summary [t2]`
4. Returns task_complete report

#### Step 9: Wave 2 Verification (Stage 1 + Stage 2)

```
Stage 1: spec-compliance-reviewer (haiku)
  - Verifies summary.yml exists with summary root key
  - Status: pass

Stage 2 gate: wave.qa_review is true → run Stage 2

Stage 2: qa-agent (opus)
  - Receives commit_range (wave 2 base..head)
  - Reviews summary.yml content quality
  - Checks cross-skill alignment (summary references config correctly)
  - Returns verdict
```

#### Expected State After Wave 2 (Plan Complete)

```yaml
status: "completed"
current_phase: null
current_wave: null
completed_waves: [1, 2]
phases:
  - name: "generate-config"
    number: 1
    status: "complete"
    commit_range:
      base_sha: "<wave-1-base>"
      head_sha: "<wave-1-head>"
  - name: "generate-summary"
    number: 2
    status: "complete"
    commit_range:
      base_sha: "<wave-2-base>"
      head_sha: "<wave-2-head>"
errors: []
recovery_notes: |
  Wave 2 completed at [timestamp].
  Tasks completed: [t1, t2].
  Key outputs: [config-data.yml, summary.yml].
  Plan complete.
```

### Expected Plan File After Completion

```yaml
plan:
  status: completed
  execution_mode: subagent
  tasks:
    - id: t1
      status: completed
      base_sha: "<sha>"
      commit_sha: "<sha>"
    - id: t2
      status: completed
      base_sha: "<sha>"
      commit_sha: "<sha>"
  waves:
    - wave: 1
      status: completed
      verification:
        passed: true
    - wave: 2
      status: completed
      verification:
        passed: true
```

---

## Scenario B: Resume After Interruption

### Setup

Execute SE11 plan but simulate interruption after wave 1 completes
(before wave 2 starts). State.yml shows wave 1 complete, current_wave: 2.

### Execution

Run: `/plan:execute .ai/plans/se11-sequential-test/plan.yml`

### Expected Behavior

```
1. Orchestrator reads state.yml — current_wave: 2, completed_waves: [1]
2. Skips wave 1 (already completed)
3. Reports: "Resuming from wave 2 of 2"
4. Dispatches t2 as subagent
5. t2 can read config-data.yml (committed by t1 in previous session)
6. Verification runs normally
7. Plan completes
```

### Pass Criteria

- [ ] Wave 1 is NOT re-executed
- [ ] t2 subagent receives config-data.yml in reads list
- [ ] t2 can read t1's output (it exists on disk from prior commit)
- [ ] Plan completes normally

---

## Pass Criteria — Full Test

### Dispatch Mechanics

- [ ] t1 dispatched via Task() with model: sonnet (senior tier)
- [ ] t1 subagent receives filled worker-dispatch.md template
- [ ] t1 subagent prompt contains SKILL.md content, ownership, and no error context
- [ ] t2 dispatched AFTER t1 completes (sequential, not parallel)
- [ ] t2 subagent prompt contains config-data.yml in reads/read_list

### Commit Protocol

- [ ] t1 creates a git commit with message matching `se11-sequential-test: generate-config [t1]`
- [ ] t2 creates a git commit with message matching `se11-sequential-test: generate-summary [t2]`
- [ ] Both commit SHAs recorded in plan file (base_sha and commit_sha per task)
- [ ] commit_range recorded per phase in state.yml

### State Management

- [ ] Orchestrator is sole writer of state.yml (subagents never touch it)
- [ ] state.yml updated after each wave (not after each task)
- [ ] Phase entries include commit_range with base_sha and head_sha
- [ ] completed_waves array grows: [] → [1] → [1, 2]
- [ ] Final status is "completed"

### Verification Flow

- [ ] Wave 1: Stage 1 only (qa_review: false, not final wave)
- [ ] Wave 2: Stage 1 + Stage 2 (qa_review: true)
- [ ] Spec review dispatched as Task(model: haiku)
- [ ] QA review dispatched as Task(model: opus)
- [ ] Quality review receives correct commit_range for wave 2

### Data Flow

- [ ] t2 can read config-data.yml (t1's output) because it's committed to git
- [ ] QA agent's git diff is scoped to wave 2 changes only (not wave 1)
- [ ] Orchestrator context stays lean — only accumulates task_complete reports (~20 lines each)

### Inline Fallback

- [ ] Running same plan with `--mode single` produces identical output files
- [ ] No subagent dispatch occurs in single mode

---

## Decision Matrix

| Wave | parallel | qa_review | Final? | Stage 1 | Stage 2 | Expected Phase Status |
|------|----------|-----------|--------|---------|---------|----------------------|
| 1    | false    | false     | No     | pass    | skipped | complete              |
| 2    | false    | true      | Yes    | pass    | PASS    | complete              |
