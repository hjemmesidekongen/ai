---
name: systematic-debugging
description: >
  4-phase debugging protocol: gather evidence, identify patterns, form hypotheses,
  validate fix. Prevents band-aid fixes by requiring root cause understanding.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "debug"
  - "investigate bug"
  - "root cause"
  - "systematic debugging"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "evidence_gathered"
      verify: "Error logs, stack traces, and reproduction steps documented"
      fail_action: "Gather evidence before forming hypotheses"
    - name: "root_cause_identified"
      verify: "Root cause is stated with supporting evidence"
      fail_action: "Keep investigating — no fix without root cause"
    - name: "fix_validated"
      verify: "Fix addresses root cause and regression test exists"
      fail_action: "Add regression test covering the root cause"
  on_fail: "Debugging incomplete — follow the protocol"
  on_pass: "Root cause found and validated with regression test"
_source:
  origin: "dev-engine"
  inspired_by: "claude-core root-cause-debugging"
  ported_date: "2026-03-10"
  iteration: 2
  changes: "Replaced generic protocol with framework-specific debugging tools and symptom-based diagnosis"
---

# Systematic Debugging

## Debugging by Symptom Type

**Render loops (React)**: Component re-renders continuously. Check: unstable references in dependency arrays (`useEffect`, `useMemo`, `useCallback`). Objects/arrays created inline re-trigger every render. Fix: memoize or hoist. Detect: React DevTools Profiler → highlight renders → look for components re-rendering without prop changes.

**Memory leaks**: Heap grows over time, eventual OOM or degraded performance. Common sources: uncleared intervals/timeouts, event listeners not removed on unmount, closures holding references to detached DOM nodes, WebSocket connections not closed. Detect: Chrome DevTools → Memory → Heap snapshots → compare two snapshots → look at "Objects allocated between snapshots."

**Race conditions**: Non-deterministic behavior depending on timing. Symptoms: works in dev, flakes in CI; data arrives in wrong order; stale closures. Fix: abort controllers for fetch, `useRef` for latest value in closures, optimistic UI with reconciliation. Detect: add artificial delays (`await new Promise(r => setTimeout(r, 500))`) to expose timing assumptions.

**Hydration mismatches (Next.js/SSR)**: Server HTML differs from client render. Causes: `Date.now()`, `Math.random()`, `window`/`localStorage` access during render, conditional rendering based on client-only state. Fix: `useEffect` for client-only values, `suppressHydrationWarning` only as last resort. Detect: Next.js dev mode logs the mismatch — read the full diff.

**Stale closures**: Event handler or effect captures an old variable value. Classic in `setInterval` + state updates. Detect: log the value inside the closure vs. the current state. Fix: `useRef` for mutable latest value, or functional state updates (`setState(prev => ...)`).

## Symptom → Tool Mapping

| Symptom | Tool | Command / Action |
|---------|------|-----------------|
| Slow renders | React DevTools Profiler | Record → identify long commits |
| Unnecessary re-renders | `React.memo` + `why-did-you-render` | Logs prop changes causing re-renders |
| Slow DB queries | Prisma query logging | `prisma.$on('query', ...)` or `DEBUG="prisma:query"` |
| Node.js memory leak | `node --inspect` + Chrome DevTools | Heap snapshot comparison |
| API response issues | Network tab / `curl -v` | Check headers, status, body |
| RSC payload issues | Next.js RSC debugger | `?__nextDataReq=1` to see raw payload |
| Expo native crash | `npx expo start --dev-client` | Read Metro + native logs in terminal |
| Unhandled rejections | `node --unhandled-rejections=strict` | Crashes on unhandled instead of warning |

## Escalation Decision Tree

- Cannot reproduce → add structured logging at the boundary, deploy, wait for recurrence
- Reproduced but cause unclear → binary search with `git bisect` or subsystem isolation
- Root cause found but fix is high-risk → flag for review, ship behind feature flag
- Recurring bug class → promote to architectural fix (error boundary, retry layer, schema validation)
