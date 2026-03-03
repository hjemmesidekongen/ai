---
name: agency:build
description: "Orchestrate the full 4-phase development pipeline — feature decomposition → wave planning → parallel agent dispatch → code review and QA validation"
arguments:
  - name: project
    description: "Project name (optional — defaults to active project)"
    required: false
  - name: feature-description
    description: "Natural language description of what to build (required for new builds)"
    required: false
  - name: --from
    description: "Resume from a specific phase: decompose | plan | execute | review"
    required: false
  - name: --wave
    description: "Resume from a specific wave number within the execute phase (e.g. --wave 3)"
    required: false
  - name: --dry-run
    description: "Decompose and plan only — write plan to project-state.yml and stop without executing"
    required: false
model_tier: senior
---

# /agency:build

Orchestrates the full 4-phase development pipeline for an agency project. Each phase feeds the next — decomposition produces components, planning produces a wave plan, execution dispatches specialist agents in parallel waves, and review audits the result.

## Usage

```
/agency:build "Add user authentication with JWT"
/agency:build blik "Redesign the dashboard"
/agency:build "Add payment integration" --dry-run
/agency:build "Add payment integration" --from execute
/agency:build "Add payment integration" --wave 3
```

## Phase Map

| Phase | Skill | Model | Checkpoint Type |
|-------|-------|-------|-----------------|
| decompose | feature-decomposer | principal | data_validation (5 checks) |
| plan | team-planner | principal | data_validation (4 checks) |
| execute | agent-dispatcher + completion-gate | senior + junior | code_quality_gate (per task) |
| review | code-review + qa-validation | senior + principal | code_quality_gate (6 checks) |

## Execution Steps

### Step 1: Determine Project

```
if first argument is a project name (no spaces, matches known project):
  project_name = first argument
  feature_description = remaining arguments
else:
  Read .ai/agency.yml → use active project
  If no agency.yml: "No agency registry found. Run /agency:init first."
  feature_description = all arguments

project_dir = .ai/projects/{project_name}/
state_file  = {project_dir}/state.yml
if state_file not found:
  "Project '{project_name}' not found. Run /agency:init {project_name} first."

state = read_yaml(state_file)
```

### Step 2: Validate Prerequisites

```
dev_config = {project_dir}/dev/dev-config.yml
if dev_config not found:
  "dev-config.yml not found. Run /agency:init {project_name} first to generate project configuration."

if --from or --wave flag provided:
  # Resume mode — feature_description from project-state.yml
  existing_build = state.modules.dev.current_build
  if existing_build not found:
    "No active build found in project-state.yml. Provide a feature description to start a new build."
  feature_description = existing_build.feature_description
else:
  if feature_description is empty:
    "Feature description is required. Usage: /agency:build [project] \"description of what to build\""
```

### Step 3: Determine Start Phase

```
phases = [decompose, plan, execute, review]

if --wave provided:
  start_phase = execute  # --wave implies resuming within execute
else if --from provided:
  start_phase = --from value
  if start_phase not in phases:
    "Unknown phase '{start_phase}'. Valid values: decompose, plan, execute, review"
    exit
else:
  # Auto-detect: find first incomplete phase from current build
  build_status = state.modules.dev.current_build.status OR "new"
  status_to_phase = {
    new:         decompose,
    decomposing: decompose,
    planning:    plan,
    planned:     execute,
    executing:   execute,
    reviewing:   review,
    completed:   null,
    failed:      decompose
  }
  start_phase = status_to_phase[build_status]
  if start_phase is null:
    "Build already complete for '{project_name}'. View report at {project_dir}/dev/build-report.md"
    "Use --from to re-run a phase."
    exit
```

Show header before starting:
```
## Build Pipeline: {project_name}
Feature: {feature_description}
Starting from: {start_phase} phase
```

### Step 4: Initialize Build Record

```
if start_phase == decompose:
  Update state.yml:
    modules.dev.status → in_progress
    modules.dev.current_build:
      feature_description: "{feature_description}"
      status: decomposing
      current_phase: 1
      started_at: "{timestamp}"
```

