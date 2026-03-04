# SE14: Model Tier Enforcement Integration Test

Tests that plan-execute correctly maps `model_tier` to the Task() `model`
parameter for each dispatch: junior → haiku, senior → sonnet, principal → opus.
Also verifies that verification dispatches use the correct tiers (spec review
as haiku, quality review as opus).

---

## Test Fixtures

### Multi-Tier Plan

```yaml
# .ai/plans/se14-model-tier-test/plan.yml
plan:
  name: "se14-model-tier-test"
  created_at: "2026-03-01T10:00:00Z"
  total_tasks: 3
  total_waves: 1
  status: pending
  verification_profile: "standard"
  execution_mode: subagent

  tasks:
    - id: t1
      name: "scaffold-template"
      depends_on: []
      files_written:
        - template.yml
      files_read: []
      status: pending
      model_tier: junior

    - id: t2
      name: "implement-logic"
      depends_on: []
      files_written:
        - logic.yml
      files_read: []
      status: pending
      model_tier: senior

    - id: t3
      name: "design-architecture"
      depends_on: []
      files_written:
        - architecture.yml
      files_read: []
      status: pending
      model_tier: principal

  waves:
    - wave: 1
      parallel: false
      tasks: [t1, t2, t3]
      depends_on_waves: []
      rationale: "Test all three model tiers in a single wave"
      status: pending
      verification:
        type: data_validation
        checks:
          - "template.yml exists"
          - "logic.yml exists"
          - "architecture.yml exists"
      qa_review: true
```

### Ownership Registry

```yaml
# .ai/plans/se14-model-tier-test/ownership.yml
t1:
  owns:
    - template.yml
  reads: []

t2:
  owns:
    - logic.yml
  reads: []

t3:
  owns:
    - architecture.yml
  reads: []
```

### Initial State

```yaml
# .ai/plans/se14-model-tier-test/state.yml
command: "plan:execute"
project: "se14-model-tier-test"
started_at: null
updated_at: null
status: pending
current_phase: null
current_phase_number: 0
total_phases: 1
phases: []
errors: []
```

---

## Scenario A: Correct Model Mapping Per Task

### Execution

Run: `/plan:execute .ai/plans/se14-model-tier-test/plan.yml --mode subagent`

### Expected Task Dispatches

#### Task t1: junior → haiku

```
Task(
  description: "Task t1: scaffold-template",
  prompt: [worker-dispatch template with model_tier: junior],
  model: haiku,
  subagent_type: "general-purpose"
)
```

**Verification points:**
- Task() `model` parameter is `haiku`
- Worker-dispatch template includes `model_tier: junior`
- task_complete report surfaces `model_tier: "junior"`

#### Task t2: senior → sonnet

```
Task(
  description: "Task t2: implement-logic",
  prompt: [worker-dispatch template with model_tier: senior],
  model: sonnet,
  subagent_type: "general-purpose"
)
```

**Verification points:**
- Task() `model` parameter is `sonnet`
- Worker-dispatch template includes `model_tier: senior`
- task_complete report surfaces `model_tier: "senior"`

#### Task t3: principal → opus

```
Task(
  description: "Task t3: design-architecture",
  prompt: [worker-dispatch template with model_tier: principal],
  model: opus,
  subagent_type: "general-purpose"
)
```

**Verification points:**
- Task() `model` parameter is `opus`
- Worker-dispatch template includes `model_tier: principal`
- task_complete report surfaces `model_tier: "principal"`

### Expected task_complete Reports

```yaml
# t1 report
task_complete:
  task_id: "t1"
  model_tier: "junior"
  status: completed
  commit_sha: "<sha>"

# t2 report
task_complete:
  task_id: "t2"
  model_tier: "senior"
  status: completed
  commit_sha: "<sha>"

# t3 report
task_complete:
  task_id: "t3"
  model_tier: "principal"
  status: completed
  commit_sha: "<sha>"
```

---

## Scenario B: Verification Dispatches Use Correct Tiers

### Expected Spec Review Dispatch

```
Task(
  description: "Spec review: wave 1",
  prompt: [spec-review-dispatch template],
  model: haiku,                              # Always haiku for spec compliance
  subagent_type: "general-purpose"
)
```

