---
name: qa-handover-generator
description: >
  Generate structured QA handover notes for completed tasks. Content includes
  what changed, test scenarios, screenshots (if UI), and regression risks.
  Output format determined by project profile: Jira comment, GitHub PR
  description, or plain markdown. Triggered by task completion.
user_invocable: true
interactive: false
model_tier: senior
depends_on:
  - "project-profile-loader"
triggers:
  - "qa handover"
  - "generate handover"
  - "qa notes"
  - "task done"
  - "complete task"
reads:
  - ".ai/tasks/<KEY>.yml"
  - "rules.yml"
  - ".ai/rules.yml"
writes:
  - ".ai/tasks/<KEY>-handover.md"
checkpoint:
  type: data_validation
  required_checks:
    - name: "handover_generated"
      verify: "Handover document exists at .ai/tasks/<KEY>-handover.md"
      fail_action: "Re-run generation — check that task file and git diff are available"
    - name: "sections_complete"
      verify: "All required sections present: changes, test scenarios, regression risks"
      fail_action: "Fill missing sections — use git diff and task description as sources"
    - name: "format_matches_profile"
      verify: "Output format matches qa.format from project profile"
      fail_action: "Re-format to match profile (jira-comment, github-pr, or markdown)"
  on_fail: "Report which sections are missing or incomplete."
  on_pass: "Report: handover generated for <KEY> (<format>). Path: .ai/tasks/<KEY>-handover.md"
_source:
  origin: "taskflow"
  inspired_by: "D-020 completion gate criteria + agency qa-validation"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "New skill. Structured QA handover with format-aware output."
---

# qa-handover-generator

Produces a QA handover document from the task file, git diff, and project profile.
Designed for work contexts where completed work needs structured handoff to QA
or reviewers.

## Steps

1. **Load profile** — run project-profile-loader to get QA format and screenshot requirements
2. **Load task** — read `.ai/tasks/<KEY>.yml` for context (summary, AC, contradictions)
3. **Analyze changes** — use `git diff` to identify what files changed and what the functional impact is
4. **Generate sections** — build each section of the handover (see `references/process.md`)
5. **Format output** — apply the format from project profile (jira-comment, github-pr, markdown)
6. **Write file** — save to `.ai/tasks/<KEY>-handover.md`

## Required sections

| Section | Content |
|---------|---------|
| Summary | What was done, 2-3 sentences |
| Changes | Files changed with functional impact of each |
| Test scenarios | Specific steps to verify the work, mapped from AC |
| Regression risks | Areas that might break due to these changes |
| Screenshots | Required if `qa.require_screenshots: true` and UI files changed |

Format modes: jira-comment (wiki markup), github-pr (GFM with checkboxes), markdown (default). See `references/process.md` for templates.

## Never

- Never fabricate test scenarios not grounded in acceptance criteria or git diff
- Never omit regression risks — if uncertain, state "low-confidence" rather than skipping

Output: `QA handover generated: .ai/tasks/<KEY>-handover.md (<format>)`
