# plan-engine — Full Process

## Overview

The plan-engine runs a goal-driven iterative loop. Each cycle plans one wave, executes it via multi-agent dispatch, verifies with an isolated agent, and records learnings. The goal is fixed at creation time. The path adapts based on accumulated learnings. Autopilot is the default execution mode.

---

## Initialization

### Goal definition

Every plan starts with a clearly defined goal. The goal is the fixed north star — it never changes during execution.

**Goal structure:**
```yaml
goal:
  statement: "What we are building and why"
  acceptance_criteria:
    - criterion: "Concrete, verifiable condition"
      verification:
        type: command | file_check | metric | expert_review
        value: "specific check to run"
  done_signal:
    type: command | file_check | metric
    target: "what to check"
    expected: "expected result"
  scope:                              # optional — enforced by hooks when present
    boundaries: ["prose description of what's in/out of scope"]
    paths:
      include: ["src/auth/**"]        # plan-scope-guard.sh warns outside these
      exclude: ["src/payments/**"]    # plan-verification-gate.sh blocks these
  constraints: ["technical, timeline, or resource constraints"]
```

**Goal clarity requirements:**
- **Measurable** — can you verify when it's done? If not, it's too vague.
- **Scoped** — does it have boundaries? What is explicitly NOT included?
- **Concrete** — does it reference specific systems, files, or behaviors?
- **Acceptance criteria** — what does "done" look like? List verifiable conditions.

### Goal clarity gate (PC-D04, strengthened)

Runs before cycle 1 starts. Six mechanical checks — no vibes-based judgment.

**Check 1: Non-empty criteria**
- acceptance_criteria array has ≥2 entries
- FAIL if: array is empty, has 1 entry, or entries are empty strings

**Check 2: Minimum specificity**
- Each criterion is ≥15 characters
- FAIL if: any criterion is shorter (too terse to be verifiable)

**Check 3: No vague markers**
- Reject criteria containing generic phrases that resist verification
- Vague markers: "works well", "is good", "is clean", "is better", "is correct", "looks right", "should work", "properly handles", "as expected", "is complete" (without quantifier)
- FAIL if: any criterion matches a vague marker

**Check 4: Verifiability signal**
- Each criterion contains at least one verifiable signal:
  - File path or glob pattern (contains `/` or `*`)
  - Command or tool reference (contains `run`, `passes`, `returns`, `outputs`)
  - Quantifier (`zero`, `no `, `all `, `every`, `none`, `≥`, `≤`, `exactly`)
  - Metric or count (contains a number or percentage)
- FAIL if: any criterion lacks a verifiable signal

**Check 5: Goal-criteria alignment**
- Extract nouns/key terms from goal statement (skip stop words)
- At least 50% of key terms appear across the acceptance criteria
- FAIL if: criteria don't reference what the goal is about

**Check 6: Verification method declared**
- Each acceptance criterion has a non-empty `verification` field
- The `verification.type` matches the allowed enum: `command`, `file_check`, `metric`, or `expert_review`
- The `verification.value` is a non-empty string
- FAIL if: any criterion is missing `verification`, has an empty `verification.value`, or uses a type not in the enum

**Scoring:**
- 6/6 pass → proceed, goal is well-formed
- 4-5/6 pass → proceed with advisory warnings for failed checks
- 0-3/6 pass → block. Surface which checks failed with examples of how to fix each. Do not proceed until the user refines.

**Cycle 2+ enforcement:**
- Re-run checks 1-4 and 6 (check 5 is cycle-1 only since goal is fixed)
- If any check that passed on cycle 1 now fails (e.g., criteria were edited) → ESCALATE
- If checks that failed on cycle 1 still fail → ESCALATE

**Goal immutability:**
- After cycle 1 completes, `goal` and `acceptance_criteria` in state.yml are frozen
- If state.yml shows different values than cycle 1 snapshot → ESCALATE with "goal was modified after initialization"
- Only way to change the goal: create a new plan

### Plan directory setup

Create `.ai/plans/{plan-name}/`:
- `state.yml` — execution state (schema: `resources/state-schema.yml`)
- `learnings.yml` — episodic memory (schema: `resources/learnings-schema.yml`)
- `plan.yml` — wave structure (schema: `resources/plan-schema.yml`)
- `plan.md` — implementation contract (standards, constraints, context recovery)
- `artifacts/` — agent output directory

