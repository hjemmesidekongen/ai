# Error Logging — Detailed Process

## Overview

The error-logging skill scaffolds Sentry-based error tracking tailored to the
confirmed framework in stack.yml. It generates initialization code, error
boundaries, API interceptors, unhandled rejection handlers, error page
integration, and source map upload configuration. The skill is framework-aware
and produces different output depending on whether the project uses Next.js,
React SPA, or Node.js backend.

## Prerequisites

Before starting, verify:
1. `.ai/projects/[name]/dev/stack.yml` exists with confirmed framework
2. `SENTRY_DSN` environment variable pattern is documented (skill references it, never hardcodes)

If stack.yml is missing, report error and suggest re-running stack-negotiation.

## Step 0: Read Stack Context

```
Read .ai/projects/[name]/dev/stack.yml
Extract:
  - framework: (nextjs | react | node | remix | sveltekit | other)
  - runtime: (node | edge | bun | deno)
  - build_tool: (vite | webpack | turbopack | esbuild | other)
  - package_manager: (npm | pnpm | yarn | bun)
  - src_root: path to source directory
  - typescript: true/false

Read .ai/projects/[name]/dev/dev-config.yml (if exists)
Extract:
  - structure.entry_points
  - structure.key_directories
  - commands.build
```

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 1: Select Sentry SDK

Based on confirmed framework, select the appropriate package:

| Framework | Package | Integration Pattern |
|-----------|---------|-------------------|
| Next.js | `@sentry/nextjs` | `instrumentation.ts` hook + `sentry.client.config.ts` + `sentry.server.config.ts` + `sentry.edge.config.ts` |
| React SPA | `@sentry/react` | `Sentry.init()` in entry point + `Sentry.ErrorBoundary` component |
| Remix | `@sentry/remix` | `entry.client.tsx` + `entry.server.tsx` integration |
| Node.js (Express) | `@sentry/node` | `Sentry.init()` + Express error handler middleware |
| Node.js (Fastify) | `@sentry/node` | `Sentry.init()` + Fastify error hook |
| Node.js (Hono) | `@sentry/node` | `Sentry.init()` + Hono error middleware |
| SvelteKit | `@sentry/sveltekit` | `hooks.client.ts` + `hooks.server.ts` |
| Other | `@sentry/node` | Generic `Sentry.init()` with manual capture |

Present selected SDK to user:
```
Framework confirmed: [framework]
Sentry package: [package]
Integration pattern: [pattern]

Proceed? [Y/n]
```

## Step 2: Generate Sentry Initialization

### Next.js Pattern

Generate three files:

**`sentry.client.config.ts`:**
```typescript
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 1.0,
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
  integrations: [
    Sentry.replayIntegration(),
    Sentry.browserTracingIntegration(),
  ],
});
```

**`sentry.server.config.ts`:**
```typescript
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  tracesSampleRate: 1.0,
});
```

**`instrumentation.ts`:**
```typescript
export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    await import("./sentry.server.config");
  }
  if (process.env.NEXT_RUNTIME === "edge") {
    await import("./sentry.edge.config");
  }
}
```

### React SPA Pattern

**`src/lib/sentry.ts`:**
```typescript
import * as Sentry from "@sentry/react";

export function initSentry() {
  Sentry.init({
    dsn: import.meta.env.VITE_SENTRY_DSN,
    tracesSampleRate: 1.0,
    replaysSessionSampleRate: 0.1,
    replaysOnErrorSampleRate: 1.0,
    integrations: [
      Sentry.browserTracingIntegration(),
      Sentry.replayIntegration(),
    ],
  });
}
```

### Node.js Backend Pattern

**`src/lib/sentry.ts`:**
```typescript
import * as Sentry from "@sentry/node";

export function initSentry() {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    tracesSampleRate: 1.0,
    integrations: [
      Sentry.httpIntegration(),
    ],
  });
}
```

