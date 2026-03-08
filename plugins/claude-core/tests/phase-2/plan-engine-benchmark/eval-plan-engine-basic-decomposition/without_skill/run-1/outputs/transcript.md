# Execution Transcript

## Prompt

Decompose this task list into waves:

Tasks:
- t1: Create user schema (depends_on: [], writes: [models/user.yml])
- t2: Build user API (depends_on: [t1], writes: [api/user.ts])
- t3: Create product schema (depends_on: [], writes: [models/product.yml])
- t4: Build product API (depends_on: [t3], writes: [api/product.ts])
- t5: Integration tests (depends_on: [t2, t4], writes: [tests/integration.yml])

Show the wave decomposition with parallel flags....

## Response

## Wave Decomposition

### Wave 1 — Schemas
| Task | Description | Parallel | Writes |
|------|-------------|----------|--------|
| t1 | Create user schema | `true` | `models/user.yml` |
| t3 | Create product schema | `true` | `models/product.yml` |

No dependencies, no file conflicts → both run in parallel.

### Wave 2 — APIs
| Task | Description | Parallel | Writes | Blocked by |
|------|-------------|----------|--------|------------|
| t2 | Build user API | `true` | `api/user.ts` | t1 |
| t4 | Build product API | `true` | `api/product.ts` | t3 |

Independent chains (t1→t2, t3→t4), no file conflicts → both run in parallel.

### Wave 3 — Validation
| Task | Description | Parallel | Writes | Blocked by |
|------|-------------|----------|--------|------------|
| t5 | Integration tests | `false` | `tests/integration.yml` | t2, t4 |

Fan-in — requires both APIs complete. Single task, no parallelism.

**Summary**: 3 waves, max parallelism = 2, critical path = t1 → t2 → t5 (or t3 → t4 → t5, same length).

## Stderr

None
