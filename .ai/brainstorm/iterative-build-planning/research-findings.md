# Iterative Build Planning — Research Findings

## Context
We're building a dynamic planning system for Claude Code that replaces rigid upfront wave planning with a learning loop: orient → reflect → plan one wave → build → verify → learn → repeat. Goal stays fixed, path adapts. Must work with autopilot for autonomous execution and accumulate learnings across iterations.

## Current system
- `plan-engine` creates all waves upfront from flat task list (topological sort, file-ownership, model-tier assignment)
- `plan-execute` runs waves sequentially with verification gates
- `autopilot` is a dumb loop — same prompt fed back on Stop hook, iteration counter, completion promise
- No feedback mechanism between iterations. No learning accumulation.

## Brainstorm state (pre-research)
- User wants a new command: `/plan:dynamic` (alongside existing `/plan:create` for known work)
- Plan initial phase + 1-2 waves, keep remainder as open goal
- After each wave: reflect, ask "is this still correct?", plan next wave, repeat
- Must include self-questioning: "Do I need more research? Could there be a better way?"
- User concerned about headaches if not thought through properly
- Architecture B (new skill wrapping plan-engine + autopilot) was the leading option

## Key design questions identified before research
1. Where do learnings accumulate?
2. How does it interact with autopilot?
3. Does it replace plan-engine or sit alongside it?
4. What triggers re-planning vs continuing?
5. Should reflect step be same-session or fresh agent?

---

## Research Sources (ranked by relevance)

### MUST READ — directly solves parts of our problem

**1. Reflexion (Shinn et al., NeurIPS 2023)**
- Paper: https://neurips.cc/virtual/2023/poster/70114
- Explainer: https://notes.muthu.co/2025/10/teaching-agents-to-learn-from-mistakes-through-reflection-and-self-critique/
- Core idea: Agent executes → evaluates → generates verbal self-critique → stores as episodic memory → uses on next attempt
- Result: 91% pass@1 on HumanEval (vs 67% baseline)
- Key: reflections stored as TEXT, not weight updates — exactly what we'd do with learnings.yml
- WARNING: agent can hallucinate bad reflections that compound. Need invalidation mechanism.
- TAKE: The episodic memory pattern. Verbal reinforcement. Structured self-critique format.
- AVOID: Blind accumulation without pruning/superseding. Their approach doesn't version or expire reflections.

**2. AdaPlanner — Adaptive Planning from Feedback**
- Paper: https://bohrium.dp.tech/paper/arxiv/2305.16653
- Core idea: Closed-loop planning with "in-plan" and "out-of-plan" refinement
- In-plan: adjust current step when minor issue occurs
- Out-of-plan: modify remaining plan when fundamental assumption changes
- Uses code-style prompts to reduce hallucination
- TAKE: The in-plan vs out-of-plan distinction. This directly answers "when to re-orient vs continue." Small failures → adjust within current wave. Big discoveries → replan remaining work.
- AVOID: Their code-style prompt format is specific to their environment. Don't cargo-cult it.

**3. GoalAct — Continuously Updated Global Planning**
- Paper: https://arxiv.org/html/2504.16563v2
- Core idea: Plan is a living document revised after every observation. Goal fixed, plan adapts.
- Outperforms both Plan-and-Solve (static) and ReAct (no plan)
- TAKE: The "continuously updatable global plan" concept. Their tight coupling of planning + execution is what we want.
- AVOID: Their specific implementation (Python, specific LLM calls). We need Claude Code native.

**4. Alibaba — "From ReAct to Ralph Loop"**
- URL: https://www.alibabacloud.com/blog/from-react-to-ralph-loop-a-continuous-iteration-paradigm-for-ai-agents_602799
- Core: Compares ReAct (adaptive but drifts), Plan-and-Execute (structured but brittle), Ralph Loop (forced iteration with external control)
- Key insight: conventional loops rely on LLM self-assessment = unreliable. External forced continuation needed.
- TAKE: Validates our autopilot stop-hook architecture. Ralph Loop IS our current autopilot.
- GAP: Their loop is stateless between iterations. Doesn't solve learning accumulation.

