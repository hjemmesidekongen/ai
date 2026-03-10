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
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Original skill, no port"
---

# nodejs-patterns

Node.js is single-threaded I/O. Every pattern decision traces back to that constraint: protect the event loop, stream data instead of buffering it, and push CPU work off-thread.

## Event Loop Model

The event loop processes one phase at a time: timers → pending I/O → idle/prepare → poll → check → close callbacks. `setImmediate` runs in the check phase (after I/O). `process.nextTick` runs after the current operation, before any I/O — overuse starves the loop.

Blocking the event loop (synchronous crypto, large JSON.parse, tight loops) stalls every request. The threshold is roughly 100ms. Anything over that belongs in a worker thread.

## Streams vs Buffers

Use streams when data volume is unknown or large. Use buffers when data must be complete before processing (JWT validation, JSON parsing of small payloads).

Decision: if the source is a file, network socket, or database cursor — stream it. If it fits in memory and processing requires the whole payload — buffer it. Default to streams for file I/O and HTTP response bodies over ~1MB.

Always use `pipeline()` over manual `.pipe()` — it handles backpressure and propagates errors automatically.

## Worker Threads

Use worker threads for CPU-bound work: image processing, compression, encryption at scale, parsing large payloads, ML inference. Not for I/O — async I/O is already non-blocking.

Pass data via `workerData` (cloned) or `SharedArrayBuffer` (zero-copy, requires coordination). Keep worker pools sized to `os.cpus().length - 1` to leave headroom for the main thread.

## Async Error Handling

Errors in async code that are not caught propagate as unhandled rejections. In production, `process.on('unhandledRejection')` should log and exit — silent swallowing hides bugs.

For Express/Fastify, async route handlers must either catch internally or be wrapped so the framework's error middleware receives the rejection. Uncaught errors in event emitters go to `'error'` event — attach a handler or the process crashes.

See `references/process.md` for event loop phases, stream implementations, worker thread patterns, cluster module, child processes, signal handling, graceful shutdown, memory management, ESM vs CJS, and anti-patterns.