### State initialization

```yaml
plan: {plan-name}
status: in_progress
mode: dynamic
goal: "{goal statement}"
acceptance_criteria:
  - criterion: "{what must be true}"
    verification:
      type: command | file_check | metric | expert_review
      value: "{specific check}"
  - criterion: "{what must be true}"
    verification:
      type: command | file_check | metric | expert_review
      value: "{specific check}"
done_signal:
  type: command | file_check | metric
  target: "{what to check}"
  expected: "{expected result}"
scope:                                   # optional — omit if no scope enforcement needed
  boundaries: ["{prose description}"]
  paths:
    include: ["{glob pattern}"]
    exclude: ["{glob pattern}"]
cycle: 1
planned_waves: []
remaining_goal: "{initial assessment of full scope}"
max_cycles: 15
replan_count: 0
done_signal_fail_streak: 0
started_at: "{timestamp}"
updated_at: "{timestamp}"
errors: []
recovery_notes: "{initial context summary}"
```

### Learnings initialization

```yaml
goal: "{goal statement}"
cycle: 1
entries: []
open_questions: []
cycle_metrics: []
next_orientation: "First cycle — no prior learnings."
```

### Autopilot execution (default)

Plans execute via autopilot by default. The plan-prompt-constructor script builds cycle-aware prompts for each iteration. Manual wave-by-wave execution only if the user explicitly requests it.

**Autopilot flow:**
1. Initialize plan (goal, state, learnings, plan.md)
2. Plan first wave
3. Start autopilot loop — each iteration runs one full OODA cycle
4. plan-prompt-constructor.sh reads state.yml + learnings.yml to build the next prompt
5. Loop continues until goal met, max_cycles reached, or ESCALATE

**Manual flow (only if requested):**
1. Initialize plan
2. Plan and execute first wave
3. User runs `/plan resume` for each subsequent cycle

---

## Phase 1: Orient

Establishes situational awareness before any planning.

### Inputs
- `state.yml` — current cycle, planned_waves, remaining_goal, replan_count
- `learnings.yml` — **active entries only** (skip superseded/invalidated)
- `plan.md` — implementation contract and quality standards
- Codebase state — what actually exists on disk

