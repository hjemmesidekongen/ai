# Implementation Plan: dev Plugin

## Overview

**What it does:** Provides a multi-agent development team with project-aware knowledge, framework packs, and a 4-phase execution flow (decompose, plan, execute, review) for building software with parallel specialist agents.

**Who it's for:** Developer / Tech Lead (developer) — cares about code quality, execution speed, cost efficiency (right model tier per task)

**Dependencies:** task-planner (required), brand-guideline (optional enrichment)

**Commands:** 4 — `/dev:init`, `/dev:build`, `/dev:scan`, `/dev:status`

**Skills:** 11 — project-scanner, config-generator, knowledge-initializer, feature-decomposer, team-planner, agent-dispatcher, tier-assigner, completion-gate, code-review, qa-validation, delta-scanner

**Output:** dev-config.yml + knowledge files + build reports + committed code

---

## Architecture

```
┌──────────────────────────────────────────────────┐
│                  task-planner                      │
│  Waves · File Ownership · Subagent Dispatch · QA  │
└──────────┬────────────────────────────────────────┘
           │
    ┌──────▼──────────────────────────────────────┐
    │                  dev plugin                   │
    │  Multi-agent team · Knowledge · Framework     │
    │  packs · 4-phase execution flow               │
    └──────┬──────────────────┬───────────────────┘
           │                  │
    ┌──────▼──────┐    ┌──────▼──────────────────┐
    │  Agent Team  │    │  Knowledge System        │
    │  15 agents   │    │  Tag-based · Maturity    │
    │  5 leadership│    │  lifecycle · Delta scan  │
    │  10 specialist│   └──────┬──────────────────┘
    └──────┬──────┘           │
           │           ┌──────▼──────────────────┐
           │           │  dev-config.yml           │
           │           │  Central project contract │
           └───────────┴──────────────────────────┘
                              │ (optional)
                       ┌──────▼──────────────────┐
                       │  brand-context-loader     │
                       │  (enrichment when avail.) │
                       └──────────────────────────┘
```

### Data Flow

```
Project Source Files
        │
        ▼
┌─ /dev:init ──────────────────────────────────┐
│  project-scanner → config-generator →         │
│  knowledge-initializer                        │
└───────────────────────┬──────────────────────┘
                        │
                        ▼
        .ai/dev/[project-name]/
        ├── dev-config.yml          ← frameworks, conventions, choices
        ├── team-state.yml          ← agent assignments, commit SHAs
        └── knowledge/
            ├── architecture.md     ← mermaid diagrams
            ├── patterns.yml        ← tagged project patterns
            ├── conventions.yml     ← tagged conventions
            └── ...                 ← more tagged knowledge files
                        │
                        ▼
┌─ /dev:build ─────────────────────────────────┐
│  Phase 1: feature-decomposer (PM+Arch+PO)    │
│  Phase 2: team-planner (PM+TLs)              │
│  Phase 3: agent-dispatcher → completion-gate  │
│  Phase 4: code-review → qa-validation         │
└───────────────────────┬──────────────────────┘
                        │
                        ▼
        Code committed to repo + build report
```

### Agent Roster

| Role | Type | Model | Notes |
|------|------|-------|-------|
| Project Manager | Leadership (fixed) | Opus | Orchestrates phases, never codes |
| Software Architect | Leadership (fixed) | Opus | Boundaries, contracts, data flow |
| Product Owner | Leadership (fixed) | Sonnet | Scope validation, end-goal alignment |
| Frontend Tech Lead | Leadership (fixed) | Opus | Assigns FE tasks, verifies overlap |
| Backend Tech Lead | Leadership (fixed) | Opus | Assigns BE tasks, verifies overlap |
| Frontend Worker | Specialist (self-tier) | Haiku→Opus | Builds UI components, pages |
| Backend Worker | Specialist (self-tier) | Haiku→Opus | Builds APIs, services, data |
| Mobile Developer | Specialist (self-tier) | Haiku→Opus | Mobile-specific implementation |
| Code Reviewer | Specialist (floor: Sonnet) | Sonnet→Opus | Audits full wave diff |
| QA Expert | Specialist (self-tier) | Haiku→Opus | Validates against spec |
| E2E Test Expert | Specialist (self-tier) | Haiku→Opus | Writes Playwright/Cypress tests |
| Security Expert | Specialist (floor: Sonnet) | Sonnet→Opus | OWASP, dependency audit |
| SEO Expert | Specialist (self-tier) | Haiku→Opus | Meta, structure, performance |
| DevOps | Specialist (self-tier) | Haiku→Opus | CI/CD, deployment, infra |
| Designer | Specialist (floor: Sonnet) | Sonnet→Opus | Visual specs, component design |

**Communication chain:** User ↔ PM ↔ Tech Leads ↔ Specialists. Specialists never talk to PM directly.

---

## YAML Schema: dev-config.yml

The central project contract. Declares what the project uses — agents load relevant knowledge based on this.

