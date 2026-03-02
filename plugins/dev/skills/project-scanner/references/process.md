# Project Scanner — Detailed Process

## Overview

The project scanner performs autonomous static analysis to detect the project's
technology stack. It produces structured findings consumed by config-generator.
All detection uses signal strength ranking: lock files > config files >
package.json deps > import patterns > directory structure.

## Step 1: Read package.json

```
Read package.json at project root
Extract:
  - dependencies (map of name → version range)
  - devDependencies (map of name → version range)
  - scripts (map of name → command string)
  - name, version (project metadata)
  - workspaces (array — if present, indicates monorepo)
```

If package.json doesn't exist, note this and skip to Step 3 (may be a non-JS project).

**Save to findings after this step (2-Action Rule checkpoint).**

## Step 2: Glob for Known Config Files

Search for these config files at project root:

| Config File | Indicates |
|-------------|-----------|
| `next.config.*` | Next.js |
| `nuxt.config.*` | Nuxt.js |
| `vite.config.*` | Vite |
| `svelte.config.*` | SvelteKit |
| `remix.config.*` | Remix |
| `angular.json` | Angular |
| `turbo.json` | Turborepo (monorepo) |
| `nx.json` | Nx (monorepo) |
| `lerna.json` | Lerna (monorepo) |
| `prisma/schema.prisma` | Prisma ORM |
| `drizzle.config.*` | Drizzle ORM |
| `docker-compose.yml` | Docker Compose |
| `Dockerfile` | Docker |
| `.github/workflows/*` | GitHub Actions CI/CD |

Record each file found with its path. Record files checked but not found (proves coverage).

**Save to findings after this step (2-Action Rule checkpoint).**

## Step 3: Detect Language

Check for language indicator files:

| File | Language |
|------|----------|
| `tsconfig.json` | TypeScript |
| `jsconfig.json` | JavaScript |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `requirements.txt` or `pyproject.toml` | Python |
| `Gemfile` | Ruby |
| `build.gradle` or `pom.xml` | Java/Kotlin |

If multiple are present (e.g., tsconfig.json + go.mod), this indicates a polyglot project.
Set the primary language to the one with the most source files.

## Step 4: Detect Package Manager

Check for lock files (strongest signal):

| Lock File | Package Manager |
|-----------|----------------|
| `pnpm-lock.yaml` | pnpm |
| `yarn.lock` | yarn |
| `bun.lockb` | bun |
| `package-lock.json` | npm |

If no lock file found, set to "unknown".
If multiple lock files exist, prefer the one matching `packageManager` field in package.json.

**Save to findings after Steps 3-4 (2-Action Rule checkpoint).**

## Step 5: Detect Architecture Pattern

**Monorepo detection:**
- Check for `packages/` or `apps/` directories at root
- Check for `workspaces` field in package.json
- Check for turbo.json, nx.json, or lerna.json
- If monorepo detected, note the tool (turborepo, nx, lerna, or workspace-only)

**Router pattern detection (for web frameworks):**
- `src/app/` with `page.tsx` or `layout.tsx` → Next.js App Router
- `src/pages/` with page files → Next.js Pages Router or similar
- `src/routes/` → SvelteKit or Remix

**API style detection:**
- Check for tRPC config (`trpc` in dependencies)
- Check for GraphQL config (`graphql`, `@apollo`, `urql` in dependencies)
- Check for gRPC config (`@grpc/grpc-js` in dependencies)
- Default to REST if none of the above

## Step 6: Detect Testing Frameworks

| Config File | Framework |
|-------------|-----------|
| `jest.config.*` or `jest` key in package.json | Jest |
| `vitest.config.*` | Vitest |
| `playwright.config.*` | Playwright |
| `cypress.config.*` | Cypress |
| `.mocharc.*` | Mocha |

Classify each as: unit, integration, or e2e.
- Jest/Vitest → unit (default, may also be integration)
- Playwright/Cypress → e2e
- Check `scripts` in package.json for test commands to verify

## Step 7: Detect Linting and Formatting

| Config File | Tool | Type |
|-------------|------|------|
| `.eslintrc.*` or `eslint.config.*` | ESLint | linter |
| `biome.json` or `biome.jsonc` | Biome | linter + formatter |
| `.prettierrc.*` or `prettier.config.*` | Prettier | formatter |
| `oxlint` in devDependencies | Oxlint | linter |

**Save to findings after Steps 5-7 (2-Action Rule checkpoint).**

