---
name: nodejs-patterns
description: >
  Node.js streams, worker threads, event loop, error handling, and clustering
  patterns. Covers when to use streams vs buffers, CPU-bound offloading decisions,
  async error propagation, and graceful shutdown.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "nodejs patterns"
  - "node.js streams"
  - "worker threads"
  - "event loop"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "no_blocking_event_loop"
      verify: "CPU-intensive operations run in worker threads or child processes, not on the main thread"
      fail_action: "Offload to workerData/worker_threads or a child process"
    - name: "streams_over_buffers_for_large_data"
      verify: "File reads, HTTP responses, and transformations over ~1MB use streams, not full buffering"
      fail_action: "Replace Buffer accumulation with pipeline() and Transform streams"
    - name: "unhandledrejection_covered"
      verify: "process.on('unhandledRejection') handler exists and does not silently swallow errors"
      fail_action: "Add handler that logs and exits with non-zero code in production"
    - name: "graceful_shutdown_wired"
      verify: "SIGTERM and SIGINT handlers close servers and drain connections before exit"
      fail_action: "Add signal handlers that call server.close() and flush pending work"
  on_fail: "Node.js structure has reliability or performance gaps — address before merging"
  on_pass: "Node.js patterns are sound"
_source:
  origin: "smedjen"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 2
  changes: "Replaced known fundamentals with Node 22+ features, AbortController patterns, and diagnostic channels"
---

# nodejs-patterns

Beyond standard event loop and streams — Node 22+ features, structured cancellation, diagnostic channels, and ESM migration.

## Node 22+ Features

**Built-in test runner** (`node:test`): `describe`, `it`, `mock` — no framework. `node --test **/*.test.js` + `--experimental-test-coverage`.
**`--env-file`**: `node --env-file=.env server.js` — no dotenv. Multiple files supported (last wins).
**Watch mode**: `node --watch server.js` replaces nodemon. Scope: `--watch-path=./src`.
**Native fetch**: Stable in 21+, undici-backed. Supports AbortSignal natively.
**`require(esm)`** (22.12+): `require()` of ES modules without flags. CJS consumers, ESM libraries.

## AbortController Patterns

Propagate signals through async chains — `fetch`, `setTimeout` (node:timers/promises), and `pipeline` all accept `{ signal }`. `AbortSignal.timeout(5000)` auto-aborts. `AbortSignal.any([userSignal, timeoutSignal])` for composite cancellation.

## Diagnostic Channels

`node:diagnostics_channel` — zero-overhead instrumentation, no APM coupling. `dc.channel('app:db-query').publish({ query, duration })`. Subscribers attach externally — app code never imports the observer. Undici publishes on `undici:request:create` for HTTP telemetry without middleware.

## Custom Transform Streams

`pipeline()` + Transform with automatic backpressure:
```js
const jsonLines = new Transform({
  objectMode: true,
  transform(chunk, enc, cb) { cb(null, JSON.stringify(chunk) + '\n'); }
});
await pipelinePromise(dataSource, jsonLines, response);
```

## ESM Migration Decision

Stay CJS: consumers use `require()`, tooling assumes CJS, migration cost > benefit.
Go ESM: shipping a library, top-level await, Node 20+.
**Dual publish**: `"type": "module"` + `"exports"` with `"import"`/`"require"` conditions. Build CJS from ESM.

See `references/process.md` for worker thread pools, cluster, child processes, memory management, and anti-patterns.
