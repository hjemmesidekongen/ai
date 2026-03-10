# nodejs-patterns: Reference

## Event Loop Phases

```
timers         → setTimeout / setInterval callbacks
pending I/O    → deferred I/O callbacks from previous iteration
idle/prepare   → internal use
poll           → retrieve new I/O events; execute I/O callbacks
check          → setImmediate callbacks
close callbacks → socket.on('close', ...) etc.
```

`process.nextTick(fn)` — runs after current operation, before next loop phase. Overuse starves poll phase and delays I/O. Reserve for: ensuring a callback fires async when the API could be sync, or correcting callback ordering within a single tick.

`setImmediate(fn)` — runs at the start of the check phase. Preferred over `process.nextTick` for deferring I/O-adjacent work.

Blocking indicators: `--prof` output showing high V8 execution time in main thread, `diagnostics_channel` latency measurements, event loop lag metrics via `perf_hooks.monitorEventLoopDelay()`.

---

## Streams

### Types

| Type | Use |
|------|-----|
| Readable | Source: file read, HTTP request body, database cursor |
| Writable | Sink: file write, HTTP response, stdout |
| Transform | Bidirectional processing: gzip, encryption, JSON parse per chunk |
| Duplex | Independent read/write: TCP socket |
| PassThrough | Transform that passes data unchanged; useful for metering |

### pipeline()

```js
import { pipeline } from 'node:stream/promises';
import { createReadStream, createWriteStream } from 'node:fs';
import { createGzip } from 'node:zlib';

await pipeline(
  createReadStream('input.txt'),
  createGzip(),
  createWriteStream('input.txt.gz')
);
```

Always prefer `stream/promises` pipeline over callback form. It propagates errors and handles cleanup automatically.

### Backpressure

When a writable cannot consume as fast as a readable produces, `writable.write()` returns `false`. The readable should pause until the writable emits `'drain'`. `pipeline()` handles this automatically. Manual `.pipe()` does not handle cleanup on error — avoid it.

### Custom Transform

```js
import { Transform } from 'node:stream';

class JsonLines extends Transform {
  constructor() { super({ objectMode: true }); }
  _transform(chunk, _enc, cb) {
    try { cb(null, JSON.parse(chunk)); }
    catch (e) { cb(e); }
  }
}
```

---

## Worker Threads

### When to Use

CPU-bound threshold: operations taking >100ms synchronously on the main thread. Examples:
- Image resize / format conversion
- Compression (brotli at high quality levels)
- Cryptographic key derivation (bcrypt, argon2)
- Large JSON parsing or transformation
- ML inference via native bindings

I/O is never a reason to use worker threads — async I/O is already non-blocking.

### Basic Pattern

```js
import { Worker, isMainThread, parentPort, workerData } from 'node:worker_threads';

// main.js
if (isMainThread) {
  const worker = new Worker('./worker.js', { workerData: { input: 'payload' } });
  worker.on('message', (result) => console.log(result));
  worker.on('error', (err) => console.error(err));
  worker.on('exit', (code) => { if (code !== 0) throw new Error(`Worker exited: ${code}`); });
}

// worker.js
parentPort.postMessage(heavyComputation(workerData.input));
```

### Worker Pool

Use `piscina` for production worker pools — it handles queuing, concurrency limits, and graceful drain. Pool size: `os.cpus().length - 1`.

### Data Transfer

- `workerData` — structured clone (copies). Safe, simple. Suitable for most inputs.
- `SharedArrayBuffer` — zero-copy shared memory. Requires `Atomics` for coordination. Use only when transfer cost is measurable.
- `transferList` — transfer ownership of `ArrayBuffer` without copying. Source buffer becomes detached.

---

## Cluster Module

Cluster forks OS processes that share a listening socket. Each worker is a full Node.js process with its own event loop and memory heap. The primary process manages workers but does no application work.

```js
import cluster from 'node:cluster';
import { cpus } from 'node:os';

if (cluster.isPrimary) {
  for (let i = 0; i < cpus().length; i++) cluster.fork();
  cluster.on('exit', (worker, code) => {
    if (code !== 0) cluster.fork(); // auto-restart on crash
  });
} else {
  // start HTTP server in worker
}
```

Cluster vs worker threads: cluster = process-level isolation, separate heaps, HTTP load distribution. Worker threads = shared process memory, CPU offload within a single server instance.

PM2 cluster mode wraps this pattern and adds zero-downtime reload (`pm2 reload`) and process monitoring.

---

## Child Processes

| Method | Use |
|--------|-----|
| `exec` | Run shell command, buffer stdout. Small output only. |
| `execFile` | Run binary directly (no shell). Safer than exec for user input. |
| `spawn` | Stream stdout/stderr. Required for large output or long-running processes. |
| `fork` | Spawn Node.js child with IPC channel. For message-passing worker pattern. |

Always set `maxBuffer` when using `exec`. Default (1MB) causes silent truncation. For anything file-system or subprocess-intensive, use `spawn` with streamed output.

---

## Error Handling

### Async/Await

```js
async function handler(req, res) {
  try {
    const data = await fetchData(req.params.id);
    res.json(data);
  } catch (err) {
    // classify and respond — never swallow
    res.status(500).json({ error: err.message });
  }
}
```

Wrap framework route handlers that use async/await. Express 4 does not catch promise rejections from route handlers automatically. Express 5 does.

