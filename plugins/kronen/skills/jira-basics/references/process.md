# Jira Basics — Process Reference

## 1. MCP Server Detection

The `atlassian` MCP server must be configured before this skill can do anything.
Detection happens implicitly — if the first MCP call returns a connection error or
"server not found", treat that as unconfigured.

**Required response on missing server:**

```
MCP server 'atlassian' not configured — this skill requires it
```

Do not fall back to REST API calls, curl, or browser automation. Stop and surface the gap.

**Check before any session that uses Jira heavily:** confirm the server is available with
a lightweight call (e.g., read a single well-known ticket) before chaining operations.

---

## 2. Reading Tickets

### Fields to fetch by default

- `summary`, `status`, `assignee`, `reporter`, `priority`
- `description` (may be Atlassian Document Format — extract plain text)
- `labels`, `components`, `fixVersions`
- `created`, `updated`, `duedate`

### Comments

Fetch separately if needed — comments are paginated. Pass `startAt` and `maxResults`.
Default page size: 50. Always check `total` vs fetched count.

### Attachments

List attachment metadata (name, size, mimeType) from the issue fields. Download
content only when the user explicitly asks — attachments can be large.

### Bulk read pattern

When context requires multiple tickets (e.g., sprint planning, dependency mapping),
fetch them in a single JQL query rather than individual reads:

```
project = PROJ AND issue in (PROJ-101, PROJ-102, PROJ-103)
```

---

## 3. JQL Search Patterns

### Common queries

| Intent | JQL |
|---|---|
| My open tickets | `assignee = currentUser() AND statusCategory != Done` |
| Active sprint | `project = PROJ AND sprint in openSprints()` |
| Unassigned in sprint | `project = PROJ AND sprint in openSprints() AND assignee is EMPTY` |
| Recently updated | `project = PROJ AND updated >= -7d ORDER BY updated DESC` |
| By label | `project = PROJ AND labels = "needs-review"` |
| Blocked tickets | `project = PROJ AND labels = "blocked" AND statusCategory != Done` |
| High priority open | `project = PROJ AND priority in (Highest, High) AND statusCategory != Done` |
| Linked to epic | `project = PROJ AND "Epic Link" = PROJ-42` |

### Search rules

- Always set `maxResults` — default is often 50, but explicit is safer. Cap at 100 for
  display; use pagination for exports.
- Use `ORDER BY` when result order matters (updated, priority, created).
- `statusCategory` is more stable than `status` name across Jira instances.
  Values: `To Do`, `In Progress`, `Done`.
- Field names with spaces need quotes: `"Story Points"`, `"Epic Link"`.
- Use `currentUser()` instead of hardcoded usernames — portable across instances.

### Filters

Named filters (saved JQL queries) can be referenced by ID. Prefer JQL inline for
skill use — named filters require knowing the filter ID upfront.

---

## 4. Status Transitions

### Workflow-aware approach

Never assume a transition name. Fetch available transitions first, then apply.

**Step 1 — get available transitions:**
Use the MCP tool to retrieve transitions for the ticket. Returns a list of:
- `id` (numeric string)
- `name` (e.g., "Start Progress", "Done", "Reopen")
- `to.name` (target status name)

**Step 2 — confirm with user if ambiguous:**
If the requested state maps to multiple transitions (e.g., two paths to "Done"),
list the options and ask which to use.

**Step 3 — apply by transition ID, not name:**
Transition IDs are stable within a workflow instance. Names can differ across projects.

### Common workflow states

Standard Jira workflows vary by project type. Most include:

```
To Do → In Progress → In Review → Done
         ↓
       Blocked (label, not always a status)
```

Software projects may add: `Selected for Development`, `QA`, `Closed`.

### Transition with resolution

Some "Done" transitions require a `resolution` field:
- `Fixed`, `Won't Fix`, `Duplicate`, `Cannot Reproduce`

Pass resolution in the transition payload if required — the MCP call will error
if it's missing and the field is mandatory.

---

## 5. Adding Comments

### Before posting

- Confirm the comment text with the user unless it was explicitly provided.
- Comments are permanent. Jira has no soft-delete for non-admins.
- Format as plain text unless the instance supports Atlassian Document Format (ADF).

### ADF vs plain text

Older Jira Server instances use wiki markup. Jira Cloud uses ADF (JSON structure).
When in doubt, use plain text — it renders safely in both.

### Mentioning users

Use `@accountId` format for mentions in ADF, `@username` in wiki markup. If you
don't know the account ID, post without mention and note it in the comment.

---

## 6. Bulk Operations

Use bulk operations when acting on more than 3 tickets to avoid rate limits and
reduce round trips.

**Bulk transition:** Not natively supported in Jira REST API. Run transitions
sequentially but in a tight loop — confirm scope with user first.

**Bulk comment:** Same constraint — sequential. Batch only when the comment is
identical across tickets (e.g., sprint closure notes).

**Bulk label add:** Some Jira versions support bulk edit via UI but not API.
Check MCP tool availability before promising this.

---

## 7. Error Handling

| Error type | Action |
|---|---|
| Connection / server not found | Print missing MCP message. Stop. |
| 401 Unauthorized | Tell user their Atlassian credentials in MCP config may be stale. Stop. |
| 403 Forbidden | User lacks permission for this operation on this project. Stop. |
| 404 Not Found | Ticket key doesn't exist or user can't see it. Confirm key with user. |
| 400 Bad Request | Likely invalid transition or missing required field. Report raw error. |
| Rate limit (429) | Wait and retry once. If it fails again, stop and report. |
| Field validation error | Report which field failed. Do not guess correct values. |

On any error not listed here: report the raw error message and stop. Do not retry
silently or attempt workarounds.

---

## 8. Anti-Patterns

**Guessing transition names.** Always fetch available transitions. "Done", "Close",
"Resolve" — the name varies by project and workflow configuration.

**Unbounded JQL searches.** Omitting `maxResults` can return hundreds of tickets.
Always cap results; paginate intentionally when you need more.

**Posting comments without confirmation.** Comments are permanent. Even when
the content seems obvious, confirm before posting.

**Chaining MCP calls without error checks.** A failed ticket read should not
silently cascade into a bad transition or comment. Check each call.

**Using hardcoded usernames.** Use `currentUser()` in JQL and avoid embedding
display names or usernames in queries — they break across Jira instances.

**Fetching full descriptions for every ticket in a bulk search.** Description
fields are large. For list operations, fetch only the fields you'll display.
