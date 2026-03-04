---
name: brainstorm-session
user-invocable: true
description: >
  Facilitate a structured brainstorm session with the user. Challenge assumptions,
  explore trade-offs, and push back on ideas. Produces a timestamped transcript
  and brainstorm-state.yml tracking topics, open questions, and session metadata.
  Use when brainstorming architecture, features, design decisions, or strategy.
phase: 0
depends_on: []
writes:
  - ".ai/brainstorm/{topic}/brainstorm-transcript-{date}.md"
  - ".ai/brainstorm/{topic}/brainstorm-state.yml"
reads:
  - ".ai/brainstorm/*/decisions.yml (past decisions for context)"
  - ".ai/agency.yml (active project)"
model_tier: principal
model: opus
interactive: true
checkpoint:
  type: data_validation
  required_checks:
    - name: "transcript_written"
      verify: "brainstorm-transcript-{date}.md exists and is non-empty"
      fail_action: "Write transcript from session history"
    - name: "state_updated"
      verify: "brainstorm-state.yml has status, topics, open_questions"
      fail_action: "Generate state from transcript content"
    - name: "topics_captured"
      verify: "At least 1 topic in brainstorm-state.yml topics array"
      fail_action: "Extract topics from transcript headings"
  on_fail: "Fix issues and re-run checkpoint"
  on_pass: "Report session summary. Suggest running brainstorm-decision-writer."
---

# Brainstorm Session

Structured brainstorm facilitation. Challenges assumptions, explores trade-offs,
and pushes back on ideas to strengthen decisions.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | Past decisions.yml files, agency.yml for project context |
| **Writes** | brainstorm-transcript-{date}.md, brainstorm-state.yml |
| **Checkpoint** | data_validation: transcript written, state updated, topics captured |
| **Interactive** | Yes — requires user dialogue throughout |

## Session Flow Summary

1. Load past decisions from `.ai/brainstorm/*/decisions.yml` for context
2. Ask user for brainstorm topic and goals
3. Facilitate structured discussion — challenge, push back, explore alternatives
4. Capture key points, trade-offs, and open questions in real-time
5. Write timestamped transcript and update brainstorm-state.yml

## Findings Persistence

Write session discoveries to `.ai/brainstorm/{topic}/findings.md`.
**2-Action Rule:** After every 2 discussion rounds, save key points to findings.md.

## Error Logging — Log errors to state.yml errors array. Check errors before retrying.

## Execution — [references/process.md](references/process.md)
