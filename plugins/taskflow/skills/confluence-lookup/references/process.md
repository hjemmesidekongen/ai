# confluence-lookup — Process Reference

## 1. Keyword Extraction

Extract from the active task YAML in priority order:

**Primary sources** (always used):
- `summary`: tokenize, remove stopwords, keep nouns and technical terms
- `labels`: use as-is (already curated)

**Secondary sources** (used if primary yields < 3 keywords):
- `description`: first 200 words, apply same tokenization
- `epic`: epic name or summary if available

**Stopword removal**: strip common English stopwords plus Jira-specific noise
(`as a`, `so that`, `given`, `when`, `then`, `should`, `must`, `will`).

**Technical term boosting**: if a label or word matches a known tech pattern
(framework names, file extensions, protocol names), treat it as high-priority keyword.

**Minimum**: 2 keywords required. If extraction fails to produce 2, abort with error
and report which fields were checked.

Example:
```
summary: "Implement user search with autocomplete"
labels: ["frontend", "search", "typeahead"]

→ keywords: ["user search", "autocomplete", "frontend", "typeahead"]
```

---

## 2. CQL Query Construction

Confluence Query Language reference: `space`, `title`, `text`, `label`, `lastModified`.

**Standard query pattern**:
```
text ~ "keyword1" AND text ~ "keyword2"
ORDER BY lastModified DESC
```

**With space constraint** (when project profile provides `confluence_space`):
```
space = "PROJ" AND (text ~ "keyword1" OR text ~ "keyword2")
ORDER BY lastModified DESC
```

**Label match** (for label-derived keywords):
```
label in ("frontend", "search") OR text ~ "autocomplete"
ORDER BY lastModified DESC
```

**Query selection logic**:
1. If `confluence_space` is set in project profile → use space-constrained query
2. If 2+ label keywords extracted → include label clause
3. Otherwise → use basic text match across all spaces

**Pagination**: fetch first 10 results. If bulk mode, fetch up to 20.

---

## 3. Relevance Scoring

Score each returned page (0–100) using:

| Factor | Points |
|--------|--------|
| Title contains a primary keyword | +30 per keyword (max 60) |
| Title contains a secondary keyword | +15 per keyword (max 30) |
| Body excerpt contains primary keyword | +10 per keyword (max 20) |
| Modified within last 30 days | +10 |
| Modified within last 90 days | +5 |
| Space matches project's `confluence_space` | +15 |

**Threshold**: include pages with score ≥ 25. Discard below threshold.
**Cap**: include max 5 pages per task (top scores).

---

## 4. Caching Results in Task Context

After scoring, write results to the task YAML under `confluence_docs:`.

Schema for each entry:
```yaml
confluence_docs:
  - title: "User Search Implementation Guide"
    url: "https://company.atlassian.net/wiki/spaces/PROJ/pages/123456"
    space: "PROJ"
    relevance_score: 75
    last_modified: "2026-02-28T10:00:00Z"
    keywords_matched: ["user search", "autocomplete"]
  - title: "Frontend Search Patterns"
    url: "https://company.atlassian.net/wiki/spaces/FE/pages/789012"
    space: "FE"
    relevance_score: 55
    last_modified: "2026-01-15T14:30:00Z"
    keywords_matched: ["frontend", "typeahead"]
```

If no pages meet the threshold, write `confluence_docs: []`.
Never leave `confluence_docs` absent from the task file after this skill runs.

---

## 5. Linking Docs for dev-engine Consumption

dev-engine reads `confluence_docs` from the task YAML when planning implementation.
It uses the linked pages as context for tech decisions, not as authoritative specs.

**What dev-engine does with these links**:
- Fetches page content via MCP when decomposing the task
- Treats existing patterns as preferred approaches
- Flags contradictions between Confluence docs and Jira acceptance criteria

**What this skill does NOT do**:
- Fetch page content (that's dev-engine's job)
- Resolve conflicts between docs
- Cache page body text (only metadata + URL)

---

## 6. Bulk Search for Multiple Tasks

When called with a list of task keys (e.g., from project-profile-loader):

```
for each task_key:
  1. Load .ai/tasks/<KEY>.yml
  2. Extract keywords
  3. Construct CQL query
  4. Execute search (deduplicate URLs across tasks)
  5. Score and link
  6. Write confluence_docs to task file
```

**Deduplication**: if the same Confluence URL appears in results for multiple tasks,
link it to each task independently. Do not suppress duplicates across tasks.

**Rate limiting**: pause 500ms between CQL queries if processing more than 5 tasks.
If MCP returns rate-limit error, back off 5s and retry once.

---

## 7. Output Format

Reported to the user after skill completion:

```
confluence-lookup complete for PROJ-456
  Keywords extracted: user search, autocomplete, frontend, typeahead
  CQL: text ~ "user search" AND text ~ "autocomplete"
  Results: 3 pages found, 3 above threshold
  Linked: User Search Implementation Guide (75), Frontend Search Patterns (55), Typeahead Components (40)
  Written to: .ai/tasks/PROJ-456.yml → confluence_docs (3 entries)
```

Dry-run format:
```
confluence-lookup: MCP not available — confluence_docs set to [] for PROJ-456
```

---

## 8. Anti-Patterns

**Do not** generate fake Confluence URLs when MCP is unavailable. Write empty array.

**Do not** include pages with score < 25 just to produce a non-empty result. Empty is
honest and correct.

**Do not** pass full task description text to the MCP query. Build a focused CQL query
from extracted keywords only. Full text bloats the query and degrades result quality.

**Do not** overwrite existing `confluence_docs` without re-running the full search.
If `confluence_docs` already exists and is non-empty, skip unless `--force` is passed.

**Do not** score all results equally. A title match is meaningfully stronger than a body
excerpt match — the scoring table in §3 reflects this intentionally.

---

## 9. Error Handling

| Error | Action |
|-------|--------|
| Task YAML not found | Abort with error — report task key and suggest jira-ingestion |
| MCP not available | Dry-run — write `confluence_docs: []`, warn user |
| Keyword extraction yields 0–1 terms | Abort with error — report which fields were empty |
| CQL syntax error from MCP | Log error, try simplified single-keyword query as fallback |
| All results below score threshold | Write `confluence_docs: []`, report "no relevant pages found" |
| MCP rate limit | Backoff 5s, retry once — if still failing, skip task and continue batch |

All errors annotated to `.ai/traces/trace-light.log` per standard format.
