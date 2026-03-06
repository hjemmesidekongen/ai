# Observability -- Detailed Process

## Overview

The observability skill scaffolds server-side system health monitoring for
projects with a backend. It reads stack.yml (from stack-negotiation) to
determine the framework, database, and whether the project is a static site.
Static sites are skipped entirely. For backend projects, it generates
OpenTelemetry tracing, performance budgets, health endpoints, slow query
logging, and uptime monitoring configuration.

## Prerequisites

Before starting, verify:
1. `.ai/projects/[name]/dev/stack.yml` exists with confirmed stack
2. `.ai/projects/[name]/dev/dev-config.yml` exists with framework and commands

If stack.yml is missing, report blocked -- stack-negotiation must run first.

## Step 0: Initialize Trace (mandatory if tracing enabled)

Read `state.yml` and check `trace.enabled`. If `true`:

1. Create trace file: `.ai/projects/[name]/traces/observability-{ISO-timestamp}.yml`
2. Write `_meta` block: schema `"trace"`, version `"1.1.0"`, skill, module, project, started_at, trace_mode
3. Initialize empty `steps: []`, `checkpoint_result: {}`, `quality_summary: {}`, `reflections: {}`

**Schema v1.1.0 -- required fields per step:**
- `decision`, `reasoning`, `uncertainty` (always required)
- `observation` -- what happened vs expected; surprises, gaps, confirmations
- `improvement_idea` -- actionable suggestion for the skill/pipeline (if any)
- `design_decision` -- lasting choice beyond this run (if any)

**Trace-level `reflections` section (REQUIRED -- Stop hook enforces):**
```yaml
reflections:
  observations: ["at least one observation about the run"]
  improvement_ideas: []   # optional but encouraged
  design_decisions: []    # optional, only for lasting choices
```

The Stop hook will BLOCK completion if reflections section is missing.

---

## Step 1: Read Stack Configuration

Read `.ai/projects/[name]/dev/stack.yml`. Extract:

- `framework` -- primary runtime framework (Next.js, Express, Fastify, NestJS, etc.)
- `runtime` -- Node.js, Python, Go, etc.
- `database` -- PostgreSQL, MySQL, MongoDB, SQLite, or null
- `database_orm` -- Prisma, Drizzle, TypeORM, Mongoose, etc.
- `static_site` -- boolean flag indicating no backend
- `observability_provider` -- confirmed provider (if any)

Also read `.ai/projects/[name]/dev/dev-config.yml` for:
- `conventions.language` -- typescript or javascript
- `commands.start` -- server start command
- `structure.src_root` -- source root directory

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 2: Static Site Detection

Check if the project is a static site:

```
if stack.yml.static_site == true:
  Update state.yml:
    skills.observability.status: skipped
    skills.observability.skip_reason: "Static site -- no backend to observe"
  Exit cleanly
```

Static site indicators (if not explicitly flagged):
- Framework is Astro (static mode), plain HTML, Jekyll, Hugo, 11ty
- No server runtime detected
- No API routes in project structure

If static site detected, log to findings.md and exit. Do not generate any files.

## Step 3: Select OTel SDK and Instrumentation

Map framework to the correct OpenTelemetry SDK and auto-instrumentation packages:

### Framework-to-SDK Mapping

| Framework | OTel SDK | Auto-Instrumentation | Notes |
|-----------|----------|---------------------|-------|
| Express | @opentelemetry/sdk-node | @opentelemetry/auto-instrumentations-node | Standard Node.js setup |
| Fastify | @opentelemetry/sdk-node | @opentelemetry/auto-instrumentations-node + @opentelemetry/instrumentation-fastify | Fastify-specific instrumentation |
| NestJS | @opentelemetry/sdk-node | @opentelemetry/auto-instrumentations-node + @opentelemetry/instrumentation-nestjs-core | NestJS-specific instrumentation |
| Next.js (API routes) | @vercel/otel | @opentelemetry/auto-instrumentations-node | Vercel OTel wrapper for edge compat |
| Hono | @opentelemetry/sdk-node | @opentelemetry/auto-instrumentations-node | Generic Node.js setup |
| Python (FastAPI) | opentelemetry-sdk | opentelemetry-instrumentation-fastapi | Python ecosystem |
| Python (Flask) | opentelemetry-sdk | opentelemetry-instrumentation-flask | Python ecosystem |
| Go (net/http) | go.opentelemetry.io/otel | go.opentelemetry.io/contrib/instrumentation/net/http | Go ecosystem |