**5. DavidM — "28-line CLAUDE.md for autonomy"**
- URL: https://dev.to/dawidm/the-road-to-agent-autonomy-challenges-discoveries-and-a-28-line-solution-35p
- Key insight: "Tell the agent WHAT to remember, not HOW to store it"
- Their .memory-bank: goal, success measures, plan, progress. Agent self-organizes.
- Over-structuring memory degrades performance by filling context with rules
- CHALLENGE TO OUR APPROACH: We're designing structured learnings.yml — should it be more freeform?
- TAKE: Minimal structure. Let the agent reason about its own memory.
- AVOID: Zero structure though — we need cross-run comparison, so some schema is needed.

### SHOULD READ — good architectural patterns

**6. Planning with Backtracking and Replanning**
- URL: https://notes.muthu.co/2025/11/planning-with-backtracking-and-replanning-for-resilient-adaptive-agents/
- Best systematic breakdown of WHEN to replan: precondition failure, execution failure, unexpected effects, timeout, opportunity detection
- Key pattern: Planner-Executor-Monitor with Diagnosis step
- TAKE: "Hybrid approach — backtrack for quick recovery, trigger replanning after N backtracks or on global changes"
- TAKE: "Plan stability metrics — measure how much plans change between replanning episodes" (prevent oscillation)

**7. Claude Agent SDK — Long-Running Memory**
- URL: https://thinktools.ai/blog/claude-agent-sdk-solves-longrunning-ai-agent-memory-problem
- Anthropic's own architecture: initializer agent + coding agent
- Initializer creates manifest, coding agent works on focused changes, initializer updates manifest
- TAKE: The "manifest" pattern = our learnings.yml. Persistent state bridging sessions.
- TAKE: Keep each iteration lightweight. Don't accumulate everything in context.

**8. TsekatM — "6-layer Memory Architecture"**
- URL: https://dev.to/tsekatm/how-i-create-memory-for-my-agents-on-claude-code-mdn
- 6 layers: rules → personas → skills → learning → plans → permissions
- Layer 5 (Plans) bridges sessions: agent writes plan file that persists
- TAKE: Separation of concerns in memory. Plans are separate from learnings.
- AVOID: 6 layers might be overengineered for our use case. We have plugins/skills already.

**9. Cybernetic Recursion — Agent Loop Architectures**
- URL: https://atlassc.net/2026/02/13/cybernetic-recursion-ai-agent-loops
- Compares OODA Loop vs PDCA Cycle. PDCA better for reliability/auditability.
- TAKE: "Cognitive Maneuverability" = speed + accuracy of the orient step. Our orient step is THE critical phase.
- TAKE: PDCA framing (Plan-Do-Check-Act) maps cleanly to our loop.

### REFERENCE ONLY — YouTube / practical context

**10. "My Claude Code Workflow for 2026"** — https://www.youtube.com/watch?v=sy65ARFI9Bg
- Planning mode + explore subagents to find patterns before planning
- Relevant: our orient step should scan codebase patterns before planning

**11. "Agentic Workflows Just Changed AI Automation Forever"** — https://www.youtube.com/watch?v=AO5aW01DKHo
- Mentions Ralph Wiggum. Continuous loops. Confirms direction, no new insight.

**12. "Agent Teams in 18 Minutes"** — https://www.youtube.com/watch?v=3dZeXTMYZPI
- 4-step cycle: plan → execute → review → adjust. Parallel execution.
- Relevant: wave execution could use Agent Teams for parallelism.

---

## Key Tensions Identified

### Tension 1: Structured vs Freeform Learnings
- Reflexion: structured self-critique works well
- 28-line guy: over-structuring degrades performance
- Resolution: Structured SCHEMA (required fields) but freeform CONTENT within fields. The schema ensures cross-run comparability. The content ensures the agent can express nuanced observations.

### Tension 2: Same-context reflect vs Fresh-agent reflect
- Same-context: has full history, can reference specific details. But carries sunk-cost bias.
- Fresh agent: no bias, but loses nuance.
- Reflexion paper insight: reflection quality matters more than freshness. Bad reflections compound.
- Resolution: Same-context reflect with adversarial prompt framing. "What would you do differently if starting over?" forces the agent to overcome its own bias.

### Tension 3: When to replan vs when to continue
- AdaPlanner: in-plan (minor) vs out-of-plan (fundamental) refinement
- Backtracking paper: replan after N local failures or on global changes
- Resolution: Define explicit triggers:
  - CONTINUE: wave succeeded, learnings are observations not blockers
  - ADJUST: wave succeeded but revealed the next wave needs different approach
  - REPLAN: wave failed, or learnings invalidate the overall approach
  - ESCALATE: discovery requires human decision (scope change, cost implication)