### Step 5: Phase 1 — feature-decomposer (if start_phase <= decompose)

```
if start_phase in [decompose]:
  # Check design module outputs for reuse
  design_outputs = {
    component_specs: .ai/projects/{project_name}/design/components/ (count files)
    web_layout:      .ai/projects/{project_name}/design/layouts/ (count files)
  }
  if design_outputs are present:
    Note to decomposer: "Design pipeline outputs available — component-specs and
    web-layout results should inform component boundaries and file structure."

  Update state.yml:
    modules.dev.current_skill → feature-decomposer

  Run skill: feature-decomposer (model: principal, interactive)
    Reads:  {project_dir}/dev/dev-config.yml
            {project_dir}/design/components/*.yml (if present)
            {project_dir}/design/layouts/*.yml (if present)
            {project_dir}/brand/brand-summary.yml (if present)
    Writes: {project_dir}/dev/feature-decomposition.yml

  Note: feature-decomposer is interactive — PM + Architect + Designer + PO
  collaborate to present components, boundaries, dependencies, and file ownership.
  User must confirm before proceeding to planning.

  Run checkpoint (data_validation, 5 checks):
    - components_defined
    - boundaries_documented
    - files_owned          (every component lists files_affected)
    - no_file_overlap      (no two components own the same file)
    - decomposition_written

  if checkpoint fails:
    Log error to state.yml errors array
    "feature-decomposer checkpoint failed. Fix issues above and re-run /agency:build."
    exit

  Update state.yml:
    modules.dev.current_build.status → planning
    modules.dev.current_build.current_phase → 2
    modules.dev.completed_skills → append feature-decomposer
    current_skill → null

  Report: "Phase 1/4: feature-decomposer complete"
```

### Step 6: Phase 2 — team-planner (if start_phase <= plan)

```
if start_phase in [decompose, plan]:
  Verify prerequisite: {project_dir}/dev/feature-decomposition.yml exists
  if not exists:
    "feature-decomposer has not run. Start from --from decompose."
    exit

  Update state.yml:
    modules.dev.current_skill → team-planner

  Run skill: team-planner (model: principal, interactive)
    Reads:  {project_dir}/dev/feature-decomposition.yml
            {project_dir}/dev/dev-config.yml
    Writes: {project_dir}/dev/wave-plan.yml

  Note: team-planner is interactive — PM + Tech Leads assign tasks to agents,
  set model tiers, verify no file overlap across parallel tasks, and build the
  wave plan. User reviews the wave plan before execution begins.

  Run checkpoint (data_validation, 4 checks):
    - waves_defined
    - tasks_assigned      (every task has assigned_agent and model_tier)
    - file_ownership_verified (no overlap across parallel tasks in same wave)
    - wave_plan_written

  if checkpoint fails:
    Log error to state.yml errors array
    "team-planner checkpoint failed. Fix issues above and re-run with --from plan."
    exit

  if --dry-run:
    Update state.yml:
      modules.dev.current_build.status → planned
    "Dry run complete. Wave plan written to {project_dir}/dev/wave-plan.yml"
    "Re-run without --dry-run to execute."
    exit

  Update state.yml:
    modules.dev.current_build.status → executing
    modules.dev.current_build.current_phase → 3
    modules.dev.completed_skills → append team-planner
    current_skill → null

  Report: "Phase 2/4: team-planner complete"
```

### Step 7: Phase 3 — agent-dispatcher + completion-gate (if start_phase <= execute)

