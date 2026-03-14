# nodejs-patterns — Debugging Reference

## Common Debugging Scenarios

### Memory leak

**Symptom:** RSS grows monotonically under sustained load. process.memoryUsage().heapUsed trends upward across GC cycles. OOMKilled in containers.

**Root cause:** Retained references — closures capturing large objects, growing Maps/Sets used as caches without eviction, event listeners added in loops without removal, detached DOM-like structures in server-side rendering.

**Diagnosis:**

1. Start the process with the inspector: `node --inspect=0.0.0.0:9229 app.mjs`
2. Open `chrome://inspect` in Chrome, connect to the target.
3. Go to Memory tab. Take a heap snapshot (Snapshot 1 — baseline).
4. Run the suspected workload (e.g., 1000 requests via `autocannon`).
5. Force GC from the console: `global.gc()` (requires `--expose-gc` flag).
6. Take Snapshot 2.
7. Switch to **Comparison** view between Snapshot 1 and Snapshot 2.
8. Sort by **Size Delta** descending. The top entries show what grew.
9. Expand retained tree to trace back to the root holder.

**Fix pattern:** Clear references explicitly. Use `WeakRef` / `WeakMap` for caches. Add `listener.removeListener()` or `AbortController` cleanup. For long-lived Maps, add TTL-based eviction or use `lru-cache`.

---

### Event loop blocking

**Symptom:** p99 latency spikes. Healthcheck timeouts under load. `process._getActiveRequests()` and `process._getActiveHandles()` counts are normal but responses stall.

**Root cause:** Synchronous CPU-bound work on the main thread — JSON.parse on large payloads, crypto operations (pbkdf2Sync), RegExp backtracking, large array sorts, synchronous file I/O.

**Diagnosis:**

1. Quick check with clinic doctor:
   ```
   npx clinic doctor -- node app.mjs
   # Run load test against the app, then Ctrl+C
   # Opens HTML report showing event loop delay, CPU, and handle activity
   ```
2. For granular CPU profiling: `node --prof app.mjs`, run load, then:
   ```
   node --prof-process isolate-*.log > processed.txt
   ```
   Look at the `[JavaScript]` section — functions sorted by ticks show where time is spent.
3. Runtime detection via `perf_hooks`:
   ```js
   import { monitorEventLoopDelay } from 'node:perf_hooks';
   const h = monitorEventLoopDelay({ resolution: 20 });
   h.enable();
   setInterval(() => {
     console.log(`p99 event loop delay: ${h.percentile(99) / 1e6}ms`);
     h.reset();
   }, 5000);
   ```

**Fix pattern:** Move CPU work to `worker_threads`. Replace sync APIs with async variants (`fs.readFile` not `fs.readFileSync`). For JSON parsing of large payloads, use streaming parsers (`stream-json`). For regex, add timeout via `RE2` or rewrite the pattern.

---

### Unhandled promise rejection

**Symptom:** Process exits with no stack trace (Node 15+) or prints `UnhandledPromiseRejectionWarning` and continues silently (Node 14). Data inconsistency from half-completed async flows.

**Root cause:** Missing `.catch()` on a promise chain. `async` function called without `await` and no error handler. `Promise.all` without wrapping individual promises. Error thrown inside a `setTimeout` callback within an async function.

**Diagnosis:**

1. Run with strict mode to crash immediately on unhandled rejection:
   ```
   node --unhandled-rejections=strict app.mjs
   ```
2. Add a global trap to log with full context before crash:
   ```js
   process.on('unhandledRejection', (reason, promise) => {
     console.error('Unhandled rejection at:', promise, 'reason:', reason);
     process.exit(1);
   });
   ```
3. Use `--trace-warnings` to get stack traces for the rejection origin:
   ```
   node --trace-warnings --unhandled-rejections=strict app.mjs
   ```
4. In test environments, add `--unhandled-rejections=throw` to fail tests on missed rejections.

**Fix pattern:** Always `await` async calls or attach `.catch()`. Wrap `Promise.all` items with individual error handling when partial failure is acceptable. Use `Promise.allSettled` when you need all results regardless of individual failures. Lint with `@typescript-eslint/no-floating-promises`.

---

### ESM/CJS interop failures

