---
name: plugin-reviewer
description: >
  Review and validate Claude Code plugins for manifest correctness, component
  registration, portability, and settings patterns. Use when reviewing plugins after
  creation, auditing existing plugins, or validating plugin changes before committing.
user_invocable: false
interactive: false
depends_on:
  - plugin-creator
reads:
  - "plugins/*/.claude-plugin/plugin.json"
  - "plugins/*/.claude-plugin/ecosystem.json"
  - "plugins/.claude-plugin/marketplace.json"
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "two_stage_review"
      verify: "Both spec compliance and quality review stages completed"
      fail_action: "Run missing stage per references/process.md"
    - name: "component_audit"
      verify: "Every file on disk cross-checked against ecosystem.json"
      fail_action: "Run component audit per references/process.md"
    - name: "verdict_produced"
      verify: "YAML verdict with status (pass/pass_with_notes/fail) generated"
      fail_action: "Generate verdict per verdict format in references/process.md"
    - name: "no_modifications"
      verify: "Reviewed files were not modified during review"
      fail_action: "Revert any changes — reviewers are read-only"
model_tier: principal
_source:
  origin: "claude-core"
  inspired_by: "https://github.com/anthropics/plugin-dev/skills/plugin-structure"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Two-stage plugin review combining mechanical manifest/registry checks with quality review for portability, settings patterns, and auto-discovery compatibility."
---

# Plugin Reviewer

Reviews Claude Code plugins for manifest correctness, registration, and portability.

## When to trigger

- Reviewing a plugin after creation or modification
- Auditing plugin manifest and ecosystem.json
- Validating marketplace registration
- Checking portability (no hardcoded paths)
- Verifying component disk-to-registry consistency

## Review stages

| Stage | Focus | Gate |
|-------|-------|------|
| **1: Spec compliance** | Manifest fields, ecosystem.json, component audit, hooks | All checks must pass |
| **2: Quality review** | Portability, settings patterns, cache docs, organization | Judgment-based |

Read-only — never modify reviewed files. Produce a YAML verdict only.

## Process

See `references/process.md` for the full review methodology: spec compliance checks,
component audit procedure, quality review dimensions, settings pattern validation,
portability checklist, verdict format, and common findings.
