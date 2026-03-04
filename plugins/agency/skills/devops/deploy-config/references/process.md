# Deploy Config — Detailed Process

## Step 1: Read Project Config

Read `.ai/projects/[name]/dev/dev-config.yml`. Extract:

- `frameworks.runtime` — primary runtime framework (Next.js, SvelteKit, Express, Fastify, etc.)
- `conventions.language` — typescript, javascript, python, go
- `commands.build` — build command
- `commands.start` — start/serve command
- `commands.test` — test command
- `commands.lint` — lint command
- `environment.node_version` — Node.js version (default: 20 if not set)
- `environment.package_manager` — npm, pnpm, yarn, bun

If dev-config.yml is missing, report blocked — config-generator must run first.

## Step 2: Determine Deployment Strategy

Map framework to recommended provider and strategy:

| Framework | Recommended Provider | Strategy |
|-----------|---------------------|----------|
| Next.js | Vercel | serverless |
| SvelteKit | Vercel | serverless |
| Remix | Vercel | serverless |
| Astro (static) | Vercel | static |
| Express / Fastify / Hapi | Railway | container |
| NestJS | Railway | container |
| Python (FastAPI/Flask) | Railway | container |
| Go / Rust | Railway or Docker | container |
| Generic | Docker | container |

If framework is `none` or unknown, default to Docker/container.

## Step 3: Provider Selection (Interactive)

Present options to the user:

```
Detected framework: [framework]
Recommended: [provider] ([strategy] strategy)

Deployment options:
  1. [Recommended provider] — [reason]
  2. Railway — container hosting, free tier available
  3. Vercel — serverless/edge, free tier available
  4. Docker only — generate Dockerfile, user handles hosting
  5. Custom — I'll specify my own

Environments:
  - Staging (auto-deploy from develop branch)?  [y/n]
  - Production (manual approval from main branch)?  [y/n]
```

Wait for user confirmation before proceeding.

## Step 4: Generate deploy-config.yml

Write to `.ai/projects/[name]/devops/deploy-config.yml`:

```yaml
_meta:
  plugin: agency
  skill: deploy-config
  version: "1.0.0"
  created_at: "[ISO timestamp]"
  project: "[name]"

provider: "railway"       # railway | vercel | docker | custom
strategy: "container"     # container | serverless | static

environments:
  staging:
    url: "https://staging.[project].up.railway.app"
    auto_deploy: true
    branch: "develop"
    enabled: true
  production:
    url: "https://[project].up.railway.app"
    auto_deploy: false
    branch: "main"
    enabled: true

build:
  command: "[commands.build from dev-config.yml]"
  start_command: "[commands.start from dev-config.yml]"
  output_dir: ".next"     # framework-specific; null for container
  node_version: "20"
  package_manager: "[from dev-config.yml]"

health_check:
  path: "/api/health"
  interval_seconds: 30

env_vars: []              # populated in Step 6
```

## Step 5: Generate Dockerfile (container strategy only)

Skip for serverless and static strategies.

Write to `.ai/projects/[name]/devops/templates/Dockerfile`.

### Node.js Multi-Stage Template

```dockerfile
# Stage 1: Dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
# Adjust for package manager (pnpm/yarn/bun)
RUN npm ci --only=production

# Stage 2: Builder
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 3: Runner
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
COPY --from=builder /app/dist ./dist
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
USER nextjs
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

Adjust `CMD` and `COPY` paths based on framework:
- Next.js: copy `.next/`, set `CMD ["node_modules/.bin/next", "start"]`
- Express/Fastify: use `dist/` or `src/` depending on TypeScript config

### Non-Node Templates

- Python: use `python:3.12-slim`, `pip install -r requirements.txt`, `CMD ["uvicorn", ...]`
- Go: use multi-stage with `golang:1.22-alpine` builder, `alpine:latest` runner
- Rust: use `rust:1.77-slim` builder, `debian:bookworm-slim` runner

## Step 6: Generate GitHub Actions CI/CD Pipeline

Write to `.ai/projects/[name]/devops/templates/deploy.yml`.

```yaml
name: Deploy

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: "20"

