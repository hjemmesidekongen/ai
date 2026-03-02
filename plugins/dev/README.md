# dev Plugin

Multi-agent development team with project-aware knowledge, framework packs, and a 4-phase execution flow (decompose, plan, execute, review) for building software with parallel specialist agents.

## Installation

This plugin is part of the claude-plugins ecosystem. Enable it on your project to activate the agent team.

## Dependencies

- **task-planner** (required) — wave planning, file ownership, subagent dispatch, verification
- **brand-guideline** (optional) — when available, enriches planning and design with brand context

## Commands

| Command | Purpose |
|---------|---------|
| `/dev:init` | Scan project, detect frameworks, produce dev-config.yml and knowledge files |
| `/dev:build` | Main workflow — decompose, plan, execute, and review a feature with the full agent team |
| `/dev:scan` | Delta scan — detect changes since last init, update knowledge files |
| `/dev:status` | Show current team state — active tasks, agent assignments, blockers |
| `/dev:refactor` | Behavior-preserving refactoring — test-first, one component per wave, per-component commits |
| `/dev:skills` | List installed framework-pack skills or check for upstream updates |

## Agent Roster

### Leadership (fixed model)

| Agent | Model | Role |
|-------|-------|------|
| Project Manager | Opus | Orchestrates phases, sequences work, tracks status |
| Software Architect | Opus | Defines boundaries, contracts, data flow |
| Product Owner | Sonnet | Validates scope, checks end-goal alignment |
| Frontend Tech Lead | Opus | Assigns frontend tasks, verifies file overlap |
| Backend Tech Lead | Opus | Assigns backend tasks, verifies file overlap |

### Specialists (self-tiering)

| Agent | Model Range | Role |
|-------|------------|------|
| Frontend Worker | Haiku-Opus | Builds UI components, pages, interactions |
| Backend Worker | Haiku-Opus | Builds APIs, services, data layers |
| Mobile Developer | Haiku-Opus | Mobile-specific implementation |
| Code Reviewer | Sonnet-Opus | Audits full wave diff for quality and security |
| QA Expert | Haiku-Opus | Validates implementation against spec |
| E2E Test Expert | Haiku-Opus | Writes end-to-end tests (Playwright/Cypress) |
| Security Expert | Sonnet-Opus | OWASP checks, dependency audit |
| SEO Expert | Haiku-Opus | Meta, structure, performance optimization |
| DevOps | Haiku-Opus | CI/CD, deployment, infrastructure |
| Designer | Sonnet-Opus | Visual specs, component design, responsive behavior |

## How It Works

### Initial Setup
1. **Init** (`/dev:init`) — Scan project, detect tech stack, generate dev-config.yml and knowledge files
   - Detects frameworks, linters, test runners, build tools
   - Initializes `.ai/dev/[project-name]/` with configuration and knowledge base
   - Creates framework-packs/ directory for skill packs (optional)

### Building Features
2. **Build** (`/dev:build "feature description"`) — 4-phase execution:
   - Phase 1: Decompose — PM + Architect + Designer + PO break down the feature
   - Phase 2: Plan — PM + Tech Leads assign tasks, tiers, verify file ownership
   - Phase 3: Execute — Agents work in parallel waves with completion gates
   - Phase 4: Review — Code review + QA validation + PO sign-off

### Maintenance & Troubleshooting
3. **Scan** (`/dev:scan`) — Delta scan to keep knowledge current
4. **Status** (`/dev:status`) — Check progress, blockers, build health
5. **Refactor** (`/dev:refactor [target]`) — Behavior-preserving code reshaping (see Refactoring below)
6. **Skills** (`/dev:skills`) — List installed skills or check for upstream updates (see Framework Packs below)

## Refactoring

`/dev:refactor` provides a safe, test-first approach to bringing code up to project conventions. Key differences from `/dev:build`:

| Aspect | /dev:build | /dev:refactor |
|--------|-----------|---------------|
| Scope | New functionality | Code reshaping only |
| Tests | After implementation | Before AND after each component |
| Wave size | Multiple components | One component per wave |
| Model tier | Risk-based | Elevated (haiku→sonnet, sonnet→opus) |
| Guarantee | Feature complete | Behavior preserved, tests pass |
| Regression | Related tests | Full test suite (mandatory) |

Usage:
```
/dev:refactor src/components/UserForm.tsx    # refactor specific file
/dev:refactor src/lib/                       # refactor directory
/dev:refactor --scope convention             # apply conventions across project
/dev:refactor src/components/ --dry-run      # plan without executing
/dev:refactor src/components/ --wave 3       # resume from wave 3
```

Prerequisites: `/dev:init` must have been run, and all existing tests must pass before refactoring begins.

## Framework Packs

Framework packs are collections of reusable skills for specific tech stacks. Installed packs live in `plugins/dev/framework-packs/` and are forked from upstream repositories.

Use `/dev:skills` to manage them:
```
/dev:skills                        # list all installed skills by pack
/dev:skills check                  # diff all skills against upstream
/dev:skills check react-nextjs     # check specific pack for updates
```

Each skill includes frontmatter metadata:
- `origin` — upstream repo (e.g., "vercel-labs/agent-skills")
- `origin_skill` — skill name in upstream
- `origin_version` — version at time of fork
- `forked_date` — ISO date the skill was forked

When upstream changes are detected, manually review the diff and merge improvements into your local fork.

## Agent Roster

This plugin brings together 12 specialized agents organized in two tiers:

### Leadership (fixed model tier)

| Agent | Model | Role |
|-------|-------|------|
| Project Manager | Opus | Orchestrates phases, sequences work, tracks status |
| Software Architect | Opus | Defines boundaries, contracts, data flow |
| Frontend Tech Lead | Opus | Assigns frontend tasks, verifies file overlap |
| Backend Tech Lead | Opus | Assigns backend tasks, verifies file overlap |
| QA Lead | Opus | Owns test strategy, acceptance criteria, final QA validation |

### Specialists (self-tiering)

Specialists choose their own model tier (Haiku for simple tasks, Sonnet for moderate, Opus for complex) based on task complexity:

| Agent | Model Range | Role |
|-------|------------|------|
| Frontend Worker | Haiku-Opus | Builds UI components, pages, interactions |
| Backend Worker | Haiku-Opus | Builds APIs, services, data layers |
| Code Reviewer | Sonnet-Opus | Audits wave diff for quality and security |
| QA Expert | Haiku-Opus | Validates implementation against spec |

Self-tiering example: A specialist reviewing a simple CSS change might choose Haiku for speed; a complex algorithmic issue gets Opus.

## MCP Server Integration

The dev plugin includes access to several MCP servers for specialized workflows:

| MCP Server | Purpose |
|-----------|---------|
| **Pencil** | Design-to-code translation — converts Untitled UI design files to React components |
| **Neon** | PostgreSQL database management — schema migrations, query optimization, branch management |
| **Railway** | Deployment orchestration — CI/CD, environment config, infrastructure provisioning |
| **Next.js DevTools** | Framework-specific assistance — file structure, API routes, data fetching patterns |
| **ESLint** | Code quality enforcement — linting rules, style consistency, best practices |
| **Tailwind CSS** | Design system integration — utility class references, responsive design patterns |

These MCPs are automatically available during `/dev:build` execution and can be invoked by agents as needed.
