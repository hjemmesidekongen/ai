# file-ownership — Process

## Ownership Model

Every file in a parallel plan has exactly one owner: the stream responsible
for creating or modifying it. Other streams may read the file but not write it.

```
Stream A owns: src/auth/handler.ts, src/auth/types.ts
Stream B owns: src/api/routes.ts, src/api/middleware.ts
Stream C owns: tests/auth/handler.test.ts, tests/api/routes.test.ts

Shared (read-only, written before parallel dispatch):
  src/types/shared.ts   ← owner: coordinator (pre-written)
```

---

## Ownership YAML Schema

Write to `.ai/plans/<plan>/ownership.yml`:

```yaml
plan: "<plan-name>"
decomposed: "<date>"
streams:
  - id: "stream-a"
    description: "Auth layer implementation"
    owns:
      - "src/auth/handler.ts"
      - "src/auth/types.ts"
    reads:
      - "src/types/shared.ts"
    depends_on: []

  - id: "stream-b"
    description: "API layer implementation"
    owns:
      - "src/api/routes.ts"
      - "src/api/middleware.ts"
    reads:
      - "src/types/shared.ts"
      - "src/auth/types.ts"   # read-only — written by stream-a
    depends_on: ["stream-a"]  # must wait for stream-a to write auth/types.ts

  - id: "stream-c"
    description: "Test suite"
    owns:
      - "tests/auth/handler.test.ts"
      - "tests/api/routes.test.ts"
    reads:
      - "src/auth/handler.ts"
      - "src/api/routes.ts"
    depends_on: ["stream-a", "stream-b"]

shared_files:
  - path: "src/types/shared.ts"
    written_by: "coordinator"
    written_before_dispatch: true
```

---

## Interface Contract Format

For each cross-stream boundary, write a contract before dispatch.
Contracts are lightweight — function signatures and types, not implementations.

Write contracts to `.ai/plans/<plan>/contracts/<boundary>.md`:

```markdown
# Contract: Auth → API Boundary

**Written by**: stream-a (auth)
**Consumed by**: stream-b (api)

## Exported Types

```typescript
export interface AuthToken {
  userId: string;
  expiresAt: number;
  scopes: string[];
}

export interface AuthResult {
  token: AuthToken | null;
  error: string | null;
}
```

## Exported Functions

```typescript
// Validates a request token and returns the decoded auth result
export async function validateToken(raw: string): Promise<AuthResult>

// Returns true if token scope includes the required scope
export function hasScope(token: AuthToken, scope: string): boolean
```

## Constraints

- `validateToken` must be async — never sync
- Returns `error` field, never throws
- `userId` is always a UUID v4 string
```

---

## Boundary Detection Heuristics

Use these patterns to find natural ownership boundaries:

| Pattern | Boundary type | Split strategy |
|---------|--------------|----------------|
| Layer architecture (controller/service/repo) | Horizontal | One stream per layer |
| Feature slices (user/order/product) | Vertical | One stream per feature |
| Test vs implementation | Test/impl | Test stream reads from impl streams |
| Client vs server | Platform | One stream per platform |
| New feature vs existing code | Change size | New feature = one stream, existing = coordinator |

---

## Dispatch Prompt Template

When dispatching a stream, include ownership context:

```
You are implementing stream-<id>: <description>

Files you OWN (you must create/modify these):
  - <file1>
  - <file2>

Files you may READ (do not modify):
  - <file3> (written by stream-<other>)

Interface contracts you must follow:
  .ai/plans/<plan>/contracts/<contract>.md

Do not write any file outside your ownership list.
```

---

## Conflict Resolution

When two streams need to share a file:

1. **Assign to one, expose via interface**: The owning stream writes the file
   and publishes a contract. The consuming stream reads only.

2. **Split the file**: Divide responsibilities into two files. Each stream
   owns one.

3. **Sequential pre-step**: If both streams need to contribute, make it a
   coordinator step that runs before parallel dispatch. Coordinator writes
   the shared file; both streams read it.

4. **Never**: Do not assign one file to two streams and hope they don't
   conflict — they will.

---

## Integration with plan-engine

When plan-engine generates a wave with parallel tasks, run file-ownership
decomposition as a pre-step:

1. Extract all task `writes` arrays from parallel tasks in the wave
2. Check for overlap
3. If overlap: resolve before dispatching
4. Write ownership.yml
5. Add ownership context to each task's dispatch prompt

This integrates cleanly with the `writes:` field in state.yml task specs.
