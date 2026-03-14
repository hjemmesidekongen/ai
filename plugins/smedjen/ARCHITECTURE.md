# Smedjen — Architecture

Single source of truth for plugin structure, conventions, and contracts.

## Purpose

Smedjen is the generic development execution plugin. It provides task
decomposition, agent dispatch, engineering discipline knowledge, tech stack
expertise, and completion verification. It depends on kronen for planning,
tracing, and memory. It integrates with taskflow for task ingestion but never
depends on it directly.

## Plugin Hierarchy

```
kronen          <- foundation, always installed
smedjen           <- development execution, depends on kronen
taskflow             <- task management, depends on kronen
agency               <- digital agency, depends on kronen
```

**Rule:** Smedjen reads taskflow output files (active.yml, tasks/) but never
imports taskflow skills or calls taskflow commands directly. The taskflow-bridge
skill handles all cross-plugin communication.

## Directory Layout

```
plugins/smedjen/
├── .claude-plugin/
│   ├── plugin.json          # Plugin manifest — no hooks
│   └── ecosystem.json       # Component registry (62 skills, 6 agents, 2 commands)
├── agents/                  # 6 agents (3 opus, 3 sonnet)
│   ├── architect.md
│   ├── backend-dev.md
│   ├── code-reviewer.md
│   ├── frontend-dev.md
│   ├── app-security-auditor.md
│   └── test-engineer.md
├── commands/                # 2 commands
│   ├── dev-scan.md
│   └── dev-run.md
├── skills/                  # 62 skills, each with SKILL.md + references/process.md
│   ├── task-decomposer/     # Core: break tasks into subtasks
│   ├── context-assembler/   # Core: assemble context for agents
│   ├── agent-dispatcher/    # Core: dispatch subtasks to agents
│   ├── completion-gate/     # Core: 10-point quality gate
│   ├── smedjen-orchestrator/  # Core: 7-stage pipeline
│   ├── tier-assignment/     # Core: risk-based model tier selection
│   ├── visual-verification/ # Core: screenshot-based UI verification
│   ├── tdd-workflow/        # Discipline: red-green-refactor
│   ├── error-handling-patterns/ # Discipline: structured error handling
│   ├── verification-before-completion/ # Discipline: proof protocol
│   ├── git-advanced-workflows/  # Discipline: branching, rebase, bisect
│   ├── code-review/         # Discipline: review criteria
│   ├── taskflow-bridge/     # Integration: cross-plugin task flow
│   ├── project-mapper/      # Integration: codebase scanning
│   ├── ...                  # 25 tech skills (react, nextjs, nestjs, expo, fumadocs, etc.)
│   ├── expo-*/              # Expo: 12 skills (dom-components, swiftui, tailwind, etc.)
│   ├── web-copywriting/     # Studio: web copy aligned with brand voice
│   ├── content-strategy-patterns/ # Studio: content planning and structure
│   ├── seo-fundamentals/    # Studio: search optimization basics
│   ├── marketing-psychology-patterns/ # Studio: persuasion and conversion
│   ├── brand-voice-implementation/    # Studio: brand consistency in code
│   ├── social-media-patterns/  # Studio: social content patterns
│   ├── sitemap-planning/    # Studio: information architecture
│   └── design-to-code-patterns/ # Studio: translating designs to components
└── resources/               # Shared resources
```

## Pipeline Architecture

The smedjen orchestrator runs a 7-stage pipeline:

```
1. project-mapper      — scan codebase, produce .ai/project-map.yml
2. taskflow-bridge      — load task from taskflow (if active)
3. task-decomposer      — break task into subtasks
4. context-assembler    — assemble context per subtask
5. tier-assignment      — assign model tier per subtask
6. agent-dispatcher     — dispatch to worker agents
7. completion-gate      — verify all work meets quality bar
```

Each stage has a skip condition — if prior output exists and is current, the
stage is skipped. This makes the pipeline idempotent for reruns.

## Conventions

- **SKILL.md max 80 lines.** Overflow content goes to `references/process.md`.
- **Agents have `model_tier` and `model` in frontmatter.** `model_tier` is the
  capability tier (opus/sonnet). `model` is the runtime selector (inherit/haiku/sonnet/opus).
- **Single-writer contract.** Each state file is owned by exactly one skill or
  command. No two components write to the same file.
- **Non-modifying reviewers.** code-reviewer and app-security-auditor use Bash
  for running tests/linters/audits, never for file modifications.
- **No cross-plugin skill imports.** Smedjen skills reference taskflow output
  files but never invoke taskflow skills directly.

## State Files

| File | Owner | Purpose |
|------|-------|---------|
| `.ai/project-map.yml` | project-mapper | Codebase structure and tech stack |
| `.ai/tasks/` | taskflow (external) | Task definitions, read by taskflow-bridge |
| `.ai/tasks/active.yml` | taskflow task-done (external) | Active task pointer, read-only for smedjen |
