# openapi-typescript — Process Reference

Full reference for package usage, code generation pipeline, schema validation, versioning, breaking change detection, mock servers, CI integration, and anti-patterns.

---

## openapi-typescript Package

Generates TypeScript types from an OpenAPI 3.x or Swagger 2.0 spec. Output is a `.d.ts` file containing a `paths` object and all `$components` types.

```bash
npx openapi-typescript openapi.yaml -o src/api/schema.d.ts
# or from a remote URL
npx openapi-typescript https://api.example.com/openapi.json -o src/api/schema.d.ts
```

Key options:
- `--immutable-types` — generates `readonly` properties (recommended for response types)
- `--path-params-as-types` — path params become literal types
- `--export-type` — wraps output in `export type` for isolatedModules compatibility

The generated file should not be edited by hand. Treat it as a build artifact.

---

## openapi-fetch: Type-Safe Clients

`openapi-fetch` wraps `fetch` and infers request/response types from the generated `paths` object. No casting, no magic strings, no `any`.

```ts
import createClient from "openapi-fetch";
import type { paths } from "./schema.d.ts";

const client = createClient<paths>({ baseUrl: "https://api.example.com" });

// Request and response types are inferred from the path + method
const { data, error } = await client.GET("/users/{id}", {
  params: { path: { id: "123" } },
});
// data: components["schemas"]["User"] | undefined
// error: components["schemas"]["ApiError"] | undefined
```

Always destructure `{ data, error }`. The client never throws — it returns a discriminated result. Check `error` before using `data`.

For mutation:
```ts
const { data, error } = await client.POST("/users", {
  body: { name: "Alice", email: "alice@example.com" },
});
```

Body type is inferred from the spec's `requestBody`. Missing required fields are caught at compile time.

---

## Code Generation Pipeline

```
openapi.yaml (source of truth)
    │
    ▼
openapi-typescript → src/api/schema.d.ts  (generated types)
    │
    ▼
openapi-fetch client  (typed HTTP calls, consumes schema.d.ts)
    │
    ▼
zod-openapi / typebox  (runtime validation at API boundary)
```

**package.json scripts:**
```json
{
  "scripts": {
    "generate:api": "openapi-typescript openapi.yaml -o src/api/schema.d.ts",
    "generate:api:remote": "openapi-typescript $API_SPEC_URL -o src/api/schema.d.ts"
  }
}
```

Run `generate:api` after any spec change. In CI, run it and fail the build if the output has an unexpected diff — this prevents spec drift from going undetected.

---

## Schema Validation

Generated TypeScript types are compile-time only. A response that doesn't match the spec won't be caught at runtime unless you validate explicitly.

### zod-openapi

Derives Zod schemas from OpenAPI component schemas:

```ts
import { extendZodWithOpenApi } from "@asteasolutions/zod-to-openapi";
import { z } from "zod";

extendZodWithOpenApi(z);

const UserSchema = z.object({
  id: z.string().openapi({ example: "user_123" }),
  name: z.string(),
  email: z.string().email(),
});

// Use the schema for both runtime validation and spec generation
const parsed = UserSchema.parse(responseData);
```

This approach works in either direction: write Zod schemas and generate the spec, or keep them in sync manually.

### @sinclair/typebox

Generates JSON Schema compatible types at runtime:

```ts
import { Type, Static } from "@sinclair/typebox";
import { Value } from "@sinclair/typebox/value";

const User = Type.Object({
  id: Type.String(),
  name: Type.String(),
  email: Type.String({ format: "email" }),
});

type User = Static<typeof User>; // TypeScript type

const result = Value.Check(User, responseData); // runtime check
```

TypeBox is faster than Zod for JSON Schema validation at scale. Prefer it when validating high-volume API responses.

### Validation placement

Apply validation at API boundaries — not inside business logic. The right place is the HTTP client layer or a dedicated API module:

```ts
export async function getUser(id: string): Promise<User> {
  const { data, error } = await client.GET("/users/{id}", {
    params: { path: { id } },
  });
  if (error) throw new ApiError(error);
  return UserSchema.parse(data); // validate at the boundary
}
```

---

## Spec-First vs Code-First

**Spec-first** (recommended): Write the OpenAPI YAML first. Generate server stubs and client types from it. The spec is the contract between teams and is reviewed in PRs.

**Code-first**: Annotate code with decorators or JSDoc and generate the spec from it. Easier to start, but the spec becomes a derivative artifact — harder to use as a real contract.

