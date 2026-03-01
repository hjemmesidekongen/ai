# Plugin Ecosystem Project

## What We're Building
Two Claude Code plugins that work together:
1. **task-planner** — Generic wave-based task planning with verification and QA
2. **brand-guideline** — Agency-grade brand guideline generator

## Architecture Rules
- task-planner is a dependency of brand-guideline (build planner first)
- All plugins follow Claude Code plugin structure: .claude-plugin/plugin.json, commands/, skills/, agents/
- Plugins produce dual outputs: human-readable docs + machine-readable YAML
- Every task must pass verification before being marked complete
- A dedicated QA agent reviews all completed work — implementing agents never self-grade
- Multi-agent runs use file-ownership to prevent write conflicts

## Project Structure
packages/
  task-planner/           # Generic planning plugin
  brand-guideline/        # Brand-specific plugin
shared/
  brand-context-loader/   # Shared skill used by all brand-consuming plugins

## Progress

### task-planner (complete)
- [x] Plugin scaffold + plugin.json
- [x] plan-schema.yml + verification-registry.yml
- [x] wave-decomposer skill
- [x] file-ownership skill + check-file-conflicts.sh
- [x] verification-runner skill
- [x] QA agent + worker agent templates
- [x] Commands: plan-create, plan-execute, plan-status, plan-resume
- [x] Test walkthrough + fixes

### brand-guideline (in progress)
- [x] Plugin scaffold + plugin.json
- [x] brand-context-loader shared skill
- [x] brand-reference-schema.yml + state-schema.yml
- [x] typography-color skill
- [x] identity-interview skill
- [x] audience-personas skill
- [x] tone-of-voice skill
- [x] visual-identity skill
- [x] logo-design skill
- [x] content-rules skill
- [x] social-media skill
- [x] compile-and-export skill (brand manual, docx, asset script, web integration, preview)
- [ ] Commands: brand-generate, brand-analyze, brand-audit, brand-switch ← **Next step**
- [ ] Brand manual template + export

## Specs
Detailed specs are in /docs/ — read the relevant spec BEFORE implementing.
Do NOT try to build everything at once. Follow the phase plan.
