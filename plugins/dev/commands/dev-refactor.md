---
name: dev-refactor
command: "/dev:refactor"
description: "(dev) Reshape existing code to match conventions without breaking functionality — test-first, one component per wave, per-component commits with rollback points"
arguments:
  - name: target
    type: string
    required: false
    description: "File, directory, or component to refactor (e.g., 'src/components/UserForm.tsx' or 'src/lib/')"
  - name: scope
    type: string
    required: false
    description: "Refactor mode: 'convention' applies convention alignment across the whole project"
  - name: dry-run
    type: boolean
    required: false
    default: false
    description: "Analyze what would change and produce a refactor plan without executing any changes"
  - name: wave
    type: number
    required: false
    description: "Resume from a specific wave number (for recovery after partial execution)"
---

# /dev:refactor

Reshape existing code to match conventions without changing behavior. Stricter than `/dev:build`: tests are written before any change, each component is refactored in isolation with a rollback point, and a full regression suite runs after all changes. If any change would alter behavior, it is flagged for explicit approval before proceeding.

## Usage

```
/dev:refactor src/components/UserForm.tsx    # refactor a specific file
/dev:refactor src/lib/                       # refactor a directory
/dev:refactor --scope convention             # apply convention alignment across the project
/dev:refactor src/components/ --dry-run      # show what would change without executing
/dev:refactor src/components/ --wave 3       # resume from wave 3 after partial execution
```

## Purpose

Provides a safe, behavior-preserving path for bringing existing code up to project conventions. Core guarantee: structure may change; behavior must not. Every structural change is preceded by tests, followed by immediate test verification, and recorded as a discrete commit — so any failed refactor can be reverted to a known-good state without losing other work.

Key differences from `/dev:build`:

| Aspect | /dev:build | /dev:refactor |
|--------|-----------|---------------|
| Wave size | Multiple components | One component per wave |
| Tests | After each wave | Before AND after each component |
| Tier assignment | Risk-based standard | One level higher (haiku→sonnet, sonnet→opus) |
| Commits | Per wave | Per component |
| Rollback | Wave-level | Per-component stash/branch |
| Behavior | May add new behavior | Must never change existing behavior |
| Regression | Related tests | Full test suite (mandatory) |
| QA validation | Standard | Mandatory — cannot be skipped |

## Prerequisites

- `/dev:init` must have been run (`dev-config.yml` must exist at `.ai/dev/[project-name]/`)
- All existing tests must pass before refactoring begins — failing tests are a hard blocker
- Task-planner plugin must be active

## Input

- `[target]` (optional) — file path or directory to refactor; omit when using `--scope`
- `--scope convention` (optional) — scan the full project for convention deviations and produce a refactor plan covering all of them
- `--dry-run` (optional) — analyze and plan only; write analysis to `refactor-plan.md` without modifying any source files
- `--wave [N]` (optional) — resume from wave N; reads existing `team-state.yml`, skips Phases 1–3

Interactive prompts during execution:
- Phase 1: Confirms what was analyzed and what needs to change
- Phase 2: Reviews the wave plan (one component per wave) before any changes are made
- During execution: Any change that would alter behavior pauses for explicit user approval

## Execution Strategy

### Phase 0: Validate Prerequisites

Read `.ai/dev/[project-name]/dev-config.yml`. If missing:
- Error: "Project not initialized. Run `/dev:init` first."
- Exit

If `--wave [N]` provided: skip to Phase 4 Resume below.

### Phase 1: Analyze Target

1. Create or update `.ai/dev/[project-name]/team-state.yml` with refactor metadata:

```yaml
refactor:
  target: "[target path or 'convention scope']"
  status: "analyzing"
  current_phase: 1
  started_at: "[timestamp]"
  baseline_tests_passed: false
  components: []
```

2. Read the target file(s) or scan the target directory. For `--scope convention`, scan the full project using delta-scanner conventions awareness.

3. For each file in scope:
   - Identify structural issues: naming, file length, function length, nesting depth, mutation patterns, missing error handling, hardcoded values, missing types
   - Flag any change that would require altering the public interface or observable behavior — these require explicit user approval before proceeding
   - Record findings in `findings.md` at `.ai/dev/[project-name]/`

