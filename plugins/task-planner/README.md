# task-planner

Generic wave-based task planning plugin for Claude Code. Any plugin that needs to break complex work into coordinated, verifiable steps consumes this one.

## What It Does

- **Wave decomposition** — Takes a list of tasks with dependencies and produces execution waves that maximize parallelism while respecting ordering constraints
- **File ownership** — Assigns file (and section-level) ownership to prevent agents from writing to the same files in parallel
- **Verification gates** — Runs checkpoint validation between waves so no phase advances until its work is proven correct
- **QA review** — A dedicated QA agent audits completed work against requirements. Implementing agents never self-grade.

## Commands

### Planning

| Command | Description |
|---------|-------------|
| `/plan:create` | Generate a wave plan from a list of tasks and dependencies |
| `/plan:execute` | Run the plan (single-agent or multi-agent mode) |
| `/plan:status` | Show current plan state, wave progress, and blockers |
| `/plan:resume` | Continue execution after a session break or crash |

### Plugin Generator

| Command | Description |
|---------|-------------|
| `/plugin:create [name]` | Walk through 8 design questions, generate specs, scaffold the plugin directory |
| `/plugin:build [name]` | Step-by-step guided build using the generated execution guide |

### Versioning & Migration

| Command | Description |
|---------|-------------|
| `/plugin:version [name] bump [major\|minor\|patch]` | Archive schema, generate migration files, update CHANGELOG |
| `/plugin:migrate [name] --project [project]` | Apply migration chain to a project's data files (supports `--dry-run`, `--rollback`) |

### Brainstorm & Discovery

| Command | Description |
|---------|-------------|
| `/brainstorm:start [project] [mode]` | Start an interactive brainstorm session to explore ideas before committing |
| `/brainstorm:decide [project]` | Extract decisions from a brainstorm session with confidence levels |
| `/brainstorm:status [project]` | Show brainstorm session state, topics covered, and decisions made |

## Skills

### Core Planning

| Skill | Purpose |
|-------|---------|
| `wave-decomposer` | Breaks tasks into dependency-aware parallel waves |
| `file-ownership` | Assigns and enforces file/section ownership per agent |
| `verification-runner` | Dispatches the right checkpoint type for each wave |
| `qa-reviewer` | Reviews completed work — reads and reports, never implements |

### Plugin Generator

| Skill | Purpose |
|-------|---------|
| `plugin-design-interview` | Walks through the 8 design questions every new plugin must answer |
| `plugin-spec-generator` | Produces implementation plan, domain addendum, and asset manifest from design.yml |
| `plugin-execution-guide-generator` | Generates a step-by-step build guide with one full prompt per skill |
| `plugin-scaffolder` | Creates directory structure, plugin.json, README, and registers verification profile |

### Versioning & Migration

| Skill | Purpose |
|-------|---------|
| `version-meta-stamper` | Adds/updates `_meta` version block in plugin output YAML files |
| `version-compatibility-checker` | Compares file version against plugin version; warns on minor mismatch, blocks on major |
| `migration-guide-generator` | Produces migration guides and transform scripts for version bumps |

### Brainstorm & Discovery

| Skill | Purpose |
|-------|---------|
| `brainstorm-session` | Runs a structured brainstorm with techniques (mind mapping, SCAMPER, six hats, etc.) |
| `brainstorm-decision-writer` | Extracts decisions from a brainstorm transcript and writes `decisions.yml` with confidence levels |
| `decision-reader` | Utility skill — interview skills call this to check for pre-existing brainstorm decisions |

## Agents

| Agent | Role |
|-------|------|
| `qa-agent` | Autonomous reviewer that audits wave output against requirements |
| `worker-agent` | Template for domain-specific worker agents spawned by consuming plugins |

## Execution Modes

- **Single-agent** (default) — Waves run sequentially, tasks within a wave run one at a time. All verification and QA benefits still apply.
- **Multi-agent** (when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is set) — Waves spawn parallel agents with file-ownership enforcement. 3-5 agents max per wave recommended.

## How Other Plugins Use This

Consuming plugins declare `"dependencies": ["task-planner"]` in their `ecosystem.json`, then call the planner with their task list and a verification profile:

```yaml
# Example: brand-guideline calling the planner
tasks:
  - id: "t1"
    name: "Generate color palette"
    depends_on: []
    files_written: ["brand-reference.yml#colors"]
  - id: "t2"
    name: "Generate typography system"
    depends_on: []
    files_written: ["brand-reference.yml#typography"]
  - id: "t3"
    name: "Generate logo concepts"
    depends_on: ["t1", "t2"]
    files_written: ["assets/logo/svg/*"]
```

The planner handles wave ordering, conflict detection, verification, and QA automatically.

## Verification Profiles

Plugins register domain-specific verification profiles (brand, web, seo, content). The planner dispatches to the right checks without needing to know the domain details. See `resources/verification-registry.yml` for the full registry.

## Hooks

The plugin ecosystem uses Claude Code hooks for context engineering and safety. These hooks apply to all plugins built on task-planner:

| Hook | Trigger | Purpose |
|------|---------|---------|
| **PreToolUse** | Before any tool call | Re-reads `state.yml` so the agent always has current phase context. Prevents repeating completed work or writing to the wrong section. |
| **PostToolUse** | After a tool call completes | Updates state tracking after file writes. Ensures `state.yml` reflects actual progress. |
| **Stop** | Before session ends | Prevents premature completion — blocks if the current phase hasn't passed its checkpoint. Catches goal drift where the agent tries to "finish" without verifying. |
| **SessionStart** | When a session begins | Runs session recovery: loads `state.yml`, reports current progress, identifies the exact resume point, and prevents the agent from starting over. |

### Why Hooks Matter

Without hooks, an agent might:
- Skip a phase it thinks is done (but wasn't checkpointed)
- Write to a section that another agent owns
- Declare completion before the QA agent has reviewed
- Lose context about where it left off after a `/compact`

Hooks enforce these invariants automatically, outside the agent's reasoning loop.

## Findings and Error Persistence

### findings.md

Skills that perform research or analysis (keyword research, competitor analysis, technical audits) store intermediate findings in a `findings.md` file in the project directory. This file:

- Persists between sessions and survives `/compact`
- Contains structured notes, data points, and observations
- Is read by downstream skills that build on the research

### Error Tracking

Errors encountered during execution are logged to `state.yml` under each phase's `checkpoint` block. This creates a queryable history:

```yaml
phases:
  - name: "keyword-research"
    checkpoint:
      passed: false
      errors:
        - "Fewer than 10 keywords identified — target is 20"
        - "Missing long-tail variants for 3 seed keywords"
```

### 2-Action Rule

When a skill encounters a checkpoint failure, it gets at most **2 attempts** to fix the issue before escalating to the user. This prevents:
- Infinite retry loops where the agent keeps trying the same broken approach
- Silent failures where errors accumulate without user awareness
- Wasted context window on repeated failed attempts

After 2 failed attempts, the skill logs the failure to `state.yml` and asks the user for guidance.

## Session Recovery

When a session starts (or resumes after a break), the **SessionStart** hook runs recovery:

1. Checks for `state.yml` in the active project directory
2. If found: reads current phase, completed phases, and recovery notes
3. Reports a summary: "Brand generation in progress. Phase 4 (typography-color) completed. Resuming at Phase 5 (visual-identity)."
4. Loads recovery notes so the agent has context without re-reading all output files
5. If not found: starts fresh (first run)

This ensures no work is lost across session boundaries, `/compact` operations, or crashes.
