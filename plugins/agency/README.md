# Agency Plugin

Full-service digital agency plugin — brand loading, design systems, content generation, development team orchestration, and deployment in one unified plugin.

## Modules

| Module | Skills | Purpose |
|--------|--------|---------|
| brand | brand-loader | Load existing brand-reference.yml, extract design tokens |
| design | logo-assets, asset-registry, design-tokens, component-specs, web-layout | Design system generation |
| content | app-copy, ux-writing | Application copy and UX microcopy |
| dev | project-scanner, config-generator, scaffold, storybook-generator, feature-decomposer, team-planner, agent-dispatcher, completion-gate, code-review, qa-validation, brainstorm-session, brainstorm-decision-writer, decision-reader | Full development team |
| devops | deploy-config, deploy-execute | CI/CD and deployment |

## Commands

- `/agency:init` — Create project, import brand reference, scan tech stack
- `/agency:design` — Run design pipeline (`--from <phase>`, `--force`)
- `/agency:content` — Generate app copy and UX writing
- `/agency:build` — Orchestrate development (4-phase)
- `/agency:deploy` — Deploy to target environment
- `/agency:status` — Show project pipeline status
- `/agency:switch` — Switch active project
- `/agency:scan` — Re-scan project for changes

## Version

1.0.0
