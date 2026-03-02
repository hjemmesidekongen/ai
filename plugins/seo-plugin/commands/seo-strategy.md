---
name: seo-strategy
command: "/seo:strategy"
description: "(seo) Generate a complete SEO strategy through guided interview and automated analysis"
arguments:
  - name: project-name
    type: string
    required: true
    description: "Kebab-case identifier for the project (e.g., 'my-saas-app')"
  - name: brand
    type: string
    required: false
    description: "Which brand context to use. If omitted and multiple brands exist, prompts for selection."
  - name: format
    type: string
    required: false
    default: "md"
    description: "Output format: md, docx, or both"
  - name: resume
    type: boolean
    required: false
    default: false
    description: "Resume a previously interrupted strategy generation."
---

# /seo:strategy

The main entry point for generating a complete SEO strategy. Orchestrates a 7-phase pipeline that combines interactive interviews (phases 1-2) with automated analysis and generation (phases 3-7).

## Usage

```
/seo:strategy my-project                          # start a new strategy
/seo:strategy my-project --brand acme-corp         # use specific brand context
/seo:strategy my-project --format both             # output md + docx
/seo:strategy my-project --resume                  # resume interrupted generation
```

## Purpose

Generates a full SEO strategy through an interactive process with keyword research, competitor analysis, technical SEO audit, content planning, and link-building recommendations. Produces both a machine-readable YAML file and a human-readable strategy document.

## Prerequisites

- task-planner plugin installed
- brand-guideline plugin installed (optional but recommended — at least one brand generated)
- Node.js 18+

## Input

- `project-name` (required) — kebab-case project identifier
- `--brand [name]` (optional) — which brand context to load
- `--format [md|docx|both]` (optional, default: md) — output format
- `--resume` (optional) — resume an interrupted generation

## Architecture

This command bridges two plugins:

- **seo-plugin** provides the 7 domain skills and SEO-specific logic
- **task-planner** provides wave decomposition, file ownership, verification, and QA

The command splits execution into two stages:

```
Stage 1: Interactive (phases 1-2)       Stage 2: Automated (phases 3-7)
┌─────────────────────────┐             ┌─────────────────────────┐
│ project-interview       │             │ /plan:create            │
│ keyword-research        │  ────────►  │ /plan:execute           │
│                         │             │   with verification     │
│ (requires user input)   │             │   and QA gates          │
└─────────────────────────┘             └─────────────────────────┘
```

Phases 1-2 **cannot** be parallelized — they are interviews that require user input and each builds on the previous. Phases 3-7 **can** be parallelized where dependencies allow.

## Execution Steps

### Step 0: Check for Resume

Before starting anything, check if this is a resume:

**If `--resume` flag is set:**

1. Scan `.ai/seo/[project-name]/state.yml` for `command: "seo:strategy"` and `status != "completed"`
2. If found: jump to **Step 7: Resume** (below)
3. If not found:
   ```
   No active strategy generation found for "[project-name]".
   Start a new one with `/seo:strategy [project-name]`.
   ```

**If no resume flag:** Check anyway for an active generation:

1. Check `.ai/seo/[project-name]/state.yml` for `command: "seo:strategy"` with `status: "in_progress"`
2. If found, ask the user:
   ```
   Found an in-progress strategy generation for "[project-name]" (phase [N] of 7).

   1. Resume it
   2. Start fresh (the in-progress one will be overwritten)
   ```

### Step 1: Initialize Project Directory

Create the project directory structure:

```
.ai/seo/[project-name]/
├── seo-strategy.yml     # written incrementally by each skill
├── state.yml            # execution state (created now)
└── seo-strategy.md      # final document (created by compile-and-export)
```

**Load brand context:**
- If `--brand` is provided: load that brand via `brand-context-loader`
- If no `--brand` but only one brand exists: load it automatically
- If multiple brands and no flag: ask user which brand to use
- If no brands exist: proceed without brand data (skills handle this gracefully)

**Initialize state.yml:**