### Tension 4: Autopilot integration
- Current autopilot: dumb loop, same prompt, iteration counter
- Needed: smart loop where each iteration reads learnings and constructs next step
- Ralph Loop (Alibaba): validates forced continuation via stop hook
- Resolution: Don't change autopilot. Build the intelligence in the dynamic-plan skill. Autopilot is the engine (loop control). Dynamic plan is the navigator (what to do each iteration).

### Tension 5: Plan state model
- Current: all waves defined upfront in state.yml
- Dynamic: only current + next wave defined. Future waves are "pending planning"
- GoalAct: plan updated after every observation
- Resolution: state.yml grows over time. New field: `planned_waves` (defined) vs `remaining_goal` (undefined). plan-execute and plan-status understand "3 of ??? waves complete."

---

## What to Build — Architectural Spec

### New command: `/plan:dynamic`
Creates a goal-oriented iterative plan. Unlike `/plan:create` which defines all waves upfront, `/plan:dynamic` plans one wave at a time with reflection between waves.

### New skill: `dynamic-planner` (claude-core)
Orchestrates the iterate loop. This is the core intelligence layer.

### Loop structure (one iteration = one "cycle"):
```
1. ORIENT (mandatory first step of every cycle)
   - Read learnings.yml (if exists)
   - Read current state (what's built, what's verified)
   - Read the goal (fixed, never changes)
   - Assess: "Where am I relative to the goal?"

2. REFLECT (skip on first cycle)
   - "What did the last wave teach me?"
   - "Is my approach still valid? What would I do differently if starting over?"
   - "Do I need to research something before planning the next wave?"
   - Classify: CONTINUE | ADJUST | REPLAN | ESCALATE
   - If ESCALATE: pause and surface to user
   - If REPLAN: go back to orient with fresh eyes

3. RESEARCH (optional, triggered by reflect)
   - If reflect identified knowledge gaps
   - Focused research on specific question
   - Results appended to learnings.yml

4. PLAN (one wave only)
   - Use existing plan-engine for wave decomposition
   - But only for the NEXT wave, not all remaining work
   - File-ownership, model-tier assignment still apply
   - Plan is appended to state.yml (growing document)

5. BUILD
   - Execute the wave (plan-execute handles this)
   - Verification gates still apply

6. LEARN
   - Record what happened: what worked, what surprised, what failed
   - Append to learnings.yml with status (active/superseded)
   - Update state.yml with wave results

7. → Back to ORIENT (or DONE if goal met)
```

### Learnings file: `.ai/plans/{name}/learnings.yml`
```yaml
goal: "Build E2E test suite for plugin validation"
cycle: 3

entries:
  - cycle: 1
    date: "2026-03-11"
    type: observation     # observation | constraint | correction | discovery
    content: "Haiku can grade rubric checks reliably — no need for Sonnet"
    impact: "Reduces cost per test by ~60%"
    status: active        # active | superseded | invalidated
    supersedes: null      # reference to earlier entry if this replaces one

  - cycle: 2
    date: "2026-03-11"
    type: correction
    content: "Initial fixture format was too verbose. 5-line briefs test more dimensions than 20-line ones."
    impact: "Simplifies all fixture files"
    status: active
    supersedes: null

open_questions:
  - "Should the runner support parallel test execution?"

next_orientation: >
  Wave 2 built the grader. Wave 3 should build the comparison system.
```

### Decision confidence (for ESCALATE trigger):
```yaml
confidence_triggers:
  escalate_to_human:
    - "Scope change that affects cost (adding brands, skills, test cases)"
    - "Architecture pivot that invalidates previous waves' work"
    - "Discovery that the goal itself may need revision"
    - "Uncertainty about user preference (technical choices with UX impact)"
  proceed_autonomously:
    - "Technical implementation choice between equivalent options"
    - "Refactoring within current architecture"
    - "Adding error handling or edge cases"
    - "Choosing between equivalent data formats"
```

### State file extension:
```yaml
# Existing fields unchanged
plan: my-plan
status: in_progress

# New fields for dynamic planning
mode: dynamic              # "static" (traditional) or "dynamic"
goal: "Build E2E test suite"
cycle: 3
planned_waves: [wave-1, wave-2, wave-3]  # waves that have been planned
remaining_goal: >          # what's left (freeform, updated each cycle)
  Build comparison/baseline system, add 3 more brand fixtures,
  write TESTING.md documentation.
```