```
if start_phase in [decompose, plan, execute]:
  Verify prerequisite: {project_dir}/dev/wave-plan.yml exists
  if not exists:
    "team-planner has not run. Start from --from plan."
    exit

  # Determine resume wave
  if --wave provided:
    resume_wave = --wave value
    "Resuming execution from wave {resume_wave}."
  else:
    resume_wave = 1

  Update state.yml:
    modules.dev.current_skill → agent-dispatcher
    modules.dev.current_build.base_sha → current git HEAD sha

  Run skill: agent-dispatcher (model: senior)
    Reads:  {project_dir}/dev/wave-plan.yml
            {project_dir}/dev/dev-config.yml
            {project_dir}/design/tokens/tailwind.config.json (if present)
    Writes: agent task dispatches via Task() tool
            {project_dir}/dev/execution-log.yml

  Dispatch strategy:
    - Load wave-plan.yml; iterate waves from resume_wave onward
    - For each wave:
        if wave.parallel == true:
          Dispatch all tasks as simultaneous Task() calls (one per agent)
        else:
          Dispatch tasks sequentially
        Wait for all tasks in wave to report complete
        Run completion-gate for each task:
          Checks: build passes, lint passes, tests pass
          If gate fails: log to state.yml errors; halt and report to user

  Note: Each specialist agent commits its own work during execution.

  After all waves complete:
    Update state.yml:
      modules.dev.current_build.status → reviewing
      modules.dev.current_build.current_phase → 4
      modules.dev.current_build.head_sha → current git HEAD sha
      modules.dev.completed_skills → append agent-dispatcher
      current_skill → null

  Report: "Phase 3/4: execution complete — all waves dispatched and verified"
```

### Step 8: Phase 4a — code-review (if start_phase <= review)

```
if start_phase in [decompose, plan, execute, review]:
  Verify prerequisite: {project_dir}/dev/execution-log.yml exists
  if not exists:
    "agent-dispatcher has not run. Start from --from execute."
    exit

  Update state.yml:
    modules.dev.current_skill → code-review

  base_sha = state.modules.dev.current_build.base_sha
  head_sha = state.modules.dev.current_build.head_sha OR "HEAD"

  Run skill: code-review (model: senior)
    Reads:  git diff {base_sha}..{head_sha}
            {project_dir}/dev/dev-config.yml
            {project_dir}/design/tokens/tailwind.config.json (if present)
    Writes: {project_dir}/dev/code-review.yml

  Review dimensions (6 checks):
    - code_quality        (readability, naming, small functions, no console.log)
    - security            (no hardcoded secrets, parameterized queries, CSRF, auth)
    - patterns            (immutability, error handling, repository interface, API shape)
    - test_coverage       (unit + integration tests for changed code)
    - file_size           (no file >800 lines)
    - design_token_compliance (CSS uses variables from tokens/variables.css, no hardcoded colors or spacing)

  Run checkpoint (code_quality_gate, 6 checks):
    - code_quality_pass
    - security_pass
    - patterns_pass
    - test_coverage_pass
    - file_size_pass
    - design_token_compliance_pass

  if checkpoint fails:
    Log error to state.yml errors array
    "code-review found issues. Fix items above and re-run with --from review."
    exit

  Update state.yml:
    modules.dev.completed_skills → append code-review
    current_skill → null

  Report: "Phase 4a: code-review complete — all 6 dimensions pass"
```

### Step 9: Phase 4b — qa-validation (if start_phase <= review)

```
Run skill: qa-validation (model: principal, interactive)
  Reads:  {project_dir}/dev/feature-decomposition.yml
          {project_dir}/dev/wave-plan.yml
          {project_dir}/dev/code-review.yml
          git diff {base_sha}..{head_sha}
  Writes: {project_dir}/dev/build-report.md
          {project_dir}/dev/qa-report.yml

Note: qa-validation is interactive — QA Expert + PO assess spec alignment,
verify acceptance criteria, score coverage, and produce a sign-off or gap report.

Run checkpoint (code_quality_gate, 4 checks):
  - spec_alignment_score  (>= 80%)
  - acceptance_criteria   (all ACs addressed)
  - edge_cases_covered
  - build_report_written

if checkpoint fails (spec_alignment < 70%):
  Log error to state.yml errors array
  Present gaps to user with 3 options:
    1. Fix tasks — identify which wave tasks to re-run and resume with --wave N
    2. Accept as-is — mark build complete with noted gaps
    3. Abort — revert to base_sha (user performs manually)
  Wait for user decision before proceeding.

if checkpoint passes (score >= 80%):
  Update state.yml:
    modules.dev.current_build.status → completed
    modules.dev.current_build.completed_at → now
    modules.dev.status → completed
    modules.dev.completed_skills → append qa-validation
    current_skill → null
    updated_at → now
    recovery_notes → "Build complete. Feature: {feature_description}. Score: {score}%.
      View report at {project_dir}/dev/build-report.md.
      Run /agency:deploy to deploy."
```