### Process-Level Handlers

```js
process.on('uncaughtException', (err) => {
  logger.error('uncaughtException', err);
  process.exit(1); // required — process is in undefined state
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('unhandledRejection', { reason, promise });
  process.exit(1);
});
```

`uncaughtException` leaves the process in an undefined state. Log and exit. Never use it for recovery. Use a process supervisor (PM2, systemd) to restart.

### EventEmitter Errors

```js
emitter.on('error', (err) => {
  logger.error('emitter error', err);
});
```

An `EventEmitter` with no `'error'` listener throws the error as an uncaught exception. Always attach error handlers to streams, HTTP servers, and custom emitters.

### Domain (Deprecated)

`domain` module is deprecated and will be removed. Do not use. Proper async context tracking is done via `AsyncLocalStorage`.

---

## Graceful Shutdown

```js
const server = http.createServer(app);

function shutdown(signal) {
  logger.info(`${signal} received — shutting down`);
  server.close(() => {
    // close DB pools, flush queues, drain workers
    process.exit(0);
  });
  // force exit if drain takes too long
  setTimeout(() => process.exit(1), 10_000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT',  () => shutdown('SIGINT'));
```

SIGTERM is sent by orchestrators (Kubernetes, systemd) for normal termination. SIGINT is Ctrl-C. Both should trigger graceful drain. SIGKILL cannot be caught — do not rely on it for cleanup.

`server.close()` stops accepting new connections but waits for existing requests to finish. Long-lived connections (WebSocket, SSE) require explicit tracking and termination.

---

## Signal Handling Reference

| Signal | Default | Use |
|--------|---------|-----|
| SIGTERM | terminate | Graceful shutdown (orchestrators) |
| SIGINT | terminate | Ctrl-C, graceful shutdown |
| SIGHUP | terminate | Config reload (convention) |
| SIGUSR1 | — | Node.js debugger activation |
| SIGUSR2 | — | Application-defined (e.g., PM2 reload) |
| SIGKILL | terminate | Cannot be caught — force kill |

---

## Memory Management

### Heap Snapshots

```bash
node --inspect app.js
# connect chrome://inspect, take heap snapshot in Memory tab
```

Programmatically:
```js
import v8 from 'node:v8';
const snapshot = v8.writeHeapSnapshot(); // writes to CWD
```

### Heap Size

```bash
node --max-old-space-size=4096 app.js  # 4GB old generation
```

Default is ~1.5GB on 64-bit. Increase only after profiling confirms heap pressure, not preemptively.

### Common Leaks

- Closures capturing large objects in event listeners not removed with `removeListener`
- Growing caches with no eviction (use `Map` with explicit size limits or LRU cache)
- `setInterval` callbacks that accumulate state
- Global registries populated but never cleared

Use `--expose-gc` + `global.gc()` in tests to force collection and measure retained size.

---

## Native ESM vs CommonJS

| | ESM | CJS |
|-|-----|-----|
| Syntax | `import/export` | `require/module.exports` |
| Loading | Async, static analysis | Sync |
| Top-level await | Yes | No |
| `__dirname` / `__filename` | Not available (use `import.meta.url`) | Available |
| Interop | Can import CJS; CJS cannot `require` ESM | — |

Enable ESM: `"type": "module"` in package.json, or use `.mjs` extension.

```js
// ESM equivalent of __dirname
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';
const __dirname = dirname(fileURLToPath(import.meta.url));
```

Default to ESM for new projects. Use CJS when publishing libraries that must support older tooling or deep CJS interop.

---

## Performance Tooling

### --inspect and Chrome DevTools

```bash
node --inspect-brk app.js  # pause at start, connect debugger before running
```

Profile CPU: DevTools → Performance tab → Record. Flame chart shows where time is spent across the call stack.

### diagnostics_channel

```js
import diagnostics_channel from 'node:diagnostics_channel';

const channel = diagnostics_channel.channel('app:db.query');
channel.subscribe(({ query, duration }) => {
  if (duration > 100) logger.warn('slow query', { query, duration });
});
```

Low-overhead instrumentation without monkey-patching. Used by OpenTelemetry auto-instrumentation.

### perf_hooks

```js
import { monitorEventLoopDelay } from 'node:perf_hooks';

const h = monitorEventLoopDelay({ resolution: 20 });
h.start();
setInterval(() => {
  console.log('event loop delay p99:', h.percentile(99), 'ms');
}, 5000);
```

---

## Common Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| `fs.readFileSync` in request handlers | Blocks event loop | Use `fs.promises.readFile` |
| `JSON.parse` on multi-MB payloads | Blocks event loop | Stream + parse incrementally with `stream-json` |
| Unbounded `Promise.all` | Exhausts connections/memory | Batch with `p-limit` or chunk the array |
| `setInterval` with async callback and no error handling | Unhandled rejection on every tick | Wrap callback in try/catch |
| Storing request objects in module-level maps | Memory leak, request cross-contamination | Use `AsyncLocalStorage` for request context |
| Using `domain` for error isolation | Deprecated, unreliable | Use `AsyncLocalStorage` + explicit try/catch |
| Not setting `--max-old-space-size` before heap OOM | Process killed without warning | Set via env var `NODE_OPTIONS=--max-old-space-size=2048` |
| Missing `error` listener on streams | Uncaught exception on stream error | Always attach `.on('error', handler)` or use `pipeline()` |
