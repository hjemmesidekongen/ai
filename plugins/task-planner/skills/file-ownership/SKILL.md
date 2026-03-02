---
name: file-ownership
user-invocable: false
description: >
  Assigns and enforces file-level and section-level ownership across tasks
  within a wave plan. Use when checking file conflicts, assigning ownership
  in wave plans, running /plan:create step 2, or validating plan pre-flight.
---

# File Ownership

Assigns and enforces file-level and section-level ownership across tasks
within a wave plan. Prevents parallel agents from writing to the same files.
Produces a `file-ownership-registry.yml` for runtime write validation.

## Context

- Reads: wave plan conforming to `resources/plan-schema.yml` (`files_written`, `files_read` per task)
- Writes: `file-ownership-registry.yml`
- Checkpoint: none (utility skill — called by wave-decomposer and plan-execute)
- Dependencies: none

## Process Summary

1. **Classify paths** — each `files_written` entry is an exact file, a `#section` claim, or a glob
2. **Detect overlaps** — check pairwise within each wave using path-comparison algorithm (section, whole-file, and glob containment rules)
3. **Resolve conflicts** — move the task with fewer downstream dependents to the next wave; tie-break by task order; loop until wave is clean
4. **Re-check target wave** — moved task may conflict with tasks already in the next wave
5. **Emit registry** — write `file-ownership-registry.yml` listing every task's `owns` and `reads`, plus conflict summary

## Execution

Read `references/process.md` for the complete overlap detection rules,
path-comparison algorithm, conflict-resolution pseudocode, registry output
format, and runtime enforcement behavior.
