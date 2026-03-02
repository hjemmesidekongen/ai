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

1. **Init** (`/dev:init`) — Scan project, detect tech stack, generate knowledge
2. **Build** (`/dev:build "feature description"`) — 4-phase execution:
   - Phase 1: Decompose — PM + Architect + Designer + PO break down the feature
   - Phase 2: Plan — PM + Tech Leads assign tasks, tiers, verify file ownership
   - Phase 3: Execute — Agents work in parallel waves with completion gates
   - Phase 4: Review — Code review + QA validation + PO sign-off
3. **Scan** (`/dev:scan`) — Delta scan to keep knowledge current
4. **Status** (`/dev:status`) — Check progress, blockers, build health
