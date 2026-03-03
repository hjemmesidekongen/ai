---
name: agency:deploy
description: "Orchestrate the deployment pipeline for an agency project — generates deployment configuration then executes the deployment with health checks"
argument-hint: "[project] [--env staging|production] [--skip-config]"
---

# /agency:deploy

Orchestrates the full deployment pipeline: deploy-config → deploy-execute. Generates deployment configuration files then executes the deployment with build verification and health checks.

## Usage

```
/agency:deploy                              # Deploy active project to staging
/agency:deploy acme                         # Deploy specific project to staging
/agency:deploy acme --env production        # Deploy to production (requires confirmation)
/agency:deploy acme --skip-config           # Use existing deploy-config.yml, execute only
/agency:deploy acme --env production --skip-config
```

## Execution Steps

### Step 1: Determine Project

```
if argument provided:
  project_name = argument
else:
  Read .ai/agency.yml → use active project
  If no agency.yml: "No agency registry found. Run /agency:init first."

project_dir = .ai/projects/{project_name}/
state_file  = {project_dir}/state.yml
if state_file not found:
  "Project '{project_name}' not found. Run /agency:init {project_name} first."

env = --env flag value OR "staging"
```

### Step 2: Validate Prerequisites

```
dev_config = {project_dir}/dev/dev-config.yml
if dev_config not found:
  "dev-config.yml not found. Run /agency:build first to generate project configuration."

if --skip-config NOT set:
  proceed to Phase 1
else:
  deploy_config = {project_dir}/devops/deploy-config.yml
  if deploy_config not found:
    "deploy-config.yml not found. Cannot use --skip-config. Run without the flag to generate it."
  proceed to Phase 2
```

### Step 3: Production Guard

```
if env == "production":
  Display warning:
    "  WARNING: You are about to deploy to PRODUCTION.
     Project: {project_name}
     Provider: {provider from deploy-config.yml if available, else 'TBD'}
     This action cannot be automatically reversed.
     Type 'deploy to production' to confirm, or press Ctrl+C to cancel."

  Wait for user confirmation.
  If not confirmed: "Deployment cancelled."
  If confirmed: proceed
```

### Phase 1: deploy-config (unless --skip-config)

Run the **deploy-config** skill:

```
Input:  {project_dir}/dev/dev-config.yml
Output: {project_dir}/devops/deploy-config.yml
        {project_dir}/devops/templates/ (Dockerfile, deploy.yml, railway.toml or vercel.json)
        {project_dir}/asset-registry.yml (updated)
        {project_dir}/devops/findings.md (confirmed values)
```

Skill execution:
1. Read dev-config.yml — extract framework, language, build commands, package manager
2. Determine deployment strategy (Next.js → Vercel, Express/Node → Railway/Docker)
3. Present provider options and confirm staging/production environment setup with user
4. Generate deploy-config.yml with provider, strategy, environments, build, and env_vars sections
5. Generate Dockerfile (multi-stage) unless serverless strategy selected
6. Generate GitHub Actions CI/CD pipeline (lint, test, build, deploy jobs)
7. Generate provider-specific config (railway.toml or vercel.json)
8. Collect environment variables (name, required, sensitive, description, default)
9. Register all generated templates in asset-registry.yml

Checkpoint gate (data_validation — 5 checks):
```
[ ] deploy_config_exists    — deploy-config.yml has provider, build, env sections
[ ] dockerfile_generated    — Dockerfile in templates/ (unless serverless)
[ ] ci_pipeline_generated   — GitHub Actions workflow YAML in templates/
[ ] env_manifest_complete   — every env var has name, required flag, and description
[ ] assets_registered       — config templates registered in asset-registry.yml
```

If checkpoint fails: fix and re-run. Do not advance to Phase 2 until all 5 checks pass.

On pass:
```
Update state.yml:
  modules.devops.current_skill → "deploy-config"
  modules.devops.status        → "in_progress"
  Append "deploy-config" to modules.devops.completed_skills
```

### Phase 2: deploy-execute

Run the **deploy-execute** skill:

```
Input:  {project_dir}/devops/deploy-config.yml
        {project_dir}/dev/dev-config.yml
Output: {project_dir}/devops/deploy-log.yml
        {project_dir}/devops/findings.md (updated with deployment outcomes)
```

Skill execution:
1. Read deploy-config.yml — extract provider, strategy, environments, build, health_check, env_vars
2. Confirm target environment with user (staging or production)
3. Pre-deploy: run build command, run tests, verify required env vars are set
4. Deploy using provider CLI:
   - Railway: `railway up`
   - Vercel: `vercel deploy` (add `--prod` for production)
   - Docker: build image, push to registry
5. Health check — poll health endpoint every 10s, confirm 200 within 60s timeout
6. Write deploy-log.yml entry (timestamp, environment, provider, status, URL, commit SHA, durations)

Checkpoint gate (code_quality_gate — 4 checks):
```
[ ] build_passes         — build command exits 0 with no errors
[ ] deploy_succeeds      — deploy command exits 0 or provider API returns success
[ ] health_check_passes  — health endpoint returns 200 within timeout
[ ] deploy_log_written   — deploy-log.yml has timestamp, environment, status, url
```

If checkpoint fails: check logs, fix issues, retry (max 3 attempts). Log errors to state.yml.
If all retries exhausted: report failure details and stop. Do not mark devops module complete.

On pass:
```
Update state.yml:
  modules.devops.current_skill → "deploy-execute"
  modules.devops.status        → "completed"
  Append "deploy-execute" to modules.devops.completed_skills
  status → "deployed" (if all modules complete) OR keep current status
  recovery_notes → "Deployed to {env}. URL: {deployment_url}. Run /agency:status for details."
```

### Step 4: Report

```
## Deployment Complete: {project_name}

### Target
  Environment: {env}
  Provider:    {provider}
  URL:         {deployment_url}

### Pipeline
  Phase 1 — deploy-config:   {completed / skipped (--skip-config)}
  Phase 2 — deploy-execute:  {completed}

### Health Check
  {health_check endpoint}: 200 OK ({response_time}ms)

### Deploy Log
  {project_dir}/devops/deploy-log.yml

### Next Steps
  /agency:status {project_name}  — view full project state
```

On failure, show:
```
## Deployment Failed: {project_name}

### Failed Phase
  {Phase 1 or Phase 2}

### Errors
  {error details from state.yml errors array}

### Recovery
  Fix the issues above, then re-run:
    /agency:deploy {project_name} --env {env} --skip-config  (if config phase passed)
    /agency:deploy {project_name} --env {env}                (if config phase failed)
```
