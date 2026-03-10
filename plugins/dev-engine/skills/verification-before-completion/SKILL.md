---
name: verification-before-completion
description: >
  Mandatory verification protocol before claiming any task is done. Run tests,
  check output, verify edge cases, and confirm acceptance criteria are met.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "verify"
  - "check work"
  - "before done"
  - "verification checklist"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "proof_command_run"
      verify: "A concrete verification command was executed (test, build, lint)"
      fail_action: "Run the proof command — no claiming done without evidence"
    - name: "output_checked"
      verify: "Command output was read and confirms success"
      fail_action: "Read the full output — do not assume success"
    - name: "edge_cases_considered"
      verify: "At least 2 edge cases or error paths were verified"
      fail_action: "Test edge cases before marking complete"
  on_fail: "Verification incomplete — run the checks"
  on_pass: "Verified — task is genuinely complete"
_source:
  origin: "dev-engine"
  inspired_by: "claude-core verification-gate + superpowers verification"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Simplified from claude-core 5-step gate for general dev use"
---

# Verification Before Completion

Before claiming any task is done, run proof. Stating that something "should work"
or "looks correct" is not verification. Verification means executing something and
reading the output.

## What Counts as Proof

**Tests**: Run the test suite. Read the output. All tests pass, no skipped tests
hiding failures. New behavior has new tests.

**Builds**: Run the build command. Read the output end-to-end. A build that "seemed
to work" and a build that produced a clean exit are different things.

**Manual checks**: For UI or workflow tasks — open the browser, click through the
flow, see the state change happen. Screenshots for anything visual.

**Lint and type checks**: Run them. Do not assume the editor would have caught it.

## Common Shortcuts That Fail

- Writing the code and assuming the tests still pass (they may not — run them).
- Reading a success message partway through output and missing an error lower down.
- Testing only the happy path and skipping the error branch.
- Trusting that a previous run's results still apply after a code change.
- Self-grading: "I'm confident this works" without executing anything.
- Marking done before checking the original acceptance criteria, not just the code.

## Minimum Bar

1. At least one proof command executed (test / build / lint).
2. Full output read — not assumed.
3. At least two edge cases or error paths confirmed.
4. Original acceptance criteria re-read and matched against output.

See `references/process.md` for checklists by task type, commands by stack, and
CI integration guidance.
