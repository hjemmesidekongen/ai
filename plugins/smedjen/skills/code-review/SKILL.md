---
name: code-review
description: >
  Bidirectional code review — supports requesting reviews from the code-reviewer
  agent and processing received review feedback. Categorizes findings by severity
  (critical, important, minor) with actionable, direct language.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "code review"
  - "review code"
  - "request review"
  - "review changes"
reads:
  - "git diff output"
  - "changed files"
writes:
  - ".ai/reviews/<review-id>.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "review_complete"
      verify: "Every changed file has been reviewed with findings or explicit pass"
      fail_action: "Review uncovered files"
    - name: "severity_valid"
      verify: "All findings have severity: critical, important, or minor"
      fail_action: "Assign missing severity levels"
    - name: "no_critical_unresolved"
      verify: "No critical findings left unaddressed"
      fail_action: "Address critical findings before marking review complete"
  on_fail: "Review incomplete — address flagged issues"
  on_pass: "Review complete — all findings categorized and addressed"
_source:
  origin: "smedjen"
  inspired_by: "superpowers-main code-review + agency code-review"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Built for smedjen with severity classification and YAML report output"
---

# Code Review

Reviews changed files across five dimensions: correctness, security, performance, readability, and testing. Outputs a structured review report with severity-rated findings.

## Bidirectional Flow

**Requesting a review** — Prepare the diff, scope, and context so the reviewer has everything needed without asking follow-up questions. See `references/process.md` for the request template.

**Receiving a review** — Process each finding by severity. Critical findings become blockers. Important findings become tasks. Minor findings are addressed or noted with rationale for deferral.

## Severity Levels

| Level | Meaning | Action required |
|-------|---------|----------------|
| critical | Bugs, security holes, data loss risks | Must fix before merge |
| important | Performance issues, missing error handling, weak tests | Should fix — document reason if deferred |
| minor | Style, naming, simplification opportunities | Nice to have — fix or skip |

## Rules

- Review every changed file. No exceptions for "obvious" changes.
- No performative language in review output. State the problem and the fix.
- Rate severity based on production impact, not personal preference.
- When reviewing generated code, focus on the generator config, not the output.
- For dependency updates, check changelogs for breaking changes and CVEs.
- Large diffs (>500 lines): split review by module, review each independently.

## Output

Findings written to `.ai/reviews/<review-id>.yml` — see `references/process.md` for schema and examples.
