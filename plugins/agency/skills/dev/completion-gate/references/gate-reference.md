# Completion Gate — Extended Reference

On-demand reference for the completion-gate skill. Loaded when retry templates, escalation YAML, findings format, error table, or full YAML shapes are needed.

---

## Retry Dispatch Message Template

When a gate check fails, build the following error context for re-dispatch:

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

Re-dispatch the same agent at the same model tier via Task(). On report received, re-run gate from Step 3.

---

## Escalation Error Log YAML

When `retry_count` reaches 2 and gate still fails, log to `project-state.yml` errors array:

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

Also: add `escalated_to: code-review` to the task record. Continue gating remaining tasks — do not block the wave on one escalated task.

---

## Findings.md Format

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

**2-Action Rule:** After every 2 gate check runs (build + lint counts as 2), write current results to findings.md immediately.

---

## Error Logging Table

Log to `project-state.yml` errors array for unexpected failures:

| Scenario | Error to log |
|----------|-------------|
| Command not found | `{ skill: "completion-gate", error: "command not found: <cmd>", next_approach: "check dev-config.yml commands match installed tooling" }` |
| Timeout | `{ skill: "completion-gate", error: "command timed out after 60s: <cmd>", next_approach: "increase timeout or check for hanging processes" }` |
| Permission denied | `{ skill: "completion-gate", error: "permission denied running <cmd>", next_approach: "check script permissions" }` |
| dev-config.yml missing | `{ skill: "completion-gate", error: "dev-config.yml not found at .ai/projects/[name]/dev/dev-config.yml", next_approach: "run config-generator skill first" }` |

Check errors array before retrying — never repeat a failed approach with the same parameters.

---

## Full dispatched_tasks YAML Shape

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
        build_passed: null       # filled by gate
        lint_passed: null
        tests_passed: null
        gate_status: pending     # pending | passed | failed | escalated
        retry_count: 0
        errors: []
```
