---
name: expo-api-routes
description: >
  API routes in Expo Router — server functions, request handling, middleware,
  and type-safe endpoints
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "expo api routes"
  - "expo server"
  - "expo router api"
  - "expo backend"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "server_only_code"
      verify: "API route files use server-only logic — no React imports, no client hooks"
      fail_action: "Remove client-side code from API route files"
    - name: "typed_request_response"
      verify: "Request params and response shapes are typed — no untyped `any` in handlers"
      fail_action: "Add explicit types or zod schemas to request/response boundaries"
    - name: "error_responses_consistent"
      verify: "All error paths return structured JSON with appropriate HTTP status codes"
      fail_action: "Replace bare throws or empty returns with typed error responses"
  on_fail: "API route has structural or type safety issues — fix before shipping"
  on_pass: "API route patterns are sound"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for dev-engine"
---

# Expo API Routes

Expo Router supports API routes via `+api.ts` files — server-only handlers running in Node.js, not in the React Native runtime. They enable full-stack Expo without a separate backend.

## File Convention

```
app/
  api/
    users+api.ts          # /api/users
    users/[id]+api.ts     # /api/users/:id
```

## Request Handlers

Export named functions per HTTP method using `ExpoRequest` / `ExpoResponse` from `expo-router/server`:

```ts
import { ExpoRequest, ExpoResponse } from 'expo-router/server';

export async function GET(request: ExpoRequest): Promise<ExpoResponse> {
  const users = await db.user.findMany();
  return ExpoResponse.json(users);
}

export async function POST(request: ExpoRequest): Promise<ExpoResponse> {
  const body = await request.json();
  const user = await db.user.create({ data: body });
  return ExpoResponse.json(user, { status: 201 });
}
```

## Key Rules

- API routes run server-side — never import React or RN components.
- Validate inputs with zod before touching any database or external service.
- Authenticate via `Authorization: Bearer` headers — cookies aren't reliable in RN clients.
- Server-only env vars are never bundled into the native app — safe to use in API routes.
- Return explicit status codes on every error path — default is 200, which misleads clients.

See `references/process.md` for dynamic segments, middleware, auth, database access, type sharing, error handling, deployment, and anti-patterns.
