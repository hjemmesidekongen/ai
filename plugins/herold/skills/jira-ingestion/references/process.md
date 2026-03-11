# jira-ingestion — Process Reference

## 1. Mode Selection

### Key validation
Before any operation, validate the ticket key matches `/^[A-Z][A-Z0-9]+-[0-9]+$/`.
Reject keys containing path separators, dots, spaces, or special characters.
This prevents path traversal in `.ai/tasks/<KEY>.yml` file writes.

### Single ticket
Input: a Jira key like `PROJ-123`.
Action: fetch that one ticket.

### Bulk mode
Input: a JQL string like `project = PROJ AND sprint in openSprints() AND assignee = currentUser()`.
Action: fetch all matching tickets. Process each sequentially.

If no input provided, prompt the user for a ticket key or JQL filter.

---

## 2. MCP Availability Check

Before calling any MCP tool, verify the Atlassian MCP server is connected:
1. Attempt a lightweight MCP call (e.g., list projects or fetch a known ticket)
2. If the call fails or the MCP tool is not available, log: `MCP unavailable — switching to dry-run mode`
3. In dry-run mode, read `plugins/herold/resources/test-data/sample-ticket.yml` as the source

---

## 3. Fetch Algorithm

### Via MCP (live mode)
```
for each ticket_key:
  1. Call MCP get_issue(key) → raw JSON
  2. Extract: key, summary, description, status, assignee, priority, labels, sprint, epic
  3. Extract: acceptance criteria (from description parsing or custom field)
  4. Fetch comments: MCP get_comments(key) → array of {author, date, body}
  5. Fetch attachments metadata: MCP get_attachments(key) → array of {name, url, mimeType}
  6. Download each attachment to .ai/tasks/attachments/<KEY>/<filename>
```

### Via dry-run (offline mode)
```
  1. Read sample-ticket.yml
  2. Parse as already-normalized data
  3. Skip attachment download (use paths as-is)
  4. Write to .ai/tasks/<KEY>.yml
```

---

## 4. Normalized Task Schema

Every ingested ticket produces a YAML file at `.ai/tasks/<KEY>.yml`:

```yaml
key: "PROJ-456"
summary: "Implement user search with autocomplete"
description: |
  Full description text from the ticket body.
acceptance_criteria:
  - "Criterion 1"
  - "Criterion 2"
comments:
  - author: "sarah.chen"
    date: "2026-03-07T14:30:00Z"
    body: "Comment text"
attachments:
  - name: "mockup.png"
    path: ".ai/tasks/attachments/PROJ-456/mockup.png"
status: "open"
assigned_to: "me"
priority: "Medium"
labels: ["frontend", "search"]
sprint: "Sprint 12"
epic: "PROJ-100"
ingested_at: "2026-03-09T20:00:00Z"
source:
  type: "jira"
  url: "https://example.atlassian.net/browse/PROJ-456"
```

### Required fields
All fields above are required. If Jira returns null for a field, use these defaults:
- `acceptance_criteria: []`
- `comments: []`
- `attachments: []`
- `labels: []`
- `sprint: null`
- `epic: null`
- `assigned_to: "unassigned"`

---

## 5. Acceptance Criteria Extraction

Jira tickets often embed AC in the description using patterns:
1. **Heading pattern**: `h3. Acceptance Criteria` or `## Acceptance Criteria` followed by bullet list
2. **Custom field**: `customfield_10100` (varies by instance)
3. **Checkbox pattern**: `* [x]` or `* [ ]` lines in description

Extraction priority:
1. Custom field (if populated)
2. Heading-based extraction from description
3. Checkbox extraction from description
4. Empty array if none found

---

## 6. Attachment Handling

```
for each attachment in ticket:
  1. Create directory: .ai/tasks/attachments/<KEY>/
  2. Download via MCP attachment URL
  3. Sanitize filename: strip path separators (/ and \), leading dots, and non-alphanumeric
     characters except hyphens, underscores, and single dots. Reject names that don't match
     /^[a-zA-Z0-9][a-zA-Z0-9._-]*$/
  4. Save as: .ai/tasks/attachments/<KEY>/<sanitized-filename>
  5. Record in task YAML: {name: "<sanitized-filename>", path: "<relative-path>"}
```

Skip binary files larger than 10MB — log a warning instead.
In dry-run mode, attachment paths reference the sample data but files are not copied.

---

## 7. Post-Ingestion

After all tickets are normalized and written:
1. Run `contradiction-detection` on each `.ai/tasks/<KEY>.yml`
2. Append contradiction results to the task file under `contradictions:` key
3. Collect summary stats: total ingested, total contradictions by severity

---

## 8. Error Handling

| Error | Action |
|-------|--------|
| MCP not available | Switch to dry-run, warn user |
| Ticket not found (404) | Log warning, skip ticket, continue batch |
| Network timeout | Retry once after 3s, then skip with warning |
| Attachment download fails | Log warning, record attachment without file |
| Invalid JQL | Report syntax error, abort batch |
| Write permission denied | Abort with error — `.ai/tasks/` must be writable |

All errors are logged to trace-light.log with severity annotation.

---

## 9. Example: Full Single-Ticket Flow

```
User: "ingest ticket PROJ-456"

1. Mode: single ticket (PROJ-456)
2. MCP check: Atlassian MCP connected ✓
3. Fetch PROJ-456 via MCP
4. Normalize to task schema
5. Download 2 attachments (search-mockup.png, search-api-spec.pdf)
6. Write .ai/tasks/PROJ-456.yml
7. Run contradiction-detection on PROJ-456
   → Found 2 contradictions (1 warning, 1 info)
8. Update .ai/tasks/PROJ-456.yml with contradictions
9. Report: "Ingested 1 ticket. Contradictions: 2 found (1 warning, 1 info)."
```

---

## 10. Example: Dry-Run Flow

```
User: "ingest ticket PROJ-456" (no MCP connected)

1. Mode: single ticket
2. MCP check: not available → dry-run mode
3. Read plugins/herold/resources/test-data/sample-ticket.yml
4. Write .ai/tasks/PROJ-456.yml (from sample data)
5. Skip attachment download
6. Run contradiction-detection
   → Found 2 contradictions from sample data
7. Report: "[DRY RUN] Ingested 1 ticket from sample data. Contradictions: 2."
```
