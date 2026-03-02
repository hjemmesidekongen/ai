---
name: status
command: "/dev:status"
description: "Show current team state — active tasks, agent assignments, wave progress, blockers"
arguments: []
---

# /dev:status

Show current team state — active tasks, agent assignments, wave progress, blockers, and build health. Read-only command that presents a formatted summary of the dev team's execution state.

## Usage

```
/dev:status
```

## Purpose

Displays the current state of a `/dev:build` execution or project initialization. Shows which phase is active, wave progress, per-task agent assignments and statuses, any blockers with impact analysis, and build/lint/test health metrics. This is a read-only command — it writes nothing.

## Prerequisites

- `/dev:init` must have been run (dev-config.yml must exist at `~/.claude/dev/[project-name]/`)
- For build status: a `/dev:build` must be in progress or completed (team-state.yml must exist)

## Input

- Arguments: none
- Flags: none
- Interactive prompts: none (read-only)

## Execution Strategy

No skills needed — reads state files and presents formatted output.

### Step 1: Read Project State

Read `~/.claude/dev/[project-name]/dev-config.yml` for project context (name, framework, tech stack).

If missing:
- Error: "Project not initialized. Run `/dev:init` first."
- Exit

### Step 2: Read Team State

Read `~/.claude/dev/[project-name]/team-state.yml`.

If missing:
- Display project info from dev-config.yml only:

```
Project: [project-name]
Status: initialized (no active build)
Last scan: [scan.last_scan_at or "never"]
Files tracked: [scan.files_tracked or 0]

Run /dev:build to start a build, or /dev:scan to update knowledge.
```
- Exit

### Step 3: Display Full Status

Present formatted status from team-state.yml:

```
Project: [project-name]
Status: [build.status]
Feature: [build.feature_description]
Phase: [build.current_phase] / 4
Wave: [execution.current_wave] / [total waves]
Started: [build.started_at]

## Tasks
| Task | Agent | Tier | Status | Files |
|------|-------|------|--------|-------|
| [id] | [assigned_agent] | [model_tier] | [status] | [files_owned count] |

## Blockers (if any)
- [task_id]: [reason] — blocks [N] tasks transitively

## Build Health
- Build: [pass/fail rate across completed tasks]
- Lint: [pass/fail rate across completed tasks]
- Tests: [pass/fail rate across completed tasks]

## Commit Range
[base_sha]..[latest commit_sha]
```

### Step 4: Blocker Impact Analysis

If blockers exist, show the PM's impact analysis:
- Directly blocked tasks (tasks with a blockedBy referencing the blocker)
- Transitively blocked tasks (tasks blocked by the directly blocked tasks)
- Independent tasks that can still proceed in parallel

## Output

- Formatted status display to stdout (no files written)

## Recovery

Not applicable — read-only command.

## Error Handling

- **dev-config.yml missing:** Error message directing user to run `/dev:init` first
- **team-state.yml missing:** Show project info only with guidance to run `/dev:build` or `/dev:scan`
- **team-state.yml malformed:** Report parsing error, suggest re-running `/dev:build`
