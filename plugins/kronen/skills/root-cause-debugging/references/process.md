# root-cause-debugging — Process

## Phase 1: Investigate

Gather ALL available evidence before forming any opinion about the cause.

**Evidence to collect:**

| Source | What to look for |
|--------|-----------------|
| Error messages | Exact text, error codes, file/line references |
| Stack traces | Where it fails, what was calling what |
| Logs | Events immediately before the failure |
| Recent changes | What changed recently (git log, git diff) |
| Environment | OS, runtime version, config values |
| Reproducibility | Does it happen always? Sometimes? Under specific conditions? |
| Scope | One user, one environment, all users, all environments? |
| Frequency | Always, intermittent, under load, on specific data? |

**Do not skip this phase.** Hypothesizing from incomplete evidence is the
primary cause of band-aid fixes.

### Reproduction evidence (mandatory)

Reproduction evidence is required before any code changes. You must have:
1. **A reproduction** — exact steps that trigger the bug, documented as inputs + environment + sequence
2. **Observed vs. expected** — stated precisely, not "it doesn't work"
3. **When it started** — after a deploy? After a data change? Always broken?

If you cannot reproduce: add structured logging at the boundary, deploy, wait for
recurrence. Do NOT guess and patch.

### Instrumentation step (mandatory when reproduction doesn't reveal cause)

When the reproduction shows the symptom but not the mechanism:
1. Add targeted instrumentation (log statements, debug flags, conditional breakpoints)
2. Focus on the boundary between "working" and "broken" — log inputs/outputs at that seam
3. Re-run with instrumentation and read the output before forming any hypothesis
4. Remove instrumentation after root cause is found

Skip only if the reproduction directly reveals the root cause (e.g., error message
points to the exact line and the fix is obvious).

---

## Phase 2: Pattern Analysis

Look at the evidence as a whole. Find the simplest explanation.

**Binary search approach:**
- `git bisect` to find the introducing commit (see [git-advanced-workflows](git-advanced-workflows skill) for scripted bisect automation)
- Comment out half a function to see if the failure disappears
- Test with minimal input — reduce to the smallest case that still fails
- Swap dependencies (mock the DB, stub the API) to isolate the layer

Questions to ask:
- What do all the failing cases have in common?
- What is different between failing and passing cases?
- Is this a regression? What changed before it started?
- Is the error message pointing at the symptom or the cause?
- Is there a simpler explanation than the most obvious one?

**What to look for:**
- Changes that correlate with the failure window (deploys, migrations, config changes)
- Whether the failure is input-dependent (specific ID, user, payload)
- Whether it's environment-specific (only prod, only after cold start, only under concurrency)
- Timing patterns (race condition, TTL expiry, cache invalidation)

Common traps:
- **Confusing symptom with cause** — "NullPointerException" is a symptom; why is the value null?
- **Assuming the obvious** — the error points to line 47, but the bug is in line 12
- **Recency bias** — assuming the last change caused it without checking earlier changes

---

## Phase 3: Hypothesis

State a specific, testable hypothesis. Format:

```
Cause:      [specific component/condition]
Mechanism:  [how the cause produces the symptom]
Evidence:   [file:line or log entry that supports this — REQUIRED]
Prediction: [if my hypothesis is correct, then X will happen when I do Y]
Test:       [the command/action that will confirm or refute this]
```

**The `Evidence` field must cite specific file:line references or log entries.**
A hypothesis without grounding in concrete evidence is speculation, not analysis.

Example:
```
Cause:      Cache key includes timestamp with second-level precision
Mechanism:  Requests within the same second share a cache entry unexpectedly
Evidence:   src/cache/key-builder.ts:23 — uses Date.now() / 1000 | 0
Prediction: Two requests within 1 second return identical results despite different inputs
Test:       Fire two requests with different inputs within 500ms, compare responses
```

If you cannot state a specific prediction with file:line evidence, your hypothesis
is not testable. Form a better hypothesis or return to Phase 1 for more evidence.

**Generate 2–3 competing hypotheses.** Test the cheapest to disprove first.
Single-hypothesis investigation creates confirmation bias.