**Adapt env var name to framework convention:**
- Next.js client: `NEXT_PUBLIC_SENTRY_DSN`
- Next.js server: `SENTRY_DSN`
- Vite: `VITE_SENTRY_DSN`
- Node.js: `SENTRY_DSN`

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 3: Scaffold Error Boundaries

Error boundaries must wrap **key UI sections**, not just the app root. This
gives granular error isolation — a failing sidebar does not take down the
main content area.

### Reusable ErrorBoundary Component

**`src/components/ErrorBoundary.tsx`:**
```typescript
import * as Sentry from "@sentry/react"; // or @sentry/nextjs

interface ErrorBoundaryProps {
  section: string;         // e.g., "header", "sidebar", "main-content"
  fallback?: React.ReactNode;
  children: React.ReactNode;
}

export function SectionErrorBoundary({
  section,
  fallback,
  children,
}: ErrorBoundaryProps) {
  return (
    <Sentry.ErrorBoundary
      fallback={fallback ?? <ErrorFallback section={section} />}
      beforeCapture={(scope) => {
        scope.setTag("ui.section", section);
      }}
    >
      {children}
    </Sentry.ErrorBoundary>
  );
}

function ErrorFallback({ section }: { section: string }) {
  return (
    <div role="alert" data-section={section}>
      <p>Something went wrong in the {section} section.</p>
    </div>
  );
}
```

### Usage Guidance

Present to user which sections should be wrapped:
```
Recommended error boundary sections:
  - header / navigation
  - sidebar (if applicable)
  - main content area
  - footer
  - dynamic widgets / dashboards

Each section fails independently — users see a localized error
message instead of a full page crash.

Add additional sections? [list or Enter to continue]
```

**For React SPA:** Import from `@sentry/react`.
**For Next.js:** Import from `@sentry/nextjs`.

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 4: Create API Error Interceptor

Generate an interceptor that captures request context for every failed API call.

**`src/lib/api-interceptor.ts`:**
```typescript
import * as Sentry from "@sentry/react"; // adjust import per framework

interface RequestContext {
  url: string;
  method: string;
  status: number;
  duration_ms: number;
  request_id?: string;
}

export function captureApiError(
  error: Error,
  context: RequestContext,
) {
  Sentry.withScope((scope) => {
    scope.setTag("api.url", context.url);
    scope.setTag("api.method", context.method);
    scope.setTag("api.status", String(context.status));
    scope.setExtra("api.duration_ms", context.duration_ms);
    if (context.request_id) {
      scope.setExtra("api.request_id", context.request_id);
    }
    Sentry.captureException(error);
  });
}
```

### Framework-Specific Integration

**Fetch wrapper (React SPA / Next.js client):**
```typescript
export async function fetchWithSentry(
  input: RequestInfo,
  init?: RequestInit,
): Promise<Response> {
  const start = performance.now();
  const method = init?.method ?? "GET";
  const url = typeof input === "string" ? input : input.url;

  try {
    const response = await fetch(input, init);
    if (!response.ok) {
      captureApiError(
        new Error(`HTTP ${response.status}: ${url}`),
        {
          url,
          method,
          status: response.status,
          duration_ms: performance.now() - start,
        },
      );
    }
    return response;
  } catch (error) {
    captureApiError(error as Error, {
      url,
      method,
      status: 0,
      duration_ms: performance.now() - start,
    });
    throw error;
  }
}
```

**Express middleware (Node.js backend):**
```typescript
import { Request, Response, NextFunction } from "express";

export function sentryErrorMiddleware(
  err: Error,
  req: Request,
  res: Response,
  _next: NextFunction,
) {
  Sentry.withScope((scope) => {
    scope.setTag("api.url", req.originalUrl);
    scope.setTag("api.method", req.method);
    scope.setTag("api.status", String(res.statusCode));
    scope.setExtra("api.user_agent", req.get("user-agent"));
    Sentry.captureException(err);
  });
  res.status(500).json({ success: false, error: "Internal server error" });
}
```

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 5: Configure Unhandled Rejection Handlers

