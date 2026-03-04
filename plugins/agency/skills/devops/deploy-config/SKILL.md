---
name: deploy-config
user-invocable: false
description: >
  Generates deployment configuration: Dockerfile, Railway/Vercel config,
  GitHub Actions CI/CD pipeline, and environment variable manifest. Reads
  dev-config.yml for framework and build commands. Use when setting up
  deployment, deploying to Railway or Vercel, running /agency:deploy config
  phase, creating CI/CD pipeline, generating Dockerfile, configuring staging
  and production environments, or documenting environment variables.
phase: 1
depends_on: [config-generator]
writes:
  - ".ai/projects/[name]/devops/deploy-config.yml"
  - ".ai/projects/[name]/devops/templates/"
  - ".ai/projects/[name]/asset-registry.yml"
reads:
  - ".ai/projects/[name]/dev/dev-config.yml"
model_tier: senior
model: sonnet
interactive: true
checkpoint:
  type: data_validation
  required_checks:
    - name: "deploy_config_exists"
      verify: "deploy-config.yml exists with provider, build, env sections"
      fail_action: "Write current config state to deploy-config.yml immediately"
    - name: "dockerfile_generated"
      verify: "Dockerfile template exists in templates/ (unless serverless strategy)"
      fail_action: "Generate Dockerfile for detected framework; skip only if serverless"
    - name: "ci_pipeline_generated"
      verify: "GitHub Actions workflow YAML exists in templates/"
      fail_action: "Generate .github/workflows/deploy.yml template"
    - name: "env_manifest_complete"
      verify: "Every env var has: name, required flag, default_value or description"
      fail_action: "Ask user about any env vars missing required fields"
    - name: "assets_registered"
      verify: "Config templates registered in asset-registry.yml"
      fail_action: "Append generated files to asset-registry.yml"
  on_fail: "Fix and re-run"
  on_pass: "Update state.yml, advance to deploy-execute"
---

# Deploy Config

Phase 1 of /agency:deploy. Reads dev-config.yml, determines deployment strategy, and generates all deployment configuration files. Output feeds deploy-execute via deploy-config.yml and the templates/ directory.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | dev-config.yml (framework, build commands, env info) |
| **Writes** | deploy-config.yml, templates/Dockerfile, templates/deploy.yml (GitHub Actions), templates/railway.toml or vercel.json |
| **Checkpoint** | data_validation — 5 checks: config, Dockerfile, CI pipeline, env manifest, asset registration |
| **Dependencies** | config-generator (must run first to produce dev-config.yml) |

## Process Summary

1. Read dev-config.yml — extract framework, language, build/start commands, package manager
2. Determine deployment strategy from framework (Next.js → Vercel, Express → Railway/Docker)
3. Present provider options to user and confirm staging/production environment setup
4. Generate deploy-config.yml with provider, strategy, environments, build, and env_vars sections
5. Generate Dockerfile (multi-stage) unless serverless strategy selected
6. Generate GitHub Actions CI/CD pipeline with lint, test, build, and deploy jobs
7. Generate provider-specific config (railway.toml or vercel.json)
8. Collect environment variables — name, required flag, sensitive flag, description, default
9. Register all generated templates in asset-registry.yml; run checkpoint

## Findings Persistence

Write confirmed values to `.ai/projects/[name]/devops/findings.md`. **2-Action Rule:** After every 2 user interactions or file reads, save to findings.md immediately. Log all errors to state.yml errors array — never repeat a failed approach.

## Execution

Follow the detailed process in [references/process.md](references/process.md).
