---
name: decision-reader
description: >
  Utility skill that reads brainstorm decisions and returns them to calling
  skills. Bridge between /brainstorm:decide and structured interview workflows.
  Does not write files — reads and filters only. Use when loading brainstorm
  decisions, checking for prior decisions during interviews, running a
  pre-interview decision check, or filtering decisions by domain.
interactive: false
depends_on: []
reads:
  - ".ai/brainstorm/[project-name]/decisions.yml"
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "finds_existing_decisions"
      verify: "Returns decisions when decisions.yml exists at the expected path"
      fail_action: "Check file path resolution logic"
    - name: "empty_when_missing"
      verify: "Returns empty result (decisions_found: false) when no decisions.yml — NOT an error"
      fail_action: "Ensure missing file returns empty result, not error"
    - name: "domain_filtering"
      verify: "Only returns decisions matching the requested domains"
      fail_action: "Fix domain filter — check array intersection logic"
    - name: "multiple_per_domain"
      verify: "Returns all matching decisions per domain, not just the first"
      fail_action: "Remove any early-return logic in domain filtering"
    - name: "priority_order"
      verify: "Checks .ai/brainstorm/ before .ai/brands/ and uses first found"
      fail_action: "Fix search order in Step 1"
  on_fail: "Fix the failing check and re-validate."
  on_pass: "Decision reader is working correctly."
---

# Decision Reader

Utility skill — reads and filters brainstorm decisions for calling interview skills. Checkpoint: none when used as utility (enforced by caller).

## Context
- Reads: decisions.yml (from project or brand directory)
- Writes: nothing — returns data to caller
- Checkpoint: data_validation (called by interview skills, not standalone)
- Dependencies: none

## Process Summary
1. Locate decisions.yml — check `.ai/brainstorm/` then `.ai/brands/`; empty result if neither exists (not an error)
2. Parse YAML and filter decisions by requested domain(s)
3. Group filtered decisions by confidence (high / medium / low)
4. Return structured result to calling skill

## Execution
Read `references/process.md` for the complete process, invocation modes, output formats, field-matching logic, and guidance on how callers should present decisions.
