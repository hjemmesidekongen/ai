---
name: plan-create
command: "/plan:create"
description: "Generate a wave-based execution plan from a description of work"
arguments:
  - name: description
    type: string
    required: true
    description: "Natural language description of the work to plan, or a structured task list"
  - name: name
    type: string
    required: false
    description: "Plan name. Auto-generated from description if omitted."
  - name: profile
    type: string
    required: false
    description: "Verification profile: brand, web, seo, content. Determines which checks run."
  - name: output
    type: string
    required: false
    default: ".ai/plans/"
    description: "Directory to save the plan file"
---

# /plan:create

Generates a wave-based execution plan from a work description. Produces a `plan.yml` file that `/plan:execute` consumes.

## Usage

```
/plan:create "Generate a complete brand guideline for Acme Corp"
/plan:create "Build the marketing site" --profile web
/plan:create --name "acme-rebrand" "Redesign logo, update colors, refresh typography"
```

Or with a structured task list:

```
/plan:create <<TASKS
- Generate color palette (writes: brand-reference.yml#colors)
- Generate typography system (writes: brand-reference.yml#typography)
- Generate logo concepts (needs: colors, typography; writes: assets/logo/svg/*)
- Compile brand manual (needs: all above; writes: brand-manual.md)
TASKS
```

## Execution Steps

### Step 1: Parse Input

Analyze the user's description and extract tasks.

**If natural language:** Decompose the description into discrete tasks. For each task, infer:
- A short `name`
- What it `depends_on` (which other tasks must complete first)
- What files it will write (`files_written`)
- What files it needs to read (`files_read`)
- An estimated duration (`estimated_minutes`)

**If structured list:** Parse the list directly. Map "needs:" to `depends_on` and "writes:" to `files_written`.

**In both cases:** Present the parsed task list to the user and ask for confirmation before proceeding. The user may add, remove, or modify tasks.

### Step 2: Generate Plan Name

If `--name` was not provided, generate one from the description:
- Lowercase, kebab-case
- Include the domain context (e.g., `brand-generate-acme-corp`, `site-build-marketing`)
- Must be unique within the output directory

### Step 3: Call Wave Decomposer

Pass the task list to the `wave-decomposer` skill:

```yaml
name: "[plan-name]"
verification_profile: "[profile]"    # from --profile flag or inferred

tasks:
  - id: "t1"
    name: "..."
    depends_on: [...]
    files_written: [...]
    files_read: [...]
    estimated_minutes: N
  # ...
```

The wave-decomposer returns the full plan with waves, verification blocks, and QA flags.

### Step 4: Call File Ownership Skill

Pass the generated plan to the `file-ownership` skill for validation:

- Check for overlapping `files_written` within parallel waves
- If conflicts found: the skill resolves them by moving tasks between waves
- Generate the `file-ownership-registry.yml`

### Step 5: Save Plan File

Write two files to the output directory:

```
.ai/plans/
└── [plan-name]/
    ├── plan.yml                        # The plan file
    └── ownership.yml                   # The file-ownership registry
```

Create the `.ai/plans/[plan-name]/` directory if it doesn't exist.

### Step 6: Initialize State

Create the initial state file:

```yaml
# .ai/plans/[plan-name]/state.yml
plan: "[plan-name]"
plan_file: ".ai/plans/[plan-name]/plan.yml"
started_at: null                    # set on first wave execution
updated_at: "[now]"
status: "created"                   # created → in_progress → completed → failed
current_wave: null                  # wave number currently executing
completed_waves: []                 # list of completed wave numbers
recovery_notes: null                # free-text context for session resumption
last_session_id: null               # session that last touched this plan
```

### Step 7: Display Summary

Show the user a clear overview of the plan:

```
## Plan: brand-generate-acme-corp

**Tasks:** 8 total across 4 waves
**Estimated time:** ~60 minutes
**Verification profile:** brand
**Execution mode:** single-agent (set CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 for parallel)

### Wave 1 (parallel — 2 tasks)
  ├─ t1: Generate color palette → brand-reference.yml#colors
  └─ t2: Generate typography system → brand-reference.yml#typography
  Verification: data_validation

### Wave 2 (parallel — 2 tasks)  [depends on wave 1]
  ├─ t3: Generate logo concepts → assets/logo/svg/*
  └─ t4: Generate icon library → assets/icons/*
  Verification: file_validation

### Wave 3 (parallel — 3 tasks)  [depends on wave 2]
  ├─ t5: Generate favicons → assets/favicons/*
  ├─ t6: Generate app icons → assets/app-icons/*
  └─ t7: Generate social images → assets/social/*
  Verification: file_validation

### Wave 4 (sequential — 1 task)  [depends on waves 1, 2, 3]
  └─ t8: Compile brand manual → brand-manual.md, brand-manual.docx
  Verification: schema_validation
  QA Review: yes

### File Ownership
  No conflicts detected. All parallel tasks write to separate paths.

Plan saved to: .ai/plans/brand-generate-acme-corp/plan.yml
Run `/plan:execute .ai/plans/brand-generate-acme-corp/plan.yml` to start.
```

## Error Handling

| Error | Action |
|-------|--------|
| No tasks could be extracted from description | Ask the user to provide more detail or a structured task list |
| Circular dependencies detected | Report the cycle and ask the user to fix the dependency graph |
| File conflicts that can't be auto-resolved | Report the conflicts and ask the user which task should move |
| Output directory not writable | Report the error and suggest an alternative path |