### Step 10: Report

```
## Build Pipeline Complete: {project_name}

### Feature
  {feature_description}

### Phases Completed This Run

| Phase | Skill | Status | Outputs |
|-------|-------|--------|---------|
| decompose | feature-decomposer | {status} | feature-decomposition.yml |
| plan | team-planner | {status} | wave-plan.yml |
| execute | agent-dispatcher | {status} | {N} tasks across {W} waves |
| review | code-review + qa-validation | {status} | code-review.yml, build-report.md |

(Only show phases that ran in this invocation; show "skipped" for phases
skipped via --from)

### Quality
  Code review:       {pass/fail with dimension counts}
  Spec alignment:    {score}%
  Acceptance criteria: {N}/{total} addressed

### Outputs
  Wave plan:         {project_dir}/dev/wave-plan.yml
  Execution log:     {project_dir}/dev/execution-log.yml
  Code review:       {project_dir}/dev/code-review.yml
  Build report:      {project_dir}/dev/build-report.md

### Next Steps
  1. /agency:deploy {project_name}  — deploy to staging
  2. /agency:status {project_name}  — review full project state
```

## Recovery

Check `state.yml` at `.ai/projects/{project_name}/`. The `modules.dev.current_build.status` field indicates where the build stopped:

| Status | Recovery |
|--------|----------|
| decomposing | Re-run `/agency:build` — Phase 1 will re-run |
| planning | Re-run `/agency:build --from plan` — reads existing decomposition, re-plans |
| planned | Re-run `/agency:build` without `--dry-run` to start execution |
| executing | Resume with `/agency:build --wave N` where N is the last incomplete wave |
| reviewing | Re-run with `/agency:build --from review` |
| completed | Build is done — view report at `{project_dir}/dev/build-report.md` |
| failed | Check build-report.md for failure details, fix issues, re-run affected wave |

Task-level failures during Phase 3 are logged to `state.yml errors array`. The `completion-gate` halts the wave on first failure — fix the reported issue and resume with `--wave N`.

## Error Handling

**dev-config.yml missing:**
```
dev-config.yml not found. Run /agency:init {project_name} first to generate project configuration.
```

**feature-decomposer checkpoint failure** — logged to `state.yml errors array`:
```yaml
errors:
  - timestamp: "[now]"
    skill: "feature-decomposer"
    error: "no_file_overlap check failed — ComponentA and ComponentB both list src/api/auth.ts"
    attempted_fix: "Reassigned src/api/auth.ts exclusively to ComponentA"
    result: "pending"
    next_approach: "Re-run feature-decomposer, ensure shared files are in a dedicated shared component"
```

**Completion gate failure during execution:**
```
Wave {N} task '{task_name}' failed completion gate.
  Build: {pass/fail}
  Lint: {pass/fail}
  Tests: {pass/fail}
Fix the issues above, then resume:
  /agency:build --wave {N}
```

**Low spec alignment score (< 70%):**
```
QA validation: spec alignment {score}% — below acceptable threshold (70%).

Gaps identified:
  {gap list}

Options:
  1. Fix tasks — run /agency:build --wave {N} for affected waves
  2. Accept as-is — note gaps and mark complete
  3. Abort — revert changes manually (git reset to {base_sha})
```

**Unknown --from value:**
```
Unknown phase 'xyz'. Valid values: decompose, plan, execute, review
```
