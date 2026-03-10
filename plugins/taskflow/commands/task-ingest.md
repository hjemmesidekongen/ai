---
name: task-ingest
description: "Ingest Jira tickets into local task storage"
argument-hint: "KEY_OR_FILTER [--bulk]"
---

# Task Ingest

Pulls Jira tickets into `.ai/tasks/` as local YAML files for offline work.

## Steps

1. **Parse argument** — if the first argument matches `[A-Z]+-[0-9]+`, treat it as a single ticket key. Otherwise treat the entire argument string as a JQL filter.

2. **Bulk vs single mode**:
   - If `--bulk` flag is present OR argument is a JQL filter, invoke `jira-ingestion` skill in bulk mode with the filter.
   - Otherwise invoke `jira-ingestion` skill in single mode with the ticket key.
   - Note: jira-ingestion runs contradiction-detection automatically — do not invoke it separately.

3. **Print summary**:
   - Total tickets ingested
   - Tickets with contradictions (count + keys)
   - Example: `Ingested 12 tickets. 3 have contradictions: PROJ-101, PROJ-108, PROJ-112`
