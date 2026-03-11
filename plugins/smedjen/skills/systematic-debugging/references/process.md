# systematic-debugging: Process Reference

## Phase 1 — Gather Evidence

The goal is a complete picture of the failure before any hypothesis is formed.

**What to collect:**
- Full error message and stack trace (not truncated)
- Exact reproduction steps — inputs, environment, sequence of actions
- Observed behavior vs. expected behavior (stated precisely)
- When it started failing: after a deploy? After a data change? Always?
- Scope: one user, one environment, all users, all environments?
- Frequency: always, intermittent, under load, on specific data?

**Tools:**
- Application logs (`grep`, `jq`, `awk` for filtering)
- Browser devtools (network, console, performance)
- `git log --oneline --since` to identify recent changes in the area
- Error tracking (Sentry, Datadog, etc.) — look at breadcrumbs, not just the exception

**Output of phase 1:**
A written summary: "When X happens under Y conditions, Z occurs instead of W. First seen after commit ABC."

---

## Phase 2 — Identify Patterns

Narrow scope using systematic elimination — not guessing.

**Binary search approach:**
- `git bisect` to find the introducing commit
- Comment out half a function to see if the failure disappears
- Test with minimal input — reduce to the smallest case that still fails
- Swap dependencies (mock the DB, stub the API) to isolate the layer

**What to look for:**
- Changes that correlate with the failure window (deploys, migrations, config changes)
- Whether the failure is input-dependent (specific ID, specific user, specific payload)
- Whether it's environment-specific (only prod, only after cold start, only under concurrency)
- Timing patterns (race condition, TTL expiry, cache invalidation)

**Tools:**
- `git bisect run <test>` for automated bisection
- Feature flags to narrow which code path is active
- `strace` / `dtrace` for system-level calls
- Network inspector to check request/response shape at the boundary

---

## Phase 3 — Form and Test Hypotheses

Write the hypothesis as a falsifiable statement before testing it.

**Template:**
> "The failure is caused by [mechanism] because [evidence]. If correct, [test] should [confirm/deny]."

**Generate 2–3 competing hypotheses.** Test the cheapest to disprove first.

**Example session:**
```
Bug: User session expires immediately after login on Safari.

H1: Cookie SameSite policy blocking cross-origin cookie on Safari redirect.
H2: Session TTL set to 0 in staging config bled into prod deploy.
H3: Clock skew between auth service and session store invalidating token immediately.

Test H2 first: check config diff between staging and prod. → Config is identical. H2 eliminated.
Test H1: set SameSite=None and test in Safari. → Session persists. H1 confirmed.
```

**Signs you're not done with phase 2:**
- Your hypothesis has no supporting evidence from phase 1
- You have only one hypothesis and haven't tried to break it
- The fix "should work" but you can't explain *why* the bug existed

---

## Phase 4 — Validate the Fix

**Write the regression test before applying the fix.**
The test should fail on the unfixed code and pass after. If you can't write the test, you don't understand the root cause well enough yet.

**Validation checklist:**
- [ ] Regression test reproduces the original failure
- [ ] Fix applied — test passes
- [ ] Fix removed — test fails (confirms the test is meaningful)
- [ ] No adjacent behavior broken (run the full test suite)
- [ ] Fix addresses root cause, not just the observable symptom

**Regression test placement:**
- Unit test if the root cause is in a single function
- Integration test if the cause spans a service boundary
- E2E test only if the failure is UI/UX-level and can't be tested lower

---

## Tooling Guide

| Scenario | Tool / Approach |
|---|---|
| Finding the introducing commit | `git bisect` |
| Isolating a network layer | curl/httpie, mocking fetch/axios |
| Diagnosing memory issues | heap snapshot, `node --inspect`, Chrome Memory tab |
| Race conditions | add delays, use thread sanitizer, check lock ordering |
| Intermittent failures | loop-run tests, chaos injection, production replay |
| Log analysis | `jq` for JSON logs, `grep -E` for patterns, structured log query |
| DB query issues | `EXPLAIN ANALYZE`, slow query log, connection pool metrics |
| Frontend rendering bugs | React DevTools, `why-did-you-render`, performance profiler |

**Debugger vs. Logs vs. Traces:**
- **Debugger**: best for synchronous, reproducible, local-only bugs. Step through state.
- **Logs**: best for production and async bugs. Add structured log points at boundaries.
- **Distributed traces**: best for multi-service failures. Identify the failing span and latency hotspot.

---

## Anti-Patterns

**Shotgun debugging**
Changing multiple things at once. You can't learn causality from this. If the bug disappears, you don't know why. Revert and test one change at a time.

**Fix-and-pray**
Shipping a change that "looks right" with no test and no evidence it addresses the root cause. The bug resurfaces in a different form or regresses in 3 months.

**Symptom fixation**
- Catching and swallowing the exception instead of finding why it throws
- Increasing a timeout instead of finding why the operation is slow
- Resetting state on error instead of finding how state became invalid

**Premature escalation**
Asking for help before exhausting phase 1. Comes across as not reading the logs. Always bring evidence when escalating — never just "it's broken."

**Tunnel vision**
Fixating on one hypothesis without testing alternatives. If your fix didn't work, the hypothesis was wrong — go back to phase 2, not phase 3.

---

## Example Debugging Session

**Bug report:** "Checkout fails for some users after the payment form is submitted."

**Phase 1 — Evidence:**
- Sentry shows `TypeError: Cannot read properties of undefined (reading 'id')` in `createOrder.js:47`
- Stack trace points to `user.address.id`
- Affects ~8% of users — not all
- Started after Monday's deploy (cart refactor)
- Reproduction: user with no saved address on file

**Phase 2 — Pattern:**
- `git log --oneline -10 -- src/cart/` shows Monday commit touched address normalization
- Binary test: hardcode an address object in the call — error disappears
- Confirmed: users with no saved address have `address: undefined`, not `address: {}`

**Phase 3 — Hypothesis:**
H1: Monday's refactor changed the address fallback from `{}` to `undefined` when no address is saved.
Test: check git diff on address normalization function. Confirmed — `|| {}` was removed.

**Phase 4 — Fix:**
Regression test: create user with no address, submit checkout, assert no TypeError.
Fix: restore `|| {}` fallback. Test passes. Suite green. Deployed.
