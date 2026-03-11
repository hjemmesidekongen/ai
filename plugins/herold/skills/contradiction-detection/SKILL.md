---
name: contradiction-detection
description: >
  Analyze Jira ticket descriptions against comments to detect contradictions,
  modifications, and extensions to requirements. Produces a severity-ranked
  list of findings with original text, contradicting text, and resolution
  suggestions. Runs standalone or auto-triggered after jira-ingestion.
user_invocable: true
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "check contradictions"
  - "contradiction detection"
  - "requirement conflicts"
  - "analyze requirements"
reads:
  - ".ai/tasks/<KEY>.yml"
writes:
  - ".ai/tasks/<KEY>.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "analysis_complete"
      verify: "Every comment was analyzed against description and acceptance criteria"
      fail_action: "Re-run analysis on skipped comments"
    - name: "findings_written"
      verify: "contradictions key exists in task YAML (even if empty array)"
      fail_action: "Write contradictions: [] to task file"
    - name: "severities_valid"
      verify: "Each finding has severity of blocker, warning, or info"
      fail_action: "Assign severity based on impact classification rules"
  on_fail: "Report which tickets had incomplete analysis."
  on_pass: "Report: N findings across M tickets (blockers: X, warnings: Y, info: Z)."
_source:
  origin: "herold"
  inspired_by: "original — no external reference"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "New skill. LLM-based requirement contradiction analysis."
---

# contradiction-detection

Reads a normalized task file and uses LLM analysis to find where comments
contradict, modify, or extend the original requirements.

## When to run

- Automatically after jira-ingestion completes
- Manually when reviewing a task before starting implementation
- When new comments are added to a ticket (re-ingest then re-analyze)

## Steps

1. **Load task** — read `.ai/tasks/<KEY>.yml`. Extract `description`, `acceptance_criteria`, and `comments`
2. **Classify each comment** — determine if it modifies, contradicts, or extends the original spec (see `references/process.md` for classification rules)
3. **Generate findings** — for each detected issue, produce: `original`, `contradicting`, `severity`, `resolution`
4. **Write results** — update the `contradictions` key in the task YAML
5. **Report** — summary of findings by severity

## Severity levels

| Level | Meaning | Example |
|-------|---------|---------|
| blocker | Direct contradiction that changes core behavior | "Don't use REST, use GraphQL" vs spec saying REST |
| warning | Modification that changes acceptance criteria | "Empty search shows recent users" vs "shows nothing" |
| info | Additive extension, no conflict with existing spec | "Also add search by username" |

Finding schema: `severity`, `original`, `contradicting`, `resolution` — see `references/process.md` §5.

## Never

- Never assign blocker severity to additive-only comments — those are info
- Never fabricate findings when no contradictions exist — empty array is correct
- Later comments can resolve earlier contradictions — see `references/process.md` §6

Output: `Contradiction analysis complete. Findings: N (blockers: X, warnings: Y, info: Z)`