```yaml
command: "seo:strategy"
project_name: "[project-name]"
brand_name: "[brand or empty]"
started_at: "[now]"
updated_at: "[now]"
current_phase: "project-interview"
current_phase_number: 1
total_phases: 7
phases:
  - name: "project-interview"
    number: 1
    status: "pending"
    checkpoint:
      type: "data_validation"
      passed: null
    artifacts: []
  - name: "keyword-research"
    number: 2
    status: "pending"
    checkpoint:
      type: "data_validation"
      passed: null
    artifacts: []
  - name: "competitor-analysis"
    number: 3
    status: "pending"
    checkpoint:
      type: "data_validation"
      passed: null
    artifacts: []
  - name: "technical-seo"
    number: 3
    status: "pending"
    checkpoint:
      type: "data_validation"
      passed: null
    artifacts: []
  - name: "on-page-optimization"
    number: 4
    status: "pending"
    checkpoint:
      type: "data_validation"
      passed: null
    artifacts: []
  - name: "content-strategy"
    number: 5
    status: "pending"
    checkpoint:
      type: "data_validation"
      passed: null
    artifacts: []
  - name: "link-building"
    number: 6
    status: "pending"
    checkpoint:
      type: "data_validation"
      passed: null
    artifacts: []
  - name: "compile-and-export"
    number: 7
    status: "pending"
    checkpoint:
      type: "file_validation"
      passed: null
    artifacts: []
last_session_id: null
recovery_notes: null
```

**Initialize seo-strategy.yml:**

```yaml
# SEO Strategy — [project-name]
# Auto-generated by /seo:strategy
# Other plugins consume this file — do not restructure.
# Last updated: [today]
```

Report to user:

```
## SEO Strategy Generator

I'll walk you through building a complete SEO strategy in 7 phases:

  1. Project interview — website, goals, audience, current status
  2. Keyword research — primary, secondary, and long-tail keywords
  3. Competitor analysis + Technical SEO (parallel)
  4. On-page optimization rules
  5. Content strategy with topic clusters
  6. Link-building strategy
  7. Compile & export — strategy document

Phases 1-2 are interactive — I'll ask questions to understand your project.
Phases 3-7 run automatically based on your answers.

Let's start with your project details.
```

### Step 2: Run Phase 1 — Project Interview

Execute the `project-interview` skill:

1. Update state: `phases[0].status → "in_progress"`, `phases[0].started_at → now`
2. Run the skill (follows its own interview flow from SKILL.md)
3. The skill writes `meta` and `project_context` sections to `seo-strategy.yml`
4. The skill runs its own checkpoint (data_validation)
5. On checkpoint pass:
   - Update state: `phases[0].status → "completed"`, `phases[0].completed_at → now`, `phases[0].checkpoint.passed → true`
   - Update state: `current_phase → "keyword-research"`, `current_phase_number → 2`
   - Record artifacts: `["seo-strategy.yml#meta", "seo-strategy.yml#project_context"]`
   - Write recovery notes
6. On checkpoint fail: the skill handles retries internally (max 3 rounds). If it still fails after 3 rounds, mark phase as `failed` and stop.

### Step 3: Run Phase 2 — Keyword Research

Execute the `keyword-research` skill:

1. Update state: `phases[1].status → "in_progress"`, `phases[1].started_at → now`
2. Run the skill (reads project_context, loads brand voice, runs interactive keyword selection)
3. The skill writes the `keywords` section to `seo-strategy.yml`
4. The skill runs its own checkpoint (data_validation)
5. On checkpoint pass:
   - Update state: `phases[1].status → "completed"`, `current_phase → "competitor-analysis"`, `current_phase_number → 3`
   - Record artifacts: `["seo-strategy.yml#keywords"]`
   - Write recovery notes
6. On checkpoint fail: skill handles retries. If still fails, mark as `failed` and stop.

**Transition message:**

