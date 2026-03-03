---
name: deploy-execute
user-invocable: false
description: >
  Executes deployment to target environment using deploy-config.yml. Runs
  build verification, deploys to staging or production, and performs health
  checks. Use when deploying project, running /agency:deploy execute phase,
  pushing to staging, promoting to production, or verifying deployment health.
phase: 2
depends_on: [deploy-config]
writes:
  - ".ai/projects/[name]/devops/deploy-log.yml"
reads:
  - ".ai/projects/[name]/devops/deploy-config.yml"
  - ".ai/projects/[name]/dev/dev-config.yml"
model_tier: senior
interactive: true
checkpoint:
  type: code_quality_gate
  required_checks:
    - name: "build_passes"
      verify: "Build command exits 0 with no errors"
    - name: "deploy_succeeds"
      verify: "Deploy command exits 0 or provider API returns success"
    - name: "health_check_passes"
      verify: "Health endpoint returns 200 within timeout"
    - name: "deploy_log_written"
      verify: "deploy-log.yml has timestamp, environment, status, url"
  on_fail: "Check logs, fix issues, retry (max 3)"
  on_pass: "Update state.yml devops module, record deployment"
---

# Deploy Execute

Phase 2 of /agency:deploy. Reads deploy-config.yml, confirms target environment with user, runs build verification and tests, executes provider-specific deploy commands, and performs health checks. Records all results in deploy-log.yml.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | deploy-config.yml (provider, strategy, commands, env vars), dev-config.yml (build/test commands) |
| **Writes** | deploy-log.yml (deployment history: timestamp, env, status, URL, durations) |
| **Checkpoint** | code_quality_gate — 4 checks: build, deploy, health check, log written |
| **Dependencies** | deploy-config (must run first to produce deploy-config.yml) |

## Process Summary

1. Read deploy-config.yml — extract provider, strategy, environments, build, health_check, env_vars
2. Confirm target environment with user (staging or production)
3. Pre-deploy: run build command, run tests, verify required env vars are set
4. Deploy using provider CLI — Railway (`railway up`), Vercel (`vercel deploy`), Docker + push
5. Health check — poll health endpoint every 10s, confirm 200 within 60s timeout
6. Write deploy-log.yml entry with timestamp, environment, provider, status, URL, commit SHA, durations
7. Run checkpoint — all 4 checks must pass; on failure fix and retry (max 3 attempts)

## Findings Persistence

Write confirmed values and deployment outcomes to `.ai/projects/[name]/devops/findings.md`. **2-Action Rule:** After every 2 operations (reads, deploys, checks), save to findings.md immediately. Log all errors to state.yml errors array — never repeat a failed approach.

## Execution

Follow the detailed process in [references/process.md](references/process.md).