```yaml
# ============================================================
# DEV CONFIG
# Auto-generated by /dev:init, kept current by /dev:scan
# Other dev skills consume this file — do not restructure.
# ============================================================

meta:
  plugin_name: "dev"
  project_name: string          # user's project name
  project_root: string          # absolute path to project root
  created_at: string            # ISO 8601 timestamp
  updated_at: string            # ISO 8601 timestamp
  version: "1.0"
  generated_by: "dev v1.0.0"

# --------------------------------------------------
# FRAMEWORKS
# --------------------------------------------------
frameworks:
  runtime:
    - name: string              # e.g., "next.js", "express", "fastify"
      version: string           # detected version
      config_file: string       # path to config (e.g., "next.config.js")
      detected_by: string       # how it was detected (e.g., "package.json dependency")
  build:
    - name: string              # e.g., "turborepo", "nx", "webpack", "vite"
      version: string
      config_file: string
      detected_by: string
  testing:
    - name: string              # e.g., "jest", "vitest", "playwright"
      version: string
      config_file: string
      detected_by: string
  database:
    - name: string              # e.g., "prisma", "drizzle", "typeorm"
      version: string
      config_file: string
      detected_by: string

# --------------------------------------------------
# CONVENTIONS
# --------------------------------------------------
conventions:
  language: string              # "typescript" | "javascript" | "python" | "go" | "rust" | "other"
  package_manager: string       # "npm" | "yarn" | "pnpm" | "bun"
  monorepo: boolean             # true if turborepo/nx/lerna detected
  monorepo_tool: string | null  # "turborepo" | "nx" | "lerna" | null
  style:
    linter: string | null       # "eslint" | "biome" | "oxlint" | null
    formatter: string | null    # "prettier" | "biome" | null
    linter_config: string | null
    formatter_config: string | null
  git:
    branch_pattern: string      # e.g., "feature/<KEY>-<desc>"
    commit_pattern: string      # e.g., "JIRA-KEY: description"
    main_branch: string         # "main" | "master"
  testing:
    unit_framework: string | null
    integration_framework: string | null
    e2e_framework: string | null
    coverage_threshold: number | null  # 0-100
  architecture:
    pattern: string             # "monolith" | "microservices" | "modular-monolith" | "serverless"
    api_style: string           # "rest" | "graphql" | "trpc" | "grpc" | "mixed"
    state_management: string | null  # "redux" | "zustand" | "context" | "jotai" | null

# --------------------------------------------------
# COMMANDS
# --------------------------------------------------
commands:
  build: string                 # e.g., "npm run build"
  dev: string                   # e.g., "npm run dev"
  test: string                  # e.g., "npm test"
  test_related: string          # e.g., "npx jest --findRelatedTests"
  lint: string                  # e.g., "npx eslint ."
  format: string | null         # e.g., "npx prettier --write ."
  typecheck: string | null      # e.g., "npx tsc --noEmit"

# --------------------------------------------------
# STRUCTURE
# --------------------------------------------------
structure:
  src_root: string              # e.g., "src/", "app/", "packages/"
  entry_points:
    - path: string              # e.g., "src/index.ts"
      type: string              # "app" | "api" | "worker" | "library"
  key_directories:
    - path: string              # e.g., "src/components/"
      purpose: string           # e.g., "React UI components"
    - path: string
      purpose: string
  component_library: string | null   # e.g., "shadcn/ui", "material-ui", null
  icon_library: string | null        # e.g., "lucide-react", "heroicons", null

# --------------------------------------------------
# SCAN STATE
# --------------------------------------------------
scan:
  last_scan_at: string          # ISO 8601 timestamp
  file_hashes:                  # for delta detection
    - path: string
      hash: string              # SHA-256 of file contents
  files_tracked: number         # count of tracked files
  scan_duration_ms: number      # how long the scan took
```

### YAML Schema: team-state.yml

Tracks the current state of agent assignments during a `/dev:build` run.

