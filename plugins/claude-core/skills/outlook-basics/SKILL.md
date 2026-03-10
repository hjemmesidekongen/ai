---
name: outlook-basics
description: >
  Email search, thread reading, and calendar access via Microsoft 365 MCP. Use when
  searching for emails by sender, subject, or keyword, reading an email thread,
  checking a calendar for upcoming meetings, listing meetings in a time range,
  or finding free/busy slots.
user_invocable: false
interactive: false
triggers:
  - "outlook"
  - "check email"
  - "check calendar"
  - "meeting schedule"
  - "email search"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "mcp_server_available"
      verify: "MCP server 'microsoft365' responds to a list or search call"
      fail_action: "Emit fallback: MCP server 'microsoft365' not configured — this skill requires it"
    - name: "search_returned_results"
      verify: "Email or calendar query returned a non-empty result set, or confirmed empty"
      fail_action: "Broaden query (remove date filter or subject constraint) and retry once"
    - name: "date_range_valid"
      verify: "All date/time parameters use ISO 8601 format"
      fail_action: "Reformat dates to ISO 8601 before reissuing the call"
model_tier: senior
_source:
  origin: "claude-core"
  inspired_by: "D-030 decisions"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New MCP interaction skill for Microsoft 365"
---

# Outlook Basics

Search email, read threads, and check calendar via the Microsoft 365 MCP server.

## MCP requirement

Requires MCP server `microsoft365` to be configured. If not available:

> MCP server 'microsoft365' not configured — this skill requires it

Check with `/mcp` in Claude Code. Tool names follow the pattern `mcp__<plugin>_microsoft365__<tool>`.

## Operations

| Goal | Tool | Key params |
|------|------|-----------|
| Search emails | `outlook_search_messages` | `query`, `top` |
| Read email thread | `outlook_get_message` | `message_id`, `include_body` |
| List calendar events | `outlook_list_events` | `start_datetime`, `end_datetime` |
| Get event details | `outlook_get_event` | `event_id` |
| List calendars | `outlook_list_calendars` | — |
| Search contacts | `outlook_search_contacts` | `query` |

## Execution sequence

**Email search**: provide a focused query, keep `top` ≤ 10 unless more is needed; report sender, subject, received date, and snippet.

**Thread reading**: get the message ID from search results, then fetch full body with `include_body: true`; present thread chronologically.

**Calendar check**: always pass ISO 8601 dates with timezone (`2026-03-10T09:00:00Z`); default to next 7 days when no range is specified.

## Fallback

If the `microsoft365` MCP server is not connected, stop and state the requirement clearly. Do not attempt workarounds.

Full operation details, filter syntax, and error patterns: `references/process.md`.
