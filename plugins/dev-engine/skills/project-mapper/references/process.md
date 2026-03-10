# Project Mapper — Process Reference

## Detection Patterns

Scan these files at repo root and each workspace root (for monorepos):

| Config file | Detected stack |
|-------------|---------------|
| `package.json` | Node.js + deps (react, next, express, etc.) |
| `tsconfig*.json` | TypeScript + compiler config |
| `prisma/schema.prisma` | Prisma ORM + database provider |
| `app.json` / `app.config.js` | Expo / React Native |
| `next.config.*` | Next.js (detect App Router vs Pages) |
| `nuxt.config.*` | Nuxt.js |
| `vite.config.*` | Vite bundler |
| `turbo.json` | Turborepo monorepo |
| `pnpm-workspace.yaml` | pnpm workspaces |
| `lerna.json` | Lerna monorepo |
| `docker-compose.yml` | Docker services |
| `Dockerfile` | Containerized deployment |
| `.github/workflows/*.yml` | GitHub Actions CI/CD |
| `pyproject.toml` / `requirements.txt` | Python |
| `go.mod` | Go |
| `Cargo.toml` | Rust |

## Dependency Mapping

For each `package.json`, extract:
- `dependencies` → runtime deps, categorize by domain (UI, state, data, auth, etc.)
- `devDependencies` → tooling (testing, linting, bundling)
- `scripts` → available commands (dev, build, test, lint, deploy)

Cross-reference imports in source files to validate which deps are actually used.

## Module Boundary Detection

A module boundary is defined by:
- A directory with its own `package.json` (workspace package)
- A directory listed in `turbo.json` pipeline or `pnpm-workspace.yaml` packages
- A top-level directory matching common conventions: `apps/`, `packages/`, `libs/`, `services/`

For each module, record:
- Name, path, type (app, library, service, config)
- Internal dependencies (imports from sibling modules)
- External dependencies (from node_modules)
- Entry point files

## Output Schema

```yaml
# .ai/project-map.yml
scanned_at: "2026-03-10T10:00:00Z"
root: "/path/to/repo"
monorepo: true
package_manager: "pnpm"

stack:
  languages: ["typescript", "python"]
  frameworks: ["next.js", "fastapi"]
  databases: ["postgresql"]
  orms: ["prisma"]
  testing: ["jest", "playwright"]
  ci: ["github-actions"]
  deployment: ["docker", "vercel"]

modules:
  - name: "web"
    path: "apps/web"
    type: "app"
    framework: "next.js"
    depends_on: ["@repo/ui", "@repo/db"]
  - name: "api"
    path: "apps/api"
    type: "service"
    framework: "fastapi"
    depends_on: ["@repo/db"]
  - name: "ui"
    path: "packages/ui"
    type: "library"
    depends_on: []

diagram: |
  C4Context
    title System Context — Project Name
    System(web, "Web App", "Next.js frontend")
    System(api, "API Service", "FastAPI backend")
    SystemDb(db, "Database", "PostgreSQL via Prisma")
    Rel(web, api, "REST/tRPC")
    Rel(api, db, "Prisma queries")
```

## Mermaid Diagram Template

Use C4Context for the top-level view. Rules:
- One `System()` per module of type app or service
- One `SystemDb()` per detected database
- `Rel()` lines for cross-module dependencies
- Keep labels short (framework name, not full description)
- Max 12 nodes — group small packages into a single "Shared Libraries" node if needed

## Monorepo Support

When `turbo.json` or workspace config is detected:
1. Scan each workspace root independently
2. Merge results into a single project-map.yml
3. Record inter-workspace dependencies in `modules[].depends_on`
4. Set `monorepo: true`

## Anti-patterns

- Do not include `node_modules` in the scan
- Do not recurse into `.git`, `dist`, `build`, or `.next` directories
- Do not list every file — summarize by directory and pattern
- Do not guess frameworks from filenames alone — verify with config content
- Do not produce diagrams with more than 12 nodes — aggregate small modules
