# Confluence Basics — Process Reference

Detailed search patterns, CQL syntax, and error handling for the `confluence-basics` skill.

---

## Search by title

Use the Atlassian MCP `confluence_search` tool with a `title` filter when the user names
a specific page or document.

```
title = "API Reference" AND space = "ENG"
```

- Exact match uses `=`; partial match uses `~`
- Combine with `space` to avoid cross-team noise
- Results: page ID, title, space key, URL, last modified

## Search by content

Use `text ~` for full-text content search when the user describes what the document covers.

```
text ~ "authentication flow" AND space = "PLATFORM"
```

- Slower than title search; use as fallback
- Narrow with `space`, `label`, or `ancestor` to improve signal
- Avoid single common words — require at least 2 meaningful terms

## CQL query patterns

Confluence Query Language (CQL) is the standard filtering syntax for the Atlassian API.

### Common operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `=` | Exact match | `space = "ENG"` |
| `~` | Contains / fuzzy | `title ~ "deploy"` |
| `!=` | Not equal | `type != "blogpost"` |
| `IN` | Value in list | `space IN ("ENG", "OPS")` |
| `AND` | Both conditions | `type = "page" AND label = "onboarding"` |
| `OR` | Either condition | `title ~ "auth" OR label = "auth"` |

### Content type filter

```
type = "page"       # Wiki pages only
type = "blogpost"   # Blog posts only
```

Default: all content types. Filter to `page` unless the user asks for blogs.

### Date filters

```
lastModified >= "2024-01-01"
lastModified >= now("-30d")
```

Use when the user asks for "recent" documentation.

### Ordering

```
ORDER BY lastModified DESC
ORDER BY title ASC
```

Default order is relevance. Use `lastModified DESC` for "latest" queries.

---

## Space filtering

Always ask for the Confluence space when the query is ambiguous across teams.

Common patterns:
- User says "our docs" → ask which space key
- User mentions a team name → map to their space key if known
- User mentions a project name → check if it matches a space key directly

If the user cannot provide a space, search all spaces but cap results at 5.

---

## Page hierarchy navigation

### Get child pages

Use `ancestor = <page-id>` in CQL to retrieve pages nested under a parent.

```
ancestor = 12345678 AND type = "page"
```

### Get parent context

After retrieving a page, the response includes `ancestors` — an ordered array from
root to direct parent. Report the last 2 ancestors for context.

### Find a page by ID

If the user provides a direct URL, extract the page ID from:
- Modern URL: `/wiki/spaces/SPACE/pages/<id>/...`
- Legacy URL: `?pageId=<id>`

Then call `confluence_get_page` with the extracted ID.

---

## Label filtering

```
label = "onboarding"
label IN ("runbook", "incident-response")
```

Labels are set by Confluence authors. They are exact match only — no fuzzy matching.

Useful when the user asks for pages tagged with a specific topic or workflow.

---

## Common search patterns

| User intent | CQL pattern |
|-------------|-------------|
| Find a specific page by name | `title = "Page Name" AND type = "page"` |
| Find pages about a topic | `text ~ "topic keyword" AND type = "page"` |
| Find docs in a space | `space = "KEY" AND type = "page"` |
| Find recent changes | `space = "KEY" ORDER BY lastModified DESC` |
| Find by label | `label = "runbook" AND space = "OPS"` |
| Find child pages | `ancestor = <id> AND type = "page"` |
| Find by author | `creator = "username" AND type = "page"` |

---

## Reading page content

After locating a page:

1. Call `confluence_get_page` with the page ID.
2. Extract the `body.storage.value` (Confluence storage format — XML-like markup).
3. Strip markup tags and return readable plain text.
4. Summarize unless the user explicitly asks for the full content.

Output format:

```
Title: <page title>
Space: <space name> (<space key>)
URL: <page URL>
Last modified: <date>

Summary:
<2–4 sentence summary of content>
```

If the user asks for full content, return the stripped plain text without the summary header.

---

## Error handling

| Error | Likely cause | Action |
|-------|-------------|--------|
| `401 Unauthorized` | Token expired or missing | Report auth failure; do not retry |
| `403 Forbidden` | Page exists but user lacks access | Report permission restriction |
| `404 Not Found` | Page ID wrong or deleted | Try title search instead |
| `429 Too Many Requests` | Rate limit hit | Wait and retry once; report if second attempt fails |
| Empty results | Query too narrow | Broaden terms, remove space filter, try `text ~` |
| Timeout | Large space, slow query | Add `type = "page"` filter and retry |

---

## Anti-patterns

- **Do not** dump raw Confluence storage XML to the user — strip markup first.
- **Do not** search without at least one meaningful filter (title, text, space, or label).
- **Do not** return more than 10 results without asking the user to narrow the query.
- **Do not** retry auth failures — they require user action to fix.
- **Do not** write Confluence content to local files unless the user explicitly asks.
- **Do not** infer page content from search snippets — fetch the full page for accuracy.
