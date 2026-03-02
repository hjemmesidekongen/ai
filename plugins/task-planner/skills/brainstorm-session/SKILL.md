---
name: brainstorm-session
description: >
  Runs an open-ended brainstorm session where Claude acts as a sparring partner,
  not an interviewer. Pushes back on weak reasoning, challenges assumptions,
  and follows the user's lead. No predefined questions or phases — the user
  sets the direction. Formalization happens later via /brainstorm:decide.
  Use when starting a brainstorm, running /brainstorm:start, exploring ideas
  before plugin creation, or having an open-ended thinking session.
interactive: true
depends_on: []
reads: []
writes:
  - "~/.claude/projects/[project-name]/brainstorm-state.yml"
  - "~/.claude/projects/[project-name]/brainstorm-transcript-[date].md"
checkpoint:
  type: data_validation
  required_checks:
    - name: "state_file_exists"
      verify: "brainstorm-state.yml exists with a session entry for this date"
      fail_action: "Create brainstorm-state.yml with the current session entry"
    - name: "transcript_recorded"
      verify: "Transcript file path is recorded in brainstorm-state.yml"
      fail_action: "Write the transcript and update brainstorm-state.yml"
    - name: "project_directory_exists"
      verify: "~/.claude/projects/[project-name]/ directory exists"
      fail_action: "Create the project directory"
  on_fail: "Fix the failing check and re-validate. Mark session complete only after all checks pass."
  on_pass: "Update brainstorm-state.yml with session details."
---

# Brainstorm Session

Open-ended thinking partner skill — no predefined questions, no structured output until `/brainstorm:decide`.

## Context
- Reads: none
- Writes: brainstorm-state.yml, brainstorm-transcript-[date].md
- Checkpoint: data_validation (state file exists, transcript recorded, project dir exists)
- Dependencies: none

## Process Summary
1. Create project directory (`~/.claude/projects/[project-name]/`) if absent
2. Check brainstorm-state.yml — resume if active, start fresh otherwise
3. Initialize or append session entry in brainstorm-state.yml
4. Run brainstorm — act as sparring partner, follow user's lead, no premature formalization
5. On session end — save transcript, update state with topics_explored, suggest /brainstorm:decide

## Execution
Read `references/process.md` for the complete process, behavior rules, and output formats.
