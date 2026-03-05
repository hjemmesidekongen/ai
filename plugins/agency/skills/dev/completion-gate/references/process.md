# Completion Gate — Detailed Process

Phase 3 quality gate for /agency:build. Verifies build integrity, lint cleanliness, and test health per task after agent-dispatcher completes each wave. Failures return to agents while context is fresh.

## Step 1: Read Configuration

Read `dev-config.yml` from `.ai/projects/[name]/dev/dev-config.yml`:

```yaml
commands:
  build: "npm run build"
  lint: "npm run lint"
  test_related: "npm run test --"  # prefix; append file paths
  test: "npm run test"             # full suite for wave boundary
```

If `dev-config.yml` or `commands` is missing: log error to `project-state.yml` errors array, surface to orchestrator, block advancement.

## Step 2: Read Dispatched Tasks

Read `project-state.yml` `execution.dispatched_tasks`. Filter to tasks where `status: completed` and `report.gate_status: pending`.

## Step 3: Per-Task Gate Execution

For each pending completed task, run sequentially:

1. **Build:** `<commands.build>` — exit 0 → `build_passed: true`
2. **Lint:** `<commands.lint>` — exit 0 → `lint_passed: true`
3. **Tests:** `<commands.test_related> <files_changed>` — exit 0 → `tests_passed: true`
4. **Gate decision:** all pass → `gate_status: passed`; any fail → retry flow (Step 4)

## Step 4: Failure Handling and Retry

1. Increment `report.retry_count` — **max 2 retries**
2. Build error context (captured stdout/stderr for each failed check + files_changed)
3. Re-dispatch same agent at same model tier via Task()
4. On report: re-run gate from Step 3
5. **Escalation:** if retry_count reaches 2 and still failing → set `gate_status: failed`, log to errors array, add `escalated_to: code-review` to task record, continue gating remaining tasks

## Step 5: Wave Boundary Full Suite

After all tasks gated: run `<commands.test>` (full suite). Record in project-state.yml:

```yaml
execution:
  waves:
    - wave_number: 1
      full_suite_passed: true
      full_suite_output: "<summary>"
```

## Step 6: Update project-state.yml

Write final report for each task:

```yaml
execution:
  dispatched_tasks:
    - task_id: "t1"
      status: completed
      report:
        build_passed: true
        lint_passed: true
        tests_passed: true
        gate_status: passed  # passed | failed | escalated
        retry_count: 0
        errors: []
```

Write atomically — read current state, merge gate results, write back.
**2-Action Rule:** After every 2 gate check runs, save results to findings.md immediately.

---

## Step 0: Initialize Trace (mandatory if tracing enabled)

Read `state.yml` and check `trace.enabled`. If `true`:

1. Create trace file: `.ai/projects/[name]/traces/{skill-name}-{ISO-timestamp}.yml`
2. Write `_meta` block: schema `"trace"`, version `"1.1.0"`, skill, module, project, started_at, trace_mode
3. Initialize empty `steps: []`, `checkpoint_result: {}`, `quality_summary: {}`, `reflections: {}`

**Schema v1.1.0 — required fields per step:**
- `decision`, `reasoning`, `uncertainty` (always required)
- `observation` — what happened vs expected; surprises, gaps, confirmations
- `improvement_idea` — actionable suggestion for the skill/pipeline (if any)
- `design_decision` — lasting choice beyond this run (if any)

**Trace-level `reflections` section (REQUIRED — Stop hook enforces):**
```yaml
reflections:
  observations: ["at least one observation about the run"]
  improvement_ideas: []   # optional but encouraged
  design_decisions: []    # optional, only for lasting choices
```

The Stop hook will BLOCK completion if reflections section is missing.

---


> **Extended reference:** See [references/gate-reference.md](gate-reference.md) for retry dispatch template, escalation error log YAML, findings.md format, error logging table, and full dispatched_tasks YAML shape.

---

## Trace Finalization (mandatory if tracing enabled)

Before completing, verify your trace file has:
1. All steps recorded (written every 2 steps per the 2-Action Rule)
2. `checkpoint_result` with pass/fail status
3. `quality_summary` with avg_uncertainty and recommendation
4. `reflections` section with at least one observation (REQUIRED — Stop hook enforces this)
5. Step-level `observation`, `improvement_idea`, or `design_decision` where applicable

The Stop hook will BLOCK completion if tracing is enabled and the trace file
is missing or has no `reflections:` section.
