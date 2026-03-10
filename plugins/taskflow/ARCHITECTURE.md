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

- `.ai/tasks/*.yml` — owned by taskflow skills
- `.ai/tasks/active.yml` — pointer file, written by task-start command
- `rules.yml` — read-only by project-profile-loader

## Extensibility

New workplace integrations follow the same pattern: a claude-core MCP basics skill for raw interaction, plus a taskflow orchestration skill that adds task awareness. The azure-devops-pipeline skill demonstrates this for non-Atlassian tools.
