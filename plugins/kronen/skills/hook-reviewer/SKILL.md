---
name: hook-reviewer
description: >
  Review and validate Claude Code hooks for correctness, security, and reliability.
  Use when reviewing hook scripts after creation, auditing existing hooks for issues,
  validating hook changes before committing, checking exit codes and JSON output
  schemas, diagnosing silent or failing hooks, or verifying hook security against
  injection and path traversal.
user_invocable: false
interactive: false
depends_on:
  - hook-creator
triggers:
  - "review hook"
  - "audit hook"
  - "hook security check"
  - "validate hook script"
  - "hook exit codes"
reads:
  - "plugins/*/.claude-plugin/plugin.json"
  - "plugins/*/scripts/*.sh"
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "two_stage_review"
      verify: "Both spec compliance and quality review stages completed"
      fail_action: "Run missing stage per references/process.md"
    - name: "verdict_produced"
      verify: "YAML verdict with status (pass/pass_with_notes/fail) generated"
      fail_action: "Generate verdict per verdict format in references/process.md"
    - name: "no_modifications"
      verify: "Reviewed files were not modified during review"
      fail_action: "Revert any changes — reviewers are read-only"
model_tier: principal
_source:
  origin: "kronen"
  inspired_by: "https://docs.anthropic.com/en/docs/claude-code/hooks"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Two-stage hook review methodology combining spec compliance checks against 18 official events with quality review for security, reliability, and performance."
---

# Hook Reviewer

Reviews Claude Code hook scripts for spec compliance, security, and reliability.

## When to trigger

- Reviewing a hook after creation or modification
- Auditing all hooks in a plugin for correctness
- Validating hook changes before committing
- Checking hook security (input validation, path traversal)
- Diagnosing hook failures or unexpected behavior

## Review stages

| Stage | Focus | Gate |
|-------|-------|------|
| **1: Spec compliance** | Event type, exit codes, JSON schema, shell header | All checks must pass |
| **2: Quality review** | Security, reliability, performance, error handling | Judgment-based |

Read-only — never modify reviewed files. Produce a YAML verdict only.

## Process

See `references/process.md` for the full review methodology: spec compliance checks,
quality review dimensions, 3-level testing hierarchy, verdict format, and common findings.
