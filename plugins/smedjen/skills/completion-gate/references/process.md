# Completion Gate — Detailed Process

## Gate Execution Algorithm

```
1. Receive subtask completion report from agent-dispatcher
2. Detect project tooling: lint command, type checker, test runner, E2E framework
3. For each of the 10 criteria:
   a. Check if criterion is applicable (skip conditions)
   b. Run the check (command or analysis)
   c. Record: pass | fail | skip, with evidence
4. Evaluate results:
   - All pass/skip → gate passed
   - Any fail → return to implementing agent
5. On retry (max 2):
   - Re-run only failed criteria
   - If still failing → mark task as failed, escalate
6. Write results to .ai/tasks/gate-results/<task-id>.yml
```

## Criteria Details

### 1. Spec Compliance
Compare completed work against original task description. Check:
- All requirements addressed
- No extra scope added (scope creep)
- Edge cases from spec handled

Evidence: list of spec requirements with pass/fail each.

### 2. Lint Passes
Run project lint command (from package.json scripts or detected config).
Evidence: lint command output, exit code.

### 3. Type Check Passes
Run `tsc --noEmit` or equivalent.
Evidence: type checker output, error count.

### 4. Unit Tests Pass
Run test command scoped to changed files.
Evidence: test output, pass/fail count.

### 5. Integration Tests Pass
Run integration test suite if it exists.
Evidence: test output. Skip if no integration test directory.

### 6. E2E Tests Pass
Run Playwright or Cypress suite if configured.
Evidence: test output. Skip if no E2E setup.

### 7. New Tests Cover New Behavior
Check that new/modified functions have corresponding test files.
Evidence: list of new functions → test mapping.

### 8. Visual Verification
Delegate to visual-verification skill if UI files changed.
Evidence: screenshot comparison results.

### 9. Security Check
Scan for: hardcoded secrets, SQL injection patterns, XSS vectors,
missing input validation, insecure dependencies.
Evidence: findings list (empty = pass).

### 10. Code-Reviewer Sign-off
Final human-in-the-loop check by Opus code-reviewer agent.
Evidence: reviewer approval or rejection with comments.

## Gate Results Schema

```yaml
task_id: "st-3"
gate_run: 1
timestamp: "2026-03-09T23:00:00Z"
results:
  - criterion: 1
    name: "spec_compliance"
    status: pass
    evidence: "All 4 requirements met"
  - criterion: 2
    name: "lint"
    status: pass
    evidence: "0 errors, 0 warnings"
  - criterion: 7
    name: "new_test_coverage"
    status: fail
    evidence: "UserService.create() has no test"
  - criterion: 8
    name: "visual_verification"
    status: skip
    reason: "No UI files changed"
overall: fail
failed_criteria: [7]
retry_count: 0
max_retries: 2
```

## Retry Flow

```
Failure detected → extract failed criteria
  → compose fix prompt with:
     - original task description
     - specific failure details
     - evidence from gate check
  → re-dispatch to implementing agent at same tier
  → agent fixes → re-run ONLY failed criteria
  → pass? → gate passed
  → fail again? → increment retry_count
  → retry_count >= 2? → mark failed, escalate to principal
```

## Tooling Detection

```yaml
lint:
  detect: ["eslint.config.*", ".eslintrc.*", "biome.json"]
  command: "npm run lint" or "npx eslint ."
type_check:
  detect: ["tsconfig.json"]
  command: "npx tsc --noEmit"
test:
  detect: ["jest.config.*", "vitest.config.*", "*.test.*", "*.spec.*"]
  command: "npm test" or "npx vitest run"
e2e:
  detect: ["playwright.config.*", "cypress.config.*"]
  command: "npx playwright test" or "npx cypress run"
```
