---
name: jira-basics
description: >
  Basic Jira operations via Atlassian MCP — read tickets, search with JQL,
  transition status, add comments. Use when asked to check a Jira ticket,
  search issues, update ticket status, or add a comment in Jira.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
reads: []
writes: []
triggers:
  - "jira"
  - "ticket"
  - "jira ticket"
  - "check ticket"
  - "jira search"
checkpoint:
  type: data_validation
  required_checks:
    - name: "mcp_available"
      verify: "Atlassian MCP server responded without connection error"
      fail_action: "Print missing MCP message and stop — do not attempt workarounds"
    - name: "ticket_key_valid"
      verify: "Ticket key matches pattern [A-Z]+-[0-9]+ before any MCP call"
      fail_action: "Ask user to confirm ticket key format"
    - name: "transition_confirmed"
      verify: "Status transition is valid for current workflow state"
      fail_action: "List available transitions and ask user to choose"
_source:
  origin: "kronen"
  inspired_by: "D-029 decisions"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New MCP interaction skill for Atlassian Jira"
---

# Jira Basics

Interact with Jira via the `atlassian` MCP server. Read tickets, search with
JQL, transition status, add comments.

## MCP Server Requirement

Before any operation, verify the `atlassian` MCP server is available. If a
call fails with a connection or "server not found" error, stop immediately and
print:

```
MCP server 'atlassian' not configured — this skill requires it
```

Do not attempt REST API fallbacks or workarounds. Surface the gap and stop.

## Key Operations

| Operation | When to use |
|---|---|
| Read ticket | Fetch fields, status, assignee, description, comments |
| JQL search | Find issues matching criteria — sprints, assignees, labels |
| Transition status | Move ticket through workflow states |
| Add comment | Post update or question to ticket thread |
| Bulk read | Fetch multiple tickets in one pass when context needs several |

## Key Rules

- Validate ticket key format (`[A-Z]+-[0-9]+`) before calling MCP.
- Never guess a transition name — fetch available transitions first.
- For status changes, confirm with user if the target state is ambiguous.
- JQL searches: always specify `maxResults` to avoid unbounded responses.
- Comments are permanent — confirm content before posting.
- On any MCP error, report the raw error message and stop. Do not retry silently.

Full MCP tool patterns, JQL examples, and anti-patterns: [references/process.md](references/process.md)
