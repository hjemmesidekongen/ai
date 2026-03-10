---
name: openapi-typescript
description: >
  OpenAPI code generation, type-safe API clients, schema validation, and
  contract-first development. Covers openapi-typescript, openapi-fetch,
  zod-openapi, breaking change detection, and CI integration.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "openapi"
  - "openapi typescript"
  - "api codegen"
  - "swagger types"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "no_manual_types"
      verify: "No hand-written types duplicate what the OpenAPI schema already defines"
      fail_action: "Delete the manual types and import from the generated output instead"
    - name: "codegen_in_ci"
      verify: "Type generation runs in CI and the diff is checked — not just locally"
      fail_action: "Add a generate + diff step to the pipeline; stale codegen is invisible drift"
    - name: "client_uses_generated_paths"
      verify: "openapi-fetch (or equivalent) is typed against generated paths, not raw strings"
      fail_action: "Replace string URLs with path keys from the generated PathsObject"
    - name: "schema_validation_at_boundary"
      verify: "Runtime validation (zod-openapi or typebox) is applied at the API boundary, not assumed"
      fail_action: "Add a validation layer — generated types are compile-time only, not runtime guarantees"
  on_fail: "Contract integrity has gaps — fix before shipping"
  on_pass: "OpenAPI contract is type-safe and CI-enforced"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
---

# openapi-typescript

The spec is the contract. Generate types from it — never write them by hand. If the spec and the types drift, every downstream assumption silently breaks.

## Contract-First Approach

Write (or own) the OpenAPI spec before writing any implementation. The spec defines the surface area: request shapes, response shapes, error variants, auth requirements. Code should conform to the spec, not the other way around.

**Spec-first wins**: schema is the source of truth, clients and servers share one contract, breaking changes are detectable before they ship, mock servers are derivable from the spec alone.

## Code Generation Workflow

Pipeline: `openapi.yaml` → `openapi-typescript` → `schema.d.ts` → `openapi-fetch` client → typed call sites.

Run generation as a script, not manually. Check the diff in CI — if generated output changes unexpectedly, the build fails. This catches spec drift before it reaches consumers.

## Type Safety Strategy

`openapi-typescript` generates a `paths` object and component types. `openapi-fetch` consumes `paths` and infers request/response types from the path key + method — no casting, no `any`.

For runtime safety, pair with `zod-openapi` or `@sinclair/typebox` to derive Zod or JSON Schema validators from the same spec. This closes the gap between compile-time types and actual API responses.

## Key Rules

- Generated files are artifacts, not source. Commit them only if the team needs them for offline use; otherwise generate on install.
- Never cast response data to a generated type — validate it. Types are promises the compiler accepts; validation is the runtime proof.
- Breaking changes (removed fields, narrowed types, changed required status) must go through a versioning strategy — path versioning (`/v2/`) or header versioning.
- If a field is optional in the spec, treat it as absent at call sites until the validation layer confirms it.
- Mocks derived from the spec (e.g., `msw-auto-mock`, Prism) keep tests honest without a live server.

See `references/process.md` for full package usage, schema validation patterns, versioning strategies, breaking change detection, mock server setup, CI integration, and anti-patterns.
