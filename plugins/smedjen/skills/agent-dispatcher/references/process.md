# Agent Dispatcher — Process Reference

## Dispatch Record Schema

```yaml
# .ai/tasks/dispatched/<task-id>.yml
task_id: "TSK-001"
dispatched_at: "2026-03-09T14:30:00Z"
completed_at: "2026-03-09T14:45:00Z"  # null if still running
status: "complete"                      # complete | partial | failed
waves:
  - wave: 0
    subtasks:
      - subtask_id: "TSK-001-01"
        agent_id: "agent-wave0-01"
        tier: "junior"
        model: "haiku"
        status: "success"               # success | failed | escalated | skipped
        attempts:
          - attempt: 1
            tier: "junior"
            started_at: "2026-03-09T14:30:00Z"
            completed_at: "2026-03-09T14:33:00Z"
            result: "success"
            error: null
        files_written:
          - "src/models/user.ts"
          - "src/migrations/001_users.sql"
        files_read:
          - "src/db/connection.ts"
        report: |
          Created User model with email, password_hash, created_at fields.
          Migration adds users table with appropriate indexes.

      - subtask_id: "TSK-001-03"
        agent_id: "agent-wave0-02"
        # ... same structure

  - wave: 1
    subtasks:
      # ... next wave

summary:
  total_subtasks: 7
  succeeded: 6
  failed: 1
  escalated: 1
  total_attempts: 9
  ownership_violations: 0
```

### Status Values

| Subtask Status | Meaning |
|---------------|---------|
| `success` | Agent completed the subtask, report collected |
| `failed` | All retry/escalation attempts exhausted |
| `escalated` | Failed at original tier, succeeded at higher tier |
| `skipped` | Skipped due to upstream failure |

### Attempt Record Fields

| Field | Type | Description |
|-------|------|-------------|
| `attempt` | int | 1-based attempt number |
| `tier` | string | Model tier used for this attempt |
| `started_at` | datetime | When the agent was dispatched |
| `completed_at` | datetime | When the agent reported back |
| `result` | string | success, failed, timeout |
| `error` | string | Error message if failed, null otherwise |

## Agent Prompt Template

Each dispatched agent receives a structured prompt. Do not deviate from this format — consistency makes failure diagnosis easier.

```
You are a worker agent assigned a specific subtask. Complete it precisely.

## Your Task
{subtask.title}

{subtask.description}

## File Ownership
You MAY write to these files (create or modify):
{subtask.file_scope.write — one per line}

You MAY read these files for context:
{subtask.file_scope.read — one per line}

Do NOT write to any file not listed above.

## Knowledge References
Before implementing, read these references if relevant to your task:
{reference_paths — one per line, from project profile skills field}

## Constraints
- Follow existing code patterns in the files you read.
- Do not refactor code outside your scope.
- If you encounter a blocker (missing dependency, unclear requirement),
  report it in your completion summary rather than guessing.

## Completion
When finished, provide a completion report:
1. What you did (brief summary)
2. Files created or modified (list)
3. Any concerns, assumptions, or blockers encountered
4. Do NOT mark the overall task as done. Your work will be reviewed.
```

### Prompt Customization

For retry attempts, append an error context section:

```
## Previous Attempt Failed
The previous attempt at this subtask failed with:
{previous_attempt.error}

Approach this differently. Do not repeat the same mistake.
```

For escalated attempts, add the full attempt history:

```
## Escalation Context
This subtask was escalated from {original_tier} to {current_tier} after
{attempt_count} failed attempts. Previous errors:
{for each attempt: attempt number, tier, error}

Use your stronger reasoning to resolve what the lower-tier model could not.
```

## Parallelization Rules

### Wave Construction

1. Take the dependency graph from the decomposed task.
2. Identify all subtasks with no unmet dependencies → Wave 0.
3. After Wave 0 completes, identify newly unblocked subtasks → Wave 1.
4. Repeat until all subtasks are assigned to a wave.

### Parallel Dispatch Within a Wave

- Max 4 agents per wave (resource constraint).
- If a wave has more than 4 subtasks, split into sub-waves of 4.
- Sub-waves within the same wave level can run sequentially (they have no inter-dependencies).

### Ordering Within a Wave

When a wave has more subtasks than the parallel limit, prioritize:
1. Subtasks on the critical path (most downstream dependents).
2. Higher-risk subtasks (fail fast — discover problems early).
3. Larger subtasks (start long-running work first).

## Retry Flow

