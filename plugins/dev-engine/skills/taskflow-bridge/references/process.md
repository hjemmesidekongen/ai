# Taskflow Bridge — Process Reference

## Detection Logic

Run on every pipeline invocation (fast — just a file existence check):

```
1. Check: does plugins/taskflow/.claude-plugin/plugin.json exist?
   → YES: taskflow installed. Set mode: "integrated"
   → NO:  Set mode: "standalone". Log and continue.

2. If integrated, check: does .ai/tasks/active.yml exist?
   → YES: active task available. Load it.
   → NO:  taskflow installed but no active task. Set mode: "integrated_no_task"
```

## Bridge Context Schema

```yaml
# .ai/tasks/bridge-context.yml
bridge_version: 1
resolved_at: "2026-03-10T14:00:00Z"
mode: "integrated"  # integrated | integrated_no_task | standalone

taskflow:
  installed: true
  plugin_version: "0.1.0"

task:
  task_id: "PROJ-142"
  title: "Add dark mode toggle to settings page"
  source: "jira"
  status: "in_progress"
  acceptance_criteria:
    - id: ac-1
      type: "functional"
      text: "Toggle switches between light and dark themes"
      gate_check: "verify: dark mode class applied to document root"
    - id: ac-2
      type: "test_coverage"
      text: "Unit tests for theme toggle hook"
      gate_check: "verify: test suite passes with theme tests"
    - id: ac-3
      type: "no_regressions"
      text: "Existing settings page tests still pass"
      gate_check: "verify: existing tests green"

gate_checks:
  - id: gc-1
    from_criterion: ac-1
    verify: "dark mode class applied to document root"
    type: "functional"
  - id: gc-2
    from_criterion: ac-2
    verify: "test suite passes with theme tests"
    type: "test_coverage"
  - id: gc-3
    from_criterion: ac-3
    verify: "existing tests green"
    type: "regression"
```

## Criteria Mapping Rules

| Criterion type | Detection pattern | Gate check template |
|---------------|-------------------|-------------------|
| Functional | Contains behavior description (verb + noun) | `verify: <behavior>` |
| Test coverage | Mentions "test", "spec", "coverage" | `verify: test suite passes` with scope |
| Output file | Mentions file path or "create", "generate" | `verify: file exists at <path>` |
| No regressions | Mentions "existing", "regression", "break" | `verify: existing tests green` |
| Performance | Mentions "fast", "< Xms", "performance" | `verify: benchmark within threshold` |
| Visual | Mentions "looks", "matches design", "screenshot" | `verify: visual comparison passes` |

If a criterion doesn't match any pattern, map it as `type: "manual"` with `verify: "manual review required"`.

## Standalone Mode Behavior

When `mode: standalone`:
- Skip acceptance criteria mapping entirely
- Completion gate uses only agent-provided checks (from task-decomposer output)
- bridge-context.yml is still written (for pipeline state tracking) with empty `task:` and `gate_checks:` sections
- No status updates are written back

## Partial Task Context

When `mode: integrated_no_task`:
- Taskflow is installed but no task is active
- Pipeline proceeds without task-derived criteria
- Log a warning: "taskflow installed but no active task — running without task context"
- Completion gate uses agent-provided checks only (same as standalone)

## Status Update Protocol

After completion gate passes in integrated mode:
1. Read `.ai/tasks/active.yml`
2. Set `status: done` and `completed_at: <timestamp>`
3. If taskflow has a `next_task` field, do not clear active.yml
4. If no next task, set `status: idle` and clear task fields

Never update active.yml in standalone or integrated_no_task modes.

## Error Handling

- If `active.yml` exists but is malformed: log error, fall back to standalone mode
- If `active.yml` has no `acceptance_criteria` field: proceed with empty criteria (integrated_no_task behavior)
- If plugin.json exists but is not valid JSON: log error, fall back to standalone mode
- Never crash the pipeline on bridge failure — always degrade to standalone
