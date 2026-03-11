---
name: verification-gate
description: >
  Mandatory 5-step verification protocol before claiming any task is done.
  IDENTIFY the proof command → RUN it → READ the full output → VERIFY it
  matches expected → ONLY THEN claim done. Bans inference-based completion
  ("should work", "probably", "seems to", "likely", "I believe it works").
  Use when completing any task in a plan wave, finishing a skill or hook
  implementation, before marking a wave done, or before reporting success
  on any multi-step change.
user_invocable: false
interactive: false
depends_on: []
triggers:
  - "verify before done"
  - "proof of completion"
  - "run verification"
  - "task not verified"
  - "claim done"
reads:
  - ".ai/plans/{name}/state.yml"
  - ".ai/traces/trace-light.log"
writes: []
checkpoint:
  type: code_validation
  required_checks:
    - name: "proof_command_identified"
      verify: "A specific, runnable proof command was chosen for this task type"
      fail_action: "Select the correct proof type from references/process.md"
    - name: "proof_command_executed"
      verify: "The proof command was actually run (visible in tool calls)"
      fail_action: "Run the command — do not infer the result"
    - name: "output_read"
      verify: "The full output was read, not summarized or assumed"
      fail_action: "Re-read the complete output before proceeding"
    - name: "verdict_stated"
      verify: "An explicit pass or fail verdict was stated based on observed output"
      fail_action: "State the verdict explicitly with the evidence"
  on_fail: "Return to the proof step. Do not mark done until all checks pass."
  on_pass: "Task is verified. Proceed to mark it done in state.yml."
model_tier: senior
_source:
  origin: "kronen"
  inspired_by: "superpowers repo — verification-before-completion gate"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Adapted from methodology doc to kronen skill + Stop hook pattern"
---

# verification-gate

No task is done until there is observed, read, verified evidence. Not inference.

Apply this protocol at the end of every task before marking `status: done`.

## 5-Step Protocol

```
1. IDENTIFY  — What is the proof command for this task type?
2. RUN       — Execute it. No skipping.
3. READ      — Read the full output. Not a summary.
4. VERIFY    — Does the output match the expected outcome?
5. CLAIM     — Only now: mark the task done and state the verdict.
```

## Banned Phrases

Never use these to claim completion:
- "should work", "should be fine"
- "probably", "likely", "I think"
- "seems to", "appears to", "looks like"
- "I believe it works", "this ought to"

Replace with: "I ran X, output was Y, verdict: pass."

## Process

See `references/process.md` for proof command selection by task type and
integration with plan-verifier.