```
dispatch(subtask, tier):
  attempt 1 → run at assigned tier
    if success → record, move on
    if failure →
      attempt 2 → retry at same tier with error context
        if success → record, move on
        if failure →
          next_tier = escalate(tier)
          if next_tier exists:
            attempt 3 → run at next_tier with escalation context
              if success → record as "escalated"
              if failure → mark as "failed", log blocker
          else:
            mark as "failed" (already at principal, nowhere to escalate)
```

### Escalation Map

| Current Tier | Escalates To |
|-------------|-------------|
| junior (haiku) | senior (sonnet) |
| senior (sonnet) | principal (opus) |
| principal (opus) | no escalation — mark failed |

### When NOT to Retry

- Agent reported a blocker (missing file, unclear requirement) → do not retry with same context, the problem is upstream.
- Agent produced a file ownership violation → fix the ownership assignment, then retry.
- Agent timed out → retry once, then escalate. Timeouts often indicate the task is too large for the tier.

## File Ownership Enforcement

### Algorithm

Before dispatching a wave:

1. Collect all `file_scope.write` lists from subtasks in the wave.
2. Build a file → subtask mapping.
3. Check for conflicts: any file appearing in 2+ subtasks' write scopes.
4. For each conflict:
   a. If the subtasks are independent, serialize them (move one to the next sub-wave).
   b. If one subtask can be restructured to avoid the shared file, adjust the decomposition.
   c. As a last resort, merge the conflicting subtasks.

### Conflict Detection

```
file_owners = {}
for subtask in wave.subtasks:
  for file in subtask.file_scope.write:
    if file in file_owners:
      conflict(file, file_owners[file], subtask.id)
    else:
      file_owners[file] = subtask.id
```

### Post-Dispatch Verification

After all agents in a wave complete, verify:
- Each agent only wrote to files in its write scope.
- No file was modified by two agents (even if they were in different sub-waves).

If a violation is detected, log it and do not proceed to the next wave until resolved.

## reference_paths Resolution (SA-D009)

Before building the agent prompt, resolve knowledge references from the project profile:

1. Read `.ai/project-map.yml` — get the app entry matching the subtask's file scope
2. From the app's `skills[]` array, select 1-2 skills most relevant to the subtask
3. Build paths: `plugins/smedjen/skills/{skill-name}/references/process.md`
4. Include in the agent prompt under "Knowledge References"

### Selection heuristics
- Match by file extension: `.tsx` files → react-patterns, nextjs-app-router
- Match by directory: `prisma/` → prisma-patterns, `api/` → nestjs-patterns
- Limit to 2 references per agent — more than 2 dilutes focus
- For junior-tier (haiku) agents: consider pre-packing the first 50 lines of each reference
  into the prompt instead of giving paths (haiku may not read proactively)

### When project-map.yml doesn't exist
- Skip reference_paths — agents work without them
- The prompt template's Knowledge References section is omitted entirely
- Do not fail or block dispatch because of missing profile

## Report Collection and Aggregation

### Per-Agent Report

Each agent returns a completion report (see prompt template). The dispatcher captures:
- Files actually written (compare against scope — flag unexpected writes)
- Summary of work done
- Any blockers or concerns raised
- Success/failure status

### Aggregated Dispatch Report

After all waves complete, produce the dispatch record YAML with:
- Per-wave, per-subtask results
- Summary statistics (success rate, escalation count, total attempts)
- Ownership violation count (should be 0)
- List of failed subtasks with final error context
- List of concerns raised by agents (aggregated for human review)

## Error Handling

### Stuck Detection

An agent is "stuck" if:
- It produces no file changes after an attempt (zero files written or modified).
- It produces the same output as a previous attempt (identical report text).
- It times out twice in a row.

Stuck agents skip the same-tier retry and escalate directly to the next tier with a note: "Previous agent produced no meaningful output."

### Cascade Failure

If a subtask fails and has downstream dependents:
1. Mark all direct dependents as `skipped` (they cannot run without their dependency).
2. Transitively skip all further dependents.
3. Log the cascade in the dispatch report.
4. Continue executing non-dependent subtasks in the same and future waves.

Do not abort the entire dispatch because one branch failed. Complete what you can.

### Partial Completion

If some subtasks succeed and others fail, the dispatch status is `partial`. The dispatch report clearly lists what succeeded and what did not, so a human or higher-level orchestrator can decide next steps.

### Timeout Handling

Default timeout per agent: 5 minutes. If an agent does not report within the timeout:
1. Log as timeout.
2. Count as a failed attempt.
3. Follow normal retry/escalation flow.

There is no mechanism to kill a running agent — the timeout is observed when checking for completion.
