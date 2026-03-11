# hjemmesidekongen/ai

## What This Is
Five plugins in a monorepo:
- **kronen** (`plugins/kronen/`) — The Crown: core foundation. Planning, brainstorm, tracing, memory governance, roadmap, doc governance, creator/reviewer tooling, autopilot, prompt optimization, and validation agents (41 skills, 14 commands, 12 agents).
- **smedjen** (`plugins/smedjen/`) — The Forge: development execution engine. Task decomposition, agent dispatch, tech knowledge, disciplines, visual verification, completion gates, project mapping, orchestration, studio knowledge, content writing (62 skills, 3 commands, 7 agents).
- **herold** (`plugins/herold/`) — The Herald: task management and workplace integration. Jira ingestion, local task storage, contradiction detection, project profiles, QA handover, bulk ingestion, PR workflows (9 skills, 8 commands).
- **våbenskjold** (`plugins/våbenskjold/`) — The Coat of Arms: brand strategy, audit, and evolution (4 skills, 5 commands).
- **segl** (`plugins/segl/`) — The Royal Seal: visual identity, design tokens, and Pencil integration (4 skills, 4 commands).

## Context Recovery
After `/compact` or when context seems incomplete, read `.ai/context/snapshot.yml` for working state (workspace, project, active plan, modified files). This file is written by PreCompact, Stop, and SessionStart hooks via `assemble-context.sh` and persists on disk.

## Architecture Rules
- State persists via `.ai/projects/<name>/state.yml` — always check at session start
- Every skill has a checkpoint — no self-grading
- QA agent reviews all final output — implementing agents never self-grade
- Multi-agent runs use file-ownership to prevent write conflicts
- Dual output: machine-readable YAML + human-readable documents
- Hooks in plugin.json (PreToolUse, PostToolUse, PreCompact, SessionStart, Stop, UserPromptSubmit)
- PreToolUse re-reads state.yml before Write/Edit/Bash — prevents goal drift
- Stop hook prevents premature completion — skill must be verified first
- Research skills write to findings.md — intermediate discoveries persist across /compact
- 2-Action Rule: save to findings.md every 2 research operations
- All errors logged to state.yml errors array — never repeat a failed approach
- Hook decisions logged to `.ai/traces/hook-errors.log` (format: `timestamp|hook_name|decision|file_path|reason`)
- SKILL.md ≤80 lines, overflow goes to references/process.md

## Project Structure
```
.ai/                                 # Project-specific generated data
  context/                           # Session context (snapshot.yml — survives compaction via CLAUDE.md pointer)
  projects/                          # Per-project data (state.yml, brand/, design/, etc.)
  brainstorm/                        # Brainstorm sessions and decisions
  plans/                             # Wave plan state files
  prompts/                           # Prompt templates
  roadmap.yml                        # Roadmap across 5 phases
plugins/
  kronen/                             # The Crown — core foundation (41 skills, 14 commands, 12 agents)
    .claude-plugin/
      plugin.json                    # v0.3.0, hooks: PreToolUse, PostToolUse, PreCompact, SessionStart, Stop
      ecosystem.json                 # Component registry
    agents/                          # plugin-validator, skill-auditor, security-auditor, component-reviewer,
                                     # architect-reviewer, refactoring-specialist, knowledge-synthesizer,
                                     # context-manager, tdd-orchestrator, error-detective, incident-responder,
                                     # agent-reviewer
    commands/                        # trace-full, roadmap-add, roadmap-view, brainstorm-start,
                                     # brainstorm-decide, plan-create, plan-dynamic, plan-execute,
                                     # plan-status, plan-resume, autopilot-run, autopilot-cancel,
                                     # full-review, prompt-create
    skills/
      roadmap-capture/               # Auto-capture out-of-scope ideas
      brainstorm-session/            # Open-ended brainstorm
      brainstorm-decision-writer/    # Extract decisions from brainstorms
      plan-engine/                   # Task → wave plan conversion
      dynamic-planner/               # Goal-oriented iterative planning with learning loop
      plan-verifier/                 # Two-stage wave verification
      brainstorm-decision-reader/    # Load past decisions for context
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
      agent-reviewer/                # Review agents (read-only)
      verification-gate/             # 5-step proof protocol before claiming done
      git-worktree-isolation/        # Isolated branch work via git worktrees
      root-cause-debugging/          # 4-phase investigation before any fix
      instinct-extractor/            # Extract behavioral instincts from observations
      instinct-evolve/               # Promote qualified instincts to skills/rules/memory
      reasoning-trace-optimizer/     # Diagnose agent reasoning quality from trace-light.log
      hypothesis-generator/          # 3-hypothesis parallel investigation to eliminate confirmation bias
      parallel-reviewer/             # 4-stream parallel code review (security/perf/arch/testing)
      file-ownership/                # File boundary decomposition for conflict-free parallel dev
      c4-architecture/               # C4 model Mermaid diagrams
      reducing-entropy/              # Manual-only mindset: bias toward deletion
      mermaid-diagrams/              # General-purpose Mermaid diagrams (7 diagram types)
      writing-clearly-and-concisely/ # Strunk's 18 rules + AI anti-patterns
      session-handoff/               # Chained session handoffs with staleness classification
      agent-teams/                   # Preset team compositions for parallel agent dispatch
      auto-doc/                      # Automated documentation updates (complements doc-checkpoint)
      prompt-optimizer/              # Sharpen vague prompts using proven frameworks (auto + builder)
    scripts/                         # session-recovery, trace-light, check-wave-complete, check-trace-written,
                                     # doc-stale-check, cache-clear, verification-gate-stop,
                                     # observation-recorder, scope-guard, tdd-gate, plan-gate, compact-gate-pre/post,
                                     # setup-autopilot, autopilot-stop-hook,
                                     # prevent-direct-push, debug-window,
                                     # dynamic-prompt-constructor, pencil-swarm-check
      tests/                         # Hook unit tests (test-tdd-gate.sh, test-scope-guard.sh, test-plan-gate.sh)
    resources/                       # error-annotation-format, memory-rules, agent-orchestration, instincts-schema
  våbenskjold/                       # The Coat of Arms — brand strategy (4 skills, 5 commands)
    skills/                          # brand-strategy, brand-audit, brand-evolve, brand-loader
    commands/                        # brand-create, brand-audit, brand-evolve, brand-apply, brand-status
    resources/                       # guideline-schema, voice-schema, values-schema
  segl/                              # The Royal Seal — visual identity + Pencil (4 skills, 4 commands)
    skills/                          # visual-identity, design-tokens, design-loader, pencil-tokens
    commands/                        # design-identity, design-tokens, design-status, design-page
    resources/                       # token-schema
  smedjen/                           # The Forge — development execution (62 skills, 3 commands, 7 agents)
    skills/                          # 7 core + 6 discipline + 24 tech + 12 expo + 5 integration + 8 studio
    commands/                        # dev-scan, dev-run
    agents/                          # architect, backend-dev, frontend-dev, test-engineer, code-reviewer, app-security-auditor, content-writer
  herold/                            # The Herald — task management (9 skills, 8 commands)
    skills/                          # jira-ingestion, contradiction-detection, bulk-ingestion, bitbucket-pr-workflow,
                                     # confluence-lookup, qa-handover-generator, azure-devops-pipeline,
                                     # project-profile-loader, session-handoff-taskflow
    commands/                        # task-status, task-list, task-start, task-ingest, task-ingest-bulk,
                                     # task-docs, task-pr, task-done
tests/
  e2e/                               # E2E plugin testing infrastructure
    fixtures/brands/                 # 4 brand fixtures (cloudmetrics, klip-co, danskbolig, nordic-essentials)
    rubrics/                         # Versioned scoring rubrics per skill
    scripts/                         # run_test, run_all, grade_deterministic, grade_llm, compare_baseline
    test-matrix.yml                  # Skill x brand test combinations
    baseline.yml                     # Score comparison baseline
    TESTING.md                       # Test infrastructure documentation
docs/
  ecosystem-strategy.md              # Architecture reference
  archive/                           # Old plugin specs (brand, seo, dev, task-planner)
```

