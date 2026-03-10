# taskflow — Architecture

## Design principles

- **Local-first**: all task data persists as YAML files in `.ai/tasks/`, queryable without MCP
- **Graceful degradation**: every MCP-dependent skill falls back cleanly when the server is unavailable
- **Task-centric**: all operations revolve around a single active task identified by Jira key
- **Separation of concerns**: taskflow owns task lifecycle; claude-core owns MCP basics; dev-engine owns execution

## Data flow

```
Jira (MCP) → jira-ingestion → .ai/tasks/<KEY>.yml → task-start → active context
                                      ↓
                          contradiction-detection
                                      ↓
                          confluence-lookup → confluence_docs appended
                                      ↓
                          (dev work happens here)
                                      ↓
                          bitbucket-pr-workflow → PR created, Jira linked
                                      ↓
                          qa-handover-generator → QA notes produced
```

## Layer boundaries

| Layer | Owner | Responsibility |
|-------|-------|---------------|
| MCP interaction | claude-core (jira-basics, confluence-basics, bitbucket-basics) | Raw API calls, auth, pagination |
| Task orchestration | taskflow | Keyword extraction, scoring, context linking, lifecycle |
| Execution | dev-engine | Code changes, testing, completion gates |

## File ownership

- `.ai/tasks/<KEY>.yml` — owned by taskflow skills exclusively
- `.ai/tasks/active.yml` — **single-writer: taskflow only**. Contains `{active: KEY, started_at: timestamp}`. Written by task-start, cleared by task-done. Dev-engine reads this pointer but never writes to it — dev-engine writes its own state to `.ai/dev-engine/`.
- `.ai/tasks/<KEY>-pipeline-status.yml` — scoped per task key (not shared)
- `.ai/tasks/handoff.yml` — written by session-handoff-taskflow
- `rules.yml` — read-only by project-profile-loader

## Key validation

All `<KEY>` tokens used in file paths must match `/^[A-Z][A-Z0-9]+-[0-9]+$/`. This prevents path traversal. Validation is enforced at the jira-ingestion entry point.

## Extensibility

New workplace integrations follow the same pattern: a claude-core MCP basics skill for raw interaction, plus a taskflow orchestration skill that adds task awareness.

Exception: azure-devops-pipeline is currently self-contained (no azure-devops-basics layer in claude-core). If Azure DevOps integration grows beyond pipeline queries, extract a basics skill to maintain the layered pattern.