### Database Instrumentation

| ORM / Driver | Instrumentation Package |
|-------------|------------------------|
| Prisma | @prisma/instrumentation |
| Drizzle | Manual span wrapping (no official instrumentation) |
| TypeORM | @opentelemetry/instrumentation-typeorm (community) |
| Mongoose | @opentelemetry/instrumentation-mongoose |
| pg (raw) | @opentelemetry/instrumentation-pg |
| mysql2 | @opentelemetry/instrumentation-mysql2 |

Record selected packages in findings.md.

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 4: Generate Tracing Initialization

Write `src/lib/tracing.ts` (or `src/lib/tracing.js` for JavaScript projects).
Adjust the source path based on `structure.src_root` from dev-config.yml.

### Node.js Template (TypeScript)

```typescript
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-http';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';
import { Resource } from '@opentelemetry/resources';
import { ATTR_SERVICE_NAME, ATTR_SERVICE_VERSION } from '@opentelemetry/semantic-conventions';
// Sentry trace ID correlation
import { SentrySpanProcessor, SentryPropagator } from '@sentry/opentelemetry';

const resource = Resource.default().merge(
  new Resource({
    [ATTR_SERVICE_NAME]: process.env.OTEL_SERVICE_NAME ?? '[project-name]',
    [ATTR_SERVICE_VERSION]: process.env.npm_package_version ?? '0.0.0',
    'deployment.environment': process.env.NODE_ENV ?? 'development',
  }),
);

const traceExporter = new OTLPTraceExporter({
  url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT ?? 'http://localhost:4318/v1/traces',
});

const metricExporter = new OTLPMetricExporter({
  url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT ?? 'http://localhost:4318/v1/metrics',
});

const sdk = new NodeSDK({
  resource,
  traceExporter,
  metricReader: new PeriodicExportingMetricReader({
    exporter: metricExporter,
    exportIntervalMillis: 30_000,
  }),
  spanProcessors: [new SentrySpanProcessor()],
  textMapPropagator: new SentryPropagator(),
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-fs': { enabled: false },
    }),
    // Add framework-specific instrumentation here
    // Add database instrumentation here
  ],
});

sdk.start();

process.on('SIGTERM', () => {
  sdk.shutdown().then(
    () => process.exit(0),
    () => process.exit(1),
  );
});

export { sdk };
```

### Sentry Trace ID Correlation

The `@sentry/opentelemetry` package bridges Sentry and OTel:

- `SentrySpanProcessor` -- attaches Sentry trace IDs to OTel spans
- `SentryPropagator` -- propagates Sentry trace context across service boundaries
- Requires `@sentry/node` to be initialized first (handled by error-logging skill)

If Sentry is not configured (no `SENTRY_DSN` env var), the bridge is a no-op.

### Framework-Specific Adjustments

**Next.js (API routes):**
```typescript
// instrumentation.ts (Next.js instrumentation hook)
import { registerOTel } from '@vercel/otel';

export function register() {
  registerOTel({
    serviceName: process.env.OTEL_SERVICE_NAME ?? '[project-name]',
  });
}
```

**NestJS:** Import tracing.ts in main.ts before `NestFactory.create()`.

**Fastify:** Add `@opentelemetry/instrumentation-fastify` to instrumentations array.

**Python (FastAPI):**
```python
# tracing.py
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.sdk.resources import Resource

resource = Resource.create({
    "service.name": os.environ.get("OTEL_SERVICE_NAME", "[project-name]"),
    "deployment.environment": os.environ.get("ENVIRONMENT", "development"),
})

provider = TracerProvider(resource=resource)
provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
trace.set_tracer_provider(provider)

def instrument_app(app):
    FastAPIInstrumentor.instrument_app(app)
```

## Step 5: Generate Performance Budgets

Write `src/lib/performance-budgets.ts`. This defines per-endpoint latency and
throughput thresholds that can be checked in monitoring dashboards or CI.

