---
name: bulk-ingestion
description: >
  Batch ingest tickets from a Jira board or filter URL — fetches all assigned
  non-closed tickets with contradiction detection on each. Requires the Atlassian
  MCP server. Falls back gracefully when unavailable.
user_invocable: true
interactive: false
model_tier: senior
depends_on:
  - "jira-ingestion"
  - "contradiction-detection"
triggers:
  - "bulk ingest"
  - "ingest board"
  - "import all tickets"
  - "batch ingest"
reads:
  - ".ai/tasks/*.yml"
writes:
  - ".ai/tasks/<KEY>.yml"
  - ".ai/tasks/bulk-ingestion-summary.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "mcp_available"
      verify: "Atlassian MCP responds before batch starts"
      fail_action: "Surface fallback message and stop"
    - name: "tickets_written"
      verify: "Each fetched ticket has a corresponding .ai/tasks/<KEY>.yml"
      fail_action: "Re-run jira-ingestion for failed keys; continue batch"
    - name: "contradiction_run"
      verify: "contradiction-detection ran on every successfully ingested ticket"
      fail_action: "Run contradiction-detection manually on skipped tickets"
    - name: "summary_written"
      verify: ".ai/tasks/bulk-ingestion-summary.yml exists with counts and errors"
      fail_action: "Write summary from in-memory results before reporting"
  on_fail: "Report which tickets failed, reason, and how many succeeded."
  on_pass: "Report: ingested N, skipped M (already local), errors K, contradictions found."
_source:
  origin: "taskflow"
  inspired_by: "D-014 decisions"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New skill. Board/filter URL → batch jira-ingestion + contradiction-detection."
---

# bulk-ingestion

Batch ingest all assigned, non-closed tickets from a Jira board or saved filter.
Deduplicates against existing local tasks. Runs contradiction-detection per ticket.

## MCP requirement

Requires Atlassian MCP. If not configured:

> "MCP server 'atlassian' not configured — this skill requires it. Add it to your
> MCP server list and restart Claude Code."

## Steps

1. **Parse input** — extract board ID, filter ID, or project key from the supplied URL
   (see `references/process.md` for URL patterns)
2. **Build JQL** — construct query from input type (see process.md)
3. **Check MCP** — verify Atlassian MCP responds before starting batch
4. **Fetch ticket list** — get all matching keys from JQL; report count before proceeding
5. **Deduplicate** — skip keys that already have a current local `.ai/tasks/<KEY>.yml`
6. **Batch ingest** — invoke `jira-ingestion` per ticket; continue on individual failures
7. **Contradiction detection** — invoke `contradiction-detection` on each ingested ticket
8. **Write summary** — write `.ai/tasks/bulk-ingestion-summary.yml` with counts and errors
9. **Report** — ingested N, skipped M (already local), errors K, contradictions found

## Progress & Errors

Emit progress every 10 tickets: `Progress: 10/47 ingested (2 errors)`. Individual failures don't stop the batch — log and continue. If MCP drops mid-batch, report last completed key and surface resume instruction.

See `references/process.md` for full details.
