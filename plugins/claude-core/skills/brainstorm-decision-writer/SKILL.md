---
name: brainstorm-decision-writer
description: >
  Extracts structured decisions from a brainstorm session. Walks through
  the conversation with the user, identifies landing points, and co-authors
  a decisions.yml file with domain tags and confidence levels. Use when
  formalizing brainstorm conclusions, extracting decisions from transcripts,
  recording what was decided after a discussion, detecting contradictions
  with previous decisions, or closing out an active brainstorm session.
user_invocable: false
interactive: true
depends_on:
  - brainstorm-session
reads:
  - ".ai/brainstorm/{topic}/brainstorm-state.yml"
  - ".ai/brainstorm/{topic}/brainstorm-transcript-{date}.md"
writes:
  - ".ai/brainstorm/{topic}/decisions.yml"
  - ".ai/brainstorm/{topic}/brainstorm-state.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "decisions_extracted"
      verify: "At least 1 decision written to decisions.yml"
      fail_action: "Re-read transcript and identify landing points"
    - name: "user_confirmed"
      verify: "Every decision was confirmed by the user before writing"
      fail_action: "Present unconfirmed decisions for user approval"
  on_fail: "Fix issues and re-run checkpoint"
  on_pass: "Report decision count and any contradictions detected."
model_tier: senior
_source:
  origin: "claude-core"
  inspired_by: "task-planner/brainstorm-decision-writer"
  ported_date: "2026-03-08"
  iteration: 1
  changes: "Flexible domain tags, contradiction detection, cleaner merge rules"
---

# brainstorm-decision-writer

Extract structured decisions from a brainstorm session. Walk through the conversation with the user, identify landing points, and co-author a decisions.yml file. Every decision is user-confirmed before writing.

Use this skill when a brainstorm session is complete and the user wants to formalize what was decided. Triggered by `/brainstorm:decide`.

## When to trigger

- User runs `/brainstorm:decide`
- User says "let's extract decisions" or "what did we decide?"
- A brainstorm session is active and the user signals closure

## Key principles

- **User confirms every decision** — no auto-extraction
- **One at a time** — present candidates individually, not as a batch
- **Preserve existing decisions** — merge, never overwrite
- **Detect contradictions** — flag when a new decision conflicts with an existing one
- **Flexible domains** — don't hardcode domain tags, infer from context

## Process

See `references/process.md` for the full extraction workflow.

## Output

- `decisions.yml` — structured decisions with domain tags, confidence, context, roadmap_item links
- Updated `roadmap.yml` — new items added or existing items enriched from decisions
- Updated `brainstorm-state.yml` — marks `decisions_extracted: true`, `roadmap_ported: true`, `active: false`
