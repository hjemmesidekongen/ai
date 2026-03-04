# Deploy Execute — Detailed Process

## Step 1: Read Deploy Config

Read `.ai/projects/[name]/devops/deploy-config.yml`. Extract:

- `provider` — railway | vercel | docker | custom
- `strategy` — container | serverless | static
- `environments.staging` — url, auto_deploy, branch, enabled
- `environments.production` — url, auto_deploy, branch, enabled
- `build.command` — build command (e.g. `npm run build`)
- `build.start_command` — start/serve command
- `build.package_manager` — npm, pnpm, yarn, bun
- `health_check.path` — health endpoint path (default: `/api/health`)
- `health_check.interval_seconds` — polling interval
- `env_vars` — list of required env vars (check `required: true` entries)

Also read `.ai/projects/[name]/dev/dev-config.yml` for:
- `commands.test` — test command
- `commands.lint` — lint command

If deploy-config.yml is missing, report blocked — deploy-config must run first.

## Step 2: Confirm Target Environment

Present deployment summary to the user:

```
Ready to deploy [project].

Provider: [provider] ([strategy] strategy)
Available environments:
  1. Staging  — [staging.url]  (branch: [staging.branch])
  2. Production — [production.url]  (branch: [production.branch])

Which environment? [staging/production]
Confirm deploy? [y/n]
```

Wait for explicit confirmation before proceeding. If production selected, show
an additional warning prompt — production deployments cannot be auto-rolled-back.

## Step 3: Pre-Deploy Checks

Run all checks before deploying. Fail fast if any check fails.

### 3a. Build Verification

```bash
[build.command]    # e.g. npm run build
```

- Capture stdout and stderr
- Record build duration (start time to exit)
- On non-zero exit: log error to findings.md and state.yml errors, report to user, stop

### 3b. Test Run

```bash
[commands.test]    # e.g. npm run test -- --run
```

- Run tests in CI mode (no watch, exit after results)
- On failure: display failing tests, ask user whether to continue or fix first
- Default: do not deploy with failing tests unless user explicitly overrides

### 3c. Environment Variable Check

For each env_var with `required: true` in deploy-config.yml:
- Check provider's env config OR local `.env.production` / `.env.staging`
- If any required var is missing: list all missing vars, ask user to set them before proceeding

Common check methods:
- Railway: `railway variables list`
- Vercel: `vercel env ls`
- Docker: inspect `--env-file` or compose file

## Step 4: Execute Deployment

### Railway (container strategy)

```bash
# Install CLI if not present
npm install -g @railway/cli

# Authenticate (prompts if not already logged in)
railway login

# Deploy to staging
railway up --service [project]-staging

# Deploy to production
railway up --service [project]-production
```

Watch for output lines containing `Deployment live at` or error messages.
Capture the deployment URL from CLI output.

### Vercel (serverless/static strategy)

```bash
# Install CLI if not present
npm install -g vercel

# Deploy to staging (preview)
vercel deploy --token $VERCEL_TOKEN

# Deploy to production
vercel deploy --prod --token $VERCEL_TOKEN
```

Capture the deployment URL from CLI output (line starting with `https://`).

### Docker (container strategy, self-hosted)

```bash
# Build image
docker build -t [project]:[commit_sha] .
docker tag [project]:[commit_sha] [registry]/[project]:latest

# Push to registry
docker push [registry]/[project]:[commit_sha]
docker push [registry]/[project]:latest

# Deploy (provider-specific — Railway, Render, Fly.io, or custom)
# e.g. fly deploy --image [registry]/[project]:[commit_sha]
```

### Custom Provider

Follow provider-specific commands stored in deploy-config.yml under
`custom_deploy_commands` (if present). Run commands sequentially;
fail on first non-zero exit.

## Step 5: Health Check

After deploy command exits 0, poll the health endpoint:

```
URL:     [environment.url][health_check.path]
Method:  GET
Timeout: 60 seconds total
Interval: 10 seconds between attempts
Success: HTTP 200 response
```

