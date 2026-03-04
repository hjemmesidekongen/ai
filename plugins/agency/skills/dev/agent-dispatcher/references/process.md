# Agent Dispatcher — Detailed Process

## Overview

The agent dispatcher is Phase 3 of /agency:build. It reads the wave plan produced
by team-planner, dispatches specialist agents via Task() with appropriate model
tiers, manages parallel vs sequential wave execution, and collects structured
reports. The orchestrator never does domain work itself — it only dispatches,
collects, and updates state.

## Prerequisites

Before starting, verify:
1. `.ai/projects/[name]/project-state.yml` has a populated `wave_plan` section
2. `wave_plan.waves` has at least 1 wave with assigned tasks
3. Every task has: id, description, assigned_agent, model_tier, files_owned
4. If wave_plan is missing, report error and suggest running team-planner first

## Step 1: Load Wave Plan and Prepare Context

```
Read project-state.yml → wave_plan (waves, tasks, file_ownership)
Read project-state.yml dev module → conventions, frameworks, structure
Read knowledge/*.yml → filter by tags relevant to each task's component

For each wave:
  Record wave.parallel flag
  For each task in wave:
    Collect: task definition, agent role, file ownership, relevant knowledge
```

**Save loaded context summary to findings.md (2-Action Rule checkpoint).**

## Step 2: Build Dispatch Prompts

For each task, construct the dispatch prompt using the worker-dispatch template:

```
Prompt includes:
  1. Task definition:
     - id, description, component
     - Acceptance criteria (from decomposition)
  2. Agent role and responsibilities:
     - assigned_agent name from team-planner output.
       Consolidated agent names: frontend-worker, backend-worker,
       project-manager, software-architect, frontend-tech-lead,
       backend-tech-lead, qa-lead, security-reviewer, devops,
       ux-qa, design-ux, documentation-specialist
     - The model_tier field (junior/senior/principal) on the task
       determines WHICH model the agent runs at — not which agent file
       to use. All domain variants (junior/senior/principal frontend,
       backend, etc.) are served by the two consolidated worker agents:
       frontend-worker and backend-worker.
     - Agent capabilities and constraints
  3. File ownership:
     - "You MUST only write to these paths:" [files_owned list]
     - "You may read from:" [dependent task outputs, knowledge files]
  4. Relevant knowledge:
     - Tag-filtered knowledge entries from knowledge/*.yml
     - Architecture knowledge (module boundaries, data flow)
  5. Dev-config conventions:
     - Coding standards from project-state.yml dev module conventions section
     - Framework-specific patterns
  6. Brand context (if applicable):
     - Loaded via brand-loader skill when task involves UI/brand work
     - Include brand tokens, typography, color palette for frontend tasks
  7. Error context (if retry):
     - Previous failure details from project-state.yml errors array
     - "Do NOT repeat: [previous approach]"
     - "Try instead: [suggested alternative]"
  8. Commit protocol:
     - Stage only owned files
     - Commit message: "[plan_name]: [task_description] [task_id]"
  9. Report format:
     - task_complete YAML block (see Report Collection)
```

## Step 3: Map Model Tiers to Dispatch Parameters

```
Tier mapping (from task.model_tier field set by tech lead during team-planner):
  junior    → model: "haiku"   (cheapest, simple/repetitive tasks)
  senior    → model: "sonnet"  (standard, most feature work)
  principal → model: "opus"    (complex, architectural decisions)

The tech lead (frontend-tech-lead or backend-tech-lead) assigns model_tier
during Wave 0 planning using the risk assessment heuristics in team-planner.
Workers receive their assigned tier in the dispatch prompt and run at that tier.

Self-tiering flow (workers that perform their own risk assessment):
  1. Dispatch at Haiku with tier-assigner skill context included in prompt
  2. Agent evaluates task complexity factors and declares required tier
  3. If declared tier > junior: re-dispatch at declared tier
  4. If declared tier == junior: task is already running at correct tier

Note: There are NO separate junior-frontend, senior-backend, etc. agent files.
All frontend execution uses agents/frontend-worker.md; all backend execution
uses agents/backend-worker.md. Tier is a runtime dispatch parameter, not an
agent identity.
```

## Step 4: Execute Waves

Process waves in strict sequence (wave 1, then wave 2, etc.):

```
For each wave:
  1. Record base_sha = git rev-parse HEAD

  2. If wave.parallel == true AND wave has 2+ tasks:
     - Dispatch ALL tasks in the wave simultaneously
     - Use multiple Task() calls in the same turn
     - Wait for all tasks to complete
     - Collect all reports

  3. If wave.parallel == false OR wave has 1 task:
     - Dispatch tasks one at a time
     - Wait for each task to complete before dispatching the next
     - Collect report after each task

  4. For each Task() dispatch:
     - Set model parameter based on tier mapping
     - Include full dispatch prompt
     - Set task description for identification

  5. After all tasks in wave complete:
     - Record head_sha = git rev-parse HEAD
     - Update execution.commit_range for this wave
     - Update execution.current_wave

  6. Save dispatch records and reports to findings.md
     (2-Action Rule: save after every 2 dispatches)
```

