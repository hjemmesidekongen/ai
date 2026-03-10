# Dev Engine Plugin

Generic development execution plugin — task decomposition, agent dispatch, tech knowledge, engineering disciplines, visual verification, and completion gates.

## Skill Categories

| Category | Count | Purpose |
|----------|-------|---------|
| Core execution | 7 | Task decomposition, context assembly, agent dispatch, completion gates, orchestration |
| Disciplines | 6 | TDD, debugging, error handling, verification, code review, git workflows |
| Tech knowledge | 23 | React, Next.js, NestJS, Prisma, Expo (12 skills), TypeScript patterns |
| Integration | 5 | Taskflow bridge, project mapping, context assembly, dev-engine orchestrator |

## Commands

- `/dev:scan` — Scan a project and generate a project map
- `/dev:run` — Run the full dev-engine pipeline from task intake to verified completion

## Agents

| Agent | Tier | Role |
|-------|------|------|
| architect | opus | Architecture reviews, design decisions, dependency analysis |
| code-reviewer | opus | Final quality gate — only agent that can approve work as done |
| app-security-auditor | opus | OWASP checks, dependency audit, auth review, secrets detection |
| backend-dev | sonnet | Server-side features, APIs, database, NestJS/Prisma/Node |
| frontend-dev | sonnet | UI features, React/Next/Vue/Nuxt, CSS, accessibility |
| test-engineer | sonnet | Test writing, coverage gaps, unit/integration/E2E |

## Version

0.2.0
