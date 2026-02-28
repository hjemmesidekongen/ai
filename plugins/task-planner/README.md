# task-planner

Generic wave-based task planning plugin for Claude Code. Any plugin that needs to break complex work into coordinated, verifiable steps consumes this one.

## What It Does

- **Wave decomposition** — Takes a list of tasks with dependencies and produces execution waves that maximize parallelism while respecting ordering constraints
- **File ownership** — Assigns file (and section-level) ownership to prevent agents from writing to the same files in parallel
- **Verification gates** — Runs checkpoint validation between waves so no phase advances until its work is proven correct
- **QA review** — A dedicated QA agent audits completed work against requirements. Implementing agents never self-grade.

## Commands

| Command | Description |
|---------|-------------|
| `/plan:create` | Generate a wave plan from a list of tasks and dependencies |
| `/plan:execute` | Run the plan (single-agent or multi-agent mode) |
| `/plan:status` | Show current plan state, wave progress, and blockers |
| `/plan:resume` | Continue execution after a session break or crash |

## Skills

| Skill | Purpose |
|-------|---------|
| `wave-decomposer` | Breaks tasks into dependency-aware parallel waves |
| `file-ownership` | Assigns and enforces file/section ownership per agent |
| `verification-runner` | Dispatches the right checkpoint type for each wave |
| `qa-reviewer` | Reviews completed work — reads and reports, never implements |

## Agents

| Agent | Role |
|-------|------|
| `qa-agent` | Autonomous reviewer that audits wave output against requirements |
| `worker-agent` | Template for domain-specific worker agents spawned by consuming plugins |

## Execution Modes

- **Single-agent** (default) — Waves run sequentially, tasks within a wave run one at a time. All verification and QA benefits still apply.
- **Multi-agent** (when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is set) — Waves spawn parallel agents with file-ownership enforcement. 3-5 agents max per wave recommended.

## How Other Plugins Use This

Consuming plugins declare `"dependencies": ["task-planner"]` in their manifest, then call the planner with their task list and a verification profile:

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
