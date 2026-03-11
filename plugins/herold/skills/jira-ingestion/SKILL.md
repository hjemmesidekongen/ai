---
name: jira-ingestion
description: >
  Fetch Jira tickets via Atlassian MCP and normalize to local YAML task files.
  Single ticket mode (by key) or bulk mode (by JQL filter). Extracts key, summary,
  description, acceptance criteria, comments, attachments, status, and assignee.
  Auto-runs contradiction-detection after ingestion. Falls back to dry-run mode
  with sample data when MCP is unavailable.
user_invocable: true
interactive: false
model_tier: senior
depends_on:
  - "contradiction-detection"
  - "kronen:jira-basics"
triggers:
  - "ingest ticket"
  - "import jira"
  - "task ingest"
  - "jira ticket"
  - "fetch ticket"
reads:
  - "plugins/herold/resources/test-data/sample-ticket.yml"
writes:
  - ".ai/tasks/<KEY>.yml"
  - ".ai/tasks/attachments/<KEY>/"
checkpoint:
  type: data_validation
  required_checks:
    - name: "task_file_written"
      verify: "At least one .ai/tasks/<KEY>.yml file exists with all required fields"
      fail_action: "Re-run ingestion for failed tickets"
    - name: "schema_valid"
      verify: "Each task file matches the normalized task schema (see process.md)"
      fail_action: "Fix missing fields — check MCP response for raw data"
    - name: "contradiction_run"
      verify: "contradiction-detection ran on every ingested ticket"
      fail_action: "Run contradiction-detection manually on skipped tickets"
  on_fail: "Report which tickets failed ingestion and why."
  on_pass: "Report: ingested N tickets, M contradictions found."
_source:
  origin: "herold"
  inspired_by: "agent-toolkit-main/skills/jira/SKILL.md"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "New skill. MCP-based Jira ingestion with dry-run fallback."
---

# jira-ingestion

Pulls Jira tickets into local `.ai/tasks/` as normalized YAML. Works in single-ticket
or bulk mode. Runs contradiction-detection automatically after ingestion.

## Steps

1. **Determine mode** — single key (`PROJ-123`) or JQL (`project = PROJ AND sprint in openSprints()`)
2. **Check MCP availability** — attempt Atlassian MCP connection. If unavailable, switch to dry-run using `resources/test-data/sample-ticket.yml`
3. **Fetch tickets** — call MCP tools to retrieve ticket data (see `references/process.md` for API mapping)
4. **Normalize** — map Jira fields to local task schema. Write each ticket to `.ai/tasks/<KEY>.yml`
5. **Download attachments** — save to `.ai/tasks/attachments/<KEY>/`. Skip if dry-run.
6. **Run contradiction-detection** — invoke on each ingested ticket
7. **Report** — list ingested tickets, contradiction counts, any failures

## Dry-run mode

When Atlassian MCP is not connected, the skill reads `resources/test-data/sample-ticket.yml`
and processes it through the same normalization pipeline. Useful for testing the ingestion
flow without a live Jira connection. Output goes to `.ai/tasks/` as normal.

## Never

- Never fabricate ticket data when MCP is unavailable — use dry-run with sample data only
- Never skip contradiction-detection after ingestion
- Never overwrite an existing task file without merging new data

Output: `Ingested N ticket(s). Contradictions: M found across N tickets.`
