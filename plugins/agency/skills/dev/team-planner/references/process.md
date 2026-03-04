# Team Planner — Detailed Process

## Overview

The team planner transforms a feature decomposition into an executable wave plan.
The PM creates work packages, dispatches Frontend and Backend Tech Leads to assign
specialists and model tiers, verifies file ownership to prevent parallel conflicts,
and assembles the final wave plan with user confirmation.

Design module awareness: components whose designer_specs entry has source=existing_spec
already have full visual specs from the design module — no design task is created for
them. The spec_ref path is passed to the Frontend TL as reference context instead.

## Prerequisites

Before starting, verify:
1. `.ai/projects/[name]/dev/feature-decomposition.yml` exists with a populated `decomposition` section
2. `decomposition.components` has at least 1 component (feature-decomposer must have run)
3. `.ai/projects/[name]/dev/dev-config.yml` exists with project structure
4. If decomposition is missing, report error and suggest running feature-decomposer first

## Step 1: Load Decomposition and Create Work Packages

```
Read feature-decomposition.yml → decomposition.components and decomposition.designer_specs
Read dev-config.yml → structure (src_root, key_directories)
Check .ai/projects/[name]/design/tokens/ for available token files (tailwind.config.json,
  variables.css, tokens.dtcg.json) — note paths for Frontend TL dispatch

For each component:
  if len(files_affected) <= 5:
    Create 1 task covering the entire component
  else:
    Split into multiple tasks:
      - Group files by directory/concern
      - Each task owns ≤ 5 files
      - Tasks within the same component share a dependency chain

Work Package format:
  - id: "T[N]" (sequential)
  - description: "[action verb] [what] for [component]"
  - component: "[component.name]"
  - type: "[component.type]" (frontend/backend/shared/infrastructure)
  - files_to_own: [subset of files_affected]
  - depends_on: [] (populated later by TLs)
  - design_task_needed: true | false
    (false when designer_specs[component].source == "existing_spec")
```

**Design task skip rule:** Before creating a design task for a frontend component,
check `decomposition.designer_specs` for a matching entry. If `source == "existing_spec"`,
set `design_task_needed: false` and record `spec_ref` for the Frontend TL.

**Save work packages to findings.md (2-Action Rule checkpoint).**

## Step 2: Dispatch Frontend Tech Lead

Skip if no components have `type: frontend`.

Dispatch the Frontend TL agent (subagent) with:

**Frontend TL prompt context:**
- Work packages where type is "frontend"
- dev-config.yml frameworks section (component library, icon library)
- Designer specs from decomposition (if present) — include source and spec_ref fields
- Design token paths (if tokens exist in .ai/projects/[name]/design/tokens/):
  - tailwind.config.json — Tailwind theme tokens
  - variables.css — CSS custom properties
  - tokens.dtcg.json — DTCG-format token definitions
- For each component with source=existing_spec: pass spec_ref as implementation reference
  and mark design_task_needed=false

**Frontend TL produces for each task:**
```yaml
frontend_assignments:
  - task_id: "T[N]"
    assigned_agent: "frontend-worker | designer | e2e-test-expert"
    risk_assessment: "low | medium | high"
    risk_reasoning: "1-2 sentences"
    model_tier: "junior | senior | principal"
    tier_reasoning: "Why this tier — based on tier-assigner logic"
    files_owned:
      - "path/to/file"
    design_token_refs:
      - "path/to/token/file"  # only if task uses design tokens
    notes: "Implementation approach or gotchas"
```

**Frontend TL assignment rules:**
- **Designer:** Tasks requiring new UI components, layout work, styling decisions
  (skip for components where design_task_needed=false — spec already exists)
- **E2E Test Expert:** Tasks focused on test coverage for user flows
- **Frontend Worker:** All other frontend implementation tasks (including those
  implementing from an existing_spec — the spec is done, coding remains)

**Tier assignment (follows tier-assigner logic):**
- Junior: 1 file, clear requirements, isolated change
- Senior: 2-5 files, some design choices, feature-scoped
- Principal: 6+ files, unclear scope, architectural change
- Designer minimum floor: senior (never junior)

**Save Frontend TL assignments to findings.md (2-Action Rule checkpoint).**

## Step 3: Dispatch Backend Tech Lead

Skip if no components have `type: backend`.

Dispatch the Backend TL agent (subagent) with:

**Backend TL prompt context:**
- Work packages where type is "backend" or "shared" or "infrastructure"
- dev-config.yml frameworks section (database, runtime)
- Architecture knowledge (module boundaries, data flow)

