# Agency Plugin Project

## What This Is
A unified digital agency plugin (`plugins/agency/`) that handles brand loading, design systems, content, development, and deployment — all in one plugin.

## Architecture Rules
- State persists via `.ai/projects/<name>/state.yml` — always check at session start
- Active project tracked in `.ai/agency.yml`
- Every skill has a checkpoint — no self-grading
- QA agent reviews all final output — implementing agents never self-grade
- Multi-agent runs use file-ownership to prevent write conflicts
- Dual output: machine-readable YAML + human-readable documents
- Hooks in plugin.json (PreToolUse, PostToolUse, SessionStart, Stop)
- PreToolUse re-reads state.yml before Write/Edit/Bash — prevents goal drift
- Stop hook prevents premature completion — skill must be verified first
- Research skills write to findings.md — intermediate discoveries persist across /compact
- 2-Action Rule: save to findings.md every 2 research operations
- All errors logged to state.yml errors array — never repeat a failed approach
- SKILL.md ≤80 lines, overflow goes to references/process.md

## Project Structure
```
.ai/                                 # Project-specific generated data
  agency.yml                         # Active project pointer + project registry
  projects/                          # Per-project data (state.yml, brand/, design/, etc.)
  brainstorm/                        # Brainstorm sessions and decisions
  prompts/                           # Prompt templates
plugins/
  agency/                            # The plugin
    .claude-plugin/
      plugin.json                    # v1.0.0, hooks: PreToolUse, PostToolUse, SessionStart, Stop
      ecosystem.json                 # Component registry (commands, skills, agents)
    commands/                        # init, design, content, build, deploy, status, switch, scan
    skills/
      brand/                         # brand-loader
      design/                        # logo-assets, asset-registry, design-tokens, component-specs, web-layout
      content/                       # app-copy, ux-writing
      dev/                           # project-scanner, config-generator, scaffold, storybook-generator,
                                     # feature-decomposer, team-planner, agent-dispatcher, completion-gate,
                                     # code-review, qa-validation, brainstorm-session,
                                     # brainstorm-decision-writer, decision-reader
      devops/                        # deploy-config, deploy-execute
    agents/dev/                      # 5 leadership + 7 specialist agents
    migrations/                      # MIGRATION-REGISTRY.yml
    resources/
      templates/                     # agency-registry, project-state, asset-registry schemas
      verification-profile.yml       # Verification rules
      deferred-backlog.yml           # 20 deferred features for post-MVP
    scripts/
      session-recovery.sh
      check-wave-complete.sh
      project-isolation-check.sh
    CHANGELOG.md
    README.md
docs/
  ecosystem-strategy.md              # Architecture reference
  archive/                           # Old plugin specs (brand, seo, dev, task-planner)
```

## Commands
| Command | Purpose |
|---------|---------|
| `/agency:init` | Initialize a new project |
| `/agency:design` | Run design phase (tokens, logos, components, layout) |
| `/agency:content` | Run content phase (app copy, UX writing) |
| `/agency:build` | Run dev build phase |
| `/agency:deploy` | Deploy project |
| `/agency:status` | Show project status |
| `/agency:switch` | Switch active project |
| `/agency:scan` | Scan existing project for agency integration |

## Progress

### Build Steps ✅ (Steps 74-85 complete)
- [x] Step 74: Plugin scaffold + plugin.json + ecosystem.json
- [x] Step 75: Core schemas (agency-registry, project-state, asset-registry)
- [x] Step 76: Deferred backlog + verification profile
- [x] Step 77: Project isolation hook + CHANGELOG + migrations
- [x] Step 78: brand-loader skill
- [x] Step 79: Design skills (logo-assets, design-tokens, asset-registry, component-specs, web-layout)
- [x] Step 80: Content skills (app-copy, ux-writing)
- [x] Step 81: Dev skills PORT (project-scanner, config-generator, feature-decomposer, team-planner, agent-dispatcher, completion-gate, code-review, qa-validation)
- [x] Step 82: Dev skills NEW (storybook-generator, scaffold)
- [x] Step 83: DevOps skills (deploy-config, deploy-execute)
- [x] Step 84: Commands (init, design, content, build, deploy, status, switch, scan)
- [x] Step 85: Dev agents (5 leadership + 7 specialist)

### Remaining
- [ ] Step 86: Self-review audit

## Specs
| File | What It Covers |
|------|---------------|
| docs/ecosystem-strategy.md | Architecture, design questions, quality standards |
| docs/archive/ | Old specs from previous plugins (brand, seo, dev, task-planner) — reference only |
| plugins/agency/resources/deferred-backlog.yml | 20 deferred post-MVP features |
| plugins/agency/resources/verification-profile.yml | Verification rules for agency skills |
