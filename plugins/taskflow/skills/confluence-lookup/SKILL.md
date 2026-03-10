---
name: confluence-lookup
description: >
  Search Confluence for pages related to the active task. Extracts keywords from
  task summary, description, and labels. Constructs CQL queries, scores results
  by relevance, and links matching docs to the task context for dev-engine
  consumption. Graceful fallback when Confluence MCP is not configured.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "check docs"
  - "find confluence"
  - "related documentation"
  - "confluence lookup"
reads:
  - ".ai/tasks/<KEY>.yml"
writes:
  - ".ai/tasks/<KEY>.yml"  # appends confluence_docs: array
checkpoint:
  type: data_validation
  required_checks:
    - name: "task_loaded"
      verify: "Active task YAML exists and has summary + description fields"
      fail_action: "Abort — run jira-ingestion first to create the task file"
    - name: "keywords_extracted"
      verify: "At least 2 keywords extracted from the task"
      fail_action: "Broaden extraction — include labels and epic name if available"
    - name: "docs_linked"
      verify: "confluence_docs key written to task YAML (empty array acceptable if no results)"
      fail_action: "Write empty array — do not leave key absent"
  on_fail: "Report which check failed and the task key that triggered it."
  on_pass: "Report: found N Confluence pages for task <KEY>."
_source:
  origin: "taskflow"
  inspired_by: "D-014 decisions"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Orchestration skill for task-aware Confluence search"
---

# confluence-lookup

Searches Confluence for documentation relevant to the active task. Built on top of
claude-core's `confluence-basics` MCP skill as the query layer. This skill adds
task keyword extraction, CQL construction, relevance scoring, and task context linking.

## Steps

1. **Load task** — read `.ai/tasks/<KEY>.yml`. If no active task, abort and report.
2. **Extract keywords** — pull terms from summary, description, labels, and epic name (see `references/process.md` §1)
3. **Build CQL query** — construct a Confluence Query Language string from keywords (see `references/process.md` §2)
4. **Execute search** — call Atlassian MCP via `confluence-basics`. If MCP unavailable, enter dry-run mode.
5. **Score results** — rank pages by relevance using keyword overlap and recency (see `references/process.md` §3)
6. **Link docs** — append top results to task YAML under `confluence_docs:` (see `references/process.md` §5)
7. **Report** — list matched pages with titles and URLs. State clearly if dry-run.

## Foundation

Uses `claude-core/confluence-basics` for raw MCP query execution. This skill owns
the task-awareness layer: keyword extraction, scoring, and context writing.
`confluence-basics` handles authentication, pagination, and response parsing.

## Dry-run mode

When Confluence MCP is not connected, the skill writes `confluence_docs: []` to the
task file and logs a warning. No stub data is fabricated — missing MCP is not an error,
just an empty result. The task remains processable by dev-engine.

Output: `Found N Confluence page(s) for <KEY>. Linked to task context.`