4. Present analysis to user:
   - Summary of files in scope and what needs to change
   - Any behavior-changing issues that were found (these need approval or will be skipped)
   - Estimated number of waves

User confirms before proceeding to Phase 2.

### Phase 2: Establish Test Baseline

Run the full existing test suite before touching any code:

```bash
# Use the test command from dev-config.yml
# Example: npm test / yarn test / pytest / go test ./...
```

**If any tests fail: ABORT immediately.**

```
ABORT: [N] tests are failing before refactoring begins.
Fix all test failures before running /dev:refactor.
Failing tests: [list]
```

Update `team-state.yml`:
```yaml
refactor:
  baseline_tests_passed: true
  baseline_test_count: [N]
  baseline_sha: "[git rev-parse HEAD]"
```

### Phase 3: Plan Waves + Test Gap Assessment

Read SKILL.md at `plugins/dev/skills/team-planner/SKILL.md`, follow its process with these constraints:

**Wave planning rules for refactoring:**
- One component/file per wave — no grouping, no matter how small the change
- Wave 0 is reserved for test gap filling (runs before any structural changes)
- Model tier for every task is elevated one level above what the equivalent feature task would receive: haiku→sonnet, sonnet→opus, opus→opus
- Each task must include a `rollback_ref` field (git stash label or branch name)

**Test gap assessment:**
- For each component scheduled for refactoring, check test coverage
- If a component has no tests or coverage is below 80%: add a Wave 0 task to write the missing tests
- Wave 0 tasks are assigned to the same worker (frontend or backend) but at elevated tier

Wave plan is written to `team-state.yml` under `wave_plan`. Each wave entry includes:

```yaml
wave: 1
parallel: false
component: "src/components/UserForm.tsx"
assigned_agent: "frontend-worker"
model_tier: "sonnet"          # elevated from what haiku would be for equivalent feature task
rollback_ref: "stash/refactor-UserForm"
structural_changes:
  - "Extract validation logic to useFormValidation composable"
  - "Replace mutation of formData with immutable spread pattern"
  - "Extract inline styles to CSS module"
behavior_changes_flagged: []  # any flagged items listed here; empty = safe to proceed
```

If `--dry-run`: write analysis to `.ai/dev/[project-name]/refactor-plan.md`, update `refactor.status` to "planned", present summary to user, and exit.

User reviews wave plan and approves before Phase 4.

### Phase 4: Execute — Wave 0 (Test Gaps)

If Wave 0 tasks exist, dispatch them first using the subagent pattern from plan-execute.

For each Wave 0 task:
- Dispatch worker agent (frontend-worker or backend-worker) at elevated model tier
- Worker writes the missing tests
- Run tests immediately after — they must PASS before proceeding
  - If new tests fail: this indicates the worker wrote tests for behavior that doesn't exist yet; log error to state.yml, report to user, skip refactoring this component

After Wave 0 completes: record commit SHA.

```yaml
refactor:
  wave_0_sha: "[git rev-parse HEAD]"
```

### Phase 5: Execute — Incremental Refactoring

For each component wave (sequential — never parallel):

#### Step a: Create rollback point

```bash
git stash push -m "[rollback_ref from wave plan]"
# OR: git checkout -b refactor/[component-name]-rollback
```

Record stash ref or branch name in `team-state.yml` under the wave entry.

#### Step b: Dispatch worker agent

Dispatch frontend-worker or backend-worker at the wave's `model_tier`. Include in the task dispatch:
- The structural changes list from the wave plan
- The explicit instruction: "Apply ONLY the structural changes listed. Do NOT change public interfaces, exported function signatures, component props, API response shapes, or any observable behavior. If a structural change would require a behavior change to implement correctly, STOP and report back — do not implement it."
- The rollback ref so the agent knows what to revert to if needed

#### Step c: Run tests immediately

After the agent completes:

```bash
# Run the full test suite (not just related tests)
```

**If tests pass:**
- Commit: `git commit -m "refactor([component]): [brief description of structural change]"`
- Record `commit_sha` in `team-state.yml` under the wave entry
- Update `refactor.status` to "wave_[N]_complete"

