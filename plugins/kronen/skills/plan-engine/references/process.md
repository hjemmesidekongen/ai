# plan-engine — Process

## Algorithm overview

```
Input: flat task list with dependencies and file claims
  → Step 1: Topological sort into waves
  → Step 2: File-ownership conflict resolution
  → Step 3: Model-tier assignment
  → Step 4: Verification setup
  → Step 5: Emit plan.yml + state.yml
Output: optimized wave plan
```

## Step 1: Dependency resolution (topological sort)

1. Build dependency graph from `depends_on` arrays
2. Find all tasks with empty/satisfied dependencies → **Wave 1**
3. Remove those tasks from the graph, mark their dependents as potentially unblocked
4. Repeat: find newly unblocked tasks → **Wave N**
5. Continue until all tasks assigned

**Cycle detection:** If any iteration finds zero unblocked tasks but tasks remain, report a dependency cycle and halt with an error listing the involved tasks.

## Step 2: File-ownership conflict resolution

For each wave, check pairwise file-ownership conflicts between tasks.

### Path comparison rules

Two paths conflict if they could write to the same location:

| Path A | Path B | Conflict? |
|--------|--------|-----------|
| `file.yml` | `file.yml` | YES — same file |
| `file.yml#colors` | `file.yml#typography` | NO — different sections |
| `file.yml#colors` | `file.yml#colors` | YES — same section |
| `file.yml` | `file.yml#colors` | YES — whole-file includes section |
| `assets/*` | `assets/icons/check.svg` | YES — glob contains path |
| `src/*.ts` | `tests/*.ts` | NO — different directories |

### Resolution

