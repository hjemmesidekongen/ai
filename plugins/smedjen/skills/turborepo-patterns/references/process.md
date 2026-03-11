# Turborepo Patterns — Process Reference

## turbo.json Structure

```json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "globalEnv": ["NODE_ENV", "CI"],
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["src/**", "package.json", "tsconfig.json"],
      "outputs": ["dist/**", ".next/**", "!.next/cache/**"]
    },
    "test": {
      "dependsOn": ["build"],
      "inputs": ["src/**", "tests/**"],
      "outputs": [],
      "env": ["TEST_DATABASE_URL"]
    },
    "lint": {
      "inputs": ["src/**", ".eslintrc.*"],
      "outputs": []
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "type-check": {
      "dependsOn": ["^build"],
      "inputs": ["src/**", "tsconfig.json"],
      "outputs": []
    }
  }
}
```

`globalDependencies` are files whose changes invalidate the cache for all tasks. `globalEnv` are env vars included in every task's cache key.

---

## dependsOn

| Pattern | Meaning |
|---------|---------|
| `"^build"` | Run `build` in all upstream workspace deps first |
| `"build"` | Run `build` in the same package first |
| `"@scope/pkg#build"` | Run `build` in a specific named package first |
| `[]` | No dependencies — task can run immediately in any order |

`^` prefix traverses the dependency graph. Use it for tasks that need compiled upstream packages (type-check, build). Omit it for tasks that only need same-package artifacts (test after build).

---

## Task Inputs and Outputs

### inputs

List of globs relative to the package root that affect this task's cache key. If omitted, Turbo defaults to all files tracked by git in the package.

```json
"inputs": [
  "src/**",
  "public/**",
  "package.json",
  "tsconfig.json",
  "!src/**/*.test.ts"   // exclude test files from build cache key
]
```

Use negation patterns (`!`) to exclude files that don't affect the output. A test file change should not invalidate the build cache.

### outputs

List of globs for artifacts to cache and restore on hit. If empty (`[]`), the task is run for side effects only (lint, type-check) and nothing is restored.

```json
"outputs": [
  "dist/**",
  ".next/**",
  "!.next/cache/**"    // exclude Next.js internal cache from Turbo cache
]
```

---

## Filtering

```bash
# Single package and its dependencies
turbo run build --filter=@scope/web

# All packages matching a glob
turbo run test --filter="./apps/*"

# Packages changed since main branch
turbo run build --filter=[main]

# Packages changed since last commit
turbo run test --filter=[HEAD^1]

# Packages that depend on a specific package (dependents)
turbo run build --filter=...@scope/ui

# Packages that a specific package depends on (dependencies)
turbo run build --filter=@scope/ui...

# Combine: changed packages and their dependents
turbo run test --filter=[main]...
```

### CI Affected Package Pattern

```bash
# In CI: run tests only for packages changed in this PR
turbo run test --filter=...[origin/main]
```

The `...` prefix means "all packages that depend on the matched packages" — ensures downstream consumers are also tested.

---

## Environment Variables in Cache Keys

### Per-task env

```json
"test": {
  "env": ["TEST_DATABASE_URL", "TEST_API_KEY"]
}
```

### Global env (all tasks)

```json
{
  "globalEnv": ["NODE_ENV", "CI", "VERCEL_ENV"]
}
```

Env vars not listed in `env` or `globalEnv` are excluded from the cache key. A task that reads `process.env.API_URL` without declaring it in `env` will produce stale cache hits when `API_URL` changes.

To audit: run `turbo run build --dry=json` and inspect `environmentVariables` in the output.

---

## Remote Cache Setup

### Vercel Remote Cache (default)

```bash
# Link to Vercel account
npx turbo login
npx turbo link

# Or pass token directly in CI
TURBO_TOKEN=<token> TURBO_TEAM=<team> turbo run build
```

### Self-Hosted Remote Cache

```json
// turbo.json
{
  "remoteCache": {
    "enabled": true,
    "apiUrl": "https://your-cache-server.com"
  }
}
```

Compatible servers: `ducktape`, `turbogrid`, or any server implementing the Turborepo Remote Cache API spec.

### CI Environment Variables

```bash
TURBO_TOKEN       # Remote cache auth token
TURBO_TEAM        # Team slug for cache isolation
TURBO_REMOTE_ONLY # Skip local cache, always use remote
TURBO_FORCE       # Bypass cache reads, always re-run
```

---

## Watch Mode

```bash
# Run dev for all packages in parallel (persistent tasks)
turbo run dev

# Watch + run tasks on change
turbo watch build test
```

