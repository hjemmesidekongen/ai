# Implementation Plan: Subagent-Driven Execution

## Overview

**What it does:** Upgrades the task-planner execution engine to dispatch each task as an isolated subagent via Claude Code's `Task()` tool, with parallel dispatch for independent tasks and per-task commits for recoverability.

**Why:** The current `plan-execute` command runs all tasks inline in a single session. After many tool calls, context pollution degrades quality. Subagent dispatch gives each task a fresh context window — the implementer can't see previous tasks' accumulated state, and reviewers start neutral. This also enables true parallel execution when `wave.parallel == true`.

**Scope:** Changes to `packages/task-planner/` only. No changes to brand-guideline, seo-plugin, or shared/ — those plugins benefit automatically because they delegate execution to plan-execute.

**Dependencies:** None (builds on existing infrastructure).

**Origin:** Pattern analysis from [obra/superpowers](https://github.com/obra/superpowers) — specifically the `subagent-driven-development` and `dispatching-parallel-agents` skills. Adapted to our wave-based architecture, file-ownership system, and two-stage verification flow.

---

## Architecture

### Current Flow (single-agent, inline)

```
plan-execute (one Claude session)
  ├── Wave 1
  │   ├── task t1 (inline)  ──→  accumulated context
  │   ├── task t2 (inline)  ──→  more accumulated context
  │   └── verification (inline) ──→ even more context
  ├── Wave 2
  │   ├── task t3 (inline, carries all wave 1 context)
  │   └── verification (inline)
  └── ... context grows until /compact or session limit
```

### Target Flow (subagent dispatch)

```
plan-execute (orchestrator — stays lean)
  ├── Wave 1
  │   ├── Task("t1", model: sonnet)  ──→  fresh context, commits, exits
  │   ├── Task("t2", model: haiku)   ──→  fresh context, commits, exits
  │   ├── Task("spec-review-w1", model: haiku) ──→ reads commits, reports
  │   └── Task("qa-review-w1", model: opus)    ──→ only if required
  ├── Wave 2 (parallel: true)
  │   ├── Task("t3", model: sonnet) ─┐
  │   ├── Task("t4", model: sonnet) ─┤──→ dispatched in same turn (parallel)
  │   ├── Task("t5", model: haiku)  ─┘
  │   ├── Task("spec-review-w2", model: haiku)
  │   └── Task("qa-review-w2", model: opus)
  └── orchestrator stays under 20% context budget throughout
```

### Key Design Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | **Hybrid verification** | Per-task spec compliance (Haiku, cheap), per-wave quality review (Opus, expensive). Catches structural issues early without burning Opus tokens on every task. |
| 2 | **Model tier enforcement** | Orchestrator maps `model_tier` → `Task()` model param. `junior → haiku`, `senior → sonnet`, `principal → opus`. Currently documented but not enforced. |
| 3 | **Structured hybrid context** | Inline the control payload (SKILL.md ≤80 lines + task def + ownership). Point to reference payload (references/process.md, brand-reference.yml sections). Subagent reads pointed files itself. |
| 4 | **Per-task commits** | Each subagent commits before reporting back. Enables git-diff-scoped quality review and crash recovery. Essential for website development work. |
| 5 | **Orchestrator never executes tasks** | Orchestrator reads plan, dispatches, collects reports, writes state. It never does domain work itself. This keeps its context window lean across the entire plan. |
| 6 | **Single-agent fallback preserved** | `--mode single` continues to work as today (inline execution). Useful for debugging, small plans, or when Task() dispatch is overkill. |

---

## Data Flow

```
Orchestrator reads:
  ├── plan.yml (once at start — holds all task definitions in memory)
  ├── ownership.yml (once at start — maps task→owns/reads)
  └── state.yml (before each dispatch — checks errors, recovery notes)

Orchestrator inlines into Task() prompt:
  ├── Task definition (from plan)
  ├── File-ownership entry (owns/reads)
  ├── SKILL.md content (≤80 lines, from progressive disclosure)
  ├── Model tier + constraints
  ├── Error context (if retry — from state.yml errors array)
  └── Output format (structured task_complete YAML)

Subagent reads itself (pointed, not inlined):
  ├── references/process.md (detailed skill procedure)
  ├── Input files from "reads" list (prior wave outputs)
  ├── brand-reference.yml sections (if brand-dependent)
  └── findings.md (if skill uses research persistence)

Subagent produces:
  ├── Output files (to "owns" paths only)
  ├── Git commit (per-task, with descriptive message)
  └── Structured report (task_complete YAML block)

Orchestrator collects:
  ├── task_complete report from each subagent
  ├── commit SHA for quality review scoping
  └── Writes state.yml, dispatches next task/wave
```

---

## Prompt Templates

### Template 1: Worker Dispatch (`resources/prompts/worker-dispatch.md`)

This is the template the orchestrator fills and passes as the `Task()` prompt. Variables in `{{...}}` are replaced by the orchestrator at dispatch time.

```markdown
# Task {{task_id}}: {{task_name}}

## Your Assignment

{{task_definition_from_plan}}

## Skill Instructions

{{SKILL_MD_content}}

## File Ownership

**You MUST only write to these paths:**
{{#each owns}}
- {{path}}
{{/each}}

**You may read from:**
{{#each reads}}
- {{path}}
{{/each}}

## Before You Start

Read these files in order before beginning work:
{{#each read_list}}
- `{{path}}` — {{reason}}
{{/each}}

## Error Context
{{#if previous_errors}}
Previous attempt failed. Do NOT repeat the same approach.
- Error: {{error}}
- What was tried: {{attempted_fix}}
- Try instead: {{next_approach}}
{{else}}
No previous errors for this task.
{{/if}}

## Commit Your Work

When implementation is complete:
1. Stage only files in your ownership list
2. Commit with message: `{{plan_name}}: {{task_name}} [{{task_id}}]`
3. Note the commit SHA in your report

## Report Format

When done, output exactly this YAML structure:

\```yaml
task_complete:
  task_id: "{{task_id}}"
  model_tier: "{{model_tier}}"
  status: completed | failed | blocked
  commit_sha: "<the commit hash>"
  artifacts_written:
    - path: "<file path>"
      description: "<what this file contains>"
  decisions_made:
    - "<any judgment calls you made>"
  recovery_notes: |
    <brief description of what you did, key decisions,
     and context the next task might need>
  error: "<only if status is failed or blocked>"
  needs: "<only if status is blocked>"
\```

## Rules

1. Only write to files in your ownership list — violations will be caught
2. Do not evaluate the quality of your own output — reviewers handle that
3. If blocked, report honestly — do not produce placeholder output
4. Commit before reporting — your commit is the deliverable
```

### Template 2: Spec Review Dispatch (`resources/prompts/spec-review-dispatch.md`)

Used per-task (when per-task verification is enabled) or per-wave.

```markdown
# Spec Compliance Review: {{scope_description}}

## What Was Requested

{{#each tasks}}
### Task {{task_id}}: {{task_name}}
{{task_definition}}
**Expected outputs:** {{files_written}}
{{/each}}

## What Was Built

{{#each task_reports}}
### Task {{task_id}} — Implementer Claims:
- Status: {{status}}
- Commit: {{commit_sha}}
- Artifacts: {{artifacts_written}}
{{/each}}

## CRITICAL: Do Not Trust the Reports

Read the ACTUAL files on disk. Verify:
1. **File existence** — every expected output file exists
2. **Non-empty** — files have real content, not placeholders
3. **Schema presence** — YAML files have required sections
4. **File ownership** — only wrote to owned paths (check git diff)
5. **State consistency** — state.yml reflects current progress

For each task, run: `git diff --stat {{base_sha}}..{{commit_sha}}`

## Output Format

\```yaml
spec_compliance:
  scope: "{{scope_description}}"
  reviewed_at: "<ISO timestamp>"
  tasks:
    {{task_id}}:
      status: pass | fail
      checks:
        file_existence: { status: pass|fail, missing: [...] }
        non_empty: { status: pass|fail, empty: [...] }
        schema_presence: { status: pass|fail, missing_sections: [...] }
        file_ownership: { status: pass|fail, violations: [...] }
      issues: [{ file: "...", line: N, issue: "..." }]
  overall: pass | fail
  summary: "<one line>"
\```
```

### Template 3: Quality Review Dispatch (`resources/prompts/quality-review-dispatch.md`)

Used per-wave (after spec compliance passes).

```markdown
# Quality Review: Wave {{wave_number}}

## What Was Implemented

{{wave_summary}}

## Git Diff Scope

```
BASE_SHA: {{wave_base_sha}}
HEAD_SHA: {{wave_head_sha}}
```

Run `git diff --stat {{wave_base_sha}}..{{wave_head_sha}}` to see all changes.
Then `git diff {{wave_base_sha}}..{{wave_head_sha}}` for full diff.

## Review Checklist

1. **Content Coherence** — do values make sense together?
2. **Domain Consistency** — does output align with brand/project context?
3. **Completeness** — are there gaps that pass schema but represent thin work?
4. **Quality Floor** — is content professional and specific, not generic?
5. **Cross-Skill Alignment** — do outputs build on earlier decisions correctly?

## Plan Context
{{#if plan_requirements}}
{{plan_requirements}}
{{/if}}

## Stage 1 Report
{{stage1_report_summary}}

## Output Format

\```yaml
qa_report:
  wave: {{wave_number}}
  reviewed_at: "<ISO timestamp>"
  review_round: {{round}}
  base_sha: "{{wave_base_sha}}"
  head_sha: "{{wave_head_sha}}"
  checks:
    - name: "<check name>"
      status: pass | fail | pass_with_notes
      notes: "<specific findings with file:line references>"
      fix_required: true | false
      severity: critical | important | minor
  verdict: PASS | PASS_WITH_NOTES | FAIL
  blocking_issues: <count>
  strengths: [<what was done well>]
  recommendations: [<non-blocking suggestions>]
\```
```

---

## Schema Changes

### Plan Schema Addition (`resources/plan-schema.yml`)

Add to the `tasks` items:

```yaml
      base_sha:
        type: string
        required: false
        description: "Git SHA before this task's commit. Set by orchestrator after dispatch. Used to scope quality review diffs."

      commit_sha:
        type: string
        required: false
        description: "Git SHA of this task's commit. Set from worker's task_complete report."
```

Add to root level:

```yaml
  execution_mode:
    type: string
    required: false
    enum: [inline, subagent]
    default: subagent
    description: "How tasks are dispatched. 'subagent' uses Task() tool per task. 'inline' runs in the orchestrator's session (legacy single-agent mode)."
```

### State Schema Addition (`resources/state-schema.yml`)

Add to `phases` items:

```yaml
      commit_range:
        type: object
        required: false
        description: "Git commit range for this phase, used by quality reviewer"
        properties:
          base_sha:
            type: string
            required: true
          head_sha:
            type: string
            required: true
```

---

## Model Tier Mapping

The orchestrator maps `model_tier` to the `model` parameter on each `Task()` call:

| model_tier | Task() model | Use case | Token cost |
|-----------|-------------|----------|------------|
| `junior` | `haiku` | Scaffolding, templated output, spec compliance review | Lowest |
| `senior` | `sonnet` | Content generation, implementation, reasoning | Medium |
| `principal` | `opus` | Architecture, QA review, cross-cutting decisions | Highest |

The worker-agent already reads and surfaces `model_tier` in its report. The change is that the orchestrator now **acts** on it when building the `Task()` call.

---

## Implementation Steps

### Phase 1: Prompt Templates (foundation)

#### Step 1: Create prompt templates directory and files

Create `packages/task-planner/resources/prompts/` with three templates:

| File | Purpose | Size |
|------|---------|------|
| `worker-dispatch.md` | Worker subagent prompt template | ~80 lines |
| `spec-review-dispatch.md` | Per-task/per-wave spec review template | ~60 lines |
| `quality-review-dispatch.md` | Per-wave quality review template | ~50 lines |

Content as specified in the Prompt Templates section above.

**Verification:** Templates exist, contain all `{{variable}}` placeholders, follow the structured hybrid pattern (inline control, point to references).

---

### Phase 2: Schema Updates

#### Step 2: Update plan-schema.yml

Add `base_sha` and `commit_sha` fields to task items. Add `execution_mode` field to plan root.

**Files modified:**
- `packages/task-planner/resources/plan-schema.yml`

**Verification:** YAML parses cleanly. New fields are optional (backward-compatible with existing plans).

#### Step 3: Update state-schema.yml

Add `commit_range` object to phase items.

**Files modified:**
- `packages/task-planner/resources/state-schema.yml`

**Verification:** YAML parses cleanly. New fields are optional.

---

### Phase 3: Execution Engine (core change)

#### Step 4: Rewrite plan-execute Step 4b — Task Dispatch

This is the central change. Replace the current inline execution loop with subagent dispatch logic.

**Current (step 4b in plan-execute.md):**
```
for each task_id in wave.tasks:
  1. Read the task definition
  2. Read the ownership entry
  3. Load domain instructions
  4. Execute the task (inline)
  5. Update task status
```

**New (step 4b in plan-execute.md):**
```
Subagent mode (default):
  1. Record wave_base_sha = current HEAD
  2. For each task in wave:
     a. Read task definition + ownership entry
     b. Read the task's SKILL.md (≤80 lines)
     c. Check state.yml errors for previous attempts
     d. Fill worker-dispatch.md template with task context
     e. Record task_base_sha = current HEAD
     f. Dispatch Task() with:
        - description: "Task {id}: {name}"
        - prompt: filled template
        - model: model_tier_map[task.model_tier]
        - subagent_type: "general-purpose"
     g. Collect task_complete report
     h. Record task.commit_sha from report
     i. Update task status in plan
     j. If status == failed: handle failure (see Step 4b-fail)
  3. Record wave_head_sha = current HEAD

  If wave.parallel == true:
     Dispatch all Task() calls in step 2f simultaneously (same turn)
     Collect all reports before proceeding

  If wave.parallel == false:
     Dispatch Task() calls sequentially (wait for each before next)

Inline mode (--mode single):
  [preserve current behavior unchanged]
```

**Files modified:**
- `packages/task-planner/commands/plan-execute.md` — step 4b rewrite + new step 2 mode logic

**New execution modes:**

```
if --mode is "single":
  mode = inline          # legacy behavior, no subagents
elif --mode is "subagent":
  mode = subagent        # new default
elif --mode is "auto":
  mode = subagent        # subagent is now the default for auto
```

The `multi` mode (Agent Teams) is removed — it was experimental and never worked reliably. Subagent mode via `Task()` replaces it.

**Verification:** Plan-execute loads a test plan, dispatches one task via Task(), receives task_complete report, updates state correctly.

#### Step 5: Add per-task spec compliance dispatch

After each task completes (or after all tasks in a parallel wave), dispatch a spec-compliance-reviewer subagent.

**Current:** Spec compliance runs per-wave, inline, after all tasks complete.

**New:** Spec compliance runs after each task commit (sequential waves) or after all parallel tasks complete (parallel waves). Dispatched as a Haiku subagent.

```
After task(s) complete:
  1. Fill spec-review-dispatch.md template with:
     - Task definitions and expected outputs
     - Implementer task_complete reports
     - base_sha and commit_sha per task
  2. Dispatch Task() with:
     - model: haiku
     - subagent_type: "general-purpose"
  3. Collect spec_compliance report
  4. If overall == fail:
     - Mark phase → failed_spec
     - Log to state.yml errors
     - Enter fix-and-retry (Step 5 in current plan-execute)
  5. If overall == pass:
     - Proceed to quality review gate (unchanged)
```

**Files modified:**
- `packages/task-planner/commands/plan-execute.md` — step 4c updated
- `packages/task-planner/skills/verification-runner/SKILL.md` — updated to dispatch via Task()

**Verification:** Spec review catches a deliberate file-ownership violation; catches a missing output file.

#### Step 6: Add git-scoped quality review dispatch

Quality review now receives `BASE_SHA..HEAD_SHA` for the wave, not just file paths.

**Files modified:**
- `packages/task-planner/commands/plan-execute.md` — step 4c quality review section
- `packages/task-planner/agents/qa-agent.md` — add git diff instructions to review protocol
- `packages/task-planner/skills/verification-runner/SKILL.md` — updated dispatch
- `packages/task-planner/skills/verification-runner/references/process.md` — updated procedures

**Verification:** QA agent receives and uses commit range; review is scoped to wave changes only.

---

### Phase 4: Worker Agent Update

#### Step 7: Update worker-agent.md for subagent execution

The worker agent template needs to be updated to work as a true subagent (not just a behavioral prompt for inline execution).

**Changes:**
- Add commit protocol (stage owned files, commit with plan-name prefix, report SHA)
- Add structured report format matching the template
- Add self-review checklist (completeness, ownership compliance, output non-empty) — this is a pre-flight before the formal spec review, not a replacement for it
- Add "Before You Begin" section for Q&A (subagent can ask questions before starting)
- Remove references to "single-agent mode" inline behavior (preserved in legacy mode only)

**Files modified:**
- `packages/task-planner/agents/worker-agent.md`

**Verification:** Worker agent template has commit protocol, report format, self-review checklist.

---

### Phase 5: Orchestrator State Management

#### Step 8: Update state.yml management for subagent flow

The orchestrator is the sole writer of state.yml — subagents never touch it. This is already true today but needs to be explicit in the subagent flow.

**Changes to plan-execute.md:**
- Before each dispatch: record `base_sha`, update task status → `in_progress`
- After each dispatch: read `task_complete` report, update task status, record `commit_sha`
- After wave: write `commit_range` to phase, update `completed_waves`
- On failure: append to `errors` array with context from the failed subagent's report

**Files modified:**
- `packages/task-planner/commands/plan-execute.md` — steps 4a, 4b, 4e

**Verification:** state.yml has commit_range after wave completion. Error entries have correct context from subagent reports.

---

### Phase 6: Parallel Dispatch

#### Step 9: Implement parallel wave dispatch

When `wave.parallel == true`, dispatch all tasks in a single turn.

**Logic:**
```
if wave.parallel == true AND mode == subagent:
  1. Build Task() calls for ALL tasks in the wave
  2. Issue all Task() calls in a single response (Claude Code runs them concurrently)
  3. Wait for ALL to return
  4. Collect all task_complete reports
  5. Check for conflicts:
     - Run check-file-conflicts.sh against actual written files
     - If conflict detected: log error, enter fix-and-retry
  6. Run spec compliance on all tasks together
  7. Proceed to quality review gate
```

**Failure handling in parallel waves:**
- If one task fails and others succeed: mark failed task, check if it blocks later waves
  - If blocking: fail the wave, enter fix-and-retry for the failed task only
  - If non-blocking: continue, report failure at wave end
- If multiple tasks fail: fail the wave, report all failures

**Files modified:**
- `packages/task-planner/commands/plan-execute.md` — step 4b parallel path

**Verification:** Two independent tasks dispatched simultaneously, both complete, no file conflicts.

---

### Phase 7: Plugin Blueprint & Generator Updates

#### Step 10: Update plugin-blueprint.md

Add Section 15: "Subagent Execution" documenting:
- How plugins benefit from subagent dispatch (automatic — plan-execute handles it)
- How to write SKILL.md files that work well as subagent context (keep ≤80 lines, put detail in references/)
- Per-task commit expectations
- Model tier selection guidance for plugin designers

**Files modified:**
- `packages/task-planner/resources/plugin-blueprint.md`

#### Step 11: Update plugin generators

Update the generators so that NEW plugins get subagent-aware structure:
- `plugin-execution-guide-generator` — per-skill prompts mention subagent dispatch, include commit instructions
- `plugin-spec-generator` — tasks include commit expectations
- `plugin-scaffolder` — no structural changes needed (progressive disclosure already creates the right SKILL.md/references split)

**Files modified:**
- `packages/task-planner/skills/plugin-execution-guide-generator/SKILL.md`
- `packages/task-planner/skills/plugin-execution-guide-generator/references/process.md`
- `packages/task-planner/skills/plugin-spec-generator/SKILL.md`
- `packages/task-planner/skills/plugin-spec-generator/references/process.md`

---

### Phase 8: Integration Testing

#### Step 12: End-to-end test — sequential subagent dispatch

Create `packages/task-planner/tests/subagent-sequential-test.md`:

1. Create a minimal 2-wave plan (wave 1: 1 task, wave 2: 1 task dependent on wave 1)
2. Execute with `--mode subagent`
3. Verify:
   - Task 1 dispatched as subagent, receives correct context
   - Task 1 commits, reports task_complete with SHA
   - Spec review dispatched as Haiku subagent, passes
   - State.yml updated with commit_range
   - Task 2 dispatched, can read Task 1's output
   - Quality review dispatched at final wave with correct SHA range
   - Plan completes, all state correct

#### Step 13: End-to-end test — parallel subagent dispatch

Create `packages/task-planner/tests/subagent-parallel-test.md`:

1. Create a plan with a parallel wave (2 tasks, non-overlapping file ownership)
2. Execute with `--mode subagent`
3. Verify:
   - Both tasks dispatched in same turn
   - Both complete without file conflicts
   - Spec review covers both tasks
   - State.yml has correct commit range spanning both commits

#### Step 14: End-to-end test — failure and retry

Create `packages/task-planner/tests/subagent-failure-test.md`:

1. Create a plan where one task will fail spec compliance (e.g., missing required output)
2. Execute with `--mode subagent`
3. Verify:
   - Spec review catches failure, marks `failed_spec`
   - Error logged to state.yml with context from subagent report
   - Fix-and-retry dispatches new subagent with error context
   - Second attempt succeeds
   - Quality review not invoked until spec passes

#### Step 15: End-to-end test — model tier enforcement

Create `packages/task-planner/tests/subagent-model-tier-test.md`:

1. Create a plan with tasks at each tier: junior, senior, principal
2. Execute with `--mode subagent`
3. Verify:
   - Junior task dispatched with `model: haiku`
   - Senior task dispatched with `model: sonnet`
   - Principal task dispatched with `model: opus`
   - Worker reports surface correct model_tier

---

## Build Order

```
Phase 1: Prompt Templates          ← Steps 1          (no dependencies)
Phase 2: Schema Updates            ← Steps 2-3        (no dependencies)
Phase 3: Execution Engine          ← Steps 4-6        (depends on Phase 1, 2)
Phase 4: Worker Agent Update       ← Step 7           (depends on Phase 1)
Phase 5: State Management          ← Step 8           (depends on Phase 3)
Phase 6: Parallel Dispatch         ← Step 9           (depends on Phase 3)
Phase 7: Blueprint & Generators    ← Steps 10-11      (depends on Phase 3)
Phase 8: Integration Testing       ← Steps 12-15      (depends on all above)
```

Phases 1 and 2 can run in parallel (no dependencies).
Phases 4 and 5 can run in parallel (both depend on Phase 3 but not each other).
Phase 6 and 7 can run in parallel.

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Task() tool overhead per dispatch | Medium — more API calls | Only use subagent mode for plans with 3+ tasks. `--mode single` preserved for simple plans. |
| Subagent reads wrong file version | Low — file ownership prevents concurrent writes | Ownership registry already handles this. Parallel tasks have non-overlapping owns. |
| Commit conflicts in parallel waves | Low | File-ownership + check-file-conflicts.sh pre-flight. Post-hoc check after parallel completion. |
| Orchestrator context still grows | Low — only accumulates reports | Reports are structured YAML (~20 lines each). Even a 20-task plan adds ~400 lines of reports — well within budget. |
| Subagent fails to commit | Medium — breaks SHA-scoped review | Worker template has explicit commit instructions. Spec review checks for commit existence. Fallback: skip SHA-scoped review, fall back to file-based review. |
| Existing plugins break | None | All changes are in plan-execute dispatch logic. Plugins don't know or care whether they're executed inline or as subagents. The SKILL.md + references/ split already exists. |

---

## What This Does NOT Change

- **Plugin structure** — no changes to any plugin's files, skills, or commands
- **Wave decomposer** — wave planning logic unchanged
- **File ownership** — ownership resolution unchanged
- **Verification logic** — same two-stage flow, same checks, same verdicts
- **State schema** — additive only (new optional fields)
- **Plan schema** — additive only (new optional fields)
- **Single-agent mode** — preserved as `--mode single` for backward compatibility
- **Brainstorm flow** — unchanged
- **Version/migration system** — unchanged

---

## Success Criteria

1. A 4-wave brand-generate plan executes with each task as a separate subagent
2. Each subagent gets fresh context (no accumulated state from previous tasks)
3. Parallel waves dispatch tasks simultaneously
4. Model tier is enforced (junior→haiku, senior→sonnet, principal→opus)
5. Per-task commits enable SHA-scoped quality review
6. `--mode single` continues to work identically to current behavior
7. Existing brand-guideline and seo-plugin plans execute without modification
8. Spec compliance catches a deliberate failure; fix-and-retry resolves it
9. Orchestrator context stays lean (reports only, no domain content)
