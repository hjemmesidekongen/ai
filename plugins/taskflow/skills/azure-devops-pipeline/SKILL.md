---
name: azure-devops-pipeline
description: >
  Query Azure DevOps pipeline status, trigger runs, and parse test results for
  the active task branch. Requires the 'azure-devops' MCP server. Falls back to
  a clear not-configured message when unavailable.
user_invocable: true
interactive: false
model_tier: senior
triggers:
  - "pipeline status"
  - "azure devops"
  - "check build"
  - "devops pipeline"
  - "ci status"
  - "build status"
depends_on: []
reads:
  - ".ai/tasks/<KEY>.yml"
writes:
  - ".ai/tasks/pipeline-status.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "mcp_available"
      verify: "azure-devops MCP server responds to a list-pipelines call"
      fail_action: "Surface fallback message and stop"
    - name: "branch_matched"
      verify: "At least one pipeline run found for the current branch"
      fail_action: "Report no runs found; suggest checking branch name"
    - name: "status_written"
      verify: ".ai/tasks/pipeline-status.yml written with run ID, status, and timestamp"
      fail_action: "Retry write; log error if it persists"
  on_fail: "Report which check failed and stop — do not guess pipeline state."
  on_pass: "Report: pipeline name, run ID, status, test pass/fail counts."
_source:
  origin: "taskflow"
  inspired_by: "D-014 decisions"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New skill. Azure DevOps MCP integration for pipeline query and trigger."
---

# azure-devops-pipeline

Query pipeline status, trigger runs, and parse test results for the active branch via
the Azure DevOps MCP server.

## MCP requirement

Requires MCP server `azure-devops`. If not configured:

> "MCP server 'azure-devops' not configured — this skill requires it. Add it to your
> MCP server list and restart Claude Code."

Stop immediately. Do not simulate or guess pipeline state.

## Steps

1. **Check MCP** — call `list-pipelines` to verify the server is reachable
2. **Get branch** — read current branch from `git branch --show-current`; cross-reference `.ai/tasks/active.yml` if present
3. **Query runs** — fetch recent runs for the branch (last 5). Write result to `.ai/tasks/pipeline-status.yml`
4. **Parse test results** — if the latest run has a test attachment, extract pass/fail/skipped counts
5. **Trigger (if requested)** — call `trigger-pipeline` with branch and any supplied parameters
6. **Report** — pipeline name, run ID, status (succeeded/failed/running), test counts, artifact links

## Trigger mode

Activated when the user says "run pipeline", "trigger build", or similar. Confirm branch
and pipeline name before triggering. Report run ID immediately after dispatch.

## Output format

## Never

- Never guess or infer pipeline status — if MCP is down, stop and say so
- Never trigger a pipeline run without confirming branch and pipeline name first

See `references/process.md` for output schema, trigger parameters, and anti-patterns.
