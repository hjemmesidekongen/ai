---
name: observability
user-invocable: false
description: >
  Scaffolds server-side observability: OpenTelemetry tracing, performance budgets,
  /health + /ready endpoints, slow query logging, uptime monitoring. Backend-only,
  skips static sites. Coordinates with error-logging (Sentry trace IDs) and
  analytics (session context). Use when setting up observability, health checks,
  request tracing, performance budgets, or slow query logging.
phase: 4
depends_on: [stack-negotiation]
writes:
  - ".ai/projects/[name]/devops/observability-config.yml"
  - "src/lib/tracing.ts"
  - "src/lib/performance-budgets.ts"
  - "src/pages/api/health.ts (or framework equivalent)"
  - "src/pages/api/ready.ts (or framework equivalent)"
  - "monitoring.yml"
reads:
  - ".ai/projects/[name]/dev/stack.yml"
  - ".ai/projects/[name]/dev/dev-config.yml"
model_tier: senior
model: sonnet
interactive: false
checkpoint:
  type: data_validation
  required_checks:
    - { name: otel_init_exists, verify: "OTel init with correct SDK for framework", fail_action: "Generate tracing.ts" }
    - { name: health_endpoints_exist, verify: "/health + /ready return correct status", fail_action: "Generate endpoints" }
    - { name: performance_budgets_defined, verify: ">=1 endpoint has latency/throughput thresholds", fail_action: "Generate defaults" }
    - { name: slow_query_logging, verify: "DB query logging configured or skipped if no DB", fail_action: "Add logging or skip" }
    - { name: sentry_trace_correlation, verify: "Sentry trace IDs linked to OTel spans", fail_action: "Add @sentry/opentelemetry" }
    - { name: static_site_skipped, verify: "Static site exits cleanly", fail_action: "Check stack.yml and exit" }
  on_fail: "Fix and re-run"
  on_pass: "Update state.yml, register assets in asset-registry.yml"
---

# Observability

Phase 4 devops skill. Reads stack.yml to determine framework and database, then scaffolds server-side observability: OpenTelemetry tracing with Sentry correlation, performance budgets, health endpoints, slow query logging, and uptime monitoring. Skips entirely for static sites.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | stack.yml (framework, runtime, database, observability provider), dev-config.yml |
| **Writes** | tracing.ts, performance-budgets.ts, health + ready endpoints, monitoring.yml |
| **Checkpoint** | data_validation -- 6 checks: OTel init, health endpoints, perf budgets, slow queries, Sentry correlation, static skip |
| **Dependencies** | stack-negotiation (must run first to produce stack.yml) |
| **Coordinates** | error-logging (Sentry trace IDs), analytics (session context) |

## Scope Separation

This skill: "System health" (tracing, latency, health endpoints, slow queries). Error logging: "What broke" (Sentry). Analytics: "What users did" (page views, funnels). Three complementary layers, no overlap.

## Process Summary

1. Read stack.yml -- detect framework, database, static site flag
2. If static site, exit with skip status (no backend to observe)
3. Select OTel SDK and instrumentation based on framework
4. Generate tracing.ts with OTel init and Sentry trace ID correlation
5. Generate performance-budgets.ts with per-endpoint latency/throughput thresholds
6. Generate /health endpoint (liveness) and /ready endpoint (dependency checks)
7. Configure slow query logging if database detected
8. Generate monitoring.yml with uptime check configuration
9. Register assets in asset-registry.yml; run checkpoint

## Findings Persistence

Write confirmed values to `.ai/projects/[name]/devops/findings.md`. **2-Action Rule:** After every 2 research operations, save to findings.md immediately. Log all errors to state.yml errors array -- never repeat a failed approach.

## Execution

Follow the detailed process in [references/process.md](references/process.md).
