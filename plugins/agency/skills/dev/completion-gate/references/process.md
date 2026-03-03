# Completion Gate — Detailed Process

## Overview

The completion gate is a quality enforcement layer that runs after agent-dispatcher completes each wave. It verifies build integrity, lint cleanliness, and test health per task before advancing the wave plan. Failures are returned to the originating agent immediately — while their changes are still in working memory — for fast correction.

---

## Step 1: Read Configuration

Read `dev-config.yml` from `.ai/projects/[name]/dev/dev-config.yml`:

```yaml
# Expected commands section shape:
commands:
  build: "npm run build"           # or yarn build, pnpm build, etc.
  lint: "npm run lint"             # or eslint, biome, etc.
  test_related: "npm run test --"  # prefix; append file paths after
  test: "npm run test"             # full suite for wave boundary
```

If `dev-config.yml` is missing or `commands` is absent:
- Log error to `project-state.yml` errors array
- Surface to orchestrator: cannot run gate without command definitions
- Block advancement — do not mark tasks as passed

---

## Step 2: Read Dispatched Tasks

Read `project-state.yml` at `.ai/projects/[name]/project-state.yml`:

```yaml
execution:
  dispatched_tasks:
    - task_id: "t1"
      status: completed          # only process completed tasks
      files_changed:
        - "src/components/Button.tsx"
        - "src/components/Button.test.tsx"
      commit_sha: "abc1234"
      report:
        build_passed: null       # will be filled by gate
        lint_passed: null
        tests_passed: null
        gate_status: pending
        retry_count: 0
        errors: []
```

Filter to tasks where `status: completed` and `report.gate_status: pending`.

---

## Step 3: Per-Task Gate Execution

For each pending completed task:

### 3a. Build Check

```bash
<commands.build>
# Exit code 0 → build_passed: true
# Exit code non-0 → build_passed: false, capture stdout+stderr
```

### 3b. Lint Check

```bash
<commands.lint>
# Exit code 0 → lint_passed: true
# Exit code non-0 → lint_passed: false, capture stdout+stderr
```

### 3c. Related Test Check

```bash
<commands.test_related> <files_changed joined by space>
# Exit code 0 → tests_passed: true
# Exit code non-0 → tests_passed: false, capture stdout+stderr
```

### 3d. Gate Decision

- **All three exit 0:** mark `gate_status: passed`, update report booleans, continue
- **Any non-zero:** proceed to retry flow (Step 4)

---

## Step 4: Failure Handling and Retry

When any gate check fails:

### Retry Dispatch

1. Increment `report.retry_count` in project-state.yml
2. Check `retry_count` — max is 2
3. Build error context for re-dispatch:

```
Task: [task_id] — Gate failure on retry [retry_count]/2

Build errors:
[captured build stdout/stderr if build failed]

Lint errors:
[captured lint stdout/stderr if lint failed]

Test failures:
[captured test stdout/stderr if tests failed]

Files changed in original task:
[files_changed list]

Fix the above errors. Commit your changes. Report back with updated files_changed.
```

4. Re-dispatch the same agent at the same model tier via Task()
5. On report received: re-run gate from Step 3

### Escalation After Max Retries

If `retry_count` reaches 2 and gate still fails:

1. Set `report.gate_status: failed`
2. Log to `project-state.yml` errors array:

```yaml
errors:
  - timestamp: "<ISO 8601>"
    skill: "completion-gate"
    task_id: "<task_id>"
    error: "Gate failed after 2 retries — build: <pass/fail>, lint: <pass/fail>, tests: <pass/fail>"
    attempted_fix: "Re-dispatched agent twice with full error context"
    result: "Agent could not resolve failures within retry budget"
    next_approach: "Escalate to code-review skill for manual inspection"
```

3. Flag task for code-review skill: add `escalated_to: code-review` to the task record
4. Continue gating remaining tasks — do not block the wave on one escalated task

---

## Step 5: Wave Boundary Full Suite

After all tasks in a wave have been gated (passed, failed, or escalated):

```bash
<commands.test>
# Full test suite run
# Exit 0 → wave cleared, advance plan
# Exit non-0 → log failures, surface to orchestrator before advancing
```

Record full suite result in `project-state.yml`:

```yaml
execution:
  waves:
    - wave_number: 1
      full_suite_passed: true   # or false
      full_suite_output: "<summary of test results>"
```

---

## Step 6: Update project-state.yml

After all gate runs complete, write final report for each task:

```yaml
execution:
  dispatched_tasks:
    - task_id: "t1"
      status: completed
      report:
        build_passed: true
        lint_passed: true
        tests_passed: true
        gate_status: passed     # passed | failed | escalated
        retry_count: 0
        errors: []
```

Write atomically — read current state, merge gate results, write back. Do not overwrite unrelated fields.

---

## Step 7: Findings Persistence

Write gate results to `.ai/projects/[name]/findings.md`:

```markdown
## Completion Gate — Wave [N] — [timestamp]

### Task t1
- Build: PASS
- Lint: PASS
- Tests: PASS
- Gate: PASSED (0 retries)

### Task t2
- Build: FAIL (exit 1)
- Retry 1: FAIL
- Retry 2: PASS after agent fix
- Lint: PASS
- Tests: PASS
- Gate: PASSED (2 retries)

### Wave Boundary Full Suite
- Result: PASS
- Tests run: 142, passed: 142, failed: 0
```

**2-Action Rule:** After every 2 gate check runs (build + lint counts as 2), write current results to findings.md immediately. Do not wait until all tasks are complete.

---

## Error Logging Reference

Log to `project-state.yml` errors array for unexpected failures:

| Scenario | Error to log |
|----------|-------------|
| Command not found | `{ skill: "completion-gate", error: "command not found: <cmd>", next_approach: "check dev-config.yml commands match installed tooling" }` |
| Timeout | `{ skill: "completion-gate", error: "command timed out after 60s: <cmd>", next_approach: "increase timeout or check for hanging processes" }` |
| Permission denied | `{ skill: "completion-gate", error: "permission denied running <cmd>", next_approach: "check script permissions" }` |
| dev-config.yml missing | `{ skill: "completion-gate", error: "dev-config.yml not found at .ai/projects/[name]/dev/dev-config.yml", next_approach: "run config-generator skill first" }` |

Check errors array before retrying — never repeat a failed approach with the same parameters.