## Step 5: Collect Subagent Reports

Each subagent returns a structured task_complete report:

```yaml
task_complete:
  task_id: "[from dispatch]"
  model_tier: "[actual tier used]"
  status: "completed | failed | blocked"
  commit_sha: "[the commit hash]"
  artifacts_written:
    - path: "[file path]"
      description: "[what this file contains]"
  decisions_made:
    - "[any judgment calls]"
  recovery_notes: |
    Brief description of what was done, key decisions,
    and context the next task might need.
  error: "[only if status is failed or blocked]"
  needs: "[only if status is blocked]"
```

**Processing reports:**

```
For each report:
  1. Parse the task_complete YAML from the subagent output
  2. Verify commit_sha exists (run git log --oneline -1 [sha] to confirm)
  3. Record in execution.dispatched_tasks:
     - task_id, agent, tier
     - dispatched_at, completed_at timestamps
     - status (from report)
     - report object (files_changed, tests_passed, lint_passed, build_passed, notes)
  4. If status == "failed":
     - Log failure to project-state.yml errors array
     - Check if re-dispatch is possible (tier escalation)
     - If task failed at junior → re-dispatch at senior
     - If task failed at senior → re-dispatch at principal
     - If task failed at principal → mark as blocked, alert PM
  5. If status == "blocked":
     - Record blocking reason
     - Check if blocking dependency can be resolved
     - If not: mark wave as blocked, alert PM
```

**Save reports to findings.md (2-Action Rule checkpoint).**

## Step 6: Handle Failures and Escalation

```
When a task fails:
  1. Read project-state.yml errors array for previous failures on this task
  2. If first failure:
     - Log error with timestamp, skill, error message
     - Escalate tier: junior → senior, senior → principal
     - Re-dispatch with error context included in prompt
  3. If second failure (already escalated once):
     - Escalate again if possible (senior → principal)
     - Include both previous error contexts
  4. If third failure or already at principal:
     - Mark task as "blocked"
     - Record: { tier: "blocked", reason: "Failed at maximum tier" }
     - Present to user:
       "Task [id] has failed at all tiers.
        Last error: [message]
        Files affected: [list]
        Options:
        a) Provide guidance and retry
        b) Skip this task and continue
        c) Abort the build"
     - Wait for user decision

When a wave is partially failed:
  - Completed tasks are kept (commits are preserved)
  - Only failed tasks are re-dispatched
  - Independent tasks in the next wave may still proceed if they
    don't depend on the failed task
```

## Step 7: Update Execution State

Write the `execution` section of `.ai/projects/[name]/project-state.yml`:

```yaml
execution:
  status: "running"  # running | completed | failed | blocked
  current_wave: [number]
  dispatched_tasks:
    - task_id: "[id]"
      agent: "[assigned_agent]"
      tier: "[junior|senior|principal]"
      dispatched_at: "[ISO 8601]"
      completed_at: "[ISO 8601]"
      status: "[running|completed|failed]"
      report:
        files_changed:
          - "[path]"
        tests_passed: true|false
        lint_passed: true|false
        build_passed: true|false
        notes: "[subagent notes]"
  commit_range:
    base_sha: "[SHA from before wave 1]"
    head_sha: "[SHA after last completed task]"
```

Also update:
- `build.status` → "executing"
- `build.current_phase` → 3
- `meta.updated_at` → current timestamp

## Step 8: Wave Completion and Handoff

After all waves are dispatched and reports collected:

```
1. Verify all tasks have terminal status (completed or failed)
2. Count: [completed] completed, [failed] failed
3. If any failed tasks remain:
   - execution.status = "failed"
   - Report failures to user with options
4. If all tasks completed:
   - execution.status = "completed"
   - Record final commit_range (base_sha of wave 1 → HEAD after last wave)
5. Update build.current_phase → 4 (ready for review)
6. Present summary:

   "## Execution Complete

   Waves: [N] executed
   Tasks: [completed]/[total] completed
   Failed: [count] (if any)
   Commit range: [base_sha]..[head_sha]

   Tier usage:
   - Haiku (junior): [count] tasks
   - Sonnet (senior): [count] tasks
   - Opus (principal): [count] tasks

   Ready for Phase 4 (review). Run /agency:build to continue."
```

**Save final state to findings.md (2-Action Rule checkpoint).**

## Error Handling

When errors occur during dispatch:

1. **Task() dispatch failures:** Log to project-state.yml errors array. Retry once with
   simplified prompt (fewer knowledge entries). If retry fails, mark task as
   failed and continue with remaining tasks.

