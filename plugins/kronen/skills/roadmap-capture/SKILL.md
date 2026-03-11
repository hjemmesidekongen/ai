---
name: roadmap-capture
description: >
  Automatically captures out-of-scope ideas, deferred features, and future
  work items into the project roadmap during conversation. Use when an idea
  surfaces that is outside the current task scope and should be tracked for
  later, when the user says "add this to the roadmap" or "track this for
  later", or when a deferred item from a brainstorm or plan needs persistent
  tracking.
user_invocable: false
interactive: false
depends_on: []
triggers:
  - "add to roadmap"
  - "track for later"
  - "out of scope idea"
  - "defer this feature"
  - "capture roadmap item"
reads:
  - ".ai/roadmap.yml"
writes:
  - ".ai/roadmap.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "item_appended"
      verify: "New roadmap item appended to .ai/roadmap.yml with valid ID"
      fail_action: "Write item with auto-generated RL-NNN ID"
    - name: "no_duplicates"
      verify: "Item title does not duplicate an existing roadmap entry"
      fail_action: "Skip capture or merge with existing entry"
  on_fail: "Fix issues and re-run checkpoint"
  on_pass: "Report captured item ID and title."
model_tier: junior
_source:
  origin: "kronen"
  inspired_by: "brainstorm/D-011"
  ported_date: "2026-03-08"
  iteration: 1
  changes: "Auto-capture of out-of-scope ideas with dedup and categorization"
---

# roadmap-capture

Automatically captures out-of-scope ideas, deferred features, and future work items into the project roadmap during any conversation.

Use this skill when the conversation surfaces an idea, feature request, improvement, or TODO that is outside the scope of the current task. Instead of losing these insights, capture them to `.ai/roadmap.yml` with proper categorization and priority.

## When to trigger

- User mentions a future feature ("we should add X someday")
- A useful enhancement is identified but isn't part of the current task
- A deferred item from a brainstorm or plan needs tracking
- The user explicitly says "add this to the roadmap" or "track this for later"

## When NOT to trigger

- The idea is part of the current task (just do it)
- The user is thinking out loud and hasn't landed on anything concrete
- The item already exists in roadmap.yml

## Process

See `references/process.md` for the full capture workflow.

## Output

Appends a new item to `.ai/roadmap.yml` with:
- Auto-generated ID (RL-NNN, sequential)
- title, description, category, plugin, priority, source, added date, tags