```yaml
meta:
  plugin_name: "dev"
  project_name: string
  build_id: string              # unique per /dev:build invocation
  created_at: string
  updated_at: string
  version: "1.0"
  generated_by: "dev v1.0.0"

# --------------------------------------------------
# BUILD CONTEXT
# --------------------------------------------------
build:
  feature_description: string   # what the user asked to build
  status: string                # "decomposing" | "planning" | "executing" | "reviewing" | "complete" | "blocked"
  current_phase: number         # 1-4
  started_at: string
  completed_at: string | null

# --------------------------------------------------
# DECOMPOSITION (Phase 1 output)
# --------------------------------------------------
decomposition:
  components:
    - name: string
      description: string
      boundaries: string        # what this component owns
      type: string              # "frontend" | "backend" | "shared" | "infrastructure"
      files_affected:
        - string                # paths that will be created/modified
  designer_specs:
    - component: string         # references components[].name
      visual_spec: string       # description of visual requirements
      wireframe_notes: string | null
  po_validation:
    status: string              # "approved" | "revised" | "rejected"
    notes: string | null

# --------------------------------------------------
# WAVE PLAN (Phase 2 output)
# --------------------------------------------------
wave_plan:
  waves:
    - wave: number
      parallel: boolean
      tasks:
        - id: string            # e.g., "T1"
          description: string
          assigned_agent: string # agent role from roster
          model_tier: string    # "junior" | "senior" | "principal"
          declared_tier: string | null  # self-tiered agents declare this
          component: string     # references decomposition.components[].name
          files_owned:
            - string            # exclusive file ownership
          depends_on:
            - string            # task IDs
          status: string        # "pending" | "dispatched" | "in_progress" | "completed" | "failed" | "blocked"
          base_sha: string | null
          commit_sha: string | null
  file_ownership:
    - file: string
      owner_task: string        # task ID that owns this file
      wave: number

# --------------------------------------------------
# EXECUTION STATE (Phase 3)
# --------------------------------------------------
execution:
  current_wave: number | null
  dispatched_tasks:
    - task_id: string
      agent: string
      tier: string
      dispatched_at: string
      completed_at: string | null
      status: string            # "running" | "completed" | "failed"
      report:
        files_changed:
          - string
        tests_passed: boolean | null
        lint_passed: boolean | null
        build_passed: boolean | null
        notes: string | null
  commit_range:
    base_sha: string | null
    head_sha: string | null

# --------------------------------------------------
# REVIEW STATE (Phase 4)
# --------------------------------------------------
review:
  code_review:
    status: string | null       # "pending" | "passed" | "failed"
    reviewer_tier: string | null
    findings:
      - file: string
        line: number | null
        severity: string        # "critical" | "warning" | "info"
        message: string
    completed_at: string | null
  qa_validation:
    status: string | null       # "pending" | "passed" | "failed" | "passed_with_notes"
    spec_alignment: number | null  # 0-100
    po_signoff: string | null   # "approved" | "revisions_needed"
    notes: string | null
    completed_at: string | null

# --------------------------------------------------
# ERRORS
# --------------------------------------------------
errors:
  - timestamp: string
    skill: string
    error: string
    attempted_fix: string | null
    result: string | null       # "fixed" | "escalated" | "blocked"
    next_approach: string | null

# --------------------------------------------------
# BLOCKERS
# --------------------------------------------------
blockers:
  - task_id: string
    reason: string
    impact:
      directly_blocked:
        - string                # task IDs
      transitively_blocked:
        - string                # task IDs
    escalated_to_user: boolean
    resolution: string | null
```

### YAML Schema: knowledge file format

Each file in `.ai/dev/[project-name]/knowledge/` follows this structure:

```yaml
# Knowledge file frontmatter
tags:
  - string                      # e.g., "api", "auth", "database", "frontend", "testing"
maturity: string                # "candidate" | "established" | "proven" | "deprecated"
created_at: string
updated_at: string
source: string                  # "init-scan" | "delta-scan" | "manual"
hash: string                    # content hash for dedup (Jaccard similarity)

# Knowledge content
entries:
  - fact: string                # concise statement of the knowledge
    confidence: string          # "high" | "medium" | "low"
    evidence: string            # where this was observed (file path, pattern)
    related_tags:
      - string                  # additional tags for cross-referencing
```

---

## Commands

### /dev:init

**Purpose:** Scan project, detect frameworks, produce dev-config.yml and initial knowledge files.

**Input:**
- Arguments: none (scans current working directory)
- Flags:
  - `--force` — re-scan even if dev-config.yml already exists
  - `--brand [name]` — load brand context for designer-relevant knowledge
- Interactive prompts: confirms detected frameworks, asks about conventions not auto-detectable

**Execution Strategy:**

Interactive phases (cannot be parallelized):
1. Run `project-scanner` — autonomous static analysis of the project
2. Run `config-generator` — present detected config to user for confirmation
3. Run `knowledge-initializer` — autonomous generation of knowledge files from confirmed config

This command does NOT use the task-planner — it runs sequentially because each step is fast and depends on the previous.

**Output:**
- `.ai/dev/[project-name]/dev-config.yml` — project configuration
- `.ai/dev/[project-name]/knowledge/*.yml` — tagged knowledge files
- `.ai/dev/[project-name]/knowledge/architecture.md` — mermaid diagrams

**Recovery:**
If interrupted, re-run `/dev:init`. It's idempotent — will overwrite existing config. Use `--force` to bypass "already initialized" check.

---

### /dev:build

**Purpose:** Main workflow — take a feature description, decompose it, plan it, execute it with agents, and review it.

**Input:**
- Arguments: `[feature-description]` — what to build (natural language)
- Flags:
  - `--brand [name]` — load brand context for planning and design agents
  - `--dry-run` — decompose and plan but don't execute
  - `--wave [N]` — resume from a specific wave (for recovery)
- Interactive prompts: confirms decomposition, reviews wave plan before execution

**Execution Strategy:**

Interactive phases (cannot be parallelized):
1. Run `feature-decomposer` — PM + Architect + Designer + PO collaborate to decompose the feature
2. Run `team-planner` — PM + TLs assign tasks, tiers, verify file overlap

After interactive phases, call /plan:create with:
- Tasks: from team-planner output (wave plan with assignments)
- Verification profile: `dev_profile`
- QA frequency: `every_wave`

Then call /plan:execute to run the plan:
- Phase 3: `agent-dispatcher` dispatches agents, `tier-assigner` handles self-tiering, `completion-gate` verifies per agent
- Phase 4: `code-review` audits diff, `qa-validation` validates against spec

**Output:**
- Code committed to repository (by specialist agents)
- `.ai/dev/[project-name]/team-state.yml` — full execution record
- Build report in team-state.yml review section

