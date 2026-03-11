# Dynamic Planner — Full Algorithm

## Overview

The dynamic planner runs an iterative loop where each cycle plans one wave, executes it, and learns from the results. The goal is fixed at creation time. The path adapts based on accumulated learnings.

## Phase 1: Orient

The orient phase establishes situational awareness before any planning.

### Inputs
- `state.yml` — current cycle, planned_waves, remaining_goal, replan_count
- `learnings.yml` — **active entries only** (skip superseded/invalidated)
- `plan.md` — implementation contract and quality standards
- Codebase state — what actually exists on disk

### Process
1. Read state.yml to get cycle number and remaining_goal
2. Read learnings.yml, filter to `status: active` entries only
3. Summarize active learnings (don't dump raw into context)
4. Scan relevant codebase areas for current state of the build
5. Assess: "Where am I relative to the goal? What's done? What's left?"

### Output
A mental model of: what exists, what works, what's left, what learnings apply.

### First cycle special case
On cycle 1, orient scans the codebase and goal but has no learnings to load. Skip directly to Plan phase (no Reflect needed).

## Phase 2: Reflect

Reflect evaluates the last cycle's results and classifies the path forward.

### Skip conditions
- Cycle 1 (no prior work to reflect on)

### Process
1. Review what the last wave attempted vs what it achieved
2. Compare cycle_metrics to previous cycle (if available): task completion rate, corrections trend, wave_passed status
3. Apply adversarial framing (see `references/reflect-prompts.md`)
4. Check: did any learnings invalidate prior assumptions?
5. Check: are open_questions blocking further progress?
6. Produce a classification: CONTINUE, ADJUST, REPLAN, or ESCALATE

### Classification criteria

**CONTINUE** — use when:
- Wave completed successfully
- Learnings are observations, not blockers
- The planned direction still makes sense
- No fundamental assumptions changed

**ADJUST** — use when:
- Wave succeeded but revealed the next wave should differ from initial expectation
- A constraint was discovered that changes approach but not goal
- An optimization opportunity was found

**REPLAN** — use when:
- Wave failed and the failure isn't recoverable by retrying
- A learning invalidates the overall approach (not just next step)
- The remaining_goal needs fundamental restructuring
- Check replan_count first: if >= 2, force ESCALATE instead

**ESCALATE** — use when:
- Scope change that affects cost or timeline
- Architecture pivot that would invalidate completed work
- Goal itself may need revision
- Uncertainty about user preference with UX impact
- replan_count >= 2 (anti-oscillation guard, D-008)
- max_cycles reached (safety valve, D-012)

### Output
- Classification (one of four)
- Reasoning (why this classification)
- If ADJUST: what should change in the next wave's approach
- If REPLAN: what assumption was invalidated and what the new approach should be
- If ESCALATE: what decision the human needs to make

## Phase 3: Research (optional)

Triggered only when the reflect phase identifies a specific knowledge gap.

### Trigger conditions
- Reflect produced a question that can't be answered from codebase or learnings
- A technical approach needs validation before committing a wave to it
- An external dependency or API needs investigation

### Process
1. Formulate a focused research question
2. Use codebase search, documentation, or (if needed) external sources
3. Record findings as a discovery-type learning entry
4. Feed findings back into the Plan phase

### Guard rails
- Research must have a specific question — no open-ended exploration
- Time-box: if research doesn't converge in one focused investigation, record what was found and plan around the uncertainty

## Phase 4: Plan

Plan one wave of work. Uses plan-engine for the mechanics.

### Process
1. Based on orient assessment + reflect classification + any research findings:
   - Define 2-5 concrete tasks for the next wave
   - Each task has: id, description, files, dependencies, tier
2. Run plan-engine to organize into a wave with file-ownership checks
3. Append the new wave ID to `planned_waves` in state.yml
4. Update `remaining_goal` to reflect what's left after this wave

### Constraints
- Plan ONE wave only — never plan multiple future waves
- Keep tasks concrete and verifiable — no vague "improve X" tasks
- Respect file-ownership: no two tasks in the wave write the same file
- If ADJUST: incorporate the adjustment into this wave's approach
- If REPLAN: start fresh from the remaining_goal, ignore prior wave plans

## Phase 5: Build

Execute the planned wave. Delegates to plan-execute.

### Process
1. Execute tasks (parallel if no file conflicts, sequential otherwise)
2. Run plan-verifier on completed wave
3. Handle verification failures:
   - Minor failure: fix and re-verify within the wave
   - Major failure: record as learning, move to Learn phase

### Output
- Wave completion status (passed/failed)
- Verification results
- Any artifacts produced

## Phase 6: Learn

Record what happened and prepare for the next cycle.

### Process
1. For each notable outcome (success, surprise, failure, discovery):
   - Create a learnings.yml entry with type, content, impact, status
   - Corrections must reference what they correct (supersedes field)
2. Check if any active learnings should be superseded by new findings
3. Update or add open_questions based on what was discovered
4. Record cycle_metrics entry (see schema):
   - tasks_planned, tasks_completed, classification, learnings_added, corrections_made, wave_passed
   - Compare to previous cycle's metrics during next Reflect phase
5. Run `doc-checkpoint` to verify documentation matches current state (CLAUDE.md counts, ecosystem.json, MEMORY.md)
6. Write next_orientation: guidance for the next orient phase
7. Increment `cycle` in state.yml
8. Update `remaining_goal` in state.yml

### Entry type guide
- **observation**: noticed a pattern or fact. "Haiku handles rubric scoring reliably."
- **constraint**: discovered a limitation. "Design tokens must be generated before component specs."
- **correction**: prior learning was wrong. "Rate limiter keys on header, not session ID."
- **discovery**: new insight that opens possibilities. "The scaffold skill can generate test fixtures."

### Quality rules
- Every cycle must produce at least one learning entry
- Content should be specific and actionable, not vague ("things went well")
- Impact should explain what this means for future planning
- Corrections MUST set supersedes to identify what they correct

## Phase 7: Loop or Done

### Done conditions
- remaining_goal is empty or satisfied
- All verification gates passed
- No open_questions that block completion

### Loop conditions
- remaining_goal has unfinished work
- max_cycles not reached
- No ESCALATE pending

### On done
- Set state.yml `status: done`
- Clear `remaining_goal`
- Final summary: cycles completed, learnings count, replans used

## Decision confidence boundaries (D-010)

### Proceed autonomously
- Technical implementation choice between equivalent options
- Refactoring within current architecture
- Adding error handling or edge cases
- Choosing between equivalent data formats

### Escalate to human
- Scope change that affects cost (adding features, expanding test matrix)
- Architecture pivot that invalidates previous waves' work
- Discovery that the goal itself may need revision
- Uncertainty about user preference (technical choices with UX impact)

## Anti-patterns to avoid

1. **Hallucinated reflections compounding** — corrections must reference what they correct. If a reflection feels speculative, mark it as observation, not correction.
2. **Over-structured memory filling context** — orient summarizes learnings, doesn't dump them raw.
3. **Plan oscillation** — max 2 replans, then escalate. Track replan_count.
4. **Sunk cost bias** — adversarial reflect prompts force fresh perspective.
5. **Infinite loop** — max_cycles safety valve.
6. **Losing progress on replan** — completed waves are never undone. Only future work is replanned.
7. **Context bloat** — only load active learnings. Superseded entries stay on disk, not in context.
