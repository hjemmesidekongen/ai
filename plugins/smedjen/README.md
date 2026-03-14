# Smedjen Plugin

Generic development execution plugin — task decomposition, agent dispatch, tech knowledge, engineering disciplines, visual verification, and completion gates.

## Skill Categories

| Category | Count | Purpose |
|----------|-------|---------|
| Core execution | 6 | Task decomposition, agent dispatch, tier assignment, completion gates, project mapping, visual verification |
| Disciplines | 6 | TDD, error handling, verification, code review, git workflows, e2e testing |
| Tech knowledge | 24 | React, Next.js, NestJS, Prisma, TypeScript, Tailwind, Vue, Nuxt, Fumadocs, testing, security |
| Expo | 12 | DOM components, SwiftUI, Tailwind, native UI, data fetching, CI/CD, deployment, upgrading |
| Integration | 2 | Design-to-code patterns, skill quality rubric |

## Commands

- `/smedjen:dev-scan` — Scan a project and generate a project map

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
