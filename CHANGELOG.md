# Changelog

All notable changes to this project will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- LICENSE file (MIT)
- CHANGELOG.md
- Explicit `dependencies` field in plugin.json for brand, design, dev-engine, taskflow

## claude-core [0.3.0] — 2026-03-11

### Added
- Dynamic planner: goal-oriented iterative planning with learning loop
- Autopilot: autonomous iteration loop with stop hook and per-session state
- Prompt optimizer and prompt-create command
- E2E plugin testing infrastructure with rubrics and grading
- Session handoff with staleness classification
- Agent teams for preset parallel dispatch
- Auto-doc skill (complements doc-checkpoint)
- Hypothesis generator for parallel investigation
- Parallel reviewer (4-stream code review)
- Writing-clearly-and-concisely skill (Strunk's rules + AI anti-patterns)
- Mermaid diagrams skill (7 diagram types)
- C4 architecture skill
- Reducing-entropy skill (deletion bias)

### Changed
- Consolidated from 7 plugins down to 5 (removed agency and task-planner)
- Prompt-grade hook outputs visible text instead of silent JSON

### Fixed
- Autopilot-run: replaced broken eval with Bash tool dispatch
- Plan-dynamic: correct autopilot handoff command name
- Stale docs and component count mismatches

## dev-engine [0.2.0] — 2026-02-15

### Added
- 8 studio knowledge skills (fumadocs-patterns and others)
- 6 integration skills (design-to-code-patterns, sitemap-planning, content-strategy, web-copywriting, social-media, marketing-psychology)
- SEO fundamentals and brand-voice-implementation knowledge skills
- Visual verification and completion gates
- 6 agents: architect, backend-dev, frontend-dev, test-engineer, code-reviewer, app-security-auditor

## brand [0.1.0] — 2026-02-01

### Added
- 4 skills: brand-strategy, brand-audit, brand-evolve, brand-loader
- 5 commands: brand-create, brand-audit, brand-evolve, brand-apply, brand-status
- Output schemas: guideline-schema, voice-schema, values-schema

## design [0.1.0] — 2026-02-05

### Added
- 3 skills: visual-identity, design-tokens, design-loader
- 3 commands: design-identity, design-tokens, design-status
- Token schema with Tailwind, CSS, and DTCG output formats

## taskflow [0.1.0] — 2026-01-20

### Added
- Jira ingestion (single and bulk)
- Local task storage with contradiction detection
- Project profiles and QA handover generator
- Bitbucket PR workflow and Azure DevOps pipeline integration
- Confluence lookup
- 8 commands: task-status, task-list, task-start, task-ingest, task-ingest-bulk, task-docs, task-pr, task-done
