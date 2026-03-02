---
name: brainstorm-decision-writer
description: >
  Extracts structured decisions from a brainstorm session. Walks through the
  conversation with the user, identifies landing points, and co-authors a
  decisions.yml file. Each decision gets a domain tag, confidence level, and
  context note. Triggered by /brainstorm:decide. Use when extracting decisions
  from brainstorm, running /brainstorm:decide, formalizing brainstorm
  conclusions, or co-authoring decisions.yml.
interactive: true
depends_on:
  - brainstorm-session
reads:
  - "~/.claude/projects/[project-name]/brainstorm-state.yml"
  - "~/.claude/projects/[project-name]/brainstorm-transcript-[date].md"
writes:
  - "~/.claude/projects/[project-name]/decisions.yml"
  - "~/.claude/projects/[project-name]/brainstorm-state.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "decisions_file_exists"
      verify: "decisions.yml exists with at least 1 decision"
      fail_action: "Write decisions.yml with the confirmed decisions"
    - name: "decision_schema_valid"
      verify: "Every decision has id, domain (list), decision (non-empty), confidence, context"
      fail_action: "Fix missing fields and re-validate"
    - name: "prior_decisions_preserved"
      verify: "If prior decisions existed, they are preserved in the output"
      fail_action: "Reload prior decisions and merge with new ones"
    - name: "state_updated"
      verify: "brainstorm-state.yml has decisions_extracted: true for this session"
      fail_action: "Update brainstorm-state.yml"
    - name: "source_sessions_tracked"
      verify: "source_sessions list in decisions.yml includes current transcript"
      fail_action: "Add current transcript path to source_sessions"
  on_fail: "Fix the failing check and re-validate. Report only after all checks pass."
  on_pass: "Report decision count and suggest next steps."
---

# Brainstorm Decision Writer

Co-authors decisions.yml from brainstorm transcripts — every decision is user-confirmed through interactive review before extraction.

## Context
- Reads: brainstorm-state.yml, brainstorm-transcript-[date].md
- Writes: decisions.yml, brainstorm-state.yml
- Checkpoint: data_validation (decisions file, schema valid, prior decisions preserved, state updated)
- Dependencies: brainstorm-session

## Process Summary
1. Load brainstorm-state.yml and read the active session transcript
2. Check for existing decisions.yml — offer review before adding new ones
3. Extract candidate landing points from transcript — present one at a time for confirmation
4. Catch stragglers — ask if any decisions were missed
5. Tag each confirmed decision with domain(s) and confidence level
6. Write decisions.yml (merge with existing if present)
7. Update brainstorm-state.yml (decisions_extracted: true, active: false)
8. Report decision count and downstream commands that will read them

## Execution
Read `references/process.md` for the complete process, behavior rules, and output formats.
