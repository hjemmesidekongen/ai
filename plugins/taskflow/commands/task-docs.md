---
name: task-docs
description: "Search related Confluence docs for the active task"
argument-hint: "[SEARCH_QUERY]"
---

# Task Docs

Searches Confluence for documentation related to the active task or a specific query.

## Steps

1. **Determine search context**:
   - If a search query is provided, use it directly.
   - If no query, extract keywords from the active task's summary, description, and acceptance criteria.

2. **Invoke confluence-lookup skill** with the search terms.

3. **Print results** as a numbered list:
   - Page title
   - Space name
   - Relevance indicator
   - URL
   - Example:
     ```
     Related docs for PROJ-123 "Implement user search":
     1. [HIGH] User Search API Design — Engineering Space
        https://company.atlassian.net/wiki/spaces/ENG/pages/12345
     2. [MED] Search Performance Guidelines — Platform Space
        https://company.atlassian.net/wiki/spaces/PLAT/pages/67890
     ```

4. **Link to task** — optionally append found docs to the task's context for dev-engine consumption.
