# Expo API Routes — Process Reference

## Setup

Requires `expo-router` 3.x+ with server output mode enabled:

```json
// app.json
{
  "expo": {
    "web": {
      "output": "server"
    }
  }
}
```

Install server runtime peer deps:

```bash
npx expo install expo-router react-native-web react-dom @expo/metro-runtime
```

## Request Handling

### Reading the Request

```ts
import { ExpoRequest, ExpoResponse } from 'expo-router/server';

export async function POST(request: ExpoRequest): Promise<ExpoResponse> {
  // JSON body
  const body = await request.json();

  // Form data
  const form = await request.formData();

  // Query params
  const url = new URL(request.url);
  const page = url.searchParams.get('page') ?? '1';

  // Headers
  const auth = request.headers.get('authorization');

  return ExpoResponse.json({ ok: true });
}
```

### Sending Responses

```ts
// JSON with status
return ExpoResponse.json({ error: 'Unauthorized' }, { status: 401 });

// Custom headers
return ExpoResponse.json(data, {
  status: 200,
  headers: { 'Cache-Control': 'max-age=60' },
});

// Plain text or redirect
return new Response('Not found', { status: 404 });
```

## Validation with Zod

Always validate before processing:

```ts
import { z } from 'zod';
import { ExpoRequest, ExpoResponse } from 'expo-router/server';

const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(2),
});

export async function POST(request: ExpoRequest): Promise<ExpoResponse> {
  const body = await request.json();
  const result = CreateUserSchema.safeParse(body);

  if (!result.success) {
    return ExpoResponse.json(
      { error: 'Invalid input', details: result.error.flatten() },
      { status: 422 }
    );
  }

  const user = await db.user.create({ data: result.data });
  return ExpoResponse.json(user, { status: 201 });
}
```

## Authentication

No session cookies in React Native — use token-based auth:

```ts
import { ExpoRequest, ExpoResponse } from 'expo-router/server';
import jwt from 'jsonwebtoken';

async function authenticate(request: ExpoRequest): Promise<{ userId: string } | null> {
  const authHeader = request.headers.get('authorization');
  if (!authHeader?.startsWith('Bearer ')) return null;

  const token = authHeader.slice(7);
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET!) as { userId: string };
    return payload;
  } catch {
    return null;
  }
}

export async function GET(request: ExpoRequest): Promise<ExpoResponse> {
  const auth = await authenticate(request);
  if (!auth) return ExpoResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const data = await db.profile.findUnique({ where: { userId: auth.userId } });
  return ExpoResponse.json(data);
}
```

For OAuth flows (Google, Apple), handle the callback in an API route and issue a JWT:

```ts
// app/api/auth/callback+api.ts
export async function GET(request: ExpoRequest): Promise<ExpoResponse> {
  const url = new URL(request.url);
  const code = url.searchParams.get('code');

  const tokens = await exchangeCode(code);
  const profile = await fetchProfile(tokens.access_token);

  const user = await db.user.upsert({ where: { email: profile.email }, ... });
  const jwt = signJwt({ userId: user.id });

  // Return token to the native deep link
  return Response.redirect(`myapp://auth?token=${jwt}`);
}
```

## Middleware Pattern

Expo Router doesn't have a built-in middleware layer — implement it as composable handler wrappers:

```ts
// lib/api-middleware.ts
import { ExpoRequest, ExpoResponse } from 'expo-router/server';

type Handler = (request: ExpoRequest, ...args: any[]) => Promise<ExpoResponse>;

export function withAuth(handler: Handler): Handler {
  return async (request, ...args) => {
    const auth = await authenticate(request);
    if (!auth) return ExpoResponse.json({ error: 'Unauthorized' }, { status: 401 });

    // Attach auth to request (via headers or a context object)
    const augmented = new Request(request.url, {
      ...request,
      headers: { ...Object.fromEntries(request.headers), 'x-user-id': auth.userId },
    }) as ExpoRequest;

    return handler(augmented, ...args);
  };
}

