# bitbucket-pr-workflow — Process Reference

## 1. PR Description Template

```markdown
## Summary

<task_summary>

Jira: [<KEY>](<jira_base_url>/browse/<KEY>)

---

## Acceptance Criteria

<for each criterion>
- [ ] <criterion>
</for>

---

## Test Plan

<test_plan>

---

## Notes

<optional_notes>
```

Populate `<task_summary>` from `task.summary`. Populate acceptance criteria from
`task.acceptance_criteria[]`. Generate `<test_plan>` — see §4 below.
Leave `<optional_notes>` blank unless the user provided additional context.

---

## 2. Branch Naming

Derive the branch name from the task key using this priority order:

1. **Explicit branch**: if the user specifies a branch name, use it as-is
2. **Existing branch**: scan local and remote branches for one containing the task key (e.g. `feature/PROJ-123-*`)
3. **Generated name**: `feature/<KEY>-<slugified-summary>` (lowercase, hyphens, max 60 chars total)

Slugify rules: lowercase, replace spaces with hyphens, strip special characters, truncate at 50 chars after the key prefix.

Example: `PROJ-123` + `"Add user search with autocomplete"` → `feature/PROJ-123-add-user-search-with-autocomplete`

---

## 3. Acceptance Criteria Extraction

Read `task.acceptance_criteria` from the task YAML. This field is already normalized
by jira-ingestion. If the array is empty, fall back to parsing `task.description` using
the same heading/checkbox patterns as jira-ingestion.

Format each item as a GitHub-style checkbox: `- [ ] <criterion text>`

Strip trailing periods. Capitalize first word. Max 10 items in the PR description —
if more exist, include the first 10 and append `_(+ N more — see Jira ticket)_`.

---

## 4. Test Plan Generation

Build a minimal test plan from the acceptance criteria:

```
For each acceptance criterion:
  → Generate a corresponding test action: "Verify that <criterion>"
```

Append a standard section at the end:

```markdown
- [ ] No console errors in browser dev tools
- [ ] Tested in Chrome (latest) and Firefox (latest)
- [ ] No regressions on adjacent flows
```

If the task has a `test_plan` field already set (from jira-ingestion or manual edit),
use that verbatim instead of generating one.

---

## 5. Pipeline Status Polling

After PR creation, poll the Bitbucket pipeline status:

```
attempts: 3
delay_between_attempts: 10s

for each attempt:
  1. Call Bitbucket MCP get_pipeline_status(pr_id or commit_sha)
  2. If status == "SUCCESSFUL" or "FAILED" or "STOPPED" → stop polling, report result
  3. If status == "IN_PROGRESS" or "PENDING" → wait and retry

After 3 attempts still IN_PROGRESS:
  → Report "Pipeline running — check Bitbucket for final status"
```

Pipeline status values to handle:

| Bitbucket status | Report as |
|---|---|
| SUCCESSFUL | passed |
| FAILED | failed — action required |
| STOPPED | stopped — check Bitbucket |
| IN_PROGRESS | running (check later) |
| PENDING | queued (check later) |
| not triggered | no pipeline configured |

---

## 6. Jira Transition + Comment

### Comment format

```
PR created: [<branch_name>](<pr_url>)
Status: <pipeline_status>
```

Post to the Jira ticket via Atlassian MCP `add_comment(key, body)`.

### Status transition (optional)

If the project profile includes a `jira_transitions.on_pr_created` field,
call `transition_issue(key, transition_id)` after posting the comment.
Common transition: `"In Review"` or `"In Progress"`.

If no transition configured, skip silently — do not prompt user.

---

## 7. Reviewer Assignment

Reviewer resolution order:

1. **Explicit**: user provided reviewer list in invocation
2. **Project profile**: read `project_profile.reviewers` from `.ai/projects/<name>/profile.yml`
3. **Repository default**: call Bitbucket MCP `get_default_reviewers(repo_slug)`
4. **None**: create PR without reviewers, warn user

Assign up to 3 reviewers by default. If more are available, assign the first 3
(alphabetical by username) and list the rest in the PR notes section.

---

## 8. Draft PR Support

If the user requests a draft PR (trigger phrase: "draft pr" or `--draft` flag):

- Set `draft: true` in the Bitbucket MCP create_pull_request call
- Prepend `[WIP]` to the PR title
- Skip Jira status transition (draft PRs are not ready for review)
- Still post the Jira comment with `(draft)` suffix

---

## 9. Output Format

```
PR created
  URL:       https://bitbucket.org/<workspace>/<repo>/pull-requests/<id>
  Branch:    feature/PROJ-123-add-user-search
  Title:     PROJ-123: Add user search with autocomplete
  Reviewers: sarah.chen, james.ko
  Pipeline:  passed
  Jira:      comment posted to PROJ-123
```

On fallback (no MCP):
```
Bitbucket MCP unavailable — PR description generated for manual submission:

[formatted PR description block]

Branch: feature/PROJ-123-add-user-search
```

---

## 10. Anti-Patterns

- Do not create a PR without a task file — empty descriptions cause review friction
- Do not auto-transition Jira status unless project profile explicitly configures it
- Do not assign more than 3 reviewers by default — keeps review load manageable
- Do not retry pipeline polling more than 3 times — pipelines can run for minutes; report and move on
- Do not include the full ticket description in the PR — use summary + AC only
- Do not proceed past step 3 if the branch does not exist on the remote — the PR will fail
- Do not post duplicate Jira comments — check if a PR comment already exists for this branch before posting
