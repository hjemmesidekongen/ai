---
name: agent-reviewer
description: >
  Review and validate Claude Code agents for frontmatter correctness, description
  quality, system prompt structure, tool scope appropriateness, and model tier
  justification. Use when reviewing agents after creation, auditing existing agents
  for compliance, validating agent changes before committing, checking triggering
  examples, or auditing all agents in a plugin for consistency.
user_invocable: false
interactive: false
depends_on:
  - agent-creator
triggers:
  - "review agent"
  - "audit agent"
  - "validate agent"
  - "agent frontmatter check"
  - "agent quality audit"
  - "check agent definition"
reads:
  - "plugins/*/agents/*.md"
  - "plugins/*/.claude-plugin/ecosystem.json"
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "five_dimension_review"
      verify: "All 5 review dimensions completed (frontmatter, description, system prompt, tool scope, model tier)"
      fail_action: "Run missing dimensions per references/process.md"
    - name: "verdict_produced"
      verify: "YAML verdict with status (pass/pass_with_notes/fail) generated"
      fail_action: "Generate verdict per verdict format in references/process.md"
    - name: "no_modifications"
      verify: "Reviewed files were not modified during review"
      fail_action: "Revert any changes — reviewers are read-only"
model_tier: senior
_source:
  origin: "claude-core"
  inspired_by: "validate-agent.sh (claude-code-templates, everything-claude-code) + skill-reviewer pattern"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New skill mirroring skill-reviewer pattern for agent definition files. Review methodology derived from validate-agent.sh external references and the existing agent-reviewer agent's 5-dimension framework."
---

# Agent Reviewer

Reviews Claude Code agent definition files for structure, quality, and correctness.

## When to trigger

- Reviewing an agent after creation or modification
- Auditing all agents in a plugin for consistency
- Validating agent changes before committing
- Checking triggering examples and description quality
- Verifying ecosystem.json registration

## Review methodology

| Step | Focus |
|------|-------|
| 1. Location | Correct directory, naming conventions |
| 2. Frontmatter | Required fields, format, value constraints |
| 3. Description | Trigger quality, examples, specificity |
| 4. System prompt | Role, structure, output format, tone |
| 5. Tool scope | Least privilege, read-only vs write alignment |
| 6. Model tier | Tier matches agent complexity |
| 7. Issue identification | Severity classification |
| 8. Recommendations | Actionable improvement items |

Read-only — never modify reviewed files. Produce a YAML verdict only.

## Process

See `references/process.md` for the full review methodology: 8-step process,
spec compliance checks, quality review dimensions, verdict format, and common findings.