```typescript
export interface PerformanceBudget {
  /** Route pattern (e.g., '/api/users/:id') */
  route: string;
  /** HTTP method */
  method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  /** Max acceptable p95 latency in milliseconds */
  maxLatencyP95Ms: number;
  /** Max acceptable p99 latency in milliseconds */
  maxLatencyP99Ms: number;
  /** Minimum requests per second the endpoint should handle */
  minThroughputRps: number;
  /** Alert severity when budget is exceeded */
  alertSeverity: 'warning' | 'critical';
}

/**
 * Performance budgets per endpoint.
 * Adjust thresholds based on your SLAs and infrastructure.
 * These are checked by uptime monitoring and can trigger alerts.
 */
export const performanceBudgets: PerformanceBudget[] = [
  {
    route: '/api/health',
    method: 'GET',
    maxLatencyP95Ms: 50,
    maxLatencyP99Ms: 100,
    minThroughputRps: 100,
    alertSeverity: 'critical',
  },
  {
    route: '/api/ready',
    method: 'GET',
    maxLatencyP95Ms: 200,
    maxLatencyP99Ms: 500,
    minThroughputRps: 50,
    alertSeverity: 'critical',
  },
  // Add application-specific endpoints below:
  // {
  //   route: '/api/users',
  //   method: 'GET',
  //   maxLatencyP95Ms: 200,
  //   maxLatencyP99Ms: 500,
  //   minThroughputRps: 50,
  //   alertSeverity: 'warning',
  // },
];

/**
 * Default budgets applied to any endpoint not explicitly listed.
 */
export const defaultBudget: Omit<PerformanceBudget, 'route' | 'method'> = {
  maxLatencyP95Ms: 500,
  maxLatencyP99Ms: 1000,
  minThroughputRps: 20,
  alertSeverity: 'warning',
};

/**
 * Look up the budget for a given route and method.
 * Falls back to defaultBudget if no specific budget is defined.
 */
export function getBudget(
  route: string,
  method: PerformanceBudget['method'],
): PerformanceBudget {
  const match = performanceBudgets.find(
    (b) => b.route === route && b.method === method,
  );
  return match ?? { route, method, ...defaultBudget };
}
```

## Step 6: Generate Health Endpoints

Generate two endpoints: `/health` (liveness) and `/ready` (readiness).

### /health -- Liveness Check

Returns 200 if the process is running. No dependency checks. Used by load
balancers and container orchestrators to determine if the process is alive.

### /ready -- Readiness Check

Returns 200 only if all dependencies (database, cache, external services) are
reachable. Used by orchestrators to determine if the instance should receive
traffic.

### Express / Fastify Template

```typescript
// health.ts
import type { Request, Response } from 'express';

export function healthCheck(_req: Request, res: Response): void {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: process.env.npm_package_version ?? '0.0.0',
  });
}
```

```typescript
// ready.ts
import type { Request, Response } from 'express';

interface DependencyCheck {
  name: string;
  check: () => Promise<boolean>;
}

const dependencies: DependencyCheck[] = [
  // Database check -- uncomment and adjust for your ORM:
  // {
  //   name: 'database',
  //   check: async () => {
  //     await prisma.$queryRaw`SELECT 1`;
  //     return true;
  //   },
  // },
  // Redis check:
  // {
  //   name: 'cache',
  //   check: async () => {
  //     const pong = await redis.ping();
  //     return pong === 'PONG';
  //   },
  // },
];

export async function readyCheck(_req: Request, res: Response): Promise<void> {
  const results = await Promise.allSettled(
    dependencies.map(async (dep) => ({
      name: dep.name,
      ok: await dep.check(),
    })),
  );

  const checks = results.map((r) =>
    r.status === 'fulfilled'
      ? { name: r.value.name, status: r.value.ok ? 'ok' : 'failed' }
      : { name: 'unknown', status: 'failed' },
  );

  const allReady = checks.every((c) => c.status === 'ok');

  res.status(allReady ? 200 : 503).json({
    status: allReady ? 'ready' : 'not_ready',
    timestamp: new Date().toISOString(),
    checks,
  });
}
```

### Next.js API Route Template

```typescript
// app/api/health/route.ts
import { NextResponse } from 'next/server';

export function GET() {
  return NextResponse.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
}
```

