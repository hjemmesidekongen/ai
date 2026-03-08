---
name: roadmap-capture
description: >
  Automatically captures out-of-scope ideas, deferred features, and future
  work items into the project roadmap during conversation. Use when an idea
  surfaces that is outside the current task scope and should be tracked for later.
user_invocable: false
interactive: false
depends_on: []
reads:
  - ".ai/roadmap.yml"
writes:
  - ".ai/roadmap.yml"
checkpoint: data_validation
model_tier: junior
_source:
  origin: "claude-core"
  inspired_by: "brainstorm/D-011"
  iteration: 1
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