jobs:
  lint-and-test:
    name: Lint and Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: "npm"               # adjust for pnpm/yarn/bun
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm run test

  build:
    name: Build
    needs: lint-and-test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: "npm"
      - run: npm ci
      - run: npm run build

  deploy-staging:
    name: Deploy to Staging
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment: staging
    steps:
      - uses: actions/checkout@v4
      # Provider-specific deploy step inserted here
      - name: Deploy to Railway (staging)
        uses: bervProject/railway-deploy@v1.0.0
        with:
          railway_token: ${{ secrets.RAILWAY_TOKEN }}
          service: "[project]-staging"

  deploy-production:
    name: Deploy to Production
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production        # requires manual approval in GitHub
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Railway (production)
        uses: bervProject/railway-deploy@v1.0.0
        with:
          railway_token: ${{ secrets.RAILWAY_TOKEN }}
          service: "[project]-production"
```

Adjust deploy steps for Vercel (`vercel/action@v1`), Docker push, or custom provider.

## Step 7: Generate Provider Config File

### Railway (container)

Write to `.ai/projects/[name]/devops/templates/railway.toml`:

```toml
[build]
builder = "DOCKERFILE"
dockerfilePath = "Dockerfile"

[deploy]
startCommand = "[commands.start]"
healthcheckPath = "/api/health"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 3
```

### Vercel (serverless/static)

Write to `.ai/projects/[name]/devops/templates/vercel.json`:

```json
{
  "buildCommand": "[commands.build]",
  "outputDirectory": ".next",
  "framework": "nextjs",
  "regions": ["iad1"],
  "env": {},
  "build": {
    "env": {}
  }
}
```

## Step 8: Collect Environment Variables

Ask the user (or infer from framework defaults):

```
What environment variables does your project need?
For each: name, required (y/n), sensitive (y/n), description, default value (if any).

Common defaults I'll pre-populate:
  - DATABASE_URL (required, sensitive) — PostgreSQL/MySQL connection string
  - NODE_ENV (required, not sensitive, default: production)
  - PORT (not required, not sensitive, default: 3000)
  - [NEXT_PUBLIC_API_URL if Next.js detected]
```

Populate `env_vars` in deploy-config.yml:

```yaml
env_vars:
  - name: "DATABASE_URL"
    required: true
    sensitive: true
    description: "Primary database connection string"
    default: null
    ci_secret: "DATABASE_URL"
  - name: "NODE_ENV"
    required: true
    sensitive: false
    description: "Node.js environment"
    default: "production"
    ci_secret: null
  - name: "PORT"
    required: false
    sensitive: false
    description: "HTTP server port"
    default: "3000"
    ci_secret: null
```

Also write a `.env.example` template to `templates/.env.example` — all vars listed, sensitive ones empty, non-sensitive ones include defaults.

## Step 9: Register Assets and Run Checkpoint

Append generated files to `.ai/projects/[name]/asset-registry.yml`:

```yaml
- path: ".ai/projects/[name]/devops/deploy-config.yml"
  type: config
  generated_by: deploy-config
- path: ".ai/projects/[name]/devops/templates/Dockerfile"
  type: template
  generated_by: deploy-config
- path: ".ai/projects/[name]/devops/templates/deploy.yml"
  type: template
  generated_by: deploy-config
- path: ".ai/projects/[name]/devops/templates/railway.toml"
  type: template
  generated_by: deploy-config
- path: ".ai/projects/[name]/devops/templates/.env.example"
  type: template
  generated_by: deploy-config
```

Run all 5 checkpoint checks. If any fail, fix immediately and re-check. On pass, update state.yml:

```yaml
skills:
  deploy-config:
    status: completed
    completed_at: "[ISO timestamp]"
    recovery_notes: |
      Provider: [provider], Strategy: [strategy]
      Templates generated: [list]
      Env vars documented: [count]
```

---

## Trace Protocol

If `state.yml` has `trace.enabled: true`, follow the
[trace protocol](../../../../resources/trace-protocol.md) to write a structured
trace file to `.ai/projects/[name]/traces/`.
