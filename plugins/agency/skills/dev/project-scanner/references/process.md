# Project Scanner — Detailed Process

## Overview

The project scanner performs autonomous static analysis to detect the project's
technology stack and design system setup. It produces structured findings consumed
by config-generator. All detection uses signal strength ranking: lock files >
config files > package.json deps > import patterns > directory structure.

**Output path:** `.ai/projects/[name]/dev/findings.md`

## Step 0.5: Read Active Profile

Before scanning, check if an active profile exists to pre-load stack defaults
and shared config references.

```
Read .ai/agency.yml to find active profile name
If profile specified:
  Read .ai/profiles/{profile-name}.yml
  Extract:
    - stack_defaults (framework, css, component_library, animation, icons)
    - shared_configs (list of @repo/* packages to expect)
    - negotiation mode (confirm vs full)
If no profile or file missing:
  Continue without defaults — all values detected from scan
```

Profile data is used later:
- In shared config detection (Step 13.5) to cross-reference expected vs found packages
- In workspace scan (Step 12) to prioritize what to look for in sibling projects
- By config-generator to pre-fill stack negotiation

**Save profile data to findings after this step (2-Action Rule checkpoint).**

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

## Step 9: Detect Design Tooling (Agency Addition)

This step is unique to the agency plugin. Check for design system and styling infrastructure.

**Tailwind CSS:**
- Glob for `tailwind.config.*` at project root and in app packages
- Check for `tailwindcss` in dependencies or devDependencies
- If found, note version and whether a custom `theme.extend` is present (open tailwind.config.* to check)

**CSS Custom Properties (design tokens via CSS):**
- Glob for `src/styles/variables.css`, `src/styles/tokens.css`, `src/styles/globals.css`
- Grep first 60 lines for `--color-`, `--font-`, `--spacing-` custom property patterns
- If custom properties found, note the file path and count of token groups detected

**Storybook:**
- Check for `.storybook/` directory at project root and in monorepo packages
- Check for `@storybook/` packages in devDependencies
- If found, note the Storybook version and whether a `preview.js` / `main.js` / `main.ts` config exists

**Design Token Files:**
- Glob for `tokens.json`, `design-tokens.json`, `tokens/*.json`, `src/tokens.*`
- Check for Style Dictionary config (`style-dictionary.config.*`)
- Check for Theo config (`theo` in devDependencies)
- Check for `@tokens-studio/` packages

**Save to findings after Step 9 (2-Action Rule checkpoint).**

## Step 10: Detect Brand Files (Agency Addition)

Check whether this project already has brand data the agency plugin can use.

**brand-reference.yml detection:**
- Check project root for `brand-reference.yml`
- Check `.ai/` directory: `.ai/active-brand.yml` and `.ai/brands/` for any `brand-reference.yml`
- Check monorepo packages root for `brand-reference.yml` (if monorepo detected)

**Record result:**
- If found: note the path, read the `_meta.version` field, record as `brand_file_found: true`
- If not found: record as `brand_file_found: false` — config-generator will offer to run /brand:generate

**Save to findings after Step 10 (2-Action Rule checkpoint).**

## Step 11: Detect Git Conventions

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

**Save to findings after Step 11 (2-Action Rule checkpoint).**

## Step 12: Workspace Scan

Scan sibling directories (projects in the same parent folder) to build workspace
context. This helps stack negotiation understand the broader environment.

```
Determine workspace root:
  parent_dir = dirname(project_root)

List sibling directories:
  ls parent_dir — filter out hidden dirs and non-project dirs

For each sibling directory (max 10):
  Check for package.json:
    - Read name, framework deps (next, nuxt, vite, etc.)
    - Note primary language (tsconfig.json → TS, go.mod → Go, etc.)
  Check for lock file:
    - Determine package manager
  Check for monorepo indicators:
    - turbo.json, nx.json, workspaces field

Record each sibling as:
  - name: [dir name]
  - stack: [framework + language]
  - package_manager: [detected]
  - monorepo: [true/false]
```

If workspace root is a monorepo itself, also scan `apps/` and `packages/`:
- Each app's stack and dependencies
- Shared packages and their purposes

**Save to findings after Step 12 (2-Action Rule checkpoint).**

## Step 13: MCP Server Discovery

Detect MCP (Model Context Protocol) servers configured in the project or user
environment. These are surfaced as recommendations during stack negotiation.

```
Check for MCP config files (in order of precedence):
  1. .mcp.json at project root
  2. mcp.json at project root
  3. .cursor/mcp.json at project root
  4. ~/.config/claude/claude_desktop_config.json (user-level)

For each config file found:
  Parse JSON
  Extract mcpServers object
  For each server entry:
    - name: [server key]
    - command: [how it's launched]
    - args: [arguments]
    - type: "stdio" or "sse" (from transport config)
    - scope: "project" or "user" (based on where found)

Classify servers by capability:
  - Database: neon, supabase, planetscale, prisma
  - Design: figma, pencil
  - Deployment: vercel, netlify, cloudflare
  - Communication: slack, linear, github
  - Storage: s3, cloudinary
  - Other: [any unrecognized]
```

Record even if no servers found — write "none found" to make the check explicit.

**Save to findings after Step 13 (2-Action Rule checkpoint).**

## Step 13.5: Shared Config Package Detection