**Backend TL produces for each task:**
```yaml
backend_assignments:
  - task_id: "T[N]"
    assigned_agent: "backend-worker | devops | security-expert"
    risk_assessment: "low | medium | high"
    risk_reasoning: "1-2 sentences"
    model_tier: "junior | senior | principal"
    tier_reasoning: "Why this tier"
    files_owned:
      - "path/to/file"
    notes: "Implementation approach or gotchas"
```

**Backend TL assignment rules:**
- **DevOps:** Tasks involving CI/CD, deployment, infrastructure config
- **Security Expert:** Tasks touching auth, input validation, secrets, encryption
- **Backend Worker:** All other backend implementation tasks

**Tier assignment:** Same logic as Frontend TL. Security Expert minimum floor: senior.

## Step 4: Present TL Assignments to User

```
"Tech Lead assignments for [N] tasks:

Frontend ([count] tasks):
| Task | Agent | Tier | Risk | Files | Design Tokens |
|------|-------|------|------|-------|---------------|
| T1   | frontend-worker | senior | medium | 3 files | tailwind.config.json |

[If any tasks skipped design work:]
Note: [N] component(s) use existing design module specs — no Designer task needed:
  - [component name] → spec_ref: [path]

Backend ([count] tasks):
| Task | Agent | Tier | Risk | Files |
|------|-------|------|------|-------|
| T3   | backend-worker | junior | low | 1 file |

Tier distribution: [N] junior, [N] senior, [N] principal
Estimated cost efficiency: [% at junior/senior vs all-Opus baseline]

Does this assignment look right? [Y/adjust]"
```

**If user adjusts:** Incorporate feedback, update assignments.
**If user confirms:** Proceed to Step 5.

**Save to findings.md (2-Action Rule checkpoint).**

## Step 5: Check File Ownership

Run file overlap detection:

```
For each pair of tasks:
  overlap = intersection(task_a.files_owned, task_b.files_owned)
  if overlap is not empty:
    record conflict:
      - task_a: [id]
      - task_b: [id]
      - files: [overlapping files]
      - resolution_options:
        a) Resequence: put tasks in different waves
        b) Merge: combine tasks into one
        c) Split: assign different sections of the file to each task
```

Check for file ownership conflicts by comparing `files_affected` across all tasks in the same wave. No two parallel tasks may write to the same file.

**If no overlaps:** Proceed to Step 6.

**If overlaps detected:**

```
"File ownership conflicts detected:

1. T2 and T5 both touch src/components/Header.tsx
   Options:
   a) Put T5 in a later wave (after T2 completes)
   b) Merge T2 and T5 into one task
   c) Split: T2 owns the component, T5 owns the tests

Which resolution? [a/b/c]"
```

Resolve each conflict with user input. Re-check after resolution.

**Save overlap check results to findings.md (2-Action Rule checkpoint).**

## Step 6: Assemble Wave Plan

Group tasks into waves:

```
Algorithm:
1. Start with wave 1
2. For each unassigned task:
   a. Check depends_on — all dependencies must be in earlier waves
   b. Check file_owned — no overlap with other tasks in the current wave
   c. If both pass: add to current wave
3. Mark wave as parallel if it has 2+ tasks with no file overlap
4. Move to next wave for remaining tasks
5. Repeat until all tasks are assigned

Ordering preferences:
- Interactive tasks come first (user input needed early)
- Infrastructure/shared tasks before dependent frontend/backend
- Test tasks after their implementation tasks
- Components with existing_spec (design_task_needed=false) can run earlier
  in parallel — their design phase is already done
```

Build the wave plan structure:

```yaml
wave_plan:
  waves:
    - wave: 1
      parallel: false
      tasks:
        - id: "T1"
          description: "..."
          assigned_agent: "backend-worker"
          model_tier: "senior"
          component: "..."
          files_owned: [...]
          depends_on: []
          status: "pending"
    - wave: 2
      parallel: true
      tasks:
        - id: "T2"
          ...
        - id: "T3"
          ...
  file_ownership:
    - file: "src/components/Header.tsx"
      owner_task: "T2"
      wave: 2
  frontend_tl_approved: true
  backend_tl_approved: true
```

## Step 7: Present Wave Plan to User

