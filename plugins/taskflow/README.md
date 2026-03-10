# taskflow

Task management and workplace integration plugin for Claude Code.

## What it does

Bridges Claude Code with project management tools (Jira, Confluence, Bitbucket, Azure DevOps) through MCP servers. Provides local task storage, contradiction detection, and structured QA handover.

## Components

- **9 skills**: jira-ingestion, contradiction-detection, project-profile-loader, qa-handover-generator, confluence-lookup, bitbucket-pr-workflow, azure-devops-pipeline, bulk-ingestion, session-handoff-taskflow
- **8 commands**: task-ingest, task-list, task-start, task-done, task-status, task-ingest-bulk, task-pr, task-docs

## Workflow

1. `/task-ingest <KEY>` — fetch a Jira ticket into `.ai/tasks/<KEY>.yml`
2. `/task-start <KEY>` — set as active task, load context
3. `/task-docs` — search Confluence for related documentation
4. Work on the task using dev-engine or manually
5. `/task-pr` — create a PR with structured description from task context
6. `/task-done` — generate QA handover and close out

## MCP dependencies

All MCP integrations degrade gracefully when servers are unavailable.

| MCP Server | Used by |
|------------|---------|
| atlassian | jira-ingestion, bulk-ingestion, contradiction-detection, confluence-lookup, bitbucket-pr-workflow |
| azure-devops | azure-devops-pipeline |

## Task storage

Tasks are stored as YAML files in `.ai/tasks/<KEY>.yml`. The active task pointer lives at `.ai/tasks/active.yml`. Project-level configuration loads from `rules.yml` via project-profile-loader.