**Recovery:**
If interrupted, check `team-state.yml` at `.ai/dev/[project-name]/`. Resume with `/dev:build --wave N` where N is the last incomplete wave. The task-planner's `/plan:resume` handles wave-level recovery.

---

### /dev:scan

**Purpose:** Delta scan — detect changes since last init/scan, update knowledge files with maturity lifecycle.

**Input:**
- Arguments: none
- Flags:
  - `--verbose` — show all changes detected, not just curated ones
- Interactive prompts: none (fully autonomous)

**Execution Strategy:**

Single skill, no planner needed:
1. Run `delta-scanner` — compares file hashes, detects changes, curates knowledge updates

**Output:**
- Updated `.ai/dev/[project-name]/knowledge/*.yml` — new/modified/deprecated entries
- Updated `.ai/dev/[project-name]/dev-config.yml` — scan.last_scan_at and file_hashes refreshed

**Recovery:**
Idempotent — re-run if interrupted.

---

### /dev:status

**Purpose:** Show current team state — active tasks, agent assignments, blockers, progress.

**Input:**
- Arguments: none
- Flags: none
- Interactive prompts: none (read-only)

**Execution Strategy:**

No skills needed — reads team-state.yml and presents a formatted summary:
1. Read `.ai/dev/[project-name]/team-state.yml`
2. Format current phase, wave progress, agent assignments, any blockers
3. If blockers exist, show impact analysis (directly and transitively blocked tasks)
4. Show commit range and test/lint/build status per completed task

**Output:**
- Formatted status display to stdout (no files written)

**Recovery:**
Not applicable — read-only command.

---

## Skills

### Skill: project-scanner

**Purpose:** Perform static analysis of the project to detect frameworks, conventions, architecture patterns, and key files.

**Interactive:** No
**Depends on:** None
**Model tier:** Junior (Haiku) — pattern matching against known framework signatures

