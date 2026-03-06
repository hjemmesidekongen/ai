---
name: error-logging
user-invocable: false
description: >
  Scaffolds framework-appropriate Sentry error logging. Sets up error boundaries,
  API interceptors, unhandled rejection handlers, error page integration (404/500),
  and source map upload. Reads stack.yml to select the correct SDK and pattern.
phase: 3
depends_on: [stack-negotiation]
reads:
  - ".ai/projects/[name]/dev/stack.yml"
  - ".ai/projects/[name]/dev/dev-config.yml"
writes:
  - "src/lib/sentry.ts"
  - "src/components/ErrorBoundary.tsx"
  - "src/lib/api-interceptor.ts"
  - "src/pages/error/500.tsx"
  - "src/pages/error/404.tsx"
model_tier: senior
model: sonnet
interactive: true
checkpoint:
  type: data_validation
  required_checks:
    - name: "sentry_init_exists"
      verify: "Sentry initialization file exists with DSN env var reference"
      fail_action: "Generate sentry init file matching confirmed framework"
    - name: "error_boundaries_exist"
      verify: "Error boundary components wrap key UI sections, not just app root"
      fail_action: "Generate ErrorBoundary component with section-level wrapping"
    - name: "api_interceptor_exists"
      verify: "API error interceptor captures URL, method, status, timing"
      fail_action: "Generate API interceptor with request context"
    - name: "unhandled_rejection_handler"
      verify: "Global handler for unhandled promise rejections is configured"
      fail_action: "Add unhandled rejection handler to Sentry init"
    - name: "error_pages_integrated"
      verify: "404/500 pages POST context to Sentry (failed URL, referrer, session ID, timestamp)"
      fail_action: "Update error pages to send context to Sentry"
    - name: "source_maps_configured"
      verify: "Build config includes Sentry source map upload plugin"
      fail_action: "Add source map upload config for confirmed build tool"
  on_fail: "Fix issues and re-run checkpoint. Do not advance until all checks pass."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Error Logging

Scaffolds Sentry-based error logging for the confirmed stack. Reads stack.yml
to select the correct SDK (`@sentry/nextjs`, `@sentry/react`, `@sentry/node`).
Distinct from analytics (user behavior) and observability (system health) —
Sentry answers "what broke and why."

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | stack.yml (confirmed framework), dev-config.yml (build commands, structure) |
| **Writes** | Sentry init, ErrorBoundary, API interceptor, error pages, source map config |
| **Checkpoint** | 6 checks: init, boundaries, interceptor, rejections, error pages, source maps |
| **Dependencies** | stack-negotiation (must confirm framework before selecting SDK) |
| **Ties to** | dec-02 (error pages send context to Sentry: failed URL, referrer, session ID) |

## Process Summary

1. Read stack.yml — determine framework, runtime, build tool
2. Select Sentry SDK and integration pattern for confirmed framework
3. Generate Sentry initialization with DSN from env var
4. Scaffold error boundaries wrapping key UI sections (not just app root)
5. Create API interceptor capturing request context (URL, method, status, timing)
6. Configure unhandled promise rejection handler
7. Integrate error pages (404/500) — POST context to Sentry (dec-02)
8. Configure source map upload for confirmed build tool
9. Present scaffolded files for user review; run checkpoint (all 6 checks)

## Rules

- **Findings:** Write to `.ai/projects/[name]/dev/findings.md`. **2-Action Rule:** save every 2 actions.
- **Errors:** Log to state.yml errors array — never repeat a failed approach.
- **Execution:** Follow [references/process.md](references/process.md).