```
## Interactive phases complete!

I've captured your project context and keyword targets. Here's a summary:

Project: [name] — [industry]
Website: [url]
Goals: [N] defined
Primary keywords: [top 3 by priority]
Total keywords: [N] (primary: [N], secondary: [N], long-tail: [N])

Now I'll run the automated analysis phases:
  3. Competitor analysis + Technical SEO (parallel)
  4. On-page optimization
  5. Content strategy
  6. Link-building
  7. Compile & export

This uses the task planner to parallelize where possible.
```

### Step 4: Create Task Plan for Phases 3-7

Call `/plan:create` with the remaining phases structured as tasks:

```yaml
tasks:
  - id: "competitor-analysis"
    name: "Analyze competitor landscape and content gaps"
    depends_on: []
    files_written:
      - "seo-strategy.yml#competitors"
    files_read:
      - "seo-strategy.yml#project_context"
      - "seo-strategy.yml#keywords"
    estimated_minutes: 10
    skill: "competitor-analysis"
    checkpoint: "data_validation"

  - id: "technical-seo"
    name: "Generate technical SEO checklist"
    depends_on: []
    files_written:
      - "seo-strategy.yml#technical"
    files_read:
      - "seo-strategy.yml#project_context"
    estimated_minutes: 8
    skill: "technical-seo"
    checkpoint: "data_validation"

  - id: "on-page-optimization"
    name: "Generate on-page SEO optimization rules"
    depends_on: ["competitor-analysis"]
    files_written:
      - "seo-strategy.yml#on_page"
    files_read:
      - "seo-strategy.yml#project_context"
      - "seo-strategy.yml#keywords"
    estimated_minutes: 8
    skill: "on-page-optimization"
    checkpoint: "data_validation"

  - id: "content-strategy"
    name: "Create content plan with topic clusters and calendar"
    depends_on: ["competitor-analysis"]
    files_written:
      - "seo-strategy.yml#content_plan"
    files_read:
      - "seo-strategy.yml#keywords"
      - "seo-strategy.yml#competitors"
    estimated_minutes: 12
    skill: "content-strategy"
    checkpoint: "data_validation"

  - id: "link-building"
    name: "Develop link-building strategy and outreach plan"
    depends_on: ["competitor-analysis", "content-strategy"]
    files_written:
      - "seo-strategy.yml#link_building"
    files_read:
      - "seo-strategy.yml#competitors"
      - "seo-strategy.yml#content_plan"
    estimated_minutes: 10
    skill: "link-building"
    checkpoint: "data_validation"

  - id: "compile-and-export"
    name: "Compile strategy document and validate data"
    depends_on: ["competitor-analysis", "technical-seo", "on-page-optimization", "content-strategy", "link-building"]
    files_written:
      - "seo-strategy.md"
      - "seo-strategy.yml#meta"
    files_read:
      - "seo-strategy.yml"
      - "state.yml"
    estimated_minutes: 15
    skill: "compile-and-export"
    checkpoint: "file_validation"
    qa_review: true
```

**Plan configuration:**

```
/plan:create --name "seo-strategy-[project-name]" --profile seo_plugin_profile
```

The wave decomposer will produce waves like:

```
Wave 3: competitor-analysis + technical-seo (parallel — no dependency between them)
Wave 4: on-page-optimization, content-strategy (both depend on competitor-analysis)
Wave 5: link-building (depends on competitor-analysis + content-strategy)
Wave 6: compile-and-export (depends on everything, QA mandatory)
```

Verification profile: `seo_plugin_profile`
QA frequency: `every_wave`

Save the plan to `.ai/plans/seo-strategy-[project-name]/`.

### Step 5: Execute the Plan

Call `/plan:execute` with the generated plan:

```
/plan:execute .ai/plans/seo-strategy-[project-name]/seo-strategy-[project-name].yml
```

The plan executor handles:
- Wave-by-wave execution with verification gates
- Fix-and-retry loops for failed checks (max 3 rounds per wave)
- QA review on the final wave (compile-and-export)
- State updates and recovery notes after each wave
- File ownership enforcement

**State sync:** After each wave completes, update the project's `state.yml`:

```
for each completed task in the wave:
  find the matching phase in state.yml
  update: status → "completed", completed_at → now, checkpoint.passed → true
  update: current_phase → next uncompleted phase name
  update: current_phase_number → next uncompleted phase number
```

### Step 6: Completion Report

After all 7 phases complete and the final QA passes:

1. Update state: all phases `"completed"`, `updated_at → now`

2. Report to user:

```
## SEO Strategy Complete: [Project Name]

All 7 phases completed. QA approved.

### What was generated

**Strategy Document:**
  seo-strategy.md — human-readable SEO strategy document

**Data File:**
  seo-strategy.yml — machine-readable strategy data (for other commands)

**State:**
  state.yml — execution history and recovery notes

### Key Metrics

  Primary keywords: [N] (top: [top 3])
  Competitors analyzed: [N]
  Content gaps found: [N]
  Technical checklist: [N] items
  Topic clusters: [N] with [N] total pages
  Link strategies: [N]
  Content calendar: [N] months

### Location
  .ai/seo/[project-name]/

### Next steps
  - Review seo-strategy.md for the complete strategy
  - Use `/seo:audit [url]` to audit pages against these rules
  - Use `/seo:content-brief [keyword]` to generate content briefs
  - Use `/seo:export [project-name]` to re-export in different formats
```

### Step 7: Resume (When Resuming an Interrupted Generation)

When resuming a previously interrupted strategy generation:

1. Read `.ai/seo/[project-name]/state.yml`
2. Read `.ai/seo/[project-name]/seo-strategy.yml`
3. Determine where execution stopped:

```
for each phase in state.phases:
  if phase.status == "completed":
    skip (already done)
  elif phase.status == "in_progress":
    this is where we resume
  elif phase.status == "pending":
    this is upcoming work
```

4. Report the current state:

```
## Resuming SEO strategy: [project_name]

**Progress:** [N] of 7 phases completed
**Last active:** [time ago]

### Completed
  Phase 1 ✓ Project interview
  Phase 2 ✓ Keyword research

### Resuming from
  Phase 3 ● Competitor analysis (was in progress)

### Remaining
  Phase 3 ○ Technical SEO
  Phase 4 ○ On-page optimization
  Phase 5 ○ Content strategy
  Phase 6 ○ Link-building
  Phase 7 ○ Compile & export
```

5. Resume based on where we stopped:

**If stopped during an interactive phase (1-2):**

Re-read seo-strategy.yml to see what data exists. The skill's checkpoint will tell us what's missing. Re-run the skill — it should detect existing data and skip questions that are already answered.

**If stopped during an automated phase (3-7):**

Check if a plan file exists in `.ai/plans/seo-strategy-[project-name]/`:
- If yes: call `/plan:resume` with that plan file
- If no: jump to **Step 4** (create the plan) and continue from there

## Output

- `seo-strategy.yml` — machine-readable strategy data at `.ai/seo/[project-name]/`
- `seo-strategy.md` — human-readable strategy document at `.ai/seo/[project-name]/`
- `state.yml` — execution state and recovery notes at `.ai/seo/[project-name]/`

## Recovery

If interrupted, check state.yml at `.ai/seo/[project-name]/` and resume from the last completed wave via `/seo:strategy [project-name] --resume`.

## Error Handling

| Error | Action |
|-------|--------|
| Project directory already exists (not resume) | Ask: overwrite, resume, or pick a different name |
| Interactive phase fails after 3 retry rounds | Mark phase as `failed`, save state, report what's missing |
| Plan creation fails | Report the error. User can fix and re-run with `--resume` |
| Plan execution fails | Plan executor handles retries. After 3 rounds, escalate to user |
| QA rejects final output | Fix-and-retry loop runs. After 3 rounds, present issues for manual review |
| Session interrupted mid-interview | State saved after each phase. Resume with `--resume` |
| Session interrupted mid-plan | Plan state saved after each wave. Resume with `--resume` calls `/plan:resume` |
| Brand not found | List available brands and ask user to select one |