Use spec-first when:
- Multiple consumers (web, mobile, third-party) depend on the API
- Backend and frontend teams work in parallel
- You need breaking change detection

Use code-first when:
- You own both sides and the API is internal-only
- You're moving fast and the spec doesn't need to be shared

---

## Versioning Strategies

**Path versioning** (`/v1/users`, `/v2/users`): explicit, cacheable, easy to reason about. Preferred for public APIs.

**Header versioning** (`API-Version: 2024-01-01`): cleaner URLs, but requires consumers to manage headers. Common in Stripe-style APIs.

**No versioning (evolution)**: add fields, never remove. Only works if consumers tolerate extra fields and you never break existing shapes.

For path versioning with code generation, maintain a spec file per version:
```
openapi/
  v1.yaml
  v2.yaml
```
Generate separate schema files:
```bash
openapi-typescript openapi/v1.yaml -o src/api/v1/schema.d.ts
openapi-typescript openapi/v2.yaml -o src/api/v2/schema.d.ts
```

---

## Breaking Change Detection

A breaking change removes or narrows something consumers depend on:
- Removing a field or endpoint
- Making an optional field required
- Changing a field's type
- Removing an enum value
- Changing auth requirements

Tools:
- **openapi-diff**: compares two spec files and lists breaking changes
- **oasdiff**: CLI and Go library, supports detailed breaking change reports
- **Spectral**: linting with custom rules for naming conventions, required fields, deprecation

CI integration:
```yaml
# GitHub Actions example
- name: Check for breaking changes
  run: |
    npx oasdiff breaking openapi/v1.yaml openapi/v1-new.yaml --fail-on ERR
```

Fail the build on breaking changes. For intentional breaks, bump the version and maintain backward compatibility in the old version through a deprecation window.

---

## Mock Servers from Specs

Mock servers let frontend teams develop against a spec without a live backend.

**Prism** (by Stoplight): starts a mock server that validates requests and returns example responses from the spec:
```bash
npx @stoplight/prism-cli mock openapi.yaml
# → http://localhost:4010
```

Prism validates that requests match the spec schema and returns the first `example` value defined for each response.

**msw-auto-mock**: generates MSW (Mock Service Worker) handlers from an OpenAPI spec for browser/test use:
```bash
npx msw-auto-mock openapi.yaml -o src/mocks/handlers.ts
```

Use Prism for local development integration. Use msw-auto-mock for unit/integration tests.

---

## CI Integration

Minimum CI pipeline for a contract-first API:

```yaml
steps:
  - name: Generate types
    run: npm run generate:api

  - name: Check for uncommitted changes
    run: |
      git diff --exit-code src/api/schema.d.ts || \
        (echo "Generated types are out of sync with the spec. Run generate:api." && exit 1)

  - name: Lint spec
    run: npx spectral lint openapi.yaml

  - name: Check for breaking changes
    run: npx oasdiff breaking openapi/main.yaml openapi.yaml --fail-on ERR

  - name: Type check
    run: npx tsc --noEmit
```

The "uncommitted changes" check is the most important gate. It catches engineers who updated the spec but forgot to regenerate, or regenerated locally but didn't commit.

---

## Common Anti-Patterns

### Manual type duplication
Writing TypeScript interfaces by hand that mirror OpenAPI schemas. They drift immediately and silently.

**Fix**: delete the manual types, run `openapi-typescript`, import from the generated file.

### Stale codegen
Generated types committed to the repo but not regenerated when the spec changes. CI has no diff check.

**Fix**: add the diff check gate to CI. Make stale output a build failure.

### Over-generating
Running codegen for every microservice into a single monolithic schema file. Changes to one service break all call sites.

**Fix**: generate per-service schema files. Co-locate each `schema.d.ts` with the service client that uses it.

### Treating types as validation
Using generated TypeScript types in place of runtime validation. A malformed response silently passes the type system.

**Fix**: add a validation step (zod-openapi or typebox) at every API boundary.

### Casting instead of narrowing
Using `as components["schemas"]["User"]` instead of validating. This is a lie to the compiler.

**Fix**: validate first, then let the type flow naturally from the validated result.

### Ignoring `error` in openapi-fetch
Destructuring only `data` and assuming success:
```ts
const { data } = await client.GET("/users/{id}", { ... }); // data may be undefined
```

**Fix**: always check `error` before using `data`. The types force this if you don't suppress them.