Tasks with `"persistent": true` run until killed (dev servers, watchers). Turbo runs them in parallel without waiting for completion. Non-persistent tasks after a persistent one in the graph will cause an error — persistent tasks must be leaves.

---

## Pruning for Docker

Generate a minimal monorepo subset for a single app:

```bash
turbo prune --scope=@scope/web --docker
```

This outputs:
- `out/json/` — package.json files only (for lockfile pruning)
- `out/full/` — full source of all required packages
- `out/yarn.lock` (or pnpm/npm equivalent) — pruned lockfile

### Dockerfile Pattern

```dockerfile
FROM node:20-alpine AS pruner
WORKDIR /app
RUN npm install -g turbo
COPY . .
RUN turbo prune --scope=@scope/web --docker

FROM node:20-alpine AS installer
WORKDIR /app
# Copy pruned lockfile and package.json files
COPY --from=pruner /app/out/json/ .
COPY --from=pruner /app/out/yarn.lock ./yarn.lock
RUN yarn install --frozen-lockfile

FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=installer /app/node_modules ./node_modules
COPY --from=pruner /app/out/full/ .
RUN turbo run build --filter=@scope/web

FROM node:20-alpine AS runner
WORKDIR /app
COPY --from=builder /app/apps/web/.next ./.next
# ...
```

The layered approach maximizes Docker cache: lockfile changes only rebuild the installer layer, source changes only rebuild the builder layer.

---

## Package-Specific Task Override

```json
// packages/web/turbo.json — override global pipeline for this package
{
  "$schema": "https://turbo.build/schema.json",
  "extends": ["//"],
  "pipeline": {
    "build": {
      "outputs": [".next/**", "!.next/cache/**"]
    }
  }
}
```

`"extends": ["//"]` inherits the root turbo.json. Override only what differs.

---

## Migration from Lerna / Nx

### From Lerna

1. Remove `lerna.json` and `lerna` from dependencies.
2. Add `turbo` to root devDependencies.
3. Create `turbo.json` with a pipeline mirroring Lerna's task definitions.
4. Replace `lerna run build` with `turbo run build` in package.json scripts and CI.
5. Lerna's `--since` filtering maps to Turbo's `--filter=[<ref>]`.

### From Nx

1. Turbo does not have Nx's project graph inference — task deps must be explicit in `turbo.json`.
2. `nx affected` maps to `turbo run --filter=[main]`.
3. Nx generators have no Turbo equivalent — keep them or replace with scripts.
4. Nx distributed task execution maps to Turbo remote cache + parallelism (`--concurrency`).

---

## Concurrency and Parallelism

```bash
# Default: number of CPU cores
turbo run build

# Explicit concurrency
turbo run build --concurrency=4

# 50% of CPU cores
turbo run build --concurrency=50%

# Serial (for debugging)
turbo run build --concurrency=1
```

Tasks within the same package always run serially. Cross-package parallelism is bounded by the dependency graph and `--concurrency`.

---

## Debugging Cache Misses

```bash
# Dry run — shows what would run and why
turbo run build --dry=json

# Verbose — shows hash inputs
turbo run build --verbosity=2

# Force re-run (bypass cache read)
turbo run build --force
```

The dry run JSON output includes `hashOfExternalDependencies`, `hashOfInternalDependencies`, `environmentVariables`, and `inputs` — compare across runs to identify what changed.

---

## Common Anti-Patterns

**Not declaring env vars in the cache key.** If a task reads `process.env.API_URL` but `API_URL` is not in `env`, the task will return a cache hit even when `API_URL` changes between environments. Always declare every env var that can affect task output.

**Using `cache: false` for tasks that could be cached.** `cache: false` is correct for persistent dev servers and tasks with non-deterministic side effects. It is wrong for build tasks — it defeats the primary value of Turbo.

**Broad inputs glob (`"**"`) on large packages.** This invalidates the cache on any file change, including files unrelated to the task. Be specific — list only source directories, config files, and package.json.

**Missing `!.next/cache/**` in Next.js outputs.** Next.js internal cache is large and changes on every build. Including it in Turbo outputs causes slow cache writes and bloated storage. Always exclude it.

**Running `turbo run dev` in CI.** Persistent tasks never exit. CI hangs indefinitely. Only run non-persistent tasks in CI.

**Circular dependencies in `dependsOn`.** Turbo detects these and errors. Circular task deps usually indicate a package structure problem — the packages should be split or the dep direction reversed.

**Relying on implicit dependency order.** Turbo executes tasks in parallel where the graph allows. If package A's test assumes B's build ran, declare `"^build"` in A's test `dependsOn` — don't rely on incidental ordering from previous runs.