## Step 8: Map Source Structure

Identify key directories:

```
Glob for common patterns:
  src/components/  → "React/Vue/Svelte UI components"
  src/lib/         → "Shared utilities and libraries"
  src/api/         → "API route handlers"
  src/hooks/       → "Custom React hooks"
  src/store/       → "State management"
  src/styles/      → "Global styles"
  app/             → "Next.js App Router pages"
  pages/           → "Next.js Pages Router"
  server/          → "Server-side code"
  lib/             → "Library code"
  utils/           → "Utility functions"
```

Detect component libraries:
- Check for `components.json` at root → shadcn/ui
- Check for `@mui/material` in dependencies → Material UI
- Check for `antd` in dependencies → Ant Design
- Check for `@chakra-ui/react` in dependencies → Chakra UI

Detect icon libraries:
- `lucide-react` → Lucide
- `@heroicons/react` → Heroicons
- `react-icons` → React Icons

Detect state management:
- `redux` or `@reduxjs/toolkit` → Redux
- `zustand` → Zustand
- `jotai` → Jotai
- `@tanstack/react-query` → React Query (server state)

Identify entry points:
- `src/index.ts` or `src/main.ts` → app entry
- `src/app/layout.tsx` → Next.js App Router entry
- `src/pages/_app.tsx` → Next.js Pages Router entry
- `server/index.ts` → server entry

## Step 9: Detect Git Conventions

```
Read last 10 commit messages:
  git log --oneline -10

Look for patterns:
  - Conventional commits: "feat:", "fix:", "chore:"
  - Jira-style: "PROJ-123: description"
  - Plain: just descriptions
  - Scope format: "feat(scope): description"

Check for branch naming patterns:
  git branch --list | head -10

Check for:
  - .github/PULL_REQUEST_TEMPLATE.md
  - .github/ISSUE_TEMPLATE/
  - .husky/ (git hooks)
  - .commitlintrc.* (commit message validation)
```

**Save to findings after Steps 8-9 (2-Action Rule checkpoint).**

## Step 10: Compile Results

Compile all detections into the findings.md format:

```markdown
## Project Scan Findings

### Detected Frameworks
- [framework]: [version] (confidence: [high/medium/low], source: [file])

### Language
- Primary: [language]
- Secondary: [language] (if polyglot)

### Package Manager
- [manager] (detected from: [lock file])

### Architecture
- Pattern: [monolith/monorepo/serverless]
- Monorepo tool: [turborepo/nx/lerna/none]
- Router: [app-router/pages-router/none]
- API style: [rest/graphql/trpc/grpc/mixed]

### Testing
- Unit: [framework] (config: [path])
- E2E: [framework] (config: [path])

### Linting & Formatting
- Linter: [tool] (config: [path])
- Formatter: [tool] (config: [path])

### Config Files Found
- [path]: [type]

### Config Files Checked (Not Found)
- [path]: checked for [purpose]

### Source Structure
- Entry points: [list]
- Key directories: [list with purposes]
- Component library: [name or none]
- Icon library: [name or none]
- State management: [name or none]

### Git Conventions
- Commit pattern: [description]
- Branch pattern: [description]

### Ambiguous Detections
- [observation]: [possible interpretations]
```

## Error Handling

When errors occur during scanning:

1. **File read failures:** Log to state.yml errors array with the path and error.
   Skip the file and continue scanning. Note the gap in findings.md.

2. **Parse errors (e.g., malformed package.json):** Log the error, attempt to
   extract partial data. Note the parse issue in findings.md Ambiguous Detections.

3. **Unexpected formats:** Log the format issue. Do not guess — write "unknown"
   and note it for config-generator to ask the user.

4. **Before retrying:** Always check state.yml errors array for previous failed
   attempts on this file/pattern. Never repeat the same approach.

## Commit Protocol

**Subagent mode** (dispatched via Task()):
1. Stage only findings.md and any other files in your ownership list
2. Commit: `[plan_name]: project-scanner [task_id]`
3. Report commit SHA in task_complete

**Inline mode:** Commit after verification passes with descriptive message.

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- findings.md exists and is non-empty
- Contains required sections (Detected Frameworks, Language, Package Manager)
- At least 3 config file paths listed (found or not-found)
- state.yml updated if errors occurred

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Detection accuracy (do listed frameworks match actual project?)
- Coverage completeness (major config files not missed?)
- Confidence levels appropriate (strong signals → high, weak → low)
- Ambiguous detections properly flagged

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.