Algorithm:
1. Wait 10 seconds after deploy completes (cold start buffer)
2. GET `[url][health_check.path]`
3. If 200 → health check passed
4. If not 200 or connection refused → wait `interval_seconds`, retry
5. After 60 seconds total without 200 → health check failed

On failure: log the last HTTP status and response body to findings.md.
Ask user whether to rollback or investigate. Do not mark deploy as success.

### Rollback Strategy

If health check fails or deploy is unstable:

**Railway:**
```bash
railway rollback --service [service-name]
```

**Vercel:**
```bash
vercel rollback [deployment-url]
# Or promote previous deployment in Vercel dashboard
```

**Docker:**
```bash
# Re-deploy previous image tag
docker tag [registry]/[project]:[previous_sha] [registry]/[project]:latest
docker push [registry]/[project]:latest
# Re-run provider deploy command
```

After rollback, log to deploy-log.yml with `status: rolled_back` and `rollback_reason`.

## Step 6: Write deploy-log.yml

Write entry to `.ai/projects/[name]/devops/deploy-log.yml`:

```yaml
_meta:
  plugin: agency
  skill: deploy-execute
  version: "1.0.0"
  project: "[name]"

deployments:
  - timestamp: "[ISO 8601 timestamp]"
    environment: "staging"           # staging | production
    provider: "railway"
    strategy: "container"
    status: "success"                # success | failed | rolled_back
    url: "https://staging.example.up.railway.app"
    commit_sha: "[git rev-parse HEAD]"
    branch: "[current branch]"
    build_duration_seconds: 45
    deploy_duration_seconds: 120
    health_check:
      passed: true
      endpoint: "/api/health"
      response_time_ms: 342
    notes: ""                        # optional: rollback reason, manual overrides
```

Append new entries — do not overwrite existing log entries. This is the
deployment audit trail.

## Step 7: Run Checkpoint

Run all 4 checkpoint checks:

1. **build_passes** — build exited 0 with no errors (recorded in findings.md)
2. **deploy_succeeds** — provider CLI exited 0 or API returned success
3. **health_check_passes** — health endpoint returned 200 within timeout
4. **deploy_log_written** — deploy-log.yml exists and contains the current deployment entry

On any failure:
- Fix the root cause (not the check)
- Maximum 3 retry attempts per deployment
- On 3rd failure, mark deployment as failed and prompt user for manual intervention

On pass, update state.yml:

```yaml
skills:
  deploy-execute:
    status: completed
    completed_at: "[ISO timestamp]"
    recovery_notes: |
      Environment: [environment]
      Provider: [provider], Strategy: [strategy]
      Deploy URL: [url]
      Status: [success/failed/rolled_back]
      Build: [duration]s, Deploy: [duration]s
      Health check: [passed/failed]
```

## Common Failures and Fixes

| Failure | Likely Cause | Fix |
|---------|-------------|-----|
| Build exits non-zero | Missing deps, type errors | Run `npm install`, fix type errors, re-run build |
| `railway: command not found` | CLI not installed | `npm install -g @railway/cli` |
| `vercel: command not found` | CLI not installed | `npm install -g vercel` |
| 401 Unauthorized | Invalid token/not logged in | Re-run `railway login` or set `VERCEL_TOKEN` |
| Health check timeout (ECONNREFUSED) | App not bound to correct port | Verify `PORT` env var and server listen address (0.0.0.0, not localhost) |
| Health check 502/503 | App crashed on startup | Check provider logs: `railway logs`, `vercel logs` |
| Missing required env var | Var not set in provider | Set via provider dashboard or CLI, re-deploy |
| Docker push denied | Registry auth missing | `docker login [registry]` before push |

---

## Trace Protocol

If `state.yml` has `trace.enabled: true`, follow the
[trace protocol](../../../../resources/trace-protocol.md) to write a structured
trace file to `.ai/projects/[name]/traces/`.