### Process
1. Read state.yml to get cycle number, remaining_goal, acceptance_criteria
2. Read learnings.yml, filter to `status: active` entries only
3. Summarize active learnings (don't dump raw into context)
4. Scan relevant codebase areas for current state of the build
5. Assess: "Where am I relative to the goal? What's done? What's left?"
6. **Cycle 1**: run goal clarity gate (6-point mechanical checklist). Block if <4 checks pass.
7. **Cycle 2+**: re-run goal clarity gate. If any previously passing check now fails → ESCALATE. If cycle-1 failures persist → ESCALATE.

### Output
A mental model of: what exists, what works, what's left, what learnings apply.

### First cycle special case
On cycle 1, orient scans the codebase and goal but has no learnings to load. Skip directly to Plan phase (no Reflect needed).

---

## Phase 2: Reflect

Evaluates the last cycle's results and classifies the path forward. **Dispatched to plan-classifier agent** for unbiased classification.

### Skip conditions
- Cycle 1 (no prior work to reflect on)

### Process
1. Assemble reflection context:
   - What the last wave attempted vs what it achieved
   - cycle_metrics from previous cycle (task completion rate, corrections trend, wave_passed)
   - Active learnings that may invalidate assumptions
   - Open questions blocking progress
2. Dispatch plan-classifier agent (see interface contract below)
3. Receive classification: CONTINUE, ADJUST, REPLAN, or ESCALATE with reasoning

### plan-classifier agent interface contract (PC-D03)

**Critical constraint:** The classifier must NOT be dispatched through context-manager or the planning system. It is a lightweight, direct Agent tool call. If it goes through context-manager, it picks up build context and loses its isolation.

**Input schema:**
```yaml
plan_classifier_input:
  goal: "{goal statement}"
  acceptance_criteria:
    - criterion: "{what must be true}"
      verification:
        type: command | file_check | metric | expert_review
        value: "{specific check}"
      status: pass | fail | pending
  cycle: {N}
  replan_count: {N}
  max_cycles: {N}
  active_learnings_summary: "{summarized, not raw — max 500 words}"
  last_wave_results:
    wave: {N}
    tasks_planned: {N}
    tasks_completed: {N}
    wave_passed: true|false
    key_outcomes: ["{outcome 1}", "{outcome 2}"]
    errors: ["{error if any}"]
  cycle_metrics_trend: ["{previous cycle metrics for comparison}"]
  adversarial_prompts: "{from references/reflect-prompts.md}"
```

**Output schema:**
```yaml
plan_classifier_output:
  classification: "CONTINUE|ADJUST|REPLAN|ESCALATE"
  reasoning: "{why this classification — one paragraph}"
  confidence: "high|medium|low"
  adjustment_detail: "{what should change — only if ADJUST}"
  replan_detail: "{what assumption was invalidated, new approach — only if REPLAN}"
  escalation_detail: "{what decision the human needs to make — only if ESCALATE}"
  concerns: ["{any worries or risks noticed during classification}"]
```

### Classifier fallback
If plan-classifier agent fails (timeout, error), fall back to inline classification using the same inputs and adversarial prompts. Degraded quality is better than a stalled plan. Log the failure as a constraint-type learning entry.

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
- replan_count >= 2 (anti-oscillation guard)
- max_cycles reached (safety valve)

### Output
- Classification (one of four)
- Reasoning (why this classification)
- If ADJUST: what should change in the next wave's approach
- If REPLAN: what assumption was invalidated and what the new approach should be
- If ESCALATE: what decision the human needs to make

---

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

---

## Phase 4: Plan

Plan one wave of work. This phase contains the wave decomposition algorithm.

### Process
1. Based on orient assessment + reflect classification + any research findings:
   - Define 2-5 concrete tasks for the next wave
   - Each task has: id, name, description, depends_on, files_written, files_read, model_tier (optional)
2. Run wave decomposition algorithm (see below)
3. Generate verification contract for the wave (see below)
4. Append the new wave to plan.yml
5. Append the new wave ID to `planned_waves` in state.yml
6. Update `remaining_goal` to reflect what's left after this wave

### Constraints
- Plan ONE wave only — never plan multiple future waves
- Keep tasks concrete and verifiable — no vague "improve X" tasks
- Respect file-ownership: no two tasks in the wave write the same file
- If ADJUST: incorporate the adjustment into this wave's approach
- If REPLAN: start fresh from the remaining_goal, ignore prior wave plans

### Wave decomposition algorithm

#### Step 1: Dependency resolution (topological sort)
1. Build dependency graph from `depends_on` arrays
2. Find all tasks with empty/satisfied dependencies → **Wave 1**
3. Remove those tasks from the graph, mark their dependents as potentially unblocked
4. Repeat: find newly unblocked tasks → **Wave N**
5. Continue until all tasks assigned

**Cycle detection:** If any iteration finds zero unblocked tasks but tasks remain, report a dependency cycle and halt with an error listing the involved tasks.

#### Step 2: File-ownership conflict resolution

For each wave, check pairwise file-ownership conflicts between tasks.

**Path comparison rules:**

| Path A | Path B | Conflict? |
|--------|--------|-----------|
| `file.yml` | `file.yml` | YES — same file |
| `file.yml#colors` | `file.yml#typography` | NO — different sections |
| `file.yml#colors` | `file.yml#colors` | YES — same section |
| `file.yml` | `file.yml#colors` | YES — whole-file includes section |
| `assets/*` | `assets/icons/check.svg` | YES — glob contains path |
| `src/*.ts` | `tests/*.ts` | NO — different directories |

**Resolution:**
1. Count downstream dependents for each conflicting task
2. Keep the task with **more** downstream dependents (critical path)
3. Move the other task to the **next wave**
4. Tie-break by task order (lower index stays)
5. Re-check the target wave for new conflicts
6. Loop until all waves are clean

#### Step 3: Model-tier assignment

| Tier | Model | When to use |
|------|-------|-------------|
| junior | Haiku | Simple scaffolding, templated output, file creation, config generation |
| senior | Sonnet | Implementation, content generation, reasoning tasks (default) |
| principal | Opus | Architecture decisions, QA/verification, cross-cutting concerns |

**Heuristics from task names:**
- Contains "scaffold", "create", "generate config" → junior
- Contains "implement", "build", "write" → senior
- Contains "review", "verify", "benchmark", "architect", "integrate" → principal

**Override:** If a task's `model_tier` is explicitly set, use it as-is.

### Verification contract generation (PC-D05)

At plan time, generate concrete verification requirements for the wave. This contract is:
- Written before execution (not ad-hoc during verification)
- Stored in plan.yml alongside the wave definition
- Visible to task agents (they know what they'll be measured against)
- Used by plan-verifier agent as the checklist

**Contract format in plan.yml:**
```yaml
waves:
  - wave: 1
    tasks: [t1, t2]
    parallel: true
    verification:
      type: data_validation
      contract:
        - "state.yml parses as valid YAML with required fields: plan, status, mode, goal"
        - "learnings.yml contains goal field matching state.yml goal"
        - "No placeholder or TODO values in any output file"
      qa_review: false
    checkpoint: false
```

**Final wave always includes acceptance criteria check:**
```yaml
verification:
  type: integration_test
  contract:
    - "All acceptance criteria from goal are met"
    - "{specific criterion 1}"
    - "{specific criterion 2}"
  qa_review: true
```

---

## Phase 5: Build

Execute the planned wave via multi-agent dispatch.

### Context assembly (PC-D11)

Before dispatching task agents, assemble context packages via context-manager agent:

```
Context package per task agent:
  1. Task spec: id, name, description, files_written, files_read, model_tier
  2. Plan rules: full plan.md content (implementation contract)
  3. Dependency artifacts: .ai/plans/<name>/artifacts/ for depends_on tasks
  4. Verification contract: the specific requirements this task contributes to
  5. Agent worries requirement: "Report any concerns, risks, or optimization
     opportunities you notice during implementation"
```

### Execution

1. If `parallel: true` → dispatch tasks as parallel Agent subagents
   - Each agent writes output to `.ai/plans/<name>/artifacts/<wave>-<task>-output.md`
   - Each agent also writes concerns to `.ai/plans/<name>/artifacts/<wave>-<task>-concerns.md`
2. If `parallel: false` → execute tasks sequentially
   - Before each task: read dependency artifacts
3. Read all artifact files directly after completion (never paraphrase agent responses)
4. Collect and surface agent concerns/worries to the user

### Agent feedback loop

Task agents are instructed to report:
- **Worries** — things that could go wrong, fragile patterns, missing edge cases
- **Optimizations** — better approaches they noticed during implementation
- **Risks** — security concerns, performance issues, architectural smells

These are collected from `*-concerns.md` artifacts and surfaced during the Learn phase. Critical concerns trigger ESCALATE.

### Coordinator responsibilities
- Reads all artifact files directly
- Advances state based on verification verdicts
- Retries failed tasks (max 3, then escalate)
- Never implements — only orchestrates
- Surfaces agent concerns to the user

### Subagent dispatch threshold
- For complex plans (3+ waves, parallel work): always use subagent dispatch
- For simple single-wave plans: inline execution is acceptable
- When in doubt, use subagent dispatch (clean context prevents quality degradation)

---

## Phase 6: Verify

Dispatch plan-verifier agent for isolated, unbiased verification.

### Why isolated
The verifier must NOT share context with the builder. If the same Claude instance builds and verifies, confirmation bias from the build phase influences the verdict.

### plan-verifier agent interface contract (PC-D03)

**Isolation guarantee:** The coordinator reads output files and passes content into the agent. The agent receives a self-contained package with no access to read additional files beyond what's provided. This is the only way to guarantee context isolation.

**Input schema:**
```yaml
plan_verifier_input:
  wave: {N}
  verification_contract:
    - "{concrete requirement 1}"
    - "{concrete requirement 2}"
  task_descriptions:
    - id: "{task_id}"
      name: "{task_name}"
      files_written: ["{file1}", "{file2}"]
  output_files:
    - path: "{file_path}"
      content: "{file content — read by coordinator, passed to agent}"
  state_yml_snapshot:
    wave_status: "in_progress"
    task_statuses: {"{task_id}": "completed"}
    current_phase: "{wave_name}"
    updated_at: "{timestamp}"
  is_final_wave: true|false
  acceptance_criteria: ["{only included if is_final_wave}"]
```

**Output schema:**
```yaml
plan_verifier_output:
  wave: {N}
  stage_1:
    status: pass|fail
    checks:
      file_existence: { status: pass|fail, missing: [] }
      schema_presence: { status: pass|fail|skipped, issues: [] }
      non_empty: { status: pass|fail, empty_files: [] }
      file_ownership: { status: pass|fail, violations: [] }
      state_consistency: { status: pass|fail, issues: [] }
  stage_2:
    status: pass|pass_with_notes|fail|skipped
    findings:
      - area: "{content quality|cross-wave consistency|completeness}"
        severity: info|warning|critical
        detail: "{description}"
        fix_required: true|false
  verdict: pass|pass_with_warnings|fail
  concerns: ["{any risks or quality issues noticed}"]
```

### Stage 1: Spec compliance (mechanical)

Six checks. All must pass.

1. **File existence** — every declared output file exists on disk
   - Section refs (`file.yml#section`): parent file must exist
   - Globs (`dir/*`): at least one match must exist
2. **Schema presence** — YAML files parse with expected top-level keys
3. **Non-empty** — no stubs, placeholders, empty values, or TODO-only content
4. **File ownership** — tasks only wrote to declared files; read-only files unmodified
5. **State consistency** — state.yml matches actual wave execution state

### Stage 2: Quality review (judgment)

Only runs when Stage 1 passes AND wave has `qa_review: true` (always true for final wave).

- Content matches task description and verification contract?
- Cross-wave consistency (naming, references)?
- Completeness (edge cases, ready for next wave)?
- Acceptance criteria check (final wave only)?

### Output format

```yaml
verification:
  wave: 1
  stage_1:
    status: pass | fail
    checks:
      file_existence: { status: pass|fail, missing: [] }
      schema_presence: { status: pass|fail|skipped, issues: [] }
      non_empty: { status: pass|fail, empty_files: [] }
      file_ownership: { status: pass|fail, violations: [] }
      state_consistency: { status: pass|fail, issues: [] }
  stage_2:
    status: pass | pass_with_notes | fail | skipped
    findings: []
  verdict: pass | pass_with_warnings | fail
```

### Failure handling
- Minor failure: fix and re-verify within the wave (max 3 rounds)
- Major failure: record as learning, move to Learn phase
- After 3 failed re-runs: escalate to manual review

### Error logging

On any failure, append to state.yml errors array:
```yaml
errors:
  - timestamp: "{iso8601}"
    phase: "verify/wave-1"
    error: "file_existence: skills/a/SKILL.md missing"
    attempted_fix: "pending"
    result: "unresolved"
    next_approach: "Rebuild skill A"
```

Before re-running, check prior errors to avoid repeating failed approaches.

### Phase checkpoints

If `checkpoint: true` on the wave:
1. Display what the wave accomplished
2. Present three options: **Continue** / **Revise** / **Abort**
3. Do NOT proceed until the user explicitly selects Continue
4. If no checkpoint flag, advance automatically

---

## Phase 7: Learn

Record what happened and prepare for the next cycle.

### Process
1. For each notable outcome (success, surprise, failure, discovery):
   - Create a learnings.yml entry with type, content, impact, status
   - Corrections must reference what they correct (supersedes field)
2. **Error-to-instinct feedback (PC-D10):** check state.yml errors for recurring patterns. If an error pattern appears across multiple waves or cycles, promote it to a constraint-type learning with impact explaining the systemic issue.
3. **Collect agent concerns:** read `*-concerns.md` artifacts. Surface critical concerns to the user. Record non-critical concerns as observation-type learnings.
4. Check if any active learnings should be superseded by new findings
5. Update or add open_questions based on what was discovered
6. Record cycle_metrics entry:
   - tasks_planned, tasks_completed, classification, learnings_added, corrections_made, wave_passed
7. **Doc-checkpoint:** run doc-checkpoint to verify documentation matches current state (CLAUDE.md counts, ecosystem.json, MEMORY.md). Plans that create or modify skills are the primary source of stale documentation.
8. Write next_orientation: guidance for the next orient phase
9. Increment `cycle` in state.yml
10. Update `remaining_goal` in state.yml

### Entry type guide
- **observation**: noticed a pattern or fact
- **constraint**: discovered a limitation
- **correction**: prior learning was wrong (must set `supersedes`)
- **discovery**: new insight that opens possibilities

### Quality rules
- Every cycle must produce at least one learning entry
- Content must be specific and actionable, not vague ("things went well")
- Impact must explain what this means for future planning
- Corrections MUST set supersedes to identify what they correct

---

## Loop Control (after Learn phase)

### Done conditions (checked in order of precedence)

**Primary check — done_signal:**
1. Execute the `done_signal` defined in state.yml:
   - `type: command` → run `target`, compare output/exit code against `expected`
   - `type: file_check` → read `target` file, check contents match `expected` pattern
   - `type: metric` → evaluate `target` metric against `expected` threshold
2. If done_signal passes → proceed to secondary checks
3. If done_signal fails → not done, continue looping

**Secondary checks (all must pass after done_signal):**
- All acceptance criteria verified (each criterion's `verification` check passes)
- All verification gates passed for completed waves
- No open_questions that block completion

**Sanity warning (non-blocking):**
- If `remaining_goal` is non-empty when done_signal + criteria pass, log a warning:
  "done_signal and all criteria passed but remaining_goal is non-empty — review whether remaining_goal is stale"
- This does NOT block completion — remaining_goal may be stale from a prior cycle

**Safety valve — done_signal misconfiguration:**
- Track consecutive cycles where all acceptance criteria pass but done_signal fails
- If this happens for 2+ consecutive cycles → ESCALATE with "done_signal may be misconfigured — all acceptance criteria pass but done_signal keeps failing"
- ESCALATE pauses for human input (same behavior as classifier ESCALATE)
- The human can fix the done_signal, override completion, or abort the plan
- Track the streak via `done_signal_fail_streak` counter in state.yml (reset to 0 when done_signal passes or any criterion changes status)

### Loop conditions
- done_signal has not passed, OR acceptance criteria have unverified entries
- max_cycles not reached
- No ESCALATE pending

### On done
- Set state.yml `status: done`
- Clear `remaining_goal`
- Final summary: cycles completed, learnings count, replans used
- Run final acceptance criteria verification (each criterion's verification check)

---

## Decision confidence boundaries

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

---

## Anti-patterns

1. **Hallucinated reflections compounding** — corrections must reference what they correct. Speculative reflections → observation, not correction.
2. **Over-structured memory filling context** — orient summarizes learnings, doesn't dump them raw.
3. **Plan oscillation** — max 2 replans, then escalate. Track replan_count.
4. **Sunk cost bias** — adversarial reflect prompts force fresh perspective.
5. **Infinite loop** — max_cycles safety valve.
6. **Losing progress on replan** — completed waves are never undone. Only future work is replanned.
7. **Context bloat** — only load active learnings. Superseded entries stay on disk, not in context.
8. **Builder-verifier contamination** — verification MUST use isolated agent. Never verify in build context.
9. **Vague goals causing drift** — goal clarity gate catches this by cycle 2 at latest.

---

## Session recovery

State persists across /compact and session breaks via `.ai/plans/{name}/` files.

### Recovery process
1. Read state.yml — get cycle, remaining_goal, planned_waves, errors
2. Read learnings.yml — get active learnings
3. Read plan.md — get implementation contract
4. Determine position:
   - **Mid-wave** (current wave has in_progress/pending tasks): resume wave execution, then continue learn → orient loop
   - **Between waves** (last wave completed): run orient phase, then continue the loop
5. Spot-check completed outputs still exist on disk (not full re-verification)
6. In-progress tasks → re-run. Completed tasks → keep.
7. Preserve cycle, remaining_goal, replan_count — never reset on recovery.

---

## Worked example

**Input goal:** "Consolidate the auth module from 3 files into 1"

**Cycle 1 — Orient:**
- Scans codebase: auth-middleware.ts, auth-utils.ts, auth-types.ts
- Acceptance criteria: "Single auth.ts file, all tests pass, no import changes in consumers"
- Goal clarity: PASS (measurable, scoped, concrete)

**Cycle 1 — Plan (wave 1):**
```yaml
tasks:
  - id: t1
    name: "Merge auth types and utils"
    files_written: ["src/auth.ts"]
    files_read: ["src/auth-types.ts", "src/auth-utils.ts"]
    model_tier: senior
  - id: t2
    name: "Update import paths in consumers"
    depends_on: ["t1"]
    files_written: ["src/routes/*.ts"]
    model_tier: senior
verification:
  contract:
    - "src/auth.ts exists and contains all types and utility functions"
    - "No file imports from auth-types.ts or auth-utils.ts"
    - "TypeScript compiles without errors"
```

**Cycle 1 — Build:** Dispatch t1, then t2 sequentially. Agent reports concern: "auth-utils.ts has a circular import with session.ts — needs careful handling."

**Cycle 1 — Verify:** plan-verifier checks contract. Pass.

**Cycle 1 — Learn:**
- Observation: "Circular import between auth-utils and session.ts resolved by moving session type to shared types"
- remaining_goal: "Delete old files, run full test suite"

**Cycle 2 — Reflect:** CONTINUE (wave passed, no assumptions changed)

**Cycle 2 — Plan (wave 2):**
- t3: Delete old files, run tests
- Verification: all tests pass, no references to deleted files

**Cycle 2 — Verify:** Pass. Acceptance criteria met. Done.

---

## Hook specifications (PC-D06)

### plan-verification-gate (bash, blocking PreToolUse)

**Event:** PreToolUse on Write|Edit
**Purpose:** Prevent advancing to next wave's files without current wave verification passing.

**Logic:**
1. Read the tool input to get the target file path
2. Find active plan: scan `.ai/plans/*/state.yml` for `status: in_progress`
3. If no active plan → exit 0 (allow)
4. Read plan.yml to get wave definitions with `files_written` per task
5. Determine which wave owns the target file
6. Read state.yml to get current wave and its verification status
7. **Allow if:** target file belongs to the current or a completed wave
8. **Block if:** target file belongs to a future wave whose predecessor hasn't been verified
9. **Allow if:** target file is not claimed by any wave (not plan-managed)

**Exit codes:**
- `exit 0` — allow the write
- `exit 2` — block the write (return JSON: `{"decision": "block", "reason": "..."}`)

**Edge cases:**
- Files claimed by multiple waves (section refs): check the specific section's wave
- Glob patterns in files_written: match against the glob
- No plan.yml found: allow (plan may have been cleaned up)

### plan-recovery (bash, SessionStart)

**Event:** SessionStart
**Purpose:** Detect interrupted plans and surface them so the user or autopilot can resume.

**Logic:**
1. Scan `.ai/plans/*/state.yml` for files with `status: in_progress`
2. For each active plan, read: plan name, cycle number, remaining_goal, last updated timestamp
3. Output a message listing active plans with their state
4. The hook does NOT resume plans — it only surfaces information

**Output format:**
```
Active plans detected:
  - {plan-name}: cycle {N}, remaining: {remaining_goal summary}
    Last updated: {timestamp}
    Resume with: /plan resume {plan-name}
```

**Exit code:** Always `exit 0` (informational only)

---

## Worked example 2: REPLAN scenario

**Input goal:** "Add rate limiting to all API endpoints"

**Cycle 1 — Orient:**
- Scans codebase: 12 API endpoints in src/routes/
- Acceptance criteria: "All endpoints rate-limited, tests pass, no latency regression > 5ms"

**Cycle 1 — Plan (wave 1):**
- t1: Implement rate limiter middleware using Redis
- t2: Add rate limit config per endpoint

**Cycle 1 — Build:** t1 completes, t2 completes.

**Cycle 1 — Verify:** Stage 1 passes. Stage 2 flags: "Redis dependency adds infrastructure complexity. Consider in-memory alternative."

**Cycle 1 — Learn:**
- Discovery: "Redis adds operational overhead — in-memory rate limiting sufficient for current scale"
- remaining_goal: "Wire middleware to all endpoints, add tests"

**Cycle 2 — Reflect:** plan-classifier returns REPLAN.
- Reasoning: "Redis-based rate limiter introduces unnecessary infrastructure dependency. In-memory approach is simpler and meets the same acceptance criteria at current scale."
- replan_count: 0 → 1

**Cycle 2 — Plan (wave 2, replanned):**
- t3: Replace Redis rate limiter with in-memory token bucket
- t4: Wire to all endpoints
- Verification: "All endpoints return 429 after limit, latency < 5ms overhead"

**Cycle 2 — Build + Verify:** Pass. Acceptance criteria met.

**Cycle 2 — Learn:**
- Correction: "In-memory rate limiting sufficient for current scale" (supersedes cycle 1 implicit assumption about needing Redis)
- Done. 2 cycles, 1 replan.
