---
name: reducing-entropy
description: >
  Minimize total codebase size by biasing toward deletion. Measures success
  by final code amount, not effort expended. Use when reducing lines of code,
  cleaning up plugins, removing dead code, shrinking the codebase, or evaluating
  whether a change reduces or increases total code. Manual activation only.
user_invocable: true
interactive: true
depends_on: []
triggers:
  - "reduce code"
  - "cleanup"
  - "delete unused"
  - "minimize codebase"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "net_reduction"
      verify: "Total lines of code after change is less than before"
      fail_action: "Re-evaluate whether the change is justified"
    - name: "no_regression"
      verify: "No functionality was lost that was actually needed"
      fail_action: "Restore needed functionality with minimal code"
  on_fail: "Reconsider the approach — entropy increased"
  on_pass: "Codebase is smaller. Mission accomplished."
model_tier: junior
_source:
  origin: "agent-toolkit-main/skills/reducing-entropy"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Added claude-core frontmatter. Removed references/ loading step (no references dir in port). Kept core content intact."
---

# Reducing Entropy

## Core Principle

More code begets more code. Entropy accumulates. Every line added creates
maintenance burden, cognitive load, and surface area for bugs. The natural
drift of any codebase is toward bloat.

## The Goal

Less total code in the final codebase. Not less effort — less output.
Success is measured by the end state, not by how much work was done.
A PR that deletes 200 lines and adds 0 is better than one that replaces
200 lines with 150 "cleaner" lines.

## Three Questions

Before every change, ask:

1. **What is the smallest possible codebase that does what we need?**
   Not the smallest diff. The smallest final result.

2. **Does this change result in less total code?**
   If not, justify why the increase is unavoidable.

3. **What can we delete?**
   Not refactor. Not rewrite. Delete. Remove entirely.

## Red Flags

- "We might need this later" — you probably won't. Delete it.
- "This abstraction makes it cleaner" — abstractions add lines. Justify them.
- "Let me add a wrapper" — wrappers are code. More code is more entropy.
- "I'll refactor this to be more maintainable" — if the line count goes up, reconsider.
- Adding a new file when an existing one could absorb the logic.
- Creating infrastructure "for consistency" when the use case is singular.

## When This Doesn't Apply

- First implementation of genuinely new functionality (you're adding, not maintaining).
- Security fixes that require additional validation code.
- Test coverage for untested critical paths (tests are an acceptable entropy cost).
- Legal/compliance requirements that mandate specific code.

Even in these cases, write the minimum viable version first.

---

Bias toward deletion. Measure the end state.