---

## Phase 4: Implement

Fix the root cause identified in Phase 3.

Rules:
- Fix the cause, not the symptom
- The fix should make the bug structurally impossible, not harder to trigger
- Apply the verification-gate protocol after implementing (run proof, read output)
- If the fix doesn't work: **do not modify and retry** — return to Phase 2 with the new evidence

---

## Root-Cause Tracing Technique

For complex bugs, follow the chain from symptom to root cause:

```
Symptom: [what the user sees]
  ↓ "What caused this?"
Proximate cause: [immediate technical cause]
  ↓ "What caused this?"
Intermediate cause: [deeper cause]
  ↓ "What caused this?"
Root cause: [the actual problem to fix]
```

Keep asking "what caused this?" until you reach a cause that has no deeper
technical cause within your control. That is the root cause.

---

## Defense-in-Depth

After fixing the root cause, consider adding layers to make the bug
structurally impossible to recur:

1. **Input validation** — reject invalid inputs before they propagate
2. **Invariant assertions** — assert invariants at module boundaries
3. **Type safety** — use types to make invalid states unrepresentable
4. **Test coverage** — add a regression test that would have caught this bug

Not all 4 layers apply to every bug. Use judgment.

---

## Condition-Based Waiting

Replace `sleep N` and fixed timeouts with condition polling:

```bash
# Bad: fixed sleep
sleep 5
check_result

# Good: condition-based
MAX_WAIT=30
INTERVAL=0.5
elapsed=0
while ! check_condition; do
  sleep $INTERVAL
  elapsed=$(echo "$elapsed + $INTERVAL" | bc)
  [ "$(echo "$elapsed >= $MAX_WAIT" | bc)" = "1" ] && { echo "Timeout"; exit 1; }
done
```

---

## Escalation Tree

- **Cannot reproduce** → add structured logging at the boundary, deploy, wait for recurrence
- **Reproduced but cause unclear** → binary search with `git bisect` or subsystem isolation
- **Root cause found but fix is high-risk** → flag for review, ship behind feature flag
- **Recurring bug class** → promote to architectural fix (error boundary, retry layer, schema validation)

---

## Escalation: 3-Failures Rule

If three separate fix attempts all fail to resolve the problem:

1. **Stop fixing** — more fixes without understanding will make things worse
2. **Document the pattern** — what have all three failures had in common?
3. **Question the architecture** — is the problem at a higher level than the fix?
4. **Surface to user** — present the pattern, the failed attempts, and a proposed
   architectural change for review

Do not attempt a 4th fix without the user's input.

---

## Symptom → Tool Mapping

| Symptom | Tool | Command / Action |
|---------|------|-----------------|
| Finding the introducing commit | `git bisect` | `git bisect run <test>` — see git-advanced-workflows |
| Slow renders | React DevTools Profiler | Record → identify long commits |
| Unnecessary re-renders | `why-did-you-render` | Logs prop changes causing re-renders |
| Slow DB queries | Prisma query logging | `prisma.$on('query', ...)` or `DEBUG="prisma:query"` |
| Memory leak (Node.js) | `node --inspect` + Chrome DevTools | Heap snapshot comparison |
| API response issues | Network tab / `curl -v` | Check headers, status, body |
| RSC payload issues | Next.js RSC debugger | `?__nextDataReq=1` for raw payload |
| Expo native crash | `npx expo start --dev-client` | Metro + native logs |
| Unhandled rejections | `node --unhandled-rejections=strict` | Crashes on unhandled |
| Log analysis | `jq` for JSON logs | `grep -E` for patterns |
| Race conditions | Add delays / chaos | Thread sanitizer, lock ordering |
| System-level calls | `strace` / `dtrace` | Trace syscalls at boundary |

**Debugger vs. Logs vs. Traces:**
- **Debugger**: synchronous, reproducible, local-only bugs. Step through state.
- **Logs**: production and async bugs. Structured log points at boundaries.
- **Distributed traces**: multi-service failures. Find the failing span.

