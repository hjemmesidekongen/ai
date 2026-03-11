# Outlook Basics — Full Reference

## Email search

### Basic search

```
outlook_search_messages(query="budget approval", top=10)
→ { value: [{ id: "AAA...", subject: "...", from: {...}, receivedDateTime: "...", bodyPreview: "..." }] }
```

`top` defaults to 10. Increase only when the user needs broader results.
Results are returned newest-first.

### Common search patterns

| Goal | Query string |
|------|-------------|
| Keyword in subject | `subject:budget` |
| From a sender | `from:alice@example.com` |
| To a recipient | `to:team@example.com` |
| Has attachment | `hasAttachment:true` |
| Combined | `from:alice subject:budget` |
| Exact phrase | `"Q4 review"` |

Microsoft 365 search uses KQL (Keyword Query Language). Combine filters with spaces (implicit AND) or `OR`.

### Filter by date

Pass `received_date_time ge 2026-01-01` as an OData `$filter` parameter if the tool supports it. Otherwise include date context in the query string:

```
query="budget after:2026-01-01"
```

If the tool only accepts a free-text query, describe the date range in natural language and let the server handle interpretation, then confirm results have the expected date range.

### Filter by folder

Some tools accept a `folder` parameter (e.g., `inbox`, `sent`, `drafts`). Default is inbox. Specify when context makes another folder likely (e.g., user says "email I sent last week").

## Reading an email thread

### Fetch message body

```
outlook_get_message(message_id="AAA...", include_body=true)
→ { id: "...", subject: "...", body: { content: "...", contentType: "html" } }
```

When `contentType` is `html`, strip tags for display unless the user needs rendered output.

### Reconstruct a thread

1. Search for messages with matching `subject` or `conversationId`
2. Sort results by `receivedDateTime` ascending for chronological order
3. Present: sender name + date header, then body

Threads in Outlook are grouped by `conversationId`. If the tool exposes it, filter by conversation ID for a clean thread.

## Calendar operations

### List events

```
outlook_list_events(
  start_datetime="2026-03-10T00:00:00Z",
  end_datetime="2026-03-17T23:59:59Z"
)
→ { value: [{ id: "...", subject: "...", start: {...}, end: {...}, organizer: {...} }] }
```

Always use ISO 8601 with timezone offset or `Z` for UTC. Missing timezone causes incorrect results.

Default range when not specified: today through 7 days from now.

### Get event details

```
outlook_get_event(event_id="BBB...")
→ { subject: "...", start: {...}, end: {...}, location: {...}, attendees: [...], body: {...} }
```

Use when you need attendee list, meeting link, or agenda from the event body.

### List calendars

```
outlook_list_calendars()
→ { value: [{ id: "...", name: "Calendar", isDefaultCalendar: true }, ...] }
```

Most users have one primary calendar. If they have multiple (personal + work), clarify which one before listing events.

## Date and time handling

All datetimes must be ISO 8601:

```
2026-03-10T09:00:00Z          # UTC
2026-03-10T09:00:00-05:00     # Eastern Standard Time
```

When the user gives a natural-language date ("next Monday"), convert it before calling the tool. Always confirm the resolved date with the user if there's any ambiguity.

## Searching contacts

```
outlook_search_contacts(query="alice")
→ { value: [{ displayName: "Alice Smith", emailAddresses: [...] }] }
```

Useful when you need an email address before composing a message or checking meeting attendees.

## Error handling

| Error | Cause | Fix |
|-------|-------|-----|
| `401 Unauthorized` | Auth token expired | Re-authenticate; the MCP server may need reconnection |
| `404 Not Found` | Wrong message or event ID | Re-run search to get a fresh ID |
| `400 Bad Request` | Malformed date or OData filter | Validate ISO 8601 format; simplify filter |
| Empty results | Query too narrow | Remove one constraint and retry |
| Tool not found | MCP server not connected | Emit fallback message; stop |

When a search returns zero results, try broadening before reporting "nothing found" — a date filter is usually the easiest thing to remove first.

## Anti-patterns

- **Don't use ambiguous date formats** — never `03/10/26` or `10 March`; always ISO 8601 with timezone.
- **Don't fetch large result sets speculatively** — start with `top=10`; increase only if the user needs more.
- **Don't present raw HTML** — strip tags from `html` body content before showing to the user.
- **Don't construct email IDs by hand** — always get them from search results; IDs are opaque and long.
- **Don't assume a single calendar** — check `isDefaultCalendar` or ask if the user has multiple calendars.
- **Don't retry on 401 immediately** — token refresh requires user action or server reconnection, not a simple retry.
