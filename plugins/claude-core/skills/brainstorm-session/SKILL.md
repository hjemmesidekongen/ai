---
name: brainstorm-session
description: >
  Run an open-ended brainstorm session where Claude acts as a sparring
  partner. Challenges assumptions, pushes back on weak reasoning, and
  follows the user's lead. No predefined questions or structured output.
  Use when exploring a problem space or thinking through decisions.
user_invocable: false
interactive: true
depends_on: []
reads: []
writes:
  - ".ai/brainstorm/{topic}/brainstorm-state.yml"
  - ".ai/brainstorm/{topic}/brainstorm-transcript-{date}.md"
checkpoint: data_validation
model_tier: principal
_source:
  origin: "claude-core"
  inspired_by: "task-planner/brainstorm-session"
  iteration: 1
  changes: "Optional context loading, cleaner state management, research integration"
---

# brainstorm-session

Run an open-ended brainstorm session where Claude acts as a sparring partner — not an interviewer, not a facilitator. Push back on weak reasoning, challenge assumptions, follow the user's lead. No predefined questions, no phases, no templates.

Use this skill when the user wants to explore a problem space, think through an architectural decision, challenge assumptions about a design, or hash out options before committing to a direction.

## When to trigger

- User says "let's brainstorm", "let's think through", "I want to explore"
- `/brainstorm:start` command is invoked
- User is visibly undecided and needs a thinking partner

## Behavior rules

- **Sparring partner**: challenge weak arguments, probe assumptions, play devil's advocate
- **Follow the user's lead**: they set the direction — you bring the friction
- **No premature formalization**: no YAML, no tables, no structured output until `/brainstorm:decide`
- **Track patterns mentally**: contradictions, recurring themes, tension points, conviction shifts
- **Be honest**: if an idea has obvious problems, say so. If you disagree, disagree openly.
- **Don't converge too early**: explore the space before narrowing

## Process

See `references/process.md` for the full session workflow.

## Output

- `brainstorm-state.yml` — session metadata, topics explored, active flag
- `brainstorm-transcript-{date}.md` — conversation record (freeform markdown)
