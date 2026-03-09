# Claude Local Workspace

## What This Is
Four plugins in a monorepo (two active, two planned):
- **claude-core** (`plugins/claude-core/`) — Foundation plugin: planning, brainstorm, tracing, memory governance, roadmap, doc governance, creator/reviewer tooling, autopilot, and validation agents (33 skills, 12 commands, 12 agents).
- **agency** (`plugins/agency/`) — Digital agency plugin: brand, design, content, dev, deploy pipelines (11 agents — security-reviewer ported to claude-core).
- **dev-engine** (`plugins/dev-engine/`) — (planned) Generic development execution: task decomposition, agent dispatch, tech knowledge, disciplines, visual verification, completion gates.
- **taskflow** (`plugins/taskflow/`) — (planned) Task management and workplace integration: Jira ingestion, local task storage, contradiction detection, project profiles, QA handover.

## Context Recovery
After `/compact` or when context seems incomplete, read `.ai/context/snapshot.yml` for working state (workspace, project, active plan, modified files). This file is written by PreCompact, Stop, and SessionStart hooks via `assemble-context.sh` and persists on disk.

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
- Hook decisions logged to `.ai/traces/hook-errors.log` (format: `timestamp|hook_name|decision|file_path|reason`)
- SKILL.md ≤80 lines, overflow goes to references/process.md
- Check `MIGRATION-REGISTRY.yml` before porting agency components to claude-core

## Project Structure
```
.ai/                                 # Project-specific generated data
  agency.yml                         # Active project pointer + project registry
  context/                           # Session context (snapshot.yml — survives compaction via CLAUDE.md pointer)
  projects/                          # Per-project data (state.yml, brand/, design/, etc.)
  brainstorm/                        # Brainstorm sessions and decisions
  plans/                             # Wave plan state files
  prompts/                           # Prompt templates
  roadmap.yml                        # 124-item roadmap across 5 phases
plugins/
  claude-core/                       # Foundation plugin (33 skills, 10 commands, 12 agents)
    .claude-plugin/
      plugin.json                    # v0.3.0, hooks: PreToolUse, PostToolUse, PreCompact, SessionStart, Stop
      ecosystem.json                 # Component registry
    agents/                          # plugin-validator, skill-auditor, security-auditor, component-reviewer,
                                     # architect-reviewer, refactoring-specialist, knowledge-synthesizer,
                                     # context-manager, tdd-orchestrator, error-detective, incident-responder,
                                     # agent-reviewer
    commands/                        # trace-full, roadmap-add, roadmap-view, brainstorm-start,
                                     # brainstorm-decide, plan-create, plan-execute, plan-status, plan-resume,
                                     # autopilot-run, autopilot-cancel,
                                     # full-review
    skills/
      roadmap-capture/               # Auto-capture out-of-scope ideas
      brainstorm-session/            # Open-ended brainstorm
      brainstorm-decision-writer/    # Extract decisions from brainstorms
      plan-engine/                   # Task → wave plan conversion
      plan-verifier/                 # Two-stage wave verification
      brainstorm-decision-reader/     # Load past decisions for context
      doc-checkpoint/                # Evaluate docs state after task completion
      hook-creator/                  # Create/modify hooks
      command-creator/               # Create/modify commands
      skill-creator/                 # Create/modify skills
      agent-creator/                 # Create/modify agents
      plugin-creator/                # Create/modify plugins
      mcp-creator/                   # Create MCP server integrations
      plugin-settings/               # .local.md config pattern for plugins
      hook-reviewer/                 # Review hooks (read-only)
      skill-reviewer/                # Review skills (read-only)
      plugin-reviewer/               # Review plugins (read-only)
      verification-gate/             # 5-step proof protocol before claiming done
      git-worktree-isolation/        # Isolated branch work via git worktrees
      root-cause-debugging/          # 4-phase investigation before any fix
      instinct-extractor/            # Extract behavioral instincts from observations
      instinct-evolve/               # Promote qualified instincts to skills/rules/memory
      reasoning-trace-optimizer/     # Diagnose agent reasoning quality from trace-light.log
      hypothesis-generator/          # 3-hypothesis parallel investigation to eliminate confirmation bias
      parallel-reviewer/             # 4-stream parallel code review (security/perf/arch/testing)
      file-ownership/                # File boundary decomposition for conflict-free parallel dev
      c4-architecture/               # C4 model Mermaid diagrams (implements H1)
      reducing-entropy/              # Manual-only mindset: bias toward deletion
      mermaid-diagrams/              # General-purpose Mermaid diagrams (7 diagram types)
      writing-clearly-and-concisely/ # Strunk's 18 rules + AI anti-patterns
      session-handoff/               # Chained session handoffs with staleness classification
      agent-teams/                   # Preset team compositions for parallel agent dispatch
      auto-doc/                        # Automated documentation updates (complements doc-checkpoint)
    scripts/                         # session-recovery, trace-light, check-wave-complete, check-trace-written,
                                     # doc-stale-check, port-dedup-check, cache-clear, verification-gate-stop,
                                     # observation-recorder, scope-guard, tdd-gate, plan-gate, compact-gate-pre/post,
                                     # setup-autopilot, autopilot-stop-hook,
                                     # prevent-direct-push, debug-window
      tests/                         # Hook unit tests (test-tdd-gate.sh, test-scope-guard.sh, test-plan-gate.sh)
    resources/                       # error-annotation-format, memory-rules, agent-orchestration, instincts-schema
  agency/                            # Digital agency plugin
    .claude-plugin/
      plugin.json                    # v1.0.0, hooks: PreToolUse, PostToolUse
      ecosystem.json                 # Component registry
    commands/                        # init, design, content, build, deploy, status, switch, scan
    skills/
      brand/                         # brand-loader
      design/                        # logo-assets, asset-registry, design-tokens, component-specs, web-layout
      content/                       # app-copy, ux-writing
      dev/                           # project-scanner, config-generator, scaffold, storybook-generator,
                                     # feature-decomposer, team-planner, agent-dispatcher, completion-gate,
                                     # code-review, qa-validation
      devops/                        # deploy-config, deploy-execute, observability
    agents/dev/                      # 5 leadership + 6 specialist agents (security-reviewer → claude-core)
    migrations/                      # MIGRATION-REGISTRY.yml
    resources/
      templates/                     # agency-registry, project-state, asset-registry schemas
      verification-profile.yml       # Verification rules
      deferred-backlog.yml           # 20 deferred features for post-MVP
    scripts/
      project-isolation-check.sh
      inject-trace-timestamp.sh
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
| `/agency:design` | Run design phase (`--from <phase>`, `--force` to reset and re-run) |
| `/agency:content` | Run content phase (`--from <phase>`, `--force` to reset and re-run) |
| `/agency:build` | Run dev build phase |
| `/agency:deploy` | Deploy project |
| `/agency:status` | Show project status |
| `/agency:switch` | Switch active project |
| `/agency:scan` | Scan existing project for agency integration |
| `/claude-core:autopilot-run` | Start autopilot loop (autonomous iteration with stop hook) |
| `/claude-core:autopilot-cancel` | Cancel active autopilot loop |

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
- [x] Step 86: Self-review audit (Phase 4 Gate — v0.3.0)

## Specs
| File | What It Covers |
|------|---------------|
| docs/ecosystem-strategy.md | Architecture, design questions, quality standards |
| docs/archive/ | Old specs from previous plugins (brand, seo, dev, task-planner) — reference only |
| plugins/agency/resources/deferred-backlog.yml | 20 deferred post-MVP features |
| plugins/agency/resources/verification-profile.yml | Verification rules for agency skills |
