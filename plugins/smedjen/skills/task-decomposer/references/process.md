# Task Decomposer — Process Reference

## Input Schema

```yaml
# .ai/tasks/input/<task-id>.yml
task_id: "TSK-001"
title: "Add user authentication to API"
description: |
  Implement JWT-based authentication for the REST API.
  Includes login, registration, token refresh, and
  middleware for protected routes.
constraints:
  - "Backwards compatible with existing public endpoints"
  - "Token expiry: 15 minutes access, 7 days refresh"
files_hint:                          # optional — narrows search
  - "src/api/**"
  - "src/middleware/**"
requested_by: "user"                 # or "plan", "agent"
parent_task: null                    # set when splitting an XL task
```

## Output Schema

```yaml
# .ai/tasks/decomposed/<task-id>.yml
task_id: "TSK-001"
title: "Add user authentication to API"
decomposed_at: "2026-03-09T14:22:00Z"
subtask_count: 5
subtasks:
  - id: "TSK-001-01"
    title: "Create user model and migration"
    description: |
      Add User table with email, password_hash, created_at.
      Write migration file. No seed data yet.
    complexity: "S"
    file_scope:
      write: ["src/models/user.ts", "src/migrations/001_users.sql"]
      read: ["src/db/connection.ts"]
    dependencies: []
    parallel_eligible: true
    risk_score:
      scope: 1
      reversibility: 2
      ambiguity: 1
      impact: 3
      dependencies: 1
    risk_total: 8.2                  # weighted sum
    notes: ""

  - id: "TSK-001-02"
    title: "Implement password hashing utility"
    # ... (same structure)

  # ... remaining subtasks
```

### Required Fields Per Subtask

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Parent task ID + sequence number |
| `title` | string | Short imperative description |
| `description` | string | What to do, acceptance criteria |
| `complexity` | enum | S, M, L, or XL |
| `file_scope.write` | string[] | Files this subtask will modify or create |
| `file_scope.read` | string[] | Files needed for context |
| `dependencies` | string[] | IDs of subtasks that must complete first |
| `parallel_eligible` | bool | True if dependencies is empty |
| `risk_score` | object | 5 factors, each 1-5 |
| `risk_total` | float | Weighted sum (see tier-assignment) |
| `notes` | string | Caveats, assumptions, open questions |

## Decomposition Algorithm

### Step 1: Scope Analysis

Read the task description and any referenced files. Build a mental model of:
- What modules are affected
- What new files need to be created
- What existing behavior must be preserved

### Step 2: Identify Work Units

Split by logical boundaries, not by file count. Each unit should be:
- Independently testable (can verify without other subtasks)
- Owned by one agent (clear file scope)
- Completable in a single agent session

Heuristics for splitting:
- New data model → separate subtask
- New utility/helper → separate subtask
- New API endpoint → separate subtask per endpoint (unless trivially similar)
- Configuration changes → group into one subtask
- Test files → pair with the subtask they test

### Step 3: Dependency Graph

For each subtask, identify which other subtasks must finish first.

Rules:
- A subtask that creates a file depended on by another subtask is a dependency.
- A subtask that modifies shared config is a dependency for subtasks reading that config.
- Test subtasks depend on the implementation subtask they test.

### Step 4: Topological Sort

Order subtasks so dependencies come first. Assign depth levels:
- Level 0: no dependencies (first wave)
- Level 1: depends only on level-0 subtasks
- Level N: depends on level N-1 or lower

Subtasks at the same level can run in parallel.

### Step 5: Risk Scoring

For each subtask, score the 5 factors:

| Factor | 1 (low) | 3 (medium) | 5 (high) |
|--------|---------|------------|----------|
| Scope | 1-2 files, single module | 3-5 files, one module boundary | 5+ files, cross-module |
| Reversibility | Config change, easily reverted | Schema addition, soft revert | Schema migration, destructive |
| Ambiguity | Clear requirements, known pattern | Some unknowns, familiar domain | Vague requirements, new domain |
| Impact | Internal utility, no consumers | Shared module, few consumers | Public API, many consumers |
| Dependencies | Standalone | 1-2 dependents | 3+ dependents or circular risk |

### Step 6: Validate

Run checkpoint checks:
1. Every subtask has all required fields.
2. No circular dependencies (topological sort succeeds).
3. Union of write scopes covers all files implied by the task.
4. Subtask count ≤ 12.

## Risk Score Calculation

```
risk_total = (scope × 1.0) + (reversibility × 0.8) + (ambiguity × 1.2)
           + (impact × 1.0) + (dependencies × 1.0)
```

Range: 5.0 (all factors = 1) to 25.0 (all factors = 5).

The weighted sum feeds directly into tier-assignment. The decomposer calculates it but does not assign tiers — that is tier-assignment's job.

## Worked Example

### Input: "Add user authentication to API"

**Step 1 — Scope:** Affects models, migrations, auth utilities, API routes, middleware, tests.

**Step 2 — Work units:**

| # | Subtask | Complexity | Files (write) |
|---|---------|-----------|---------------|
| 01 | Create user model and migration | S | user.ts, 001_users.sql |
| 02 | Implement password hashing utility | S | hash.ts, hash.test.ts |
| 03 | Add JWT token service | M | token.ts, token.test.ts, .env.example |
| 04 | Build registration endpoint | M | register.ts, register.test.ts |
| 05 | Build login endpoint | M | login.ts, login.test.ts |
| 06 | Add auth middleware | M | auth-middleware.ts, auth-middleware.test.ts |
| 07 | Protect existing routes | S | routes/index.ts |

**Step 3 — Dependencies:**
- 02 depends on 01 (needs User type)
- 03 depends on nothing (standalone JWT logic)
- 04 depends on 01, 02, 03
- 05 depends on 01, 02, 03
- 06 depends on 03
- 07 depends on 06

**Step 4 — Levels:**
- Level 0: 01, 03
- Level 1: 02, 06
- Level 2: 04, 05
- Level 3: 07

**Step 5 — Risk scores (example for subtask 01):**
- Scope: 1 (2 files, one module)
- Reversibility: 2 (migration is additive, can drop table)
- Ambiguity: 1 (standard user table)
- Impact: 3 (foundational — other subtasks depend on it)
- Dependencies: 1 (no upstream deps)
- Total: (1×1.0) + (2×0.8) + (1×1.2) + (3×1.0) + (1×1.0) = 6.8

## Edge Cases

### Too-vague tasks

If the description lacks file scope hints and the domain is unfamiliar, the ambiguity factor will score 4-5. When the average ambiguity across subtasks exceeds 3.5, halt decomposition and ask for clarification. Do not produce a subtask graph you cannot validate.

Questions to surface:
- "Which modules are in scope?"
- "What is the expected end state?"
- "Are there performance or compatibility constraints?"

### Circular dependencies

If two subtasks mutually depend on each other, they cannot be topologically sorted. Resolution: merge them into one subtask, or extract the shared concern into a third subtask that both depend on.

Never leave a circular dependency in the output — the dispatcher cannot execute it.

### Oversized tasks (>12 subtasks)

If decomposition produces more than 12 subtasks, the input task is too large. Split the parent task into 2-3 smaller tasks, each decomposed separately. Set `parent_task` on each child to maintain traceability.

### Single-file tasks

If the entire task fits in one file with no dependencies, produce a single subtask. Do not artificially split for the sake of having multiple subtasks.

### Ambiguous file scope

When `files_hint` is not provided and the codebase is unfamiliar, use Glob and Grep to discover relevant files before decomposing. The decomposer should never guess at file paths.
