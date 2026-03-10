# Dev Engine Orchestrator — Process Reference

## Stage Specifications

### Stage 1: project-mapper
- **Purpose**: Scan repo for tech stack, module boundaries, architecture
- **Input**: Repository root path (default: cwd)
- **Output**: `.ai/project-map.yml`
- **Skip condition**: `.ai/project-map.yml` exists and mtime < 24 hours
- **On failure**: Log error, continue without project map (downstream stages degrade)

### Stage 2: taskflow-bridge
- **Purpose**: Detect taskflow, load active task, map acceptance criteria
- **Input**: Plugin detection + `.ai/tasks/active.yml`
- **Output**: `.ai/tasks/bridge-context.yml`
- **Skip condition**: Never skipped (fast detection, always runs)
- **On failure**: Fall back to standalone mode (no task criteria for gate)

### Stage 3: task-decomposer
- **Purpose**: Break task into subtasks with complexity and file scope
- **Input**: Task description (from bridge context or user input)
- **Output**: `.ai/tasks/decomposed/<task-id>.yml`
- **Skip condition**: Decomposition exists for current task revision
- **On failure**: Halt pipeline — cannot proceed without decomposition

### Stage 4: context-assembler
- **Purpose**: Build bounded context packages for each agent
- **Input**: Project map + decomposed subtasks + knowledge skills
- **Output**: `.ai/tasks/context/<task-id>-<subtask-id>.yml`
- **Skip condition**: Context files exist for same task revision
- **On failure**: Halt pipeline — agents cannot dispatch without context

### Stage 5: tier-assignment
- **Purpose**: Assign model tiers (junior/senior/principal) to subtasks
- **Input**: Decomposed subtasks
- **Output**: Tier annotations in decomposed task file
- **Skip condition**: Tier assignments exist for current decomposition
- **On failure**: Default all subtasks to senior tier and continue

### Stage 6: agent-dispatcher
- **Purpose**: Dispatch agents for each subtask with context packages
- **Input**: Tiered subtasks + context packages
- **Output**: `.ai/tasks/dispatched/<subtask-id>.yml` per agent
- **Skip condition**: All subtasks have dispatched results
- **On failure**: Log failed subtask, continue dispatching others, mark pipeline partial

### Stage 7: completion-gate
- **Purpose**: Verify all subtasks meet acceptance criteria
- **Input**: Dispatched results + bridge context gate checks
- **Output**: Gate verdict in `pipeline-state.yml`
- **Skip condition**: Never skipped
- **On failure**: Pipeline fails — surface which checks failed and why

## Pipeline State Schema

```yaml
# .ai/tasks/pipeline-state.yml
pipeline_id: "pipe-001"
task_id: "TSK-001"
started_at: "2026-03-10T14:00:00Z"
completed_at: null
mode: "execute"  # execute | dry-run
status: "in_progress"  # in_progress | completed | failed | partial

stages:
  project-mapper:
    status: "completed"  # pending | skipped | completed | failed
    skip_reason: null
    started_at: "2026-03-10T14:00:00Z"
    completed_at: "2026-03-10T14:00:30Z"
    error: null
  taskflow-bridge:
    status: "completed"
    skip_reason: null
    started_at: "2026-03-10T14:00:30Z"
    completed_at: "2026-03-10T14:00:31Z"
    error: null
  context-assembler:
    status: "in_progress"
    skip_reason: null
    started_at: "2026-03-10T14:00:31Z"
    completed_at: null
    error: null
```

## Dry-Run Output

When `--dry-run` is passed:

```yaml
# Printed to stdout, not written to pipeline-state.yml
dry_run: true
task: "Add dark mode toggle"
stages:
  project-mapper: { action: "skip", reason: "scan cache fresh (2h old)" }
  taskflow-bridge: { action: "run", reason: "always runs" }
  task-decomposer: { action: "run", reason: "new task" }
  context-assembler: { action: "run", reason: "no cached context for this task" }
  tier-assignment: { action: "run", reason: "depends on decomposition" }
  agent-dispatcher: { action: "skip (dry-run)", reason: "dry-run mode" }
  completion-gate: { action: "skip (dry-run)", reason: "dry-run mode" }
estimated_subtasks: 4
estimated_agents: 3
```

## Resume Protocol

On resume after failure:
1. Read `pipeline-state.yml`
2. Find the first stage with `status: failed` or `status: pending`
3. Re-run from that stage (all earlier completed stages are skipped)
4. If the failed stage succeeds on retry, continue the pipeline normally
5. Record retry count in the stage entry

## Configuration

Pipeline behavior can be customized via `.ai/dev-engine-config.yml`:

```yaml
# Optional — all values have sensible defaults
context_budget: 8000          # token ceiling per agent context
scan_cache_ttl: 86400         # seconds before project map is stale (24h)
default_tier: "senior"        # fallback if tier-assignment fails
max_subtasks: 20              # decomposer limit
dry_run_default: false        # set true to require explicit --execute
```

## Anti-patterns

- Never skip the completion gate — it is the only quality assurance in the pipeline
- Never re-run completed stages on resume — only failed or pending stages
- Never dispatch agents without context packages — context-assembler is a hard dependency
- Never silently continue after a failure — log it, update pipeline state, and surface it
- Never run the full pipeline for a task that is already completed — check pipeline-state first