Spec compliance is ALWAYS dispatched as haiku regardless of the tasks it
reviews. This is by design — spec compliance is mechanical (file existence,
schema presence, non-empty) and doesn't need reasoning capability.

### Expected Quality Review Dispatch

```
Task(
  description: "Quality review: wave 1",
  prompt: [quality-review-dispatch template],
  model: opus,                               # Always opus for quality review
  subagent_type: "general-purpose"
)
```

Quality review is ALWAYS dispatched as opus regardless of the tasks it
reviews. This is by design — quality review requires judgment, cross-skill
alignment reasoning, and domain expertise.

---

## Scenario C: Default Model Tier (Missing Field)

### Setup

A task with `model_tier` omitted from the plan:

```yaml
- id: t4
  name: "unspecified-tier-task"
  depends_on: []
  files_written:
    - output.yml
  status: pending
  # model_tier intentionally omitted
```

### Expected Behavior

```
1. Orchestrator reads t4 — model_tier is undefined
2. Apply default: model_tier = "senior" (from plan-schema.yml default)
3. Dispatch with model: sonnet
```

### Pass Criteria for Scenario C

- [ ] Missing model_tier defaults to `senior`
- [ ] Task dispatched with model: sonnet
- [ ] No error or warning (this is expected behavior)

---

## Scenario D: Model Tier in Worker Report

### Purpose

Verify that the worker agent includes the correct model_tier in its
task_complete report, and the orchestrator can cross-reference it against
the plan's declared tier.

### Expected Behavior

```
For each task:
  1. Orchestrator dispatches with model_tier X and model Y
  2. Worker-dispatch template tells subagent: "model_tier: X"
  3. Subagent includes model_tier: X in task_complete report
  4. Orchestrator reads report and verifies model_tier matches plan
     (informational — not a blocking check, but logged if mismatched)
```

### Pass Criteria for Scenario D

- [ ] Worker report model_tier matches plan task model_tier
- [ ] Model tier visible in completion report for auditability

---

## Model Tier Mapping Reference

| model_tier | Task() model | Cost | Typical Use Cases |
|-----------|-------------|------|-------------------|
| `junior`  | `haiku`     | Lowest | Scaffolding, templated output, spec compliance review, simple data transforms |
| `senior`  | `sonnet`    | Medium | Content generation, implementation, reasoning, most domain work |
| `principal` | `opus`    | Highest | Architecture decisions, QA review, cross-cutting analysis, complex judgment |

### Verification-Specific Tiers (Not Configurable Per-Task)

| Verification Stage | Model | Rationale |
|-------------------|-------|-----------|
| Spec compliance (Stage 1) | `haiku` | Mechanical checks — file existence, schema, non-empty |
| Quality review (Stage 2) | `opus` | Judgment-heavy — coherence, quality floor, cross-skill alignment |

---

## Pass Criteria — Full Test

### Model Mapping

- [ ] junior task dispatched with `model: haiku`
- [ ] senior task dispatched with `model: sonnet`
- [ ] principal task dispatched with `model: opus`
- [ ] Missing model_tier defaults to senior (sonnet)

### Verification Tiers

- [ ] Spec review always dispatched as `model: haiku`
- [ ] Quality review always dispatched as `model: opus`
- [ ] Verification tier is independent of task tiers in the wave

### Worker Reports

- [ ] Each task_complete report includes correct `model_tier` field
- [ ] Model tier in report matches plan declaration

### Cost Efficiency

- [ ] Junior tasks use cheapest model (haiku)
- [ ] Spec compliance (frequent, mechanical) uses cheapest model (haiku)
- [ ] Opus reserved for quality review and principal-tier tasks only

---

## Decision Matrix

| Task Tier | Dispatched Model | Spec Review Model | QA Review Model |
|-----------|-----------------|-------------------|-----------------|
| junior    | haiku           | haiku             | opus            |
| senior    | sonnet          | haiku             | opus            |
| principal | opus            | haiku             | opus            |
| (missing) | sonnet (default)| haiku             | opus            |