export function withCors(handler: Handler): Handler {
  return async (request, ...args) => {
    const response = await handler(request, ...args);
    response.headers.set('Access-Control-Allow-Origin', '*');
    return response;
  };
}
```

Usage:

```ts
export const GET = withAuth(withCors(async (request) => {
  return ExpoResponse.json({ ok: true });
}));
```

## Database Access

API routes run in Node.js — full ORM access is available. Prisma:

```ts
import { PrismaClient } from '@prisma/client';

// Singleton to avoid connection exhaustion in dev
const globalForPrisma = global as unknown as { prisma: PrismaClient };
export const db = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = db;
```

For serverless deployments (EAS functions), prefer `@prisma/client` with connection pooling via PgBouncer or Neon's serverless driver to avoid cold-start connection overhead.

## Type Sharing Between Client and Server

Define shared types in a `types/` folder or alongside the API file — importable by both native and server code:

```ts
// types/api.ts
export type User = {
  id: string;
  email: string;
  name: string;
};

export type CreateUserInput = {
  email: string;
  name: string;
};
```

The native client imports the same types for typed `fetch` calls:

```ts
// In a React Native component
import type { User } from '@/types/api';

const res = await fetch('/api/users');
const users: User[] = await res.json();
```

For stricter end-to-end type safety, generate typed client functions from your API handlers (similar to tRPC) or use the `openapi-typescript` skill to generate types from an OpenAPI spec.

## Error Handling

Centralize error shaping:

```ts
// lib/api-error.ts
export class ApiError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string
  ) {
    super(message);
  }
}

export function handleApiError(error: unknown): ExpoResponse {
  if (error instanceof ApiError) {
    return ExpoResponse.json(
      { error: error.code, message: error.message },
      { status: error.status }
    );
  }

  console.error('Unhandled API error:', error);
  return ExpoResponse.json({ error: 'INTERNAL_ERROR' }, { status: 500 });
}
```

Wrap handlers:

```ts
export async function POST(request: ExpoRequest): Promise<ExpoResponse> {
  try {
    // handler logic
    return ExpoResponse.json(result);
  } catch (error) {
    return handleApiError(error);
  }
}
```

## Environment Variables

Server-only env vars are safe in API routes — they're never bundled into the native app:

```ts
// Safe in API routes — server-only
const apiKey = process.env.STRIPE_SECRET_KEY;

// Exposed to native bundle — only use for truly public values
const publicKey = process.env.EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY;
```

Never reference `process.env.SECRET_*` in files that are imported by React Native screens or components.

## Deployment

API routes deploy to:
- **EAS Hosting** — managed serverless, zero config with `eas deploy`
- **Node.js server** — `npx expo export --platform web` + serve with Express or Fastify
- **Edge runtimes** — limited Node.js API availability; avoid filesystem access and full ORMs

For EAS Hosting, set env vars in `eas.json` under `"env"` or via the EAS dashboard — they're injected at build time and available at runtime in API routes.

## Common Anti-Patterns

**Importing React Native in API routes**
API routes run in Node.js — importing RN packages (StyleSheet, View, etc.) will throw. Keep server code in files that never import from `react-native`.

**Unvalidated user input going to the database**
Always run zod (or equivalent) before any DB write. Skipping validation is the fastest path to injection vulnerabilities and data corruption.

**Returning raw database objects**
Shape the response explicitly — don't return the full ORM record, which may include sensitive fields (passwords, tokens, internal IDs).

**No status codes on errors**
Returning `ExpoResponse.json({ error: '...' })` without a status code defaults to 200 — clients can't tell it's an error without parsing the body. Always set the appropriate HTTP status.

**Using cookies for auth tokens in React Native clients**
React Native's `fetch` doesn't send cookies automatically. Use `Authorization: Bearer` headers and store the token in SecureStore.