**Symptom:** `ERR_REQUIRE_ESM` when importing an ESM-only package from CJS. `SyntaxError: Cannot use import statement outside a module`. `ERR_UNKNOWN_FILE_EXTENSION` for `.ts` files. `default` import resolves to `{ default: ... }` wrapper object.

**Root cause:** Mismatch between the module system the consuming code uses and what the dependency exports. Common after dependency upgrades where packages drop CJS support (chalk v5, node-fetch v3, etc.).

**Diagnosis:**

1. Check your project's module system:
   ```
   cat package.json | grep '"type"'
   # "module" = ESM, "commonjs" or absent = CJS
   ```
2. Check the dependency's exports map:
   ```
   node -e "console.log(JSON.stringify(require('./node_modules/<pkg>/package.json').exports, null, 2))"
   ```
   Look for `"require"` (CJS) and `"import"` (ESM) conditional exports.
3. Check what Node actually resolves:
   ```
   node --input-type=module -e "import('<pkg>').then(m => console.log(Object.keys(m)))"
   ```
4. For default import issues, check if the package uses `export default` or `export =`:
   ```
   node -e "import('<pkg>').then(m => console.log('default' in m, typeof m.default))"
   ```

**Fix pattern:** If your project is CJS and the dep is ESM-only: use dynamic `import()` (returns a promise) or switch your project to ESM. If your project is ESM importing CJS: use `import pkg from 'pkg'` (default) or `import { named } from 'pkg'` (Node reads CJS named exports via static analysis). For TypeScript, set `"moduleResolution": "bundler"` or `"node16"` and `"module": "node16"` in tsconfig. Pin ESM-only packages to last CJS version if migration isn't feasible yet.

---

### Stream backpressure

**Symptom:** Memory usage grows unbounded when piping data. Writable stream buffer fills up. `write()` returns `false` but upstream keeps pushing. Consumer slower than producer causes OOM.

**Root cause:** Ignoring the return value of `writable.write()`. Manual pipe logic without respecting `drain` events. Transform streams doing async work without signaling completion. Using `readable.on('data')` instead of proper piping.

**Diagnosis:**

1. Monitor writable buffer fill level:
   ```js
   const interval = setInterval(() => {
     console.log(`writableLength: ${writable.writableLength}`);
     console.log(`writableHighWaterMark: ${writable.writableHighWaterMark}`);
     console.log(`fill%: ${(writable.writableLength / writable.writableHighWaterMark * 100).toFixed(1)}%`);
   }, 1000);
   ```
2. Check if `write()` return value is respected:
   ```js
   const ok = writable.write(chunk);
   if (!ok) {
     console.warn('Backpressure signal received — should pause upstream');
   }
   ```
3. Use `stream.pipeline()` to get automatic backpressure handling and error propagation:
   ```js
   import { pipeline } from 'node:stream/promises';
   await pipeline(readable, transform, writable);
   ```

**Fix pattern:** Replace manual `.pipe()` chains and `on('data')` handlers with `stream.pipeline()`. It handles backpressure, error propagation, and cleanup automatically. For custom streams, always call `callback()` in `_transform()` and `_write()` to signal readiness for next chunk. Set appropriate `highWaterMark` based on expected throughput and memory constraints. For object mode streams, `highWaterMark` counts objects, not bytes — set it lower (default 16).

## Debugging Tools

| Tool | When to use | Command |
|------|------------|---------|
| Node inspector | Memory leaks, CPU profiling, step debugging | `node --inspect app.mjs` |
| Chrome DevTools | Heap snapshots, comparison view, allocation timeline | `chrome://inspect` |
| clinic doctor | Event loop delay, CPU, and active handles overview | `npx clinic doctor -- node app.mjs` |
| clinic flame | CPU flamegraph for hot path identification | `npx clinic flame -- node app.mjs` |
| node --prof | V8 CPU profiler (tick-based, no external deps) | `node --prof app.mjs && node --prof-process isolate-*.log` |
| autocannon | HTTP load generation for reproducing under pressure | `npx autocannon -c 100 -d 30 http://localhost:3000` |
| 0x | Flamegraph generator (alternative to clinic flame) | `npx 0x app.mjs` |
| wtfnode | Find active handles keeping process alive | `require('wtfnode').dump()` |
| why-is-node-running | Identify open handles preventing clean exit | `npx why-is-node-running` |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