Add global catch-all for unhandled promise rejections.

**Browser (client-side):**
```typescript
// Added to Sentry init file
window.addEventListener("unhandledrejection", (event) => {
  Sentry.captureException(event.reason, {
    tags: { "error.type": "unhandled_rejection" },
    extra: { promise: String(event.promise) },
  });
});
```

**Node.js (server-side):**
```typescript
// Added to Sentry init file
process.on("unhandledRejection", (reason, promise) => {
  Sentry.captureException(reason, {
    tags: { "error.type": "unhandled_rejection" },
    extra: { promise: String(promise) },
  });
});

process.on("uncaughtException", (error) => {
  Sentry.captureException(error, {
    tags: { "error.type": "uncaught_exception" },
  });
});
```

**Next.js:** Both handlers are included — client in `sentry.client.config.ts`,
server in `sentry.server.config.ts`.

## Step 6: Error Page Integration (dec-02)

Error pages (404 and 500) must POST context to Sentry so failed navigations
are tracked with full context. This ties to dec-02 (error pages design).

**`src/pages/error/404.tsx` (or app equivalent):**
```typescript
import * as Sentry from "@sentry/react"; // adjust per framework
import { useEffect } from "react";

export default function NotFound() {
  useEffect(() => {
    Sentry.captureMessage("404 — Page Not Found", {
      level: "warning",
      tags: {
        "error.type": "404",
        "error.page": "not_found",
      },
      extra: {
        failed_url: window.location.href,
        referrer: document.referrer,
        session_id: getSessionId(), // from your session utility
        timestamp: new Date().toISOString(),
      },
    });
  }, []);

  return (/* 404 page UI — designed per dec-02 */);
}
```

**`src/pages/error/500.tsx`:**
```typescript
import * as Sentry from "@sentry/react";
import { useEffect } from "react";

export default function ServerError() {
  useEffect(() => {
    Sentry.captureMessage("500 — Server Error", {
      level: "error",
      tags: {
        "error.type": "500",
        "error.page": "server_error",
      },
      extra: {
        failed_url: window.location.href,
        referrer: document.referrer,
        session_id: getSessionId(),
        timestamp: new Date().toISOString(),
      },
    });
  }, []);

  return (/* 500 page UI — designed per dec-02 */);
}
```

**Next.js App Router:** Use `error.tsx` and `not-found.tsx` conventions instead.

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 7: Source Map Upload Configuration

Configure the build tool to upload source maps to Sentry for readable
production stack traces.

### Vite (React SPA)

```typescript
// vite.config.ts
import { sentryVitePlugin } from "@sentry/vite-plugin";

export default defineConfig({
  build: { sourcemap: true },
  plugins: [
    sentryVitePlugin({
      org: process.env.SENTRY_ORG,
      project: process.env.SENTRY_PROJECT,
      authToken: process.env.SENTRY_AUTH_TOKEN,
    }),
  ],
});
```

### Next.js

```typescript
// next.config.ts
import { withSentryConfig } from "@sentry/nextjs";

const nextConfig = { /* existing config */ };

export default withSentryConfig(nextConfig, {
  org: process.env.SENTRY_ORG,
  project: process.env.SENTRY_PROJECT,
  authToken: process.env.SENTRY_AUTH_TOKEN,
  silent: true,
  widenClientFileUpload: true,
  hideSourceMaps: true,
});
```

### Webpack (generic)

```typescript
// webpack.config.js
const { sentryWebpackPlugin } = require("@sentry/webpack-plugin");

module.exports = {
  devtool: "source-map",
  plugins: [
    sentryWebpackPlugin({
      org: process.env.SENTRY_ORG,
      project: process.env.SENTRY_PROJECT,
      authToken: process.env.SENTRY_AUTH_TOKEN,
    }),
  ],
};
```

### Required Environment Variables

