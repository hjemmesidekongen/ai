# Brand Plugin Build — Autopilot

## Goal
Build a complete, production-quality `brand` plugin at `plugins/brand/`.

## Source of Truth (read EVERY iteration)
1. `.ai/brainstorm/brand-plugin/decisions.yml` — 18 final decisions
2. `.ai/brainstorm/brand-plugin/findings.md` — external reference templates
3. `.ai/brainstorm/brand-plugin/learnings.md` — what you learned so far

## The Loop

You do NOT have a fixed plan. Every iteration is: discover → plan → build → learn.

### 1. Orient (every iteration starts here)
- Read `learnings.md` — what did you learn last time?
- Check what exists in `plugins/brand/` — what's already built?
- Identify the SINGLE most important thing to build next
- If unsure, ask: "what would unblock the most downstream work?"

### 2. Research (before every build)
- Study the relevant existing plugin code (claude-core, dev-engine) for the pattern you're about to implement
- Read the specific external-reference files listed in findings.md that apply to THIS chunk
- If building a skill, read 2-3 existing SKILL.md files from dev-engine first
- If building plugin infrastructure, read claude-core's plugin.json first
- Write down what you learned in a scratchpad before proceeding

### 3. Plan ONE chunk
- Use `/plan:create` for ONLY the next thing to build
- The plan should be 1-3 tasks max — one logical unit of work
- Do NOT plan future chunks. You don't know enough yet.

### 4. Build it
- Use `/plan:execute` to build
- Production quality. No stubs, no TODOs.
- Follow conventions from the code you studied in step 2

### 5. Verify
- Valid YAML/frontmatter, checkpoints defined, ecosystem.json accurate
- If it's a skill: SKILL.md ≤ 80 lines, references/process.md for overflow
- Actually test: try loading/parsing output schemas

### 6. Commit
- One commit per chunk. Descriptive message. No AI attribution.

### 7. Learn
- Append to `learnings.md`:
  - What you built
  - What was harder than expected
  - What pattern you discovered that applies to future chunks
  - What you'd do differently
- This is the most important step. Skip nothing.

### 8. Loop
- Go back to step 1. The next chunk might be different from what you'd have guessed before building this one.

## Constraints
- Brand = strategy only. No hex codes, no CSS, no tokens.
- Brand truth at `.ai/brand/{name}/`.
- Depends only on claude-core.
- SKILL.md ≤ 80 lines.
- Every skill has a checkpoint.
- No AI attribution in commits.

## Definition of Done
The plugin is done when:
- Plugin scaffold complete (plugin.json, ecosystem.json, marketplace entry)
- Skills built: brand-strategy, brand-audit, brand-evolve, brand-loader
- Commands built: /brand:create, /brand:audit, /brand:evolve, /brand:apply, /brand:status
- Output schemas defined
- Self-review passes (use plugin-validator agent)
- ecosystem.json matches reality

You decide the ORDER. You decide how many chunks. You adapt as you learn.

<promise>BRAND PLUGIN COMPLETE AND VERIFIED</promise>
