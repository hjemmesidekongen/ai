# Agency Plugin Changelog

All notable changes to the agency plugin will be documented in this file.

## [1.0.1] - 2026-03-09

### Changed
- security-reviewer agent ported to claude-core as security-auditor (plugin infrastructure focus)
- Agency agents reduced from 12 to 11 — security review now cross-plugin via claude-core
- Updated agent references in backend-tech-lead, frontend-tech-lead, project-manager, agent-dispatcher
- Partial port: OWASP Top 10 web checks, dependency scanning, SaaS code review remain agency-scoped (deferred)

## [1.1.1] - 2026-03-05

### Added
- Trace schema v1.1.0: step-level `observation`, `improvement_idea`, `design_decision` fields
- Trace schema v1.1.0: trace-level `reflections` section (observations, improvement_ideas, design_decisions)
- Trace protocol: guidance on step-level vs trace-level reflections, mandatory reflections rule
- Stop hook: `check-trace-written.sh` blocks completion when tracing enabled but trace file missing or lacks reflections
- All 23 process.md files: Step 0 (initialize trace) + Trace Finalization footer replacing passive reference

### Fixed
- Auto-detect phase mismatch: design pipeline now checks `brand.completed_skills` for brand-loader instead of `design.completed_skills`
- `/agency:init --brand` no longer marks brand as "completed" prematurely — marks as "loaded" instead, letting `/agency:design` run brand-loader properly
- Legacy cleanup: `--force` removes `brand-loader` from `design.completed_skills` if present from older runs

### Added
- `--force` flag on `/agency:design` and `/agency:content` — resets module state and re-runs pipeline (composable with `--from`)
- Logo-assets fast-forward mode — detects existing logos from `/brand:generate` and offers validate+copy instead of full interactive flow

## [1.1.0] - 2026-03-04

### Added
- Visual render skill (`design/visual-render`) — bridges agency specs to Pencil MCP
- Render command (`/agency:render`) — 4-phase visual pipeline (variables → components → pages → images)
- Render module in project-state-schema — tracks render pipeline status
- Reads design tokens, component specs, web layouts, and app copy to produce .pen files
- Generates reusable Pencil components, composed page screens, AI/stock imagery
- Outputs render-manifest.yml mapping all Pencil node IDs
- 7-point visual validation checkpoint

## [1.0.0] - 2026-03-03

### Added
- Initial plugin scaffold with plugin.json and ecosystem.json
- Core schemas: agency-registry, project-state, asset-registry
- Deferred backlog tracking 20 features for post-MVP
- Agency verification profile in verification-profile.yml
- Project isolation hook (PreToolUse)
- Session recovery and stop hooks
- Brand module: brand-loader skill
- Design module: logo-assets, asset-registry, design-tokens, component-specs, web-layout
- Content module: app-copy, ux-writing
- Dev module: project-scanner, config-generator, storybook-generator, scaffold, feature-decomposer, team-planner, agent-dispatcher, completion-gate, code-review, qa-validation, brainstorm-session, brainstorm-decision-writer, decision-reader
- DevOps module: deploy-config, deploy-execute
- Commands: init, design, content, build, deploy, status, switch, scan
- Dev agents: 5 leadership + 7 specialist