**If tests fail:**
- Revert to rollback point: `git stash pop` or `git checkout [rollback-branch]`
- Log to `state.yml` errors array:
  ```yaml
  - timestamp: "[ISO timestamp]"
    skill: "dev-refactor"
    component: "[component path]"
    error: "Tests failed after refactoring [component]. Changes reverted."
    attempted_fix: "[description of what was tried]"
    result: "reverted"
    next_approach: "manual review required"
  ```
- Report to user: which component failed, which tests failed, that the component was reverted
- Continue to the next component — do not abort the entire refactor run

### Phase 6: Full Regression

After all component waves complete (including any that were reverted):

```bash
# Run the complete test suite one final time
```

Record results:

```yaml
refactor:
  regression_passed: true
  regression_test_count: [N]
  components_refactored: [N]
  components_reverted: [N]
  head_sha: "[git rev-parse HEAD]"
  commit_range: "[baseline_sha]..[head_sha]"
```

If regression fails after all components passed individually: this indicates a cross-component interaction issue. Log to state.yml errors array, present the failing tests to the user, and do not proceed to QA until resolved.

### Phase 7: QA Validation

QA validation is mandatory for every refactor run — it cannot be skipped.

Dispatch QA Lead (`qa-lead`) agent with:
- `commit_range`: `baseline_sha..HEAD`
- `validation_mode`: "refactor" — QA verifies that behavior is preserved, not just that tests pass
- QA Lead checks:
  1. All tests pass (unit, integration, E2E)
  2. Coverage did not decrease from baseline
  3. No new public interface changes (props, exports, API routes)
  4. No behavior differences visible in the diff (logic changes flagged)
  5. Code style is consistent with project conventions

QA Lead produces a sign-off or a list of issues to address.

Write refactor report to `.ai/dev/[project-name]/refactor-report.md`.

Present report to user.

### Phase 4 Resume (--wave N)

When `--wave [N]` provided:
1. Read existing `.ai/dev/[project-name]/team-state.yml`
2. Verify `wave_plan` exists and baseline was established
3. Skip to Phase 5, starting at wave N
4. Warn user: "Resuming at wave N. Baseline test SHA was [baseline_sha]. Confirm tests still pass before proceeding? [Y/n]"
5. Continue with Phase 6 and 7 after waves complete

## Output

- Source files refactored in place (each component committed separately)
- `.ai/dev/[project-name]/team-state.yml` — full execution record (analysis, wave plan, per-component results, regression, QA sign-off)
- `.ai/dev/[project-name]/refactor-report.md` — human-readable report: components refactored, components reverted, test delta, QA sign-off
- `.ai/dev/[project-name]/findings.md` — analysis findings from Phase 1

## Recovery

Check `team-state.yml` at `.ai/dev/[project-name]/`. The `refactor.status` field indicates where execution stopped:

| Status | Meaning | Recovery |
|--------|---------|----------|
| analyzing | Phase 1 interrupted | Re-run `/dev:refactor [target]` — analysis restarts |
| planned | Plan written, not started | Re-run without `--dry-run` |
| baseline_failed | Tests were failing before start | Fix failing tests, then re-run |
| wave_0_[N]_complete | Test gap wave N done | Re-run with `--wave N+1` |
| wave_[N]_complete | Component wave N done | Re-run with `--wave N+1` |
| regression_failed | Full regression failed | Fix cross-component issue, re-run `--wave` at last complete wave |
| qa_review | QA in progress | Re-run Phase 7 manually or wait |
| completed | Done | View report at refactor-report.md |

## Error Handling

- **dev-config.yml missing:** Error directing user to run `/dev:init` first
- **Tests failing at baseline:** Hard abort — list failing tests, do not proceed
- **Component refactor fails tests:** Revert that component, log error, continue with next component
- **Behavior-changing refactor detected:** Pause and request explicit user approval before proceeding; skip if declined
- **Full regression failure:** Stop, log errors, require manual resolution before QA
- **QA validation fails:** Present issues to user — options are: fix the flagged items, accept with notes, or mark as needs-review
