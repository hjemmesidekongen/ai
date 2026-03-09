---
name: full-review
description: Run a 5-phase comprehensive code review with parallel agents per phase and severity gates between phases
user_invocable: true
arguments:
  - name: target
    description: "File path, directory, or git diff range to review (default: staged changes)"
    required: false
  - name: from-phase
    description: "Resume from a specific phase number (1-5)"
    required: false
---

# /full-review

Run a comprehensive 5-phase code review with 2 parallel reviewers per phase and severity gates between phases. Extends the `parallel-reviewer` skill with sequential depth and checkpoint control.

## Phases

| Phase | Reviewer A | Reviewer B | Focus |
|-------|-----------|-----------|-------|
| 1 | Code Quality | Architecture | Structure, readability, coupling, boundaries |
| 2 | Security | Performance | Vulnerabilities, OWASP, complexity, memory |
| 3 | Testing | Documentation | Coverage gaps, test quality, doc accuracy |
| 4 | Best Practices | DevOps | Conventions, linting, CI/CD impact, deploy safety |
| 5 | — | — | Consolidation: deduplicate, rank, report |

## Execution

### Phase 1-4: Parallel Review Pairs

For each phase:

1. **Dispatch** 2 reviewer agents in parallel (use Agent tool)
   - Each gets: the target code, phase-specific review criteria, prior phase findings
   - Each writes to `.review/phase-N-{dimension}.yml`

2. **Collect** both phase outputs

3. **Severity gate**: If either reviewer found a CRITICAL issue:
   - STOP and report: "Phase N found critical issues. Review before continuing."
   - Wait for user: `continue` | `fix-and-rerun` | `abort`

4. **If no criticals**: proceed to next phase automatically

### Phase 5: Consolidation

Read all `.review/phase-*.yml` files and produce the final report:

1. **Deduplicate** findings that appear in multiple phases
2. **Rank** by severity: Critical > High > Medium > Low > Info
3. **Group** by file, then by category
4. **Produce** the consolidated report

### Output

Write final report to `.review/report.md`:

```markdown
# Code Review Report

## Summary
- Files reviewed: N
- Total findings: N (Critical: N, High: N, Medium: N, Low: N)
- Phases completed: 4/4

## Critical Issues
(Must fix before merge)

## High Priority
(Should fix before merge)

## Medium Priority
(Fix in follow-up)

## Low Priority / Info
(Consider for future improvement)

## By File
(Grouped findings per file)
```

### Reviewer Prompts

Each reviewer agent gets:

```
You are a {dimension} reviewer. Review the following code for {specific criteria}.

Prior findings from earlier phases:
{findings from phases 1 through N-1}

Write your findings in YAML:
- file: path
  line: N (if applicable)
  severity: critical|high|medium|low|info
  category: {review dimension}
  finding: description
  suggestion: how to fix
```

## Notes

- Phase 1-4 each spawns 2 parallel agents — total 8 agent dispatches
- Prior phase findings are passed forward to avoid duplicate investigation
- Severity gate only stops on CRITICAL — other severities continue automatically
- Use `--from-phase N` to resume from a specific phase after fixing issues
- `.review/` directory is created in the current working directory
