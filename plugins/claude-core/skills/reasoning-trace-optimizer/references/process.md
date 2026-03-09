# reasoning-trace-optimizer — Process

## Input

Read `.ai/traces/trace-light.log`. Each line has the format:
```
timestamp|tool_name|status|context
```
or extended with error fields:
```
timestamp|tool_name|status|context|severity|error_summary
```

Parse lines into a sequence of tool calls with their outcomes.

---

## Pattern Detection

### 1. Context Degradation

**What it looks like:**
- Same file read 3+ times in a session without meaningful changes to it
- Increasing frequency of error lines in the second half of a session vs the first
- Tool calls become shorter and less targeted over time

**Detection:**
```
Count per-file reads: file read >= 3 = candidate
Compare error rate: errors in last 30% of session > 2x rate in first 30%
```

**Fix:** Compact the session before continuing. Write intermediate findings
to disk. Use structured artifacts instead of re-reading to reconstruct state.

---

### 2. Tool Confusion

**What it looks like:**
- Bash used for file reads that Read tool could handle
- Edit called on a file that doesn't exist yet (should be Write)
- Grep used to "understand" code rather than find a specific pattern
- Same tool called with same or similar arguments repeatedly

**Detection:**
```
Bash lines with patterns: cat, head, tail, sed, awk → should be Read/Edit
Edit on non-existent file (precedes Write on same path)
Grep same pattern on same path 2+ times
```

**Fix:** Identify the canonical tool for the task and use it consistently.
If retrying, change the approach — not just the arguments.

---

### 3. Instruction Drift

**What it looks like:**
- Tool calls writing to files not mentioned in the original task
- Growing scope (files from unrelated directories being modified)
- The last 10 tool calls don't relate to the task stated in first tool call

**Detection:**
```
Extract task description from first Write/Edit context field
Compare file paths in last 25% of session to declared task scope
Files outside task scope with no clear connection = drift
```

**Fix:** Re-read the original task. Use scope-guard hook output as a signal.
If drift is intentional, update the task scope explicitly.

---

### 4. Goal Abandonment

**What it looks like:**
- Session ends with no completion marker
- Last tool call is a Read or Bash (not a Write/Edit)
- State file not updated to `done` or `complete`
- Verification-gate never ran

**Detection:**
```
Last tool call is not Write/Edit/Bash-with-commit
No verification-gate entry in last 20 lines
State file not updated in last 20% of session
```

**Fix:** Resume with an explicit completion target. Run verification-gate
before the next stop. Check for blockers that caused silent abandonment.

---

### 5. Circular Reasoning

**What it looks like:**
- Identical sequence of tool calls appears 2+ times
- Investigation phase repeated without new evidence
- Same error encountered, same fix attempted

**Detection:**
```
Sliding window: check if any 5-tool sequence repeats
Look for identical (tool, file_path) pairs within 15 calls of each other
```

**Fix:** Break the loop by adding new information. If stuck, surface the
blocker explicitly instead of retrying. Check if a different tool or approach
would gather new evidence.

---

### 6. Premature Conclusion

**What it looks like:**
- "Done" or "complete" stated before verification ran
- State file marked `done` without a preceding proof command
- verification-gate lines absent from a supposedly completed task

**Detection:**
```
Look for state.yml write with status: done
Check if verification-gate ran in the 10 lines before that write
If not: premature conclusion
```

**Fix:** Always run verification-gate before marking anything done.
If the proof command can't run, state why explicitly — don't skip.

---

## Output Format

Write to `.ai/traces/reasoning-diagnosis.md`:

```markdown
# Reasoning Trace Diagnosis

**Session**: [date range from log]
**Lines analyzed**: [count]
**Patterns found**: [count]

## Findings

### [Pattern Name] — [Severity]

**Evidence**: [specific lines or counts from log]
**Impact**: [what this likely caused]
**Fix**: [concrete next action]

---

## Summary

[One paragraph: overall session quality, primary issue, recommended action]

## Pattern Counts

| Pattern | Found | Severity |
|---------|-------|---------|
| Context degradation | yes/no | high/— |
| Tool confusion | yes/no | medium/— |
| Instruction drift | yes/no | high/— |
| Goal abandonment | yes/no | critical/— |
| Circular reasoning | yes/no | medium/— |
| Premature conclusion | yes/no | high/— |
```

## When to escalate

If 3+ patterns are found at high or critical severity, recommend a full
session restart with a fresh compact rather than attempting to patch the
current session.