**Inputs:**
- Reads: project source files via Glob and Grep
- Key files to check: package.json, tsconfig.json, next.config.*, vite.config.*, prisma/schema.prisma, turbo.json, nx.json, .eslintrc.*, .prettierrc.*, jest.config.*, vitest.config.*, playwright.config.*, docker-compose.yml, Dockerfile, .github/workflows/*

**Process:**
1. Read package.json (if exists) — extract dependencies, devDependencies, scripts
2. Glob for known config files — next.config.*, vite.config.*, turbo.json, nx.json, prisma/schema.prisma, etc.
3. Detect language — check for tsconfig.json (TypeScript), jsconfig.json (JavaScript), go.mod (Go), Cargo.toml (Rust), requirements.txt/pyproject.toml (Python)
4. Detect package manager — check for pnpm-lock.yaml, yarn.lock, bun.lockb, package-lock.json
5. Detect architecture pattern — check for packages/ or apps/ (monorepo), src/pages or src/app (Next.js app/pages router), src/routes (SvelteKit/Remix)
6. Detect testing frameworks — check for jest.config.*, vitest.config.*, playwright.config.*, cypress.config.*
7. Detect linting/formatting — check for .eslintrc.*, biome.json, .prettierrc.*
8. Map src structure — identify entry points, key directories, component libraries (check for shadcn components.json, material-ui imports)
9. Detect git conventions — read recent commit messages for patterns, check for .github/ templates
10. Compile scan results into structured internal format

**Output:**
- Internal scan results object (passed to config-generator, not written to disk)

**Checkpoint:**
- Type: data_validation
- Checks:
  - Scan results contain at least 1 detected framework or explicit "none detected"
  - Language field is populated
  - Package manager field is populated (or "unknown")
  - At least 3 config files checked (even if not found)

---

### Skill: config-generator

**Purpose:** Transform scan results into dev-config.yml, present to user for confirmation and correction of any misdetections.

**Interactive:** Yes
**Depends on:** project-scanner
**Model tier:** Senior (Sonnet) — needs to reason about ambiguous detections and present clearly

**Inputs:**
- Reads: scan results from project-scanner
- Reads: brand-reference.yml (optional, via brand-context-loader — if `--brand` flag provided)

**Process:**
1. Transform scan results into dev-config.yml schema format
2. For each detected framework, show the user: name, version, detection method, confidence
3. Ask user to confirm or correct: "Detected Next.js 14.1.0 (from package.json). Correct? [Y/n]"
4. For conventions not auto-detectable, ask explicitly:
   - "What's your branch naming pattern?" (suggest based on git log if possible)
   - "What's your commit message format?" (suggest based on recent commits)
   - "Target test coverage threshold?" (suggest 80% as default)
5. Populate the `commands` section by reading package.json scripts — map `build`, `dev`, `test`, `lint`, `format`, `typecheck`
6. If any commands are missing, ask the user: "No test command detected. What command runs your tests?"
7. Write dev-config.yml to `.ai/dev/[project-name]/dev-config.yml`
8. Present final summary and get user confirmation

**Output:**
- `.ai/dev/[project-name]/dev-config.yml` — the central project contract

**Checkpoint:**
- Type: data_validation
- Checks:
  - dev-config.yml exists at expected path
  - `meta` section has all required fields (plugin_name, project_name, created_at, version)
  - `frameworks` section has at least the `runtime` array (can be empty but must exist)
  - `conventions.language` is populated
  - `commands.build` is populated (every project must have a build command)
  - User confirmed the config (status: confirmed noted in interaction)

---

### Skill: knowledge-initializer

**Purpose:** Generate initial tagged knowledge files and mermaid architecture diagrams from the confirmed project config and source analysis.

**Interactive:** No
**Depends on:** config-generator
**Model tier:** Senior (Sonnet) — needs to reason about architecture and produce useful knowledge

**Inputs:**
- Reads: `.ai/dev/[project-name]/dev-config.yml`
- Reads: project source files (for architecture analysis)

**Process:**
1. Read dev-config.yml to understand project structure, frameworks, conventions
2. Analyze source structure — identify modules, their imports, and data flow between them
3. Generate architecture knowledge file with mermaid diagram:
   - Module boundaries (which directories are which concerns)
   - Data flow (which modules call which)
   - External integrations (APIs, databases, third-party services)
4. Generate patterns knowledge file:
   - Detected design patterns (repository, service layer, middleware chain, etc.)
   - State management patterns
   - Error handling patterns
5. Generate conventions knowledge file:
   - Naming conventions (from existing code analysis)
   - File organization patterns
   - Import ordering patterns
6. Tag each knowledge file with relevant tags from: `api`, `auth`, `database`, `frontend`, `backend`, `testing`, `devops`, `architecture`, `patterns`, `conventions`
7. Set initial maturity to `candidate` for all entries (promoted to `established` after first successful build)
8. Compute content hashes for Jaccard dedup in future delta scans
9. Write all knowledge files to `.ai/dev/[project-name]/knowledge/`
10. Update dev-config.yml `scan` section with file hashes and timestamp

**Output:**
- `.ai/dev/[project-name]/knowledge/architecture.md` — mermaid diagrams
- `.ai/dev/[project-name]/knowledge/patterns.yml` — detected design patterns
- `.ai/dev/[project-name]/knowledge/conventions.yml` — naming and organization conventions
- Additional knowledge files as detected

**Checkpoint:**
- Type: file_validation
- Checks:
  - At least 1 knowledge file created in knowledge/ directory
  - All knowledge files have frontmatter with `tags` array (at least 1 tag per file)
  - All knowledge files have `maturity` field set to `candidate`
  - architecture.md contains at least 1 mermaid code block
  - dev-config.yml `scan.last_scan_at` is updated

---

### Skill: feature-decomposer

**Purpose:** Phase 1 of /dev:build — PM orchestrates Architect, Designer, and PO to break a feature request into components with clear boundaries, visual specs, and validated scope.

**Interactive:** Yes
**Depends on:** config-generator (dev-config.yml must exist)
**Model tier:** Principal (Opus) — architectural reasoning, multi-perspective synthesis

**Inputs:**
- Reads: user's feature description (from /dev:build argument)
- Reads: `.ai/dev/[project-name]/dev-config.yml` — project structure and frameworks
- Reads: `.ai/dev/[project-name]/knowledge/*.yml` — existing architecture and patterns
- Reads: brand-reference.yml (optional, via brand-context-loader)

**Process:**
1. PM receives the feature description and presents initial understanding to user: "Here's what I understand you want to build: [summary]. Correct?"
2. PM dispatches Architect agent to analyze the feature against existing architecture:
   - Which existing modules are affected?
   - What new modules need to be created?
   - What are the boundaries between components?
   - What contracts (interfaces, API endpoints) need to be defined?
3. Present Architect's component breakdown to user for feedback
4. PM dispatches Designer agent (if UI is involved):
   - Produce visual specs for each frontend component
   - Reference brand context if available (colors, typography, layout rules)
   - Define responsive behavior and interaction patterns
5. Present Designer's specs to user for feedback
6. PM dispatches PO agent to validate scope:
   - Does the decomposition achieve the user's stated goal?
   - Are there missing components?
   - Is the scope appropriate (not too large, not too small)?
7. Present PO validation to user: "PO assessment: [approval/concerns]. Proceed?"
8. Write decomposition to team-state.yml `decomposition` section
9. Present final summary with all components, boundaries, and visual specs

**Output:**
- `.ai/dev/[project-name]/team-state.yml` — decomposition section populated

**Checkpoint:**
- Type: data_validation
- Checks:
  - At least 1 component defined in decomposition.components
  - Every component has non-empty `name`, `description`, `boundaries`, `type`
  - Every component has at least 1 entry in `files_affected`
  - PO validation status is recorded (approved/revised/rejected)
  - If UI components exist: at least 1 designer_spec entry

---

### Skill: team-planner

**Purpose:** Phase 2 of /dev:build — PM creates work packages, Frontend and Backend Tech Leads assign tasks to their teams with appropriate model tiers, verify file overlap, and assemble the final wave plan.

**Interactive:** Yes
**Depends on:** feature-decomposer
**Model tier:** Principal (Opus) — planning, tier assignment, conflict resolution

**Inputs:**
- Reads: `.ai/dev/[project-name]/team-state.yml` — decomposition section
- Reads: `.ai/dev/[project-name]/dev-config.yml` — project structure

**Process:**
1. PM creates initial work packages from decomposition: each component becomes 1+ tasks
2. PM dispatches Frontend TL agent for frontend tasks:
   - Assign each frontend task to a specialist (Frontend Worker, Designer, E2E Test Expert)
   - Assess risk and assign model tier: junior (single file, clear spec), senior (multi-file), principal (system-wide)
   - Identify files each task will touch
3. PM dispatches Backend TL agent for backend tasks:
   - Assign each backend task to a specialist (Backend Worker, DevOps, Security Expert)
   - Assess risk and assign model tier
   - Identify files each task will touch
4. Both TLs verify file overlap — no two agents touch the same file in the same wave
   - If overlap detected: TLs negotiate resolution (resequence, merge tasks, or split file responsibility)
5. PM assembles final wave plan:
   - Group independent tasks into parallel waves
   - Sequential tasks form their own waves
   - Interactive tasks (if any) come first
6. Present wave plan to user with task assignments, tiers, and parallelism
7. User confirms or adjusts the plan
8. Write wave plan to team-state.yml `wave_plan` section
9. Register file ownership in team-state.yml `wave_plan.file_ownership`

**Output:**
- `.ai/dev/[project-name]/team-state.yml` — wave_plan section populated with tasks, tiers, ownership

**Checkpoint:**
- Type: data_validation
- Checks:
  - Wave plan has at least 1 wave
  - Every task has: id, description, assigned_agent, model_tier, component, files_owned
  - No two tasks in the same wave own the same file
  - Every component from decomposition has at least 1 task assigned
  - TL sign-off recorded (frontend_tl_approved, backend_tl_approved)
  - User confirmed the plan

---

### Skill: agent-dispatcher

**Purpose:** Phase 3 of /dev:build — dispatch specialist agents via Task() tool for isolated parallel execution, collect structured reports.

**Interactive:** No
**Depends on:** team-planner
**Model tier:** Senior (Sonnet) — orchestration, report collection, error handling

**Inputs:**
- Reads: `.ai/dev/[project-name]/team-state.yml` — wave_plan section
- Reads: `.ai/dev/[project-name]/knowledge/*.yml` — tag-filtered per task context

**Process:**
1. Read the wave plan from team-state.yml
2. For each wave in sequence:
   a. Record base_sha (current HEAD) for the wave
   b. For each task in the wave:
      - Build the dispatch prompt: task description, assigned agent role, file ownership list, relevant knowledge (tag-filtered), brand context (if available)
      - Map model_tier to model selection: junior→Haiku, senior→Sonnet, principal→Opus
      - For self-tiering agents: dispatch at Haiku first for assessment, then at declared tier
   c. If wave.parallel is true: dispatch all tasks in the wave simultaneously via multiple Task() calls
   d. If wave.parallel is false: dispatch tasks sequentially
   e. Collect subagent reports (files changed, commit SHA, notes)
   f. Update team-state.yml with dispatch/completion timestamps and commit SHAs
3. After all tasks in a wave complete, record wave commit range (base_sha → HEAD)
4. Pass to completion-gate for verification

**Output:**
- `.ai/dev/[project-name]/team-state.yml` — execution section updated with dispatched tasks, reports, commit SHAs

**Checkpoint:**
- Type: data_validation
- Checks:
  - All tasks in the current wave have status "completed" or "failed"
  - Every completed task has a subagent report with files_changed list
  - Every completed task has a commit_sha recorded
  - team-state.yml execution.current_wave is updated

---

### Skill: tier-assigner

**Purpose:** Self-tiering logic for domain specialist agents — assess task complexity at Haiku cost, declare appropriate tier, auto-escalate on failure.

**Interactive:** No
**Depends on:** None (utility skill called by agent-dispatcher)
**Model tier:** Junior (Haiku) — the assessment itself runs at Haiku to minimize cost

**Inputs:**
- Reads: task brief from team-planner (description, scope, files affected)
- Reads: agent role definition (model floor, capabilities)

**Process:**
1. Receive task brief and agent role
2. Assess complexity factors:
   - Number of files affected (1 → junior, 2-5 → senior, 6+ → principal)
   - Ambiguity of spec (clear → junior, some choices → senior, unclear → principal)
   - Risk level (low → junior, medium → senior, high/critical → principal)
   - Cross-cutting concerns (isolated → junior, feature-scoped → senior, system-wide → principal)
3. Apply model floors: Code Reviewer and Security Expert never below Sonnet, Designer never below Sonnet
4. Declare tier with reasoning
5. If a previous attempt at this task failed at a lower tier: auto-escalate one level
6. If failed at Opus (max tier): report blocked to PM with failure details

**Output:**
- Tier assignment: { tier: "junior"|"senior"|"principal", reasoning: string, escalated_from: string|null }

**Checkpoint:**
- Type: data_validation
- Checks:
  - Tier is one of: junior, senior, principal
  - Tier respects model floor for the agent role
  - If escalated: previous tier and failure reason are recorded
  - Reasoning is non-empty (at least 1 sentence)

---

### Skill: completion-gate

**Purpose:** Per-agent pragmatic quality gate — verify that the agent's output builds, lints clean, and passes related tests. Agents fix failures while context is fresh.

**Interactive:** No
**Depends on:** agent-dispatcher
**Model tier:** Junior (Haiku) — runs shell commands, checks exit codes

**Inputs:**
- Reads: subagent reports from agent-dispatcher (files changed per task)
- Reads: `.ai/dev/[project-name]/dev-config.yml` — build, lint, test commands

**Process:**
1. For each completed task's changed files:
   a. Run the build command from dev-config.yml `commands.build`
   b. Run the lint command from dev-config.yml `commands.lint`
   c. Run the related test command: `commands.test_related [changed files]`
2. If all three pass: mark task gate as passed
3. If any fail:
   a. Return failure details to the agent (while it still has context)
   b. Agent attempts fix
   c. Re-run gate checks
   d. If still failing after 2 attempts: mark as failed, log to errors array
4. At wave boundary (all tasks in wave done): run full test suite via `commands.test`
5. Record gate results in team-state.yml execution.dispatched_tasks[].report

**Output:**
- Gate results per task: { build_passed, lint_passed, tests_passed }
- Updated team-state.yml with gate results

**Checkpoint:**
- Type: code_quality_gate
- Checks:
  - Build command exits with code 0
  - Lint command exits with code 0
  - Related tests exit with code 0
  - If any gate failed: error is logged to team-state.yml errors array

---

### Skill: code-review

**Purpose:** Phase 4a — Code Reviewer agent audits the full wave diff for quality, patterns, security, and convention adherence.

**Interactive:** No
**Depends on:** completion-gate
**Model tier:** Senior (Sonnet) — minimum floor, may escalate to Opus for complex diffs

**Inputs:**
- Reads: git diff for the wave (execution.commit_range: base_sha..head_sha)
- Reads: `.ai/dev/[project-name]/dev-config.yml` — conventions section
- Reads: `.ai/dev/[project-name]/knowledge/conventions.yml` — project patterns

**Process:**
1. Get the wave's commit range from team-state.yml
2. Run `git diff base_sha..head_sha` to get the full wave diff
3. Review each changed file for:
   a. Code quality — readability, naming, function size, nesting depth
   b. Pattern adherence — does the code follow existing patterns from knowledge files?
   c. Convention compliance — naming, imports, file organization per dev-config.yml
   d. Security — check for OWASP top 10 (injection, XSS, auth bypass, hardcoded secrets)
   e. Performance — obvious N+1 queries, unnecessary re-renders, missing indexes
4. Rate each finding: critical (must fix), warning (should fix), info (suggestion)
5. Write findings to team-state.yml review.code_review section
6. If critical findings exist: report back to PM for remediation before QA

**Output:**
- `.ai/dev/[project-name]/team-state.yml` — review.code_review populated

**Checkpoint:**
- Type: data_validation
- Checks:
  - Code review report has status field (pending/passed/failed)
  - All changed files are covered in the review (no files skipped)
  - Each finding has: file, severity (critical/warning/info), message
  - If critical findings: review status is "failed" (blocks QA)

---

### Skill: qa-validation

**Purpose:** Phase 4b — QA Expert validates the build against the original spec, PO checks end-goal alignment.

**Interactive:** No
**Depends on:** code-review
**Model tier:** Principal (Opus) — judgment-heavy, spec interpretation, holistic assessment

**Inputs:**
- Reads: `.ai/dev/[project-name]/team-state.yml` — decomposition (original spec), code review findings, execution reports
- Reads: user's original feature description

**Process:**
1. Read the original decomposition (the spec) from team-state.yml
2. Read all subagent reports and code review findings
3. QA assessment:
   a. Spec alignment — does every component from the decomposition have corresponding implemented code?
   b. Completeness — are there any unimplemented requirements?
   c. Quality — aggregate gate results (build/lint/test) and code review findings
   d. Calculate spec alignment score (0-100): components implemented / components specified × quality factor
4. PO assessment:
   a. Does the implementation achieve the user's original stated goal?
   b. Are there any deviations from the intended scope?
   c. Record PO sign-off: approved or revisions_needed
5. Generate build report:
   a. Summary of what was built
   b. Which agents worked on what (with tiers used)
   c. Test results summary
   d. Code review findings summary
   e. Any blockers encountered and how they were resolved
6. Write QA report and build report to team-state.yml review section

**Output:**
- `.ai/dev/[project-name]/team-state.yml` — review.qa_validation populated, build report in review section

**Checkpoint:**
- Type: data_validation
- Checks:
  - QA report has spec_alignment score (0-100)
  - PO sign-off recorded (approved/revisions_needed)
  - Build report generated with at least: summary, agents used, test results
  - If spec_alignment < 70: status is "failed" with specific gaps listed

---

### Skill: delta-scanner

**Purpose:** Lightweight re-scan — compare file hashes to detect changes since last scan, curate knowledge updates using maturity lifecycle (candidate → established → proven → deprecated).

**Interactive:** No
**Depends on:** None (standalone, used by /dev:scan)
**Model tier:** Junior (Haiku) — hash comparison, maturity state machine

**Inputs:**
- Reads: `.ai/dev/[project-name]/dev-config.yml` — scan.file_hashes (previous hashes)
- Reads: `.ai/dev/[project-name]/knowledge/*.yml` — existing knowledge entries
- Reads: project source files (for new hash computation)

**Process:**
1. Read previous file hashes from dev-config.yml scan section
2. Compute current hashes for all tracked files
3. Identify changed files (hash mismatch), new files (no previous hash), deleted files (hash exists but file missing)
4. For each changed/new file:
   a. Analyze the change — what's different?
   b. Curate: Is this worth knowing? (skip trivial formatting changes, version bumps)
   c. If worth knowing: determine which knowledge file it belongs to (by tags)
   d. Check for duplicates using Jaccard similarity against existing entries
   e. Create or update knowledge entry
5. Apply maturity lifecycle:
   - New entries: `candidate`
   - Entries confirmed by multiple scans: promote to `established`
   - Entries stable for 3+ scans: promote to `proven`
   - Entries contradicted by new evidence: `deprecated`
   - Entries not seen in 90 days: `deprecated` (time-based decay)
6. Update file hashes in dev-config.yml scan section
7. Update scan.last_scan_at timestamp

**Output:**
- Updated knowledge files in `.ai/dev/[project-name]/knowledge/`
- Updated dev-config.yml scan section

**Checkpoint:**
- Type: data_validation
- Checks:
  - Hash comparison completed (files_tracked count matches or explains difference)
  - Every new/updated knowledge entry has tags and maturity fields
  - No duplicate entries (Jaccard similarity < 0.8 for all pairs)
  - dev-config.yml scan.last_scan_at is updated

---

## Build Order

| # | Skill | Model Tier | Rationale |
|---|-------|------------|-----------|
| 1 | project-scanner | junior | Foundation — all other skills depend on scan data |
| 2 | project-scanner spec compliance | junior | Stage 1 verification |
| 3 | project-scanner quality review | principal | Stage 2 verification |
| 4 | config-generator | senior | Transforms scan data, needs user interaction logic |
| 5 | config-generator spec compliance | junior | Stage 1 verification |
| 6 | config-generator quality review | principal | Stage 2 verification |
| 7 | knowledge-initializer | senior | Architecture analysis and knowledge generation |
| 8 | knowledge-initializer spec compliance | junior | Stage 1 verification |
| 9 | knowledge-initializer quality review | principal | Stage 2 verification |
| 10 | tier-assigner | junior | Simple rule engine, needed by agent-dispatcher |
| 11 | tier-assigner spec compliance | junior | Stage 1 verification |
| 12 | tier-assigner quality review | principal | Stage 2 verification |
| 13 | feature-decomposer | principal | Multi-agent orchestration, architectural reasoning |
| 14 | feature-decomposer spec compliance | junior | Stage 1 verification |
| 15 | feature-decomposer quality review | principal | Stage 2 verification |
| 16 | team-planner | principal | Planning, tier assignment, conflict resolution |
| 17 | team-planner spec compliance | junior | Stage 1 verification |
| 18 | team-planner quality review | principal | Stage 2 verification |
| 19 | agent-dispatcher | senior | Orchestration, Task() dispatch, report collection |
| 20 | agent-dispatcher spec compliance | junior | Stage 1 verification |
| 21 | agent-dispatcher quality review | principal | Stage 2 verification |
| 22 | completion-gate | junior | Shell command execution, exit code checks |
| 23 | completion-gate spec compliance | junior | Stage 1 verification |
| 24 | completion-gate quality review | principal | Stage 2 verification |
| 25 | code-review | senior | Diff analysis, pattern matching, security checks |
| 26 | code-review spec compliance | junior | Stage 1 verification |
| 27 | code-review quality review | principal | Stage 2 verification |
| 28 | qa-validation | principal | Judgment-heavy, spec interpretation, holistic |
| 29 | qa-validation spec compliance | junior | Stage 1 verification |
| 30 | qa-validation quality review | principal | Stage 2 verification |
| 31 | delta-scanner | junior | Hash comparison, state machine logic |
| 32 | delta-scanner spec compliance | junior | Stage 1 verification |
| 33 | delta-scanner quality review | principal | Stage 2 verification |

### Model Tier Distribution

| Tier | Count | Tasks |
|------|-------|-------|
| Junior (Haiku) | 16 | project-scanner, tier-assigner, completion-gate, delta-scanner, all 11 spec compliance checks |
| Senior (Sonnet) | 4 | config-generator, knowledge-initializer, agent-dispatcher, code-review |
| Principal (Opus) | 13 | feature-decomposer, team-planner, qa-validation, all 11 quality reviews |

### Verification Task Dependencies

```
project-scanner → project-scanner spec compliance → project-scanner quality review
config-generator → config-generator spec compliance → config-generator quality review
knowledge-initializer → knowledge-initializer spec compliance → knowledge-initializer quality review
tier-assigner → tier-assigner spec compliance → tier-assigner quality review
feature-decomposer → feature-decomposer spec compliance → feature-decomposer quality review
team-planner → team-planner spec compliance → team-planner quality review
agent-dispatcher → agent-dispatcher spec compliance → agent-dispatcher quality review
completion-gate → completion-gate spec compliance → completion-gate quality review
code-review → code-review spec compliance → code-review quality review
qa-validation → qa-validation spec compliance → qa-validation quality review
delta-scanner → delta-scanner spec compliance → delta-scanner quality review
```

Stage 1 (spec compliance, junior) always gates Stage 2 (quality review, principal). If Stage 1 fails, Stage 2 is skipped and the skill is marked `failed_spec`.
