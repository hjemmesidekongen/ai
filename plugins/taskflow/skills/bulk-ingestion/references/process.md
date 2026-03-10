# bulk-ingestion — Process Detail

## URL Parsing Patterns

The skill accepts three input forms. Parse the URL to extract the relevant ID.

### Board URL

```
https://<org>.atlassian.net/jira/software/projects/<PROJECT>/boards/<BOARD_ID>
```

Extract: `BOARD_ID` (numeric). Use to derive active sprint via:
```
get-board-sprints(boardId: <BOARD_ID>, state: "active")
```

### Filter URL

```
https://<org>.atlassian.net/issues/?filter=<FILTER_ID>
```

Extract: `FILTER_ID` (numeric). Call `get-filter(filterId)` to retrieve the saved JQL,
then execute that JQL directly.

### Project Key (bare input)

If the user supplies just a project key (e.g., `PROJ`), treat it as a project-level query.

## JQL Query Construction

| Input type | Generated JQL |
|------------|---------------|
| Board (active sprint) | `project = <KEY> AND sprint in openSprints() AND assignee = currentUser() AND status != Done` |
| Board (all open) | `project = <KEY> AND assignee = currentUser() AND status not in (Done, Closed, Resolved)` |
| Filter | Use saved JQL from filter verbatim; do not append extra clauses |
| Project key | `project = <KEY> AND assignee = currentUser() AND status not in (Done, Closed, Resolved)` |

Always add `ORDER BY updated DESC` to all generated queries.

Confirm the generated JQL with the user before executing if more than 50 tickets are expected.

## Batch Processing Pipeline

```
for each KEY in ticket_list:
  1. check if .ai/tasks/<KEY>.yml exists and is current (modified < 24h)
     → if yes: skip, record as "already_local"
  2. invoke jira-ingestion(KEY)
     → on success: record as "ingested"
     → on failure: record as "error" with reason; continue
  3. invoke contradiction-detection(KEY)
     → on success: record contradiction count
     → on failure: log warning; do not block ingestion record
```

## Progress Reporting Format

```
Bulk ingestion: <PROJECT> board (<BOARD_ID>)
JQL: <generated query>
Fetched 47 tickets — starting ingestion...

Progress:  10/47  ✓ 9  ✗ 1  skipped 0
Progress:  20/47  ✓ 18  ✗ 2  skipped 0
Progress:  30/47  ✓ 26  ✗ 2  skipped 2
...
Done: 47 processed in <duration>
```

## Rate Limiting

Atlassian MCP enforces rate limits. If a `429` or rate-limit error is returned:
1. Pause for 5 seconds
2. Retry the current ticket once
3. If it fails again, skip and log as error

Do not hammer the API — add a 100ms pause between tickets when batch size > 20.

## Error Handling Per Ticket

Errors that should skip the ticket and continue:
- `404 Not Found` — ticket deleted or no access
- `403 Forbidden` — no read permission
- MCP timeout on a single ticket

Errors that should pause the batch and surface to user:
- MCP server disconnects (all calls failing)
- Auth token expired (401 on all calls)

## Deduplication with Existing Local Tasks

A ticket is considered "already local" when:
1. `.ai/tasks/<KEY>.yml` exists, AND
2. Its `fetched_at` timestamp is less than 24 hours old

If the file exists but is stale (>24h), re-ingest to pick up status changes.

Always list the skipped keys in the summary so the user knows what was not refreshed.

## bulk-ingestion-summary.yml Output Schema

```yaml
completed_at: "2026-03-10T15:30:00Z"
source:
  type: "board"          # board | filter | project
  id: "42"
  url: "https://..."
jql: "project = PROJ AND sprint in openSprints()..."
counts:
  fetched: 47
  ingested: 38
  skipped_already_local: 5
  errors: 4
  contradictions_found: 6
errors:
  - key: "PROJ-91"
    reason: "404 Not Found — ticket may have been deleted"
  - key: "PROJ-104"
    reason: "MCP timeout after 2 retries"
```

## Anti-Patterns

- **Do not stop the batch on a single ticket failure** — log and continue.
- **Do not re-ingest tickets already local and fresh** — deduplication exists for a reason.
- **Do not pass raw JQL as user input without parsing** — always derive JQL from the URL type.
- **Do not run contradiction-detection on failed ingestions** — only on successfully written tasks.
- **Do not report "done" before summary is written** — write the summary file first.
- **Do not fetch more than 200 tickets without confirming** — large batches can saturate context.