Document these in the project README or .env.example:
```
SENTRY_DSN=             # Sentry Data Source Name
SENTRY_ORG=             # Sentry organization slug
SENTRY_PROJECT=         # Sentry project slug
SENTRY_AUTH_TOKEN=      # Auth token for source map upload (CI only)
```

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 8: Present Summary and Review

Present all scaffolded files to the user:

```
## Error Logging Summary

**SDK:** [package] ([framework] integration)
**Files generated:**
  - [path]: Sentry initialization
  - [path]: ErrorBoundary component (wraps [N] sections)
  - [path]: API error interceptor (captures URL, method, status, timing)
  - [path]: 404 page with Sentry context (failed URL, referrer, session ID)
  - [path]: 500 page with Sentry context
  - [path]: Source map upload config ([build tool])

**Unhandled rejection handler:** Configured in init file
**Env vars needed:** SENTRY_DSN, SENTRY_ORG, SENTRY_PROJECT, SENTRY_AUTH_TOKEN

Changes look good? [Y/n]
```

Wait for explicit user confirmation. If user wants changes, go back to the
relevant step and re-generate.

## Step 9: Run Checkpoint

Run all 6 checkpoint checks:
1. Sentry init exists with DSN env var reference
2. Error boundaries wrap key UI sections (not just app root)
3. API interceptor captures URL, method, status, timing
4. Unhandled rejection handler is configured
5. 404/500 pages POST context to Sentry (failed URL, referrer, session ID, timestamp)
6. Source map upload configured for confirmed build tool

If any check fails, fix and re-run. Do not advance until all pass.

## Error Handling

1. **stack.yml not found:** Log to state.yml errors array. Report error and
   suggest re-running stack-negotiation.
2. **Unknown framework:** Fall back to generic `@sentry/node` or `@sentry/browser`
   depending on runtime. Log the fallback decision.
3. **Conflicting Sentry config exists:** Detect existing Sentry setup, present
   diff to user, ask whether to merge or replace.
4. **Before retrying:** Always check state.yml errors array. Never repeat a
   failed approach.

## Commit Protocol

**Subagent mode** (dispatched via Task()):
1. Stage only generated Sentry files and findings.md updates
2. Commit: `[plan_name]: error-logging [task_id]`
3. Report commit SHA in task_complete

**Inline mode:** Commit after verification passes with descriptive message.

---

## Step 0b: Initialize Trace (mandatory if tracing enabled)

Read `state.yml` and check `trace.enabled`. If `true`:

1. Create trace file: `.ai/projects/[name]/traces/error-logging-{ISO-timestamp}.yml`
2. Write `_meta` block: schema `"trace"`, version `"1.1.0"`, skill, module, project, started_at, trace_mode
3. Initialize empty `steps: []`, `checkpoint_result: {}`, `quality_summary: {}`, `reflections: {}`

**Schema v1.1.0 — required fields per step:**
- `decision`, `reasoning`, `uncertainty` (always required)
- `observation` — what happened vs expected; surprises, gaps, confirmations
- `improvement_idea` — actionable suggestion for the skill/pipeline (if any)
- `design_decision` — lasting choice beyond this run (if any)

**Trace-level `reflections` section (REQUIRED — Stop hook enforces):**
```yaml
reflections:
  observations: ["at least one observation about the run"]
  improvement_ideas: []   # optional but encouraged
  design_decisions: []    # optional, only for lasting choices
```

The Stop hook will BLOCK completion if reflections section is missing.

---

## Trace Finalization (mandatory if tracing enabled)

Before completing, verify your trace file has:
1. All steps recorded (written every 2 steps per the 2-Action Rule)
2. `checkpoint_result` with pass/fail status
3. `quality_summary` with avg_uncertainty and recommendation
4. `reflections` section with at least one observation (REQUIRED — Stop hook enforces this)
5. Step-level `observation`, `improvement_idea`, or `design_decision` where applicable

The Stop hook will BLOCK completion if tracing is enabled and the trace file
is missing or has no `reflections:` section.