```typescript
// app/api/ready/route.ts
import { NextResponse } from 'next/server';

export async function GET() {
  // Add dependency checks here
  const checks: Array<{ name: string; status: string }> = [];

  const allReady = checks.every((c) => c.status === 'ok');
  return NextResponse.json(
    { status: allReady ? 'ready' : 'not_ready', checks },
    { status: allReady ? 200 : 503 },
  );
}
```

### NestJS Template

```typescript
// health.controller.ts
import { Controller, Get } from '@nestjs/common';
import { HealthCheck, HealthCheckService, TypeOrmHealthIndicator } from '@nestjs/terminus';

@Controller()
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private db: TypeOrmHealthIndicator,
  ) {}

  @Get('health')
  @HealthCheck()
  check() {
    return this.health.check([]);
  }

  @Get('ready')
  @HealthCheck()
  readiness() {
    return this.health.check([
      () => this.db.pingCheck('database'),
    ]);
  }
}
```

**Adjust endpoint paths based on framework routing conventions:**
- Express/Fastify: `/api/health`, `/api/ready` (registered on router)
- Next.js: `app/api/health/route.ts`, `app/api/ready/route.ts`
- NestJS: `health.controller.ts` with `@Get('health')` and `@Get('ready')`

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 7: Configure Slow Query Logging

If a database is detected in stack.yml, configure slow query logging.
If no database, skip this step and note in findings.md.

### Prisma

Add query event logging to the Prisma client initialization:

```typescript
import { PrismaClient } from '@prisma/client';

const SLOW_QUERY_THRESHOLD_MS = Number(process.env.SLOW_QUERY_THRESHOLD_MS ?? 500);

const prisma = new PrismaClient({
  log: [
    { level: 'query', emit: 'event' },
    { level: 'error', emit: 'stdout' },
    { level: 'warn', emit: 'stdout' },
  ],
});

prisma.$on('query', (e) => {
  if (e.duration > SLOW_QUERY_THRESHOLD_MS) {
    console.warn('[SLOW QUERY]', {
      query: e.query,
      params: e.params,
      duration: `${e.duration}ms`,
      timestamp: e.timestamp.toISOString(),
    });
    // Optionally: record as OTel span event
  }
});

export { prisma };
```

### Drizzle (with pg driver)

```typescript
import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';

const SLOW_QUERY_THRESHOLD_MS = Number(process.env.SLOW_QUERY_THRESHOLD_MS ?? 500);

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// pg driver emits query events when log is configured
pool.on('query', (query) => {
  // Note: timing must be measured manually with drizzle
});

export const db = drizzle(pool, {
  logger: {
    logQuery(query: string, params: unknown[]) {
      const start = performance.now();
      // Log format for downstream analysis
      return () => {
        const duration = performance.now() - start;
        if (duration > SLOW_QUERY_THRESHOLD_MS) {
          console.warn('[SLOW QUERY]', { query, duration: `${duration.toFixed(1)}ms` });
        }
      };
    },
  },
});
```

### General Pattern

For ORMs/drivers without built-in query events, wrap the query layer:

1. Measure `performance.now()` before and after each query
2. If duration exceeds `SLOW_QUERY_THRESHOLD_MS`, log the query
3. Optionally emit an OTel span event for the slow query

**Environment variable:** `SLOW_QUERY_THRESHOLD_MS` (default: 500ms)

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 8: Generate Uptime Monitoring Config

Write `monitoring.yml` to the project root. This provider-agnostic config
can be used with any uptime monitoring service (UptimeRobot, Betterstack,
Checkly, Datadog Synthetics, etc.).

