# Smedjen — Architecture

Single source of truth for plugin structure, conventions, and contracts.

## Purpose

Smedjen is the generic development execution plugin. It provides task
decomposition, agent dispatch, engineering discipline knowledge, tech stack
expertise, and completion verification. It depends on kronen for planning,
tracing, and memory. It integrates with herold for task ingestion but never
depends on it directly.

## Plugin Hierarchy

```
kronen          <- foundation, always installed
smedjen           <- development execution, depends on kronen
herold               <- task management, depends on kronen
```

## Directory Layout

```
plugins/smedjen/
├── .claude-plugin/
│   ├── plugin.json          # Plugin manifest — no hooks
│   └── ecosystem.json       # Component registry (50 skills, 6 agents, 1 command)
├── agents/                  # 6 agents
│   ├── architect.md
│   ├── backend-dev.md
│   ├── code-reviewer.md
│   ├── frontend-dev.md
│   ├── app-security-auditor.md
│   └── test-engineer.md
├── commands/                # 1 command
│   └── dev-scan.md
├── skills/                  # 50 skills, each with SKILL.md + references/process.md
│   ├── task-decomposer/     # Core: break tasks into subtasks
│   ├── agent-dispatcher/    # Core: dispatch subtasks to agents (with reference_paths)
│   ├── completion-gate/     # Core: 10-point quality gate
│   ├── tier-assignment/     # Core: risk-based model tier selection
│   ├── visual-verification/ # Core: screenshot-based UI verification
│   ├── project-mapper/      # Core: project profile with skills matching
│   ├── tdd-workflow/        # Discipline: red-green-refactor
│   ├── error-handling-patterns/ # Discipline: structured error handling
│   ├── verification-before-completion/ # Discipline: proof protocol
│   ├── git-advanced-workflows/  # Discipline: branching, rebase, bisect
│   ├── code-review/         # Discipline: review criteria
│   ├── skill-quality-rubric/ # Integration: skill scoring framework
│   ├── ...                  # 24 tech skills (react, nextjs, nestjs, expo, fumadocs, etc.)
│   ├── expo-*/              # Expo: 12 skills (dom-components, swiftui, tailwind, etc.)
│   └── design-to-code-patterns/ # Integration: design-code handoff
└── resources/               # Shared resources
```

## Execution Model

Smedjen components chain naturally via Claude — no pipeline orchestrator.
The typical flow:

```
1. project-mapper      — scan codebase, produce .ai/project-map.yml
2. task-decomposer     — break task into subtasks
3. tier-assignment     — assign model tier per subtask
4. agent-dispatcher    — dispatch to worker agents (with reference_paths)
5. completion-gate     — verify all work meets quality bar
```

Ordering invariants are enforced by agent-dispatcher's prerequisites checkpoint:
decomposition must exist and file ownership must be resolved before dispatch.

## reference_paths

Agent-dispatcher includes relevant skill reference paths in each agent's prompt.
Paths come from `.ai/project-map.yml` which maps detected tech stack to smedjen
knowledge skill names. Agents read references on demand via the Read tool.

## Conventions

- **SKILL.md max 80 lines.** Overflow content goes to `references/process.md`.
- **Agents have `model_tier` and `model` in frontmatter.** `model_tier` is the
  capability tier (opus/sonnet). `model` is the runtime selector.
- **Single-writer contract.** Each state file is owned by exactly one skill or
  command. No two components write to the same file.
- **Non-modifying reviewers.** code-reviewer and app-security-auditor use Bash
  for running tests/linters/audits, never for file modifications.

## State Files

| File | Owner | Purpose |
|------|-------|---------|
| `.ai/project-map.yml` | project-mapper | Project profile with tech stack and skills matching |
| `.ai/tasks/` | herold (external) | Task definitions |