## Commands
| Command | Purpose |
|---------|---------|
| `/kronen:trace-full` | Toggle full tracing on/off |
| `/kronen:roadmap-add` | Add item to roadmap interactively |
| `/kronen:roadmap-view` | Display roadmap with filters |
| `/kronen:brainstorm-start` | Start open-ended brainstorm session |
| `/kronen:brainstorm-decide` | Extract decisions from brainstorm |
| `/kronen:plan-create` | Create a wave-based execution plan |
| `/kronen:plan-dynamic` | Start a goal-oriented iterative plan (dynamic mode) |
| `/kronen:plan-execute` | Execute a wave plan with verification gates |
| `/kronen:plan-status` | Show plan progress |
| `/kronen:plan-resume` | Resume interrupted plan |
| `/kronen:autopilot-run` | Start autopilot loop (autonomous iteration with stop hook) |
| `/kronen:autopilot-cancel` | Cancel active autopilot loop |
| `/kronen:full-review` | 5-phase comprehensive code review |
| `/kronen:prompt-create` | Turn rough intent into structured prompt |
| `/våbenskjold:brand-create` | Create a new brand from scratch |
| `/våbenskjold:brand-audit` | Codify an existing brand from materials |
| `/våbenskjold:brand-evolve` | Refresh or reinvent an existing brand |
| `/våbenskjold:brand-apply` | Load brand into context or wire into project |
| `/våbenskjold:brand-status` | Show brand status and guideline summary |
| `/segl:design-identity` | Create visual identity system |
| `/segl:design-tokens` | Generate platform tokens (Tailwind, CSS, DTCG) |
| `/segl:design-status` | Show design artifact status |
| `/segl:design-page` | Full Pencil design orchestrator — tokens to agents in one command |
| `/smedjen:dev-scan` | Scan repo to detect tech stack and architecture |
| `/smedjen:dev-run` | Run full dev-engine pipeline |
| `/herold:task-status` | Show active task details |
| `/herold:task-list` | List locally stored tasks |
| `/herold:task-start` | Set a task as active |
| `/herold:task-ingest` | Ingest Jira tickets |
| `/herold:task-ingest-bulk` | Batch ingest from Jira board/filter |
| `/herold:task-docs` | Search Confluence docs for active task |
| `/herold:task-pr` | Create PR from active task |
| `/herold:task-done` | Complete active task with QA handover |

## Specs
| File | What It Covers |
|------|---------------|
| docs/ecosystem-strategy.md | Architecture, design questions, quality standards |
| docs/archive/ | Old plugin specs (brand, seo, dev, task-planner) — reference only |
