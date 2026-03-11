---
name: confluence-basics
description: >
  Confluence page search and content reading via Atlassian MCP. Use when asked
  to find documentation, check Confluence, search by title or content, read
  page content, navigate page hierarchies, or filter by space or label.
user_invocable: false
interactive: false
depends_on: []
triggers:
  - "confluence"
  - "check docs"
  - "find documentation"
  - "confluence search"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "mcp_available"
      verify: "MCP server 'atlassian' is configured and reachable"
      fail_action: "Report: MCP server 'atlassian' not configured — this skill requires it"
    - name: "results_returned"
      verify: "Search returned at least one result or confirmed empty"
      fail_action: "Broaden query terms or try CQL fallback per references/process.md"
    - name: "content_readable"
      verify: "Page content was retrieved without error"
      fail_action: "Check permissions or try alternate page ID resolution"
model_tier: senior
_source:
  origin: "kronen"
  inspired_by: "D-029 decisions"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New MCP interaction skill for Confluence"
---

# Confluence Basics

Search and read Confluence content via the Atlassian MCP server.

## MCP requirement

This skill requires the `atlassian` MCP server. If it is not configured, stop
immediately and report: **MCP server 'atlassian' not configured — this skill requires it.**

Do not attempt workarounds. Surfacing the missing dependency is the correct output.

## Operations

| Operation | When to use |
|-----------|-------------|
| Search by title | User names a specific page or doc |
| Search by content | User describes what the doc covers |
| Read page content | After locating a page, fetch its body |
| Navigate hierarchy | User asks for child pages or parent context |
| Filter by space/label | User scopes to a team, project, or category |

## Key rules

- Always confirm which Confluence space to search when ambiguous.
- Prefer title search first; fall back to CQL content search if no match.
- Return page title, space, URL, and a summary — not a raw content dump.
- If results exceed 5 pages, ask the user to narrow the query.
- Never cache or write Confluence content to disk without explicit instruction.

## Graceful fallback

If the MCP call fails (timeout, auth error, empty results):
1. Report the error clearly.
2. Suggest narrowing or rephrasing the query.
3. Offer to retry with a CQL query if a plain-text search failed.

Full search patterns and CQL syntax: [references/process.md](references/process.md).
