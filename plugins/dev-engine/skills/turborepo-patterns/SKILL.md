---
name: turborepo-patterns
description: >
  Turborepo pipeline config, caching, filtering, remote cache, and monorepo task
  orchestration. Use when configuring turbo.json pipelines, setting up remote cache,
  filtering tasks to specific packages, migrating from Lerna or Nx, pruning for Docker
  builds, or debugging cache misses.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "turborepo"
  - "turbo"
  - "monorepo build"
  - "turbo cache"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "pipeline_deps_declared"
      verify: "Task dependencies use dependsOn with ^prefix for workspace deps, no prefix for same-package deps"
      fail_action: "Add ^build to dependsOn for tasks that require upstream builds to complete first"
    - name: "cache_inputs_explicit"
      verify: "Cached tasks declare inputs — no implicit reliance on default glob patterns for correctness"
      fail_action: "Add inputs array to the task config; omitting it caches based on all tracked files"
    - name: "env_vars_in_cache_key"
      verify: "Environment variables that affect build output are listed in env or globalEnv"
      fail_action: "Add env array to affected tasks — missing env vars cause stale cache hits across envs"
  on_fail: "Turborepo config has caching or dependency issues — fix before running CI"
  on_pass: "Turborepo pipeline is correctly configured"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for dev-engine"
---

# Turborepo Patterns

Turborepo's core value is task-level caching and parallel execution across a monorepo. Both depend on a correctly declared pipeline — wrong dependency edges or missing cache keys produce incorrect builds silently.

## Pipeline Structure

`turbo.json` defines what tasks exist and how they relate. Task keys are `package#task` or bare task names that apply across all packages. The `dependsOn` field controls execution order; `^` prefix means "wait for this task in all upstream dependencies first."

Outputs and inputs define the cache contract. Omitting `outputs` means nothing is cached for restore. Omitting `inputs` defaults to all git-tracked files — overly broad and causes spurious cache misses.

## Caching

Turbo hashes task inputs (files matching `inputs`, env vars in `env`/`globalEnv`, task graph position) to produce a cache key. On hit, outputs are restored from cache without re-running the task. On miss, the task runs and outputs are saved.

Cache hits show `>>> FULL TURBO` in output. A cache miss when you expect a hit means inputs changed — run `turbo run build --dry=json` to inspect the hash and what contributed to it.

## Filtering

`--filter` scopes the task graph to a subset of packages. It supports package names, directory globs, git ranges, and combinations. Use it in CI to run only affected packages.

## Remote Cache

Remote cache shares hits across machines and CI runs. Vercel's hosted cache is the default option; self-hosted alternatives (S3, Turborepo Remote Cache open source) are available. All remote cache traffic is signed — the token never travels with the artifact.

## Pruning for Docker

`turbo prune --scope=<app>` generates a minimal monorepo subset for a specific app. This produces a `out/` directory with only the packages and lockfile entries the app needs — reducing Docker layer size and rebuild surface.

See `references/process.md` for full turbo.json config, pipeline examples, filtering syntax, remote cache setup, env key configuration, watch mode, migration from Lerna/Nx, and anti-patterns.
