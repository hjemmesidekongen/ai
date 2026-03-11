---
name: brainstorm-decision-reader
user_invocable: false
_source:
  origin: "task-planner/skills/decision-reader + agency/skills/dev/decision-reader"
  ported_date: "2026-03-08"
  iteration: 2
  changes: "merged TP read-only utility with agency findings.md writer, domain-agnostic, added domain mapping"
description: >
  Load and filter past brainstorm decisions relevant to the current task. Scans
  all decisions.yml files across brainstorm topics, filters by domain relevance,
  and returns a structured summary. Use when starting new work, before architectural
  decisions, when any skill or agent needs prior context about what was already
  decided, checking what decisions exist for a domain, or reviewing past conclusions
  before making new ones.
depends_on: []
triggers:
  - "load past decisions"
  - "what was decided"
  - "prior decisions"
  - "decision context"
  - "review past conclusions"
reads:
  - ".ai/brainstorm/*/decisions.yml"
writes: []
model_tier: junior
interactive: false
checkpoint:
  type: data_validation
  required_checks:
    - name: "decisions_loaded"
      verify: "At least 1 decisions.yml file was scanned"
      fail_action: "Check .ai/brainstorm/ exists and contains topic directories"
    - name: "relevance_filtered"
      verify: "Decisions filtered by domain match if domain was specified"
      fail_action: "Apply domain filter or return all decisions"
    - name: "output_delivered"
      verify: "Decisions returned to caller or written to specified output path"
      fail_action: "Format and return/write decision summary"
  on_fail: "Fix issues and re-run checkpoint"
  on_pass: "Report count of relevant decisions loaded into context."
---

# Decision Reader

Loads relevant past brainstorm decisions into the current task context.
Utility skill — can be called by any agent or skill needing prior decisions.
Domain-agnostic: works for any plugin, not tied to a specific project structure.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | All `.ai/brainstorm/*/decisions.yml` files |
| **Output** | Returns decisions to caller; optionally writes to a specified path |
| **Checkpoint** | data_validation: decisions loaded, filtered, output delivered |
| **Dependencies** | None (utility — can run anytime) |

## Input

The caller may provide:
- `domains` — list of domains to filter by (e.g., ["dev", "security"]). If omitted, returns all.
- `output_path` — file path to write the summary. If omitted, returns inline.

## Load Flow Summary

1. Scan all `.ai/brainstorm/*/decisions.yml` files
2. Filter decisions by domain relevance (if domains specified)
3. Sort by confidence (high first), then by date (recent first)
4. Return or write structured summary

## Domain Mapping

Related domains auto-included: dev→security,strategy | design→brand,content | content→brand,design | brand→design | devops→dev,security.

Full process and error logging: [references/process.md](references/process.md).
