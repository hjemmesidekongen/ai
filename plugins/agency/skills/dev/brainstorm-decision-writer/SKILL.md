---
name: brainstorm-decision-writer
user-invocable: false
description: >
  Extract structured decisions from a brainstorm transcript into decisions.yml.
  Each decision captures id, domain, decision text, confidence level, context,
  and session date. Appends to existing decisions.yml without overwriting prior
  entries. Use after brainstorm-session completes, when formalizing brainstorm
  outcomes, or when extracting decisions from discussion transcripts.
phase: 0
depends_on: [brainstorm-session]
writes:
  - ".ai/brainstorm/{topic}/decisions.yml"
reads:
  - ".ai/brainstorm/{topic}/brainstorm-transcript-*.md"
  - ".ai/brainstorm/{topic}/brainstorm-state.yml"
model_tier: senior
model: sonnet
interactive: false
checkpoint:
  type: data_validation
  required_checks:
    - name: "decisions_yml_exists"
      verify: "decisions.yml exists in .ai/brainstorm/{topic}/"
      fail_action: "Create decisions.yml with extracted decisions"
    - name: "decision_fields_complete"
      verify: "Each decision has id, domain[], decision, confidence, context, session_date"
      fail_action: "Fill missing fields from transcript context"
    - name: "no_duplicate_ids"
      verify: "All decision IDs are unique within the file"
      fail_action: "Regenerate IDs for duplicates using topic-NNN format"
  on_fail: "Fix issues and re-run checkpoint"
  on_pass: "Report decisions extracted. Update brainstorm-state.yml status to decided."
---

# Brainstorm Decision Writer

Extracts structured decisions from brainstorm transcripts into decisions.yml.
Preserves the established schema: id, domain, decision, confidence, context.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | brainstorm-transcript-*.md, brainstorm-state.yml |
| **Writes** | decisions.yml (append, never overwrite existing entries) |
| **Checkpoint** | data_validation: file exists, fields complete, no duplicate IDs |
| **Dependencies** | brainstorm-session (transcript must exist) |

## Extraction Flow Summary

1. Read latest brainstorm-transcript-*.md for the topic
2. Read brainstorm-state.yml to understand session context
3. Identify decision points from transcript (explicit decisions, conclusions, agreements)
4. Structure each into the decisions.yml schema
5. Append to existing decisions.yml (preserving prior decisions)
6. Update brainstorm-state.yml status

## Findings Persistence

Write extraction results to `.ai/brainstorm/{topic}/findings.md`.
**2-Action Rule:** After every 2 decisions extracted, save to findings.md.

## Error Logging — Log errors to state.yml errors array. Check errors before retrying.

## Execution — [references/process.md](references/process.md)