### Interaction with existing system:
- `/plan:create` → static mode (unchanged, all waves upfront)
- `/plan:dynamic` → dynamic mode (goal + first wave, iterates)
- `/plan:execute` → works for both (reads mode from state.yml)
- `/plan:status` → shows "3 of ??? waves" for dynamic, "3 of 7" for static
- `/plan:resume` → works for both
- Autopilot: the loop engine. Dynamic planner: the navigation intelligence.

### A/B testing integration:
- Each cycle produces measurable outputs (like skill-creator evals)
- Learnings.yml tracks what changed and what the impact was
- Comparison: run dynamic plan for same goal twice with different parameters
- Baseline: first run's scores become the baseline for comparison
- Same infrastructure as the E2E test suite (rubrics, timestamped results)

### Quality gates:
- Reflect step must produce a classification (CONTINUE/ADJUST/REPLAN/ESCALATE)
- Every learning entry must have type + impact + status
- Superseded entries must reference what supersedes them
- Open questions must be addressed before marking goal as complete
- ESCALATE decisions must be surfaced — never silently skipped

---

## What to Avoid (Anti-patterns from research)

1. **Hallucinated reflections compounding** (Reflexion paper warning)
   - Mitigation: type field forces categorization. "correction" type requires referencing what it corrects.

2. **Over-structured memory filling context** (28-line CLAUDE.md insight)
   - Mitigation: learnings.yml has minimal required fields. Content is freeform prose.

3. **Plan oscillation / instability** (Backtracking paper)
   - Mitigation: REPLAN requires justification. Track how many times we've replanned — if >2, escalate to human.

4. **Sunk cost bias in reflection** (our own observation)
   - Mitigation: adversarial prompt in reflect step: "What would you do differently if starting over right now?"

5. **Infinite loop with no progress** (Ralph Loop limitation)
   - Mitigation: cycle counter + max_cycles in state.yml. Same as autopilot's max_iterations.

6. **Losing partial progress on replan** (AdaPlanner insight)
   - Mitigation: REPLAN preserves completed waves. Only future work is replanned. Never undo verified work.

7. **Context bloat from accumulated learnings** (general LLM limitation)
   - Mitigation: Orient step reads learnings.yml but summarizes it. Don't load full history into every prompt. Only load active entries.

---

## Implementation Priority

1. **learnings.yml schema** — define the format, versioned
2. **dynamic-planner skill** — the loop orchestrator
3. **state.yml extension** — mode, goal, cycle, remaining_goal fields
4. **/plan:dynamic command** — entry point
5. **plan-execute integration** — handle dynamic mode
6. **plan-status integration** — show "? of ???" for dynamic
7. **autopilot integration** — dynamic planner as autopilot prompt
8. **A/B comparison hooks** — track iteration quality

## Build approach
Use the dynamic planner itself to build the dynamic planner (once wave 1 is done manually). This is the ultimate dogfooding — if the tool can build itself iteratively, it works.

---

## Sources for user review (prioritized)

### Read these (30 min total):
1. Reflexion explainer: https://notes.muthu.co/2025/10/teaching-agents-to-learn-from-mistakes-through-reflection-and-self-critique/ (10 min, foundational pattern)
2. AdaPlanner abstract: https://bohrium.dp.tech/paper/arxiv/2305.16653 (5 min, in-plan vs out-of-plan)
3. DavidM 28-line approach: https://dev.to/dawidm/the-road-to-agent-autonomy-challenges-discoveries-and-a-28-line-solution-35p (10 min, challenges our assumptions about structure)
4. Backtracking/replanning: https://notes.muthu.co/2025/11/planning-with-backtracking-and-replanning-for-resilient-adaptive-agents/ (5 min, when to replan)

### Skim these (15 min total):
5. GoalAct abstract: https://arxiv.org/html/2504.16563v2 (3 min, continuously updated plan)
6. Alibaba Ralph Loop: https://www.alibabacloud.com/blog/from-react-to-ralph-loop-a-continuous-iteration-paradigm-for-ai-agents_602799 (5 min, validates our autopilot)
7. Claude Agent SDK memory: https://thinktools.ai/blog/claude-agent-sdk-solves-longrunning-ai-agent-memory-problem (5 min, Anthropic's own pattern)

### Watch if interested:
8. "My Claude Code Workflow for 2026": https://www.youtube.com/watch?v=sy65ARFI9Bg (20 min, practical patterns)
