---
name: task-ingest-bulk
description: "Batch ingest tickets from a Jira board or filter URL"
argument-hint: "BOARD_URL_OR_FILTER [--limit N]"
---

# Task Ingest Bulk

Fetches all assigned non-closed tickets from a Jira board or filter and ingests them into `.ai/tasks/`.

## Steps

1. **Parse argument** — detect whether the input is a board URL, filter URL, or raw JQL string.
   - Board URL pattern: `*.atlassian.net/jira/software/projects/*/boards/*`
   - Filter URL pattern: `*.atlassian.net/issues/?filter=*`
   - Otherwise treat as raw JQL.

2. **Apply limit** — if `--limit N` is provided, cap the fetch to N tickets. Default: no limit.

3. **Invoke bulk-ingestion skill** with the parsed source and limit.

4. **Print summary**:
   - Total tickets fetched
   - New vs already-existing (skipped)
   - Tickets with contradictions
   - Any failures (key + reason)
   - Example: `Bulk ingest complete. 23 new tickets, 5 skipped (existing), 3 with contradictions, 1 failed (PROJ-456: timeout)`
