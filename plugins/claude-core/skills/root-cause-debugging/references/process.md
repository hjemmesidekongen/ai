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

**Do not skip this phase.** Hypothesizing from incomplete evidence is the
primary cause of band-aid fixes.

---

## Phase 2: Pattern Analysis

Look at the evidence as a whole. Find the simplest explanation.

Questions to ask:
- What do all the failing cases have in common?
- What is different between failing and passing cases?
- Is this a regression? What changed before it started?
- Is the error message pointing at the symptom or the cause?
- Is there a simpler explanation than the most obvious one?

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
Prediction: [if my hypothesis is correct, then X will happen when I do Y]
Test:       [the command/action that will confirm or refute this]
```

Example:
```
Cause:      The cache key includes a timestamp with second-level precision
Mechanism:  Requests within the same second share a cache entry unexpectedly
Prediction: Two requests fired within 1 second will return identical results even with different inputs
Test:       Run two requests with different inputs within 500ms, compare responses
```

If you cannot state a specific prediction, your hypothesis is not testable.
Form a better hypothesis or gather more evidence.

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

Or in higher-level languages:
```python
import time
deadline = time.time() + 30
while not condition_met():
    if time.time() > deadline:
        raise TimeoutError("condition not met within 30s")
    time.sleep(0.5)
```

---

## Escalation: 3-Failures Rule

If three separate fix attempts all fail to resolve the problem:

1. **Stop fixing** — more fixes without understanding will make things worse
2. **Document the pattern** — what have all three failures had in common?
3. **Question the architecture** — is the problem at a higher level than the fix?
4. **Surface to user** — present the pattern, the failed attempts, and a proposed
   architectural change for review

Do not attempt a 4th fix without the user's input.