When a conflict is found within a wave:
1. Count downstream dependents for each conflicting task
2. Keep the task with **more** downstream dependents (it's on the critical path)
3. Move the other task to the **next wave**
4. Tie-break by task order (lower index stays)
5. Re-check the target wave for new conflicts
6. Loop until all waves are clean

### Section-level ownership

Section refs (e.g., `file.yml#colors`) enable safe parallel writes to the same YAML file when tasks write different keys. This is critical for plans where multiple tasks contribute to a shared config file.

## Step 3: Model-tier assignment

Assign based on task characteristics:

| Tier | Model | When to use |
|------|-------|-------------|
| junior | Haiku | Simple scaffolding, templated output, file creation, config generation |
| senior | Sonnet | Implementation, content generation, reasoning tasks (default) |
| principal | Opus | Architecture decisions, QA/verification, cross-cutting concerns, A/B benchmarks |

**Heuristics from task names:**
- Contains "scaffold", "create", "generate config" → junior
- Contains "implement", "build", "write" → senior
- Contains "review", "verify", "benchmark", "architect", "integrate" → principal

**Override:** If a task's `model_tier` is explicitly set in the input, use it as-is.

## Step 4: Verification setup

Assign verification type per wave based on the output patterns of its tasks:

| Output pattern | Verification type |
|---------------|-------------------|
| YAML files (.yml, .yaml) | `data_validation` |
| Asset files (.svg, .png, .jpg) | `file_validation` |
| Code files (.ts, .js, .css, .py) | `code_validation` |
| Benchmark results | `ab_benchmark` |
| Final wave | `integration_test` |

**Generate concrete checks** specific to the wave's tasks. Not generic checks — specific assertions about what should exist and be valid after the wave completes.

**QA review flag:**
- Final wave: always `qa_review: true`
- Other waves: `qa_review: false` unless the plan explicitly requests it

**Phase checkpoint flag:**
- Set `checkpoint: true` on a wave to pause plan-execute after verification and require
  explicit user approval before continuing to the next wave.
- When the user creates the plan with phase gates requested, or when the plan spans
  high-risk implementation waves, add checkpoints on key boundaries.
- Default: no checkpoint (automatic advancement). Backward compatible — plans without
  checkpoint flags behave exactly as before.
- plan-execute presents three options at each checkpoint: Continue, Revise, or Abort.

## Step 5: Emit plan

Write two files:

### plan.yml
Conforming to `plugins/kronen/resources/plan-schema.yml`:
- Plan metadata (name, description, timestamps, totals)
- Flat task list with status, model_tier added
- Wave definitions with verification blocks
- All statuses set to `pending`
- For tasks that produce intermediate findings for downstream tasks, set `artifact`:
  ```yaml
  - id: t1
    name: "Research phase"
    artifact: "artifacts/wave1-t1-output.md"   # downstream tasks read this
  ```
  The artifacts directory (`.ai/plans/<name>/artifacts/`) is created at plan init time.

### state.yml
Conforming to `plugins/kronen/resources/state-schema.yml`:
- Command: `plan:execute`
- Project: plan name
- Status: `pending`
- Phases: one entry per wave
- Empty errors array
- Recovery notes summarizing the plan

## Worked example

**Input:**
```yaml
tasks:
  - id: t1
    name: "Create schemas"
    depends_on: []
    files_written: ["resources/schema-a.yml", "resources/schema-b.yml"]

  - id: t2
    name: "Build skill A"
    depends_on: ["t1"]
    files_written: ["skills/a/SKILL.md", "skills/a/references/process.md"]

  - id: t3
    name: "Build skill B"
    depends_on: ["t1"]
    files_written: ["skills/b/SKILL.md", "skills/b/references/process.md"]

  - id: t4
    name: "Integration test"
    depends_on: ["t2", "t3"]
    files_written: ["tests/results.yml"]
```

**Step 1 — Topological sort:**
- Wave 1: [t1] (no dependencies)
- Wave 2: [t2, t3] (both depend only on t1)
- Wave 3: [t4] (depends on t2 and t3)

**Step 2 — File-ownership check:**
- Wave 1: single task, no conflicts
- Wave 2: t2 writes `skills/a/*`, t3 writes `skills/b/*` — no overlap → parallel: true
- Wave 3: single task, no conflicts

**Step 3 — Model tiers:**
- t1: "Create schemas" → junior (templated creation)
- t2, t3: "Build skill" → senior (implementation)
- t4: "Integration test" → principal (cross-cutting validation)

**Output:** 3 waves, 4 tasks, t2 and t3 run in parallel in wave 2.

## Error handling

- **Dependency cycle:** Report the cycle and list involved task ids. Do not attempt to break the cycle automatically — surface it to the user.
- **Unresolvable conflict:** If moving a task creates a cascade of conflicts across multiple waves, surface the specific conflict and suggest the user restructure the tasks.
- **Missing dependency:** If a task references a `depends_on` id that doesn't exist, report it immediately.

## Dynamic Planning Mode

### New state.yml fields (all optional, backward compatible)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `mode` | string | `static` | `static` (traditional all-waves-upfront) or `dynamic` (goal-oriented iterative) |
| `goal` | string | — | The fixed goal being pursued. Set once, never changes. |
| `cycle` | integer | 1 | Current iteration number. Incremented after each learn phase. |
| `planned_waves` | string[] | — | Wave IDs that have been planned so far. Grows each cycle. |
| `remaining_goal` | string | — | Freeform description of what's left to achieve. Updated each cycle. |
| `max_cycles` | integer | 15 | Safety valve. Escalate to human if reached. |
| `replan_count` | integer | 0 | How many times the plan was fundamentally replanned. Max 2 before escalate. |

### Backward compatibility rules
- All new fields are optional. Missing fields = static mode behavior.
- `mode` defaults to `static` if absent — all existing plans work unchanged.
- plan-execute checks `mode` and delegates to dynamic-planner skill if `dynamic`.
- plan-status reads `mode` to format output ("3 of 7" vs "3 of ???").

### Dynamic mode lifecycle
1. `/plan:dynamic` creates state.yml with `mode: dynamic`, `goal`, `cycle: 1`
2. Each cycle: dynamic-planner plans one wave, appends to `planned_waves`, executes, learns
3. After learn phase: `cycle` increments, `remaining_goal` updates
4. On REPLAN: `replan_count` increments, only future work replanned
5. On completion: `status: done`, `remaining_goal` cleared