```
"## Wave Plan — [N] waves, [M] tasks

### Wave 1 (sequential)
| Task | Component | Agent | Tier | Files |
|------|-----------|-------|------|-------|
| T1   | auth-api  | backend-worker | senior | 3 |

### Wave 2 (parallel — 2 tasks simultaneously)
| Task | Component | Agent | Tier | Files |
|------|-----------|-------|------|-------|
| T2   | header-ui | frontend-worker | senior | 2 |
| T3   | user-api  | backend-worker | junior | 1 |

[Repeat for each wave]

### Summary
- Total waves: [N]
- Parallel waves: [count] (potential time savings)
- Tier distribution: [junior]J / [senior]S / [principal]P
- File conflicts resolved: [count]
- Design module reuse: [N] component(s) skipped design tasks (specs pre-existing)

Does this wave plan look right? [Y/adjust]"
```

**If user adjusts:** Incorporate feedback, re-check file ownership, re-present.
**If user confirms:** Proceed to Step 8.

## Step 8: Write Wave Plan to wave-plan.yml

Write the `wave_plan` section of `.ai/projects/[name]/dev/wave-plan.yml`:

```yaml
wave_plan:
  waves:
    - wave: [number]
      parallel: [true/false]
      tasks:
        - id: "[from work packages]"
          description: "[from work packages]"
          assigned_agent: "[from TL assignment]"
          model_tier: "[from TL assignment]"
          component: "[from decomposition]"
          files_owned: ["[from TL assignment]"]
          depends_on: ["[task IDs]"]
          status: "pending"
  file_ownership:
    - file: "[path]"
      owner_task: "[task ID]"
      wave: [number]
  frontend_tl_approved: true
  backend_tl_approved: true
```

Also update:
- `build.status` → "planning" (during) → "executing" (after)
- `build.current_phase` → 2 (during) → 3 (after pass)
- `meta.updated_at` → current timestamp

## Step 9: Present Final Summary

```
## Team Planning Complete

**Feature:** [description]
**Waves:** [N] ([parallel count] parallel, [sequential count] sequential)
**Tasks:** [M] ([junior count] junior, [senior count] senior, [principal count] principal)

### Wave Overview
1. Wave 1 ([mode]): [task count] tasks — [brief description]
2. Wave 2 ([mode]): [task count] tasks — [brief description]
[Repeat]

### File Ownership
- [count] files tracked across [count] tasks
- Conflicts resolved: [count]

### Design Module Reuse
- [N] component(s) used existing design module specs — Designer tasks skipped
- [N] component(s) required new visual specs — Designer tasks included

### Cost Estimate
- Junior tasks: [count] × Haiku ≈ low cost
- Senior tasks: [count] × Sonnet ≈ medium cost
- Principal tasks: [count] × Opus ≈ higher cost
- Savings vs all-Opus: ~[estimate]%

Ready for Phase 3 (execution). Run /agency:dev:build to continue.
```

**Save final state to findings.md (2-Action Rule checkpoint).**

## Error Handling

When errors occur during team planning:

1. **TL dispatch failures:** Log to state.yml errors array with the TL name
   and error. Retry once with simplified task list. If retry fails, present
   partial assignments to the user and ask for manual assignment.

2. **Unresolvable file conflicts:** After 2 resolution attempts, ask the user
   to manually decide task boundaries. Log the conflict and resolution.

3. **User rejects plan twice:** Ask the user to describe their preferred wave
   structure. Do not loop indefinitely.

4. **Design module spec not found:** If a component has source=existing_spec
   but spec_ref points to a missing file, flag it to the user. Either locate
   the correct path or treat the component as source=new and dispatch Designer.

5. **Before retrying:** Always check state.yml errors array for previous failed
   attempts. Never repeat the same approach.

## Commit Protocol

**Subagent mode** (dispatched via Task()):
1. Stage only wave-plan.yml and findings.md updates
2. Commit: `[plan_name]: team-planner [task_id]`
3. Report commit SHA in task_complete

**Inline mode:** Commit after verification passes with descriptive message.

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- wave-plan.yml wave_plan section exists and is non-empty
- wave_plan.waves has at least 1 wave
- Every task has non-empty: id, description, assigned_agent, model_tier, component, files_owned
- No two tasks in the same wave have overlapping files_owned
- Every component from decomposition.components is referenced by at least 1 task
- frontend_tl_approved and backend_tl_approved are present

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Tier assignments are appropriate (not all principal, not all junior)
- Parallelism is utilized where possible (independent tasks in same wave)
- File ownership is complete (no orphaned files from decomposition)
- Wave sequencing respects dependencies
- Task descriptions are actionable (not vague or generic)
- Components with source=existing_spec correctly have no Designer task assigned
- Design token refs are populated for frontend tasks where tokens are available

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.
