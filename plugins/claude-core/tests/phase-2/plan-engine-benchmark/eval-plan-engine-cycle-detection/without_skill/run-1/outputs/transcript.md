# Execution Transcript

## Prompt

Decompose this task list:

- t1: Build A (depends_on: [t3])
- t2: Build B (depends_on: [t1])
- t3: Build C (depends_on: [t2])

What happens?...

## Response

**Circular dependency — no valid execution order exists.**

The chain: `t1 → t3 → t2 → t1` forms a cycle. Every task is blocked by another task in the loop, so nothing can start.

A wave decomposer should detect this and reject the input. The fix is to break the cycle by removing at least one dependency edge — whichever relationship is weakest or can be decoupled (e.g., use an interface/contract instead of a hard dependency).

## Stderr

None