**Framework-specific debugging:** When debugging a framework-specific issue, load the
relevant smedjen tech skill's `references/debugging.md` for detailed scenarios and
framework-specific instrumentation guidance.

---

## Anti-Patterns

**Shotgun debugging**
Changing multiple things at once. You can't learn causality from this. If the bug
disappears, you don't know why. Revert and test one change at a time.

**Fix-and-pray**
Shipping a change that "looks right" with no test and no evidence it addresses the
root cause. The bug resurfaces in a different form or regresses in 3 months.

**Symptom fixation**
- Catching and swallowing the exception instead of finding why it throws
- Increasing a timeout instead of finding why the operation is slow
- Resetting state on error instead of finding how state became invalid

**Premature escalation**
Asking for help before exhausting Phase 1. Always bring evidence when escalating —
never just "it's broken."

**Tunnel vision**
Fixating on one hypothesis without testing alternatives. If your fix didn't work,
the hypothesis was wrong — go back to Phase 2, not Phase 3.

---

## Hypothesis-Driven Extension: 3-Hypothesis Parallel Investigation

For complex bugs where the root cause is genuinely unclear after Phase 1,
generate **three competing hypotheses** before investigating any single one.
Then investigate each in parallel (or sequentially if resources are limited).
Synthesize evidence from all three before committing to a fix.

### Why three hypotheses

A single hypothesis creates confirmation bias — evidence gets interpreted to
support it. Three competing hypotheses force you to look for disconfirming
evidence and consider multiple mechanisms simultaneously.

### Hypothesis generation protocol

After completing Phase 1 (evidence gathering), generate exactly three hypotheses:

```
Hypothesis A: [most obvious explanation]
  Cause:      [component/condition]
  Mechanism:  [how it produces the symptom]
  Evidence:   [file:line supporting this]
  Prediction: [what you'd observe if A is true]
  Test:       [how to confirm or refute A]

Hypothesis B: [second-most likely — different mechanism]
  Cause:      [different component/condition from A]
  Mechanism:  [different pathway to the same symptom]
  Evidence:   [file:line supporting this]
  Prediction: [what you'd observe if B is true, different from A's prediction]
  Test:       [how to confirm or refute B]

Hypothesis C: [less obvious but possible — often deeper/systemic]
  Cause:      [systemic or upstream cause]
  Mechanism:  [how a deeper issue produces the visible symptom]
  Evidence:   [file:line supporting this]
  Prediction: [what you'd observe if C is true]
  Test:       [how to confirm or refute C]
```

**Rules for good hypotheses:**
- Each hypothesis must have a different root cause — not just different symptoms
- Tests must be distinct — running one test can't confirm/refute another's hypothesis
- At least one hypothesis should be "the obvious culprit" and one should be surprising
- Each must cite file:line evidence grounding

### Parallel investigation

If parallelizable, dispatch all three investigations simultaneously:
- Assign each hypothesis to an independent investigation thread/subagent
- Each thread collects only the evidence relevant to its hypothesis
- Do not mix evidence between threads during investigation

### Evidence synthesis

After all three investigations complete:

1. Score each hypothesis: CONFIRMED / POSSIBLE / REFUTED
2. Look for evidence overlap: does evidence for A also support/refute B or C?
3. If exactly one is CONFIRMED: proceed to Phase 4 with that hypothesis
4. If two are CONFIRMED: look for a unifying root cause that explains both
5. If all three are REFUTED: return to Phase 1 — the root cause is not yet visible
6. If all three are POSSIBLE: run the most discriminating test to break the tie

### Integration with the 4-phase protocol

This extension sits between Phase 1 and Phase 3:

```
Phase 1: INVESTIGATE  → gather evidence
[Extension]: GENERATE THREE HYPOTHESES → before any single investigation
Phase 2: PATTERN      → evidence informs hypothesis scoring
Phase 3: HYPOTHESIS   → select the confirmed hypothesis from the three
Phase 4: IMPLEMENT    → fix the confirmed root cause
```

Use the extension when Phase 1 evidence doesn't clearly point to a single cause.
