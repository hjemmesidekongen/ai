# azure-devops-pipeline — Process Detail

## MCP Server Setup

The skill requires an MCP server named `azure-devops` that exposes at minimum:

| MCP Tool | Purpose |
|----------|---------|
| `list-pipelines` | Enumerate pipelines in the project |
| `get-pipeline-runs` | Fetch runs by pipeline ID and branch filter |
| `get-run-details` | Retrieve status, stages, and test attachment links |
| `trigger-pipeline` | Dispatch a new run with optional parameters |
| `get-test-results` | Parse test attachment for pass/fail breakdown |

If any tool is missing, surface the gap explicitly — do not silently skip steps.

## Pipeline Query Patterns

### Branch-Based Filtering

```
get-pipeline-runs(
  pipelineId: <id>,
  branchFilter: "refs/heads/<branch>",
  top: 5
)
```

Always normalize the branch name to `refs/heads/<branch>` format.
Strip leading `refs/heads/` if the user supplies the full ref.

### Multi-Pipeline Projects

Some projects have several pipelines (CI, CD, nightly). Query all pipelines first via
`list-pipelines`, then filter to those that have runs on the target branch. Report each
separately in the output.

## Trigger Run with Parameters

```
trigger-pipeline(
  pipelineId: <id>,
  branch: "refs/heads/<branch>",
  parameters: {
    <key>: <value>     # optional, user-supplied
  }
)
```

Before triggering:
1. Confirm pipeline name and branch with the user (or from active.yml)
2. Check if a run is already in progress — warn before triggering a duplicate
3. After dispatch, record run ID in `.ai/tasks/pipeline-status.yml`

## Test Result Parsing

Test results are attached to a run as a `test-results` artifact. Parsing steps:

1. Get run details — look for `testResultsId` in the response
2. Call `get-test-results(testResultsId)` to retrieve the summary
3. Extract: `passedCount`, `failedCount`, `skippedCount`, `totalCount`
4. If `failedCount > 0`, extract failed test names and failure messages

Failed test format for report:
```
FAILED: <TestSuiteName>.<TestName>
  Message: <first line of failure message>
```

## Build Artifact Access

Artifact links are returned in run details under `artifacts[]`. Surface the download URL
directly — do not attempt to download unless the user explicitly asks.

## Status Polling

If a run is in `running` or `queued` state and the user asks to "wait for it":
- Poll every 30 seconds using `get-run-details`
- Stop after 20 polls (10 minutes) and report current status
- Do not block the session — report intermediate status and continue

## pipeline-status.yml Output Schema

```yaml
queried_at: "2026-03-10T14:22:00Z"
branch: "feature/PROJ-123-auth-refactor"
pipelines:
  - name: "CI Build"
    pipeline_id: 42
    run_id: 1881
    status: "succeeded"
    started_at: "2026-03-10T14:10:00Z"
    finished_at: "2026-03-10T14:19:00Z"
    tests:
      passed: 312
      failed: 0
      skipped: 4
      total: 316
    artifacts: []
```

## Anti-Patterns

- **Do not guess status** — if MCP is unavailable, stop and surface the message. Never infer "probably passed" from prior runs.
- **Do not trigger without confirmation** — always confirm branch + pipeline before a trigger call.
- **Do not retry endlessly** — if `get-pipeline-runs` fails twice, report the error and stop.
- **Do not load full test logs** — extract counts and failed names only. Full logs are too large for context.
- **Do not cache run IDs across sessions** — always query fresh; run IDs can be reused.
