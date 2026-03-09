---
name: skill-reviewer
description: >
  Review and validate Claude Code skills for structure, content quality, and
  progressive disclosure. Use when reviewing skills after creation, auditing existing
  skills for issues, or validating skill changes before committing.
user_invocable: false
interactive: false
depends_on:
  - skill-creator
reads:
  - "plugins/*/skills/*/SKILL.md"
  - "plugins/*/skills/*/references/*.md"
  - "plugins/*/.claude-plugin/ecosystem.json"
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "eight_step_review"
      verify: "All 8 review steps completed in sequence"
      fail_action: "Run missing steps per references/process.md"
    - name: "verdict_produced"
      verify: "YAML verdict with status (pass/pass_with_notes/fail) generated"
      fail_action: "Generate verdict per verdict format in references/process.md"
    - name: "no_modifications"
      verify: "Reviewed files were not modified during review"
      fail_action: "Revert any changes — reviewers are read-only"
model_tier: principal
_source:
  origin: "claude-core"
  inspired_by: "https://github.com/anthropics/plugin-dev/agents/skill-reviewer"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "8-step review methodology adapted from Anthropic skill-reviewer agent. Added two-stage flow (spec compliance then quality), severity classification, and common findings table."
---

# Skill Reviewer

Reviews Claude Code skills for structure, content quality, and progressive disclosure.

## When to trigger

- Reviewing a skill after creation or modification
- Auditing all skills in a plugin for consistency
- Validating skill changes before committing
- Checking progressive disclosure and context efficiency
- Verifying ecosystem.json registration

## Review methodology

| Step | Focus |
|------|-------|
| 1. Location | Correct directory, naming conventions |
| 2. Structure | Required files present, organization |
| 3. Description | Trigger quality, specificity |
| 4. Content quality | Depth, accuracy, completeness |
| 5. Progressive disclosure | Tier efficiency, no duplication |
| 6. Supporting files | References exist, substantive |
| 7. Issue identification | Severity classification |
| 8. Recommendations | Actionable improvement items |

Read-only — never modify reviewed files. Produce a YAML verdict only.

## Process

See `references/process.md` for the full review methodology: 8-step process,
spec compliance checks, quality review dimensions, verdict format, and common findings.