```yaml
_meta:
  plugin: agency
  skill: observability
  version: "1.0.0"
  created_at: "[ISO timestamp]"
  project: "[name]"

monitors:
  - name: "[project] Health Check"
    type: http
    url: "${BASE_URL}/api/health"
    method: GET
    interval_seconds: 60
    timeout_seconds: 10
    expected_status: 200
    alert_channels: ["default"]
    regions: ["us-east", "eu-west"]

  - name: "[project] Readiness Check"
    type: http
    url: "${BASE_URL}/api/ready"
    method: GET
    interval_seconds: 300
    timeout_seconds: 15
    expected_status: 200
    alert_channels: ["default"]
    regions: ["us-east"]

  - name: "[project] SSL Certificate"
    type: ssl
    url: "${BASE_URL}"
    alert_days_before_expiry: 30
    alert_channels: ["default"]

alert_channels:
  - name: "default"
    type: "email"
    target: "${ALERT_EMAIL}"
    # Add Slack/PagerDuty/webhook targets as needed:
    # - name: "slack-ops"
    #   type: "webhook"
    #   target: "${SLACK_WEBHOOK_URL}"

thresholds:
  # Link to performance-budgets.ts for endpoint-specific thresholds
  global_p95_latency_ms: 500
  global_uptime_target_percent: 99.9
  consecutive_failures_before_alert: 3
```

## Step 9: Register Assets and Run Checkpoint

Append generated files to `.ai/projects/[name]/asset-registry.yml`:

```yaml
- path: "src/lib/tracing.ts"
  type: source
  generated_by: observability
- path: "src/lib/performance-budgets.ts"
  type: source
  generated_by: observability
- path: "src/pages/api/health.ts"
  type: source
  generated_by: observability
- path: "src/pages/api/ready.ts"
  type: source
  generated_by: observability
- path: "monitoring.yml"
  type: config
  generated_by: observability
- path: ".ai/projects/[name]/devops/observability-config.yml"
  type: config
  generated_by: observability
```

Adjust paths based on the framework (Next.js app router, NestJS controller, etc.).

Run all 6 checkpoint checks:

1. **otel_init_exists** -- tracing.ts uses the correct SDK for the confirmed framework
2. **health_endpoints_exist** -- /health returns `{ status: "healthy" }`, /ready returns `{ status: "ready"|"not_ready", checks: [] }`
3. **performance_budgets_defined** -- at least 1 endpoint has latency/throughput thresholds
4. **slow_query_logging** -- if database in stack.yml, slow query logging is configured; if no DB, this check passes automatically
5. **sentry_trace_correlation** -- SentrySpanProcessor and SentryPropagator are present in tracing init
6. **static_site_skipped** -- if static site, verify skill exited without generating files

If any check fails, fix immediately and re-check. On pass, update state.yml:

```yaml
skills:
  observability:
    status: completed
    completed_at: "[ISO timestamp]"
    recovery_notes: |
      Framework: [framework]
      OTel SDK: [sdk]
      Database: [db or "none"]
      Slow query threshold: [threshold]ms
      Health endpoints: /api/health, /api/ready
      Monitoring: monitoring.yml generated
```

## Error Handling

1. **stack.yml missing:** Report blocked. Stack-negotiation must complete first.
2. **Unknown framework:** Fall back to generic `@opentelemetry/sdk-node` setup. Log a warning in findings.md.
3. **No database detected:** Skip slow query logging. Mark `slow_query_logging` check as passed with note "no database".
4. **Sentry not configured:** Generate the bridge code anyway (it no-ops without `SENTRY_DSN`). Note in findings.md.
5. **Before retrying:** Always check state.yml errors array. Never repeat a failed approach.

## Environment Variables

The skill references these environment variables in generated code:

| Variable | Purpose | Default |
|----------|---------|---------|
| `OTEL_SERVICE_NAME` | Service name in traces | project name |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP collector endpoint | `http://localhost:4318` |
| `NODE_ENV` | Deployment environment tag | `development` |
| `SLOW_QUERY_THRESHOLD_MS` | Slow query threshold | `500` |
| `SENTRY_DSN` | Sentry DSN (from error-logging) | none |
| `BASE_URL` | Production URL for monitoring | none |
| `ALERT_EMAIL` | Alert notification email | none |

---

## Trace Finalization (mandatory if tracing enabled)

Before completing, verify your trace file has:
1. All steps recorded (written every 2 steps per the 2-Action Rule)
2. `checkpoint_result` with pass/fail status
3. `quality_summary` with avg_uncertainty and recommendation
4. `reflections` section with at least one observation (REQUIRED -- Stop hook enforces this)
5. Step-level `observation`, `improvement_idea`, or `design_decision` where applicable

The Stop hook will BLOCK completion if tracing is enabled and the trace file
is missing or has no `reflections:` section.