2. **Subagent timeout:** If a Task() call does not return within expected time,
   check if the subagent committed any work (git log). If partial commit exists,
   record it and re-dispatch for remaining work. If no commit, re-dispatch fully.

3. **Report parsing failures:** If subagent output doesn't contain valid
   task_complete YAML, attempt to extract key fields (status, commit_sha) from
   unstructured output. If extraction fails, mark task as failed with
   "report_parse_error".

4. **File ownership violations:** If a subagent modifies files outside its
   ownership list (detected by comparing commit diff against files_owned),
   log warning but do not revert. Flag for code review in Phase 4.

5. **Before retrying:** Always check project-state.yml errors array for previous
   failed attempts. Never repeat the same approach.

## Commit Protocol

**Subagent mode** (dispatched via Task()):
1. Stage only project-state.yml and findings.md updates
2. Commit: `[plan_name]: agent-dispatcher [task_id]`
3. Report commit SHA in task_complete

**Inline mode:** Commit after verification passes with descriptive message.

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- project-state.yml execution section exists and is non-empty
- execution.dispatched_tasks has at least 1 entry
- Every dispatched task has non-empty: task_id, agent, tier, status
- Every completed task has a non-empty commit_sha
- Every completed task report has non-empty files_changed array
- execution.current_wave matches the last completed wave
- execution.commit_range.base_sha and head_sha are populated

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Tier mapping is correct (junior→haiku, senior→sonnet, principal→opus)
- Dispatch prompts included proper file ownership constraints
- Reports are complete and internally consistent
- Failed tasks have error context and escalation records
- Commit range covers all dispatched work

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.

## Example Loading Protocol

This section covers how to load tag-filtered code examples from framework packs
when building dispatch prompts in Step 2 (after loading knowledge entries).

### 1. Determine Relevant Framework Packs

Read the dev module in project-state.yml to identify which framework packs are
active. Then map the current task's domain to relevant packs:

```
If task involves frontend (UI components, pages, styling):
  Relevant packs: react-nextjs, typescript, tailwind, generic

If task involves backend (API routes, services, database):
  Relevant packs: typescript, prisma, generic

If task involves testing (unit, integration, E2E):
  Relevant packs: testing, generic

If task involves both frontend and backend:
  Relevant packs: all active packs
```

Framework pack examples live at:
`plugins/dev/framework-packs/[pack-name]/examples/`

Available packs: react-nextjs, typescript, tailwind, prisma, testing, generic

### 2. Scan and Parse Example Headers

For each example file in the relevant packs, read the comment header and
extract the Tags line:

```
Example header format:
  /**
   * Example: [title]
   * Pack: [pack-name]
   * Tags: react, nextjs, server-component, data-fetching
   * ...
   */

Parse Tags line → split on comma + trim whitespace → tag set
```

### 3. Match Examples to Task

Extract matching signals from the task definition:
- Keywords from task description (e.g. "server component", "data fetching")
- Component name (e.g. "ProductList", "AuthForm")
- Framework hints from dev module conventions in project-state.yml

Match rule: include an example when 2 or more of its tags match the task
context (description keywords + component name + framework conventions).

```
Example: task description = "Build a server-side data fetching component"
  component = "ProductList"
  Tags [react, nextjs, server-component, data-fetching] → 2+ matches → INCLUDE
  Tags [prisma, schema, migration] → 0 matches → SKIP
```

### 4. Include Matched Examples in Dispatch Prompt

Add a "## Reference Examples" section to each dispatch prompt that has
matched examples:

```
## Reference Examples

The following examples are from the project's framework packs. Follow their
patterns for the relevant areas of this task.

### [example-filename.tsx] (pack: react-nextjs)

[full file content]

Note: Follow this pattern for server-component work in this project.

---

### [example-filename.ts] (pack: prisma)

[full file content]

Note: Follow this pattern for data-fetching work in this project.
```

Include the full file content of each matched example. Examples are designed
to be 50-100 lines each, keeping prompt overhead manageable.

### 5. Limit and Priority Rules

- **Maximum 3 examples per dispatch** to control prompt size.
- **Priority order** when more than 3 examples match:
  1. Most specific match first (highest number of matching tags)
  2. Most relevant pack second (pack whose domain most closely matches the
     task type — e.g. react-nextjs for frontend tasks)
  3. generic pack examples are lowest priority (used only as fallback when
     fewer than 3 domain-specific examples are available)

If no examples match (0 examples with 2+ tag matches), omit the
"## Reference Examples" section entirely. Do not include partial matches.

---

## Trace Protocol

If `state.yml` has `trace.enabled: true`, follow the
[trace protocol](../../../../resources/trace-protocol.md) to write a structured
trace file to `.ai/projects/[name]/traces/`.
