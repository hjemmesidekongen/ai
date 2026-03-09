---
name: parallel-reviewer
description: >
  Dispatch 4 specialized reviewers in parallel (security, performance,
  architecture, testing), each analyzing the code independently. Coordinator
  consolidates findings, deduplicates, and ranks by severity. Use when
  reviewing a non-trivial code change that touches multiple quality dimensions,
  before merging a feature branch, when a PR needs thorough multi-angle review,
  or when a single reviewer pass may miss domain-specific issues.
user_invocable: false
interactive: false
depends_on: []
triggers:
  - "code review"
  - "parallel review"
  - "PR review"
  - "multi-angle review"
  - "security review"
reads:
  - "code files under review (context-dependent)"
writes:
  - ".ai/plans/*/artifacts/*-review-report.md"
checkpoint:
  type: code_validation
  required_checks:
    - name: "all_four_reviewers_ran"
      verify: "Security, performance, architecture, and testing review artifacts all exist"
      fail_action: "Run all four reviewers before consolidation — do not skip any"
    - name: "findings_deduplicated"
      verify: "Duplicate findings merged; each issue reported once with combined context"
      fail_action: "Scan for duplicate issue descriptions across review artifacts"
    - name: "severity_ranked"
      verify: "Final report lists findings ranked by severity (critical first)"
      fail_action: "Re-sort findings by severity before delivering report"
    - name: "coordinator_read_artifacts"
      verify: "Coordinator read artifact files directly; did not paraphrase reviewer responses"
      fail_action: "Read artifact files from disk per forward-message pattern"
  on_fail: "Complete all reviews and consolidate from artifacts before reporting."
  on_pass: "Parallel review complete. Report ranked by severity and deduplicated."
model_tier: senior
_source:
  origin: "claude-core"
  inspired_by: "agents-main/plugins/agent-teams/skills/multi-reviewer-patterns/"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "4-reviewer parallel dispatch pattern adapted to claude-core agent system. Uses forward-message artifact pattern from E1 for lossless result collection."
---

# parallel-reviewer

4 specialized reviewers run in parallel. Coordinator consolidates from artifacts.
No telephone game — artifacts read directly per forward-message pattern.

## 4 Review Streams

| Reviewer | Focus | Artifacts checked |
|----------|-------|------------------|
| security | Auth, injection, secrets, input validation, OWASP top 10 | All modified files |
| performance | N+1 queries, blocking calls, memory allocation, loop complexity | Hot paths |
| architecture | Coupling, cohesion, boundary violations, pattern consistency | Module boundaries |
| testing | Coverage gaps, missing edge cases, test quality, mock hygiene | Test files + coverage |

## Dispatch Protocol

1. Collect modified files for review
2. Dispatch all 4 reviewers as parallel Agent calls (or sequential subagent tasks)
3. Each reviewer writes findings to `.ai/plans/<plan>/artifacts/<name>-review.md`
4. Coordinator reads all 4 artifacts directly (do NOT paraphrase)
5. Consolidate: deduplicate, rank by severity, write final report

## Full Process

See `references/process.md` for reviewer prompt templates, deduplication rules,
consolidation format, and severity ranking criteria.
