---
name: decision-reader
user-invocable: false
description: >
  Load and filter past brainstorm decisions relevant to the current task. Scans
  all decisions.yml files across brainstorm topics, filters by domain relevance,
  and writes a summary to the active project's findings.md. Use when starting
  a new skill, before architectural decisions, or when agents need prior context.
phase: 0
depends_on: []
writes:
  - ".ai/projects/[name]/dev/findings.md (decisions section)"
reads:
  - ".ai/brainstorm/*/decisions.yml"
  - ".ai/projects/[name]/state.yml (current module/skill for relevance filter)"
model_tier: junior
model: haiku
interactive: false
checkpoint:
  type: data_validation
  required_checks:
    - name: "decisions_loaded"
      verify: "At least 1 decisions.yml file was scanned"
      fail_action: "Check .ai/brainstorm/ exists and contains topic directories"
    - name: "relevance_filtered"
      verify: "Decisions filtered by domain match to current module/skill"
      fail_action: "Apply domain filter using state.yml current_module"
    - name: "summary_written"
      verify: "findings.md contains ## Past Decisions section"
      fail_action: "Write decisions summary to findings.md"
  on_fail: "Fix issues and re-run checkpoint"
  on_pass: "Report count of relevant decisions loaded into context."
---

# Decision Reader

Loads relevant past brainstorm decisions into the current task context.
Utility skill — can be called by any agent or skill needing prior decisions.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | All decisions.yml files, state.yml for current module/skill |
| **Writes** | findings.md with ## Past Decisions summary |
| **Checkpoint** | data_validation: decisions loaded, relevance filtered, summary written |
| **Dependencies** | None (utility — can run anytime) |

## Load Flow Summary

1. Read state.yml to determine current module, skill, and domain context
2. Scan all `.ai/brainstorm/*/decisions.yml` files
3. Filter decisions by domain relevance to current module/skill
4. Sort by confidence (high first), then by date (recent first)
5. Write summary to `.ai/projects/[name]/dev/findings.md` under ## Past Decisions

## Findings Persistence

Results written directly to findings.md as the primary output of this skill.

## Error Logging — Log errors to state.yml errors array. Check errors before retrying.

## Execution — [references/process.md](references/process.md)