In monorepo/turborepo setups, discover shared config packages that must be
extended (never duplicated) by new projects in the workspace.

```
If monorepo detected (from Step 5):
  Scan packages/ directory:
    ls packages/ — look for config-related packages

  Common patterns to detect:
    - @repo/eslint-config or packages/eslint-config
    - @repo/typescript-config or packages/typescript-config
    - @repo/tailwind-config or packages/tailwind-config
    - @repo/prettier-config or packages/prettier-config
    - @repo/ui (shared component library)
    - @repo/utils (shared utilities)

  For each found package:
    Read its package.json:
      - name: [package name, e.g., @repo/eslint-config]
      - path: [relative path, e.g., packages/eslint-config]
      - purpose: [inferred from name and deps]
      - exports: [main/exports field — what it provides]

  Cross-reference with profile:
    If active profile has shared_configs list:
      - Mark each profile-listed config as "expected"
      - Flag any expected configs NOT found in packages/ as "missing"
      - Flag any found configs NOT in profile as "discovered"

If NOT a monorepo:
  Record "Not a monorepo — shared config detection skipped"
  If profile lists shared_configs, note: "Profile expects shared configs but
  project is not a monorepo — verify profile selection"
```

**Save to findings after Step 13.5 (2-Action Rule checkpoint).**

## Step 14: Compile Results

Compile all detections (including workspace, MCP, and shared config data) into
the findings.md format:

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

### Design Tooling
- Tailwind: [version or none] (config: [path])
- CSS custom properties: [yes/no] (file: [path], token groups: [count])
- Storybook: [version or none] (config: .storybook/)
- Design tokens: [file or none] (format: [json/style-dictionary/theo])

### Brand Files
- brand_file_found: [true/false]
- brand_reference_path: [path or none]
- brand_version: [version or none]

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

### Active Profile
- Profile: [name or "none"]
- Stack defaults: [framework, css, etc. or "none — full negotiation"]
- Shared configs (expected): [list from profile or "none"]

### Workspace Context
- Workspace root: [parent directory path]
- Sibling projects:
  - [name]: [stack] ([package manager], monorepo: [yes/no])
- Common patterns: [shared tech across siblings, e.g., "all use pnpm + TypeScript"]

### MCP Servers
- Config source: [file path or "none found"]
- Servers:
  - [name]: [type] (scope: [project/user], capability: [category])
- Recommendations: [servers relevant to detected stack]

### Shared Config Packages
- Monorepo: [yes/no]
- Found packages:
  - [name]: [path] (purpose: [description])
- Profile cross-reference:
  - Expected and found: [list]
  - Expected but missing: [list]
  - Found but not in profile: [list]

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
- findings.md exists and is non-empty at `.ai/projects/[name]/dev/findings.md`
- Contains required sections (Detected Frameworks, Language, Package Manager, Design Tooling, Brand Files, Workspace Context, MCP Servers, Shared Config Packages)
- At least 3 config file paths listed (found or not-found)
- Workspace Context section present (even if empty)
- MCP Servers section present (servers listed or "none found")
- Shared Config Packages section present (packages listed or "not a monorepo")
- state.yml updated if errors occurred

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Detection accuracy (do listed frameworks match actual project?)
- Coverage completeness (major config files not missed?)
- Confidence levels appropriate (strong signals → high, weak → low)
- Design tooling detection thorough (Tailwind theme, token file formats noted)
- Brand file detection accurate (correct path recorded if found)
- Workspace scan covers sibling projects (not just current project)
- MCP servers correctly classified by capability
- Shared config packages cross-referenced with profile (if profile active)
- Ambiguous detections properly flagged

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.

---

## Step 0: Initialize Trace (mandatory if tracing enabled)

Read `state.yml` and check `trace.enabled`. If `true`:

1. Create trace file: `.ai/projects/[name]/traces/{skill-name}-{ISO-timestamp}.yml`
2. Write `_meta` block: schema `"trace"`, version `"1.1.0"`, skill, module, project, started_at, trace_mode
3. Initialize empty `steps: []`, `checkpoint_result: {}`, `quality_summary: {}`, `reflections: {}`

**Schema v1.1.0 — required fields per step:**
- `decision`, `reasoning`, `uncertainty` (always required)
- `observation` — what happened vs expected; surprises, gaps, confirmations
- `improvement_idea` — actionable suggestion for the skill/pipeline (if any)
- `design_decision` — lasting choice beyond this run (if any)

**Trace-level `reflections` section (REQUIRED — Stop hook enforces):**
```yaml
reflections:
  observations: ["at least one observation about the run"]
  improvement_ideas: []   # optional but encouraged
  design_decisions: []    # optional, only for lasting choices
```

The Stop hook will BLOCK completion if reflections section is missing.

---


## Trace Finalization (mandatory if tracing enabled)

Before completing, verify your trace file has:
1. All steps recorded (written every 2 steps per the 2-Action Rule)
2. `checkpoint_result` with pass/fail status
3. `quality_summary` with avg_uncertainty and recommendation
4. `reflections` section with at least one observation (REQUIRED — Stop hook enforces this)
5. Step-level `observation`, `improvement_idea`, or `design_decision` where applicable

The Stop hook will BLOCK completion if tracing is enabled and the trace file
is missing or has no `reflections:` section.
