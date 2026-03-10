# bitbucket-basics: Process Reference

## MCP setup

Add the Atlassian MCP server to your plugin's `.mcp.json`:

```json
{
  "mcpServers": {
    "atlassian": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@atlassian/mcp-atlassian"],
      "env": {
        "ATLASSIAN_API_TOKEN": "${ATLASSIAN_API_TOKEN}",
        "ATLASSIAN_EMAIL": "${ATLASSIAN_EMAIL}",
        "ATLASSIAN_SITE": "${ATLASSIAN_SITE}"
      }
    }
  }
}
```

Required env vars: `ATLASSIAN_API_TOKEN`, `ATLASSIAN_EMAIL`, `ATLASSIAN_SITE`
(e.g. `https://your-org.atlassian.net`).

---

## Create a PR

### Resolve workspace from git remote

```bash
git remote get-url origin
# https://bitbucket.org/<workspace>/<repo>.git
```

Parse `workspace` and `repo` from the remote URL before calling MCP.

### PR description template

```markdown
## Summary
<1-3 bullet points covering what changed and why>

## Test plan
- [ ] <specific thing to verify>
- [ ] <regression check if applicable>

## Notes
<optional: migration steps, breaking changes, deployment order>
```

### MCP call pattern

```
create_pull_request(
  workspace: <slug>,
  repo_slug: <repo>,
  title: "<imperative, under 72 chars>",
  source_branch: "<feature-branch>",
  destination_branch: "main",
  description: "<structured template above>",
  close_source_branch: true
)
```

---

## Check pipeline status

### Get latest pipeline for a branch

```
list_pipelines(workspace, repo_slug, branch=<branch>, pagelen=1)
→ returns pipeline_uuid
```

### Fetch step-level detail

```
list_pipeline_steps(workspace, repo_slug, pipeline_uuid)
→ returns each step with state, duration, and log URL
```

### Report format

```
Pipeline: <pipeline_uuid> — FAILED (3m 12s)
  ✓ lint         (42s)
  ✓ unit-tests   (1m 08s)
  ✗ build        (1m 22s) — exit code 1
  - deploy       (skipped)
```

Never report only the top-level status. Always include step breakdown.

---

## Add a PR comment

```
create_pull_request_comment(
  workspace, repo_slug, pull_request_id,
  content: "<markdown comment>"
)
```

Use for inline review notes, blocking issues, or follow-up tasks.

---

## Approve a PR

```
approve_pull_request(workspace, repo_slug, pull_request_id)
```

Constraints:
- Never approve in the same session that created the PR.
- Confirm the pipeline is green before approving.
- Do not approve if any unresolved blocking comments exist.

---

## List open PRs

```
list_pull_requests(workspace, repo_slug, state="OPEN", pagelen=25)
```

Output: PR ID, title, author, source branch, age, reviewer count.

---

## Branch operations

### Create branch

```
create_branch(workspace, repo_slug, name="feature/<name>", target=<commit_sha>)
```

Default target is the HEAD of the default branch unless specified.

### Delete branch

```
delete_branch(workspace, repo_slug, name=<branch>)
```

Requires explicit user confirmation. Do not delete `main`, `master`, or
any branch with an open PR.

---

## Common workflows

### Feature PR workflow

1. Resolve workspace + repo from git remote.
2. Verify source branch exists on remote (`git push -u origin <branch>`).
3. Check pipeline is green on source branch.
4. Create PR with structured description.
5. Notify reviewer via comment or out-of-band.

### CI failure triage

1. `list_pipelines` → get latest `pipeline_uuid`.
2. `list_pipeline_steps` → identify failing step.
3. Fetch log URL from step detail.
4. Surface step name, exit code, and log URL to user.

### Pre-merge checklist

1. Pipeline green on source branch.
2. At least one approval (not the author).
3. No unresolved comments.
4. Target branch is up to date (or rebase/merge-commit acceptable).

---

## Error handling

| Error | Cause | Resolution |
|-------|-------|------------|
| 401 Unauthorized | Bad or missing API token | Verify `ATLASSIAN_API_TOKEN` env var |
| 404 Not Found | Wrong workspace or repo slug | Re-parse from `git remote get-url origin` |
| 409 Conflict | PR already exists for this branch | Fetch existing PR ID and update instead |
| MCP timeout | Server slow or unreachable | Retry once; if still fails, surface MCP error |
| Pipeline not found | Branch has no pipeline runs | Confirm CI is configured in `bitbucket-pipelines.yml` |

Always surface the raw MCP error message alongside the human-readable explanation.

---

## Anti-patterns

- **Do not fabricate PR or pipeline data** when MCP is unavailable. Stop and surface the connectivity issue.
- **Do not skip step-level pipeline detail.** Top-level status alone is not actionable.
- **Do not hardcode workspace slugs.** Always resolve from git remote or user input.
- **Do not auto-approve.** PR approval is a human decision; only call `approve_pull_request` when the user explicitly requests it.
- **Do not batch-delete branches** without listing them and getting per-branch confirmation.
- **Do not create PRs without a description.** Empty or template-placeholder descriptions fail the `pr_fields_complete` checkpoint.
