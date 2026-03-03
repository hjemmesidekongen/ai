# Feature Decomposer — Detailed Process

## Overview

The feature decomposer is Phase 1 of /agency:dev:build. It transforms a user's feature
request into a structured decomposition that Phase 2 (team-planner) can turn into
an executable wave plan. Three agent perspectives — Architect, Designer, PO —
each contribute analysis, with user checkpoints between each stage.

## Prerequisites

Before starting, verify:
1. `.ai/projects/[name]/dev/dev-config.yml` exists with confirmed config
2. If dev-config.yml is missing, report error and suggest running `/agency:dev:init` first
3. `.ai/projects/[name]/dev/team-state.yml` exists (create from schema if not)

## Step 0: Check for Existing Design Module Outputs

Before receiving the feature description, PM scans for reusable design artifacts:

```
1. Check .ai/projects/[name]/design/component-specs/ for existing component YAML files
2. Check .ai/projects/[name]/design/web-layout.yml for page layout definitions
3. If found: note which components are already specced — these can be referenced
   or reused directly instead of regenerating in Step 4
4. Log findings: "Found [N] existing component specs: [names]"
```

This prevents duplication between the design module and dev decomposition.
**Save component inventory to findings.md before proceeding.**

## Step 1: Receive and Clarify Feature Description

```
Input: user's feature description (from /agency:dev:build argument)

1. PM reads the feature description
2. PM reads dev-config.yml — extract structure, frameworks, conventions
3. PM reads knowledge/*.yml — filter by tags relevant to the feature area
4. PM presents initial understanding to user, noting any design module overlaps:

   "Here's what I understand you want to build: [summary].
    [If design artifacts found:] I also found existing specs for [components]
    that may be relevant — I'll reference these in the visual spec step.
    Does this capture your intent? [Y/n]"

5. If user corrects: update understanding, re-present
6. If user confirms: proceed to Step 2
```

**One question at a time.** If the description is vague, offer examples of
clarifying questions rather than asking multiple questions at once.

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 2: Dispatch Architect Agent

Dispatch the Software Architect agent (subagent) with this context:

**Architect prompt context:**
- Feature description (refined after user confirmation)
- `dev-config.yml` structure section (src_root, key_directories, entry_points)
- `knowledge/architecture.md` (module boundaries, data flow)
- `knowledge/patterns.yml` (design patterns in use)

**Architect produces:**
```yaml
components:
  - name: "[component name]"
    description: "What this component does"
    boundaries: "What this component owns (and what it doesn't)"
    type: "frontend | backend | shared | infrastructure"
    files_affected:
      - "path/to/new-or-modified-file"
    new_modules: true | false
    contracts:
      - type: "api_endpoint | interface | event | shared_type"
        description: "Contract between this and another component"
        connects_to: "[other component name]"
```

**Architect must consider:**
- Which existing modules are affected? (from architecture.md)
- What new modules need to be created?
- What are the boundaries between components? (each component should own
  a clear, non-overlapping responsibility)
- What contracts (interfaces, API endpoints, events) need to be defined?

## Step 3: Present Architect's Breakdown to User

```
"The Architect proposes [N] components:

1. [name] ([type]) — [description]
   Files: [file list]

2. [name] ([type]) — [description]
   Files: [file list]

[New contracts needed:]
- [component A] ↔ [component B]: [contract description]

Does this decomposition make sense? [Y/n/adjust]"
```

**If user adjusts:** Incorporate feedback, optionally re-dispatch Architect.
**If user confirms:** Proceed to Step 4.

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 4: Dispatch Designer Agent (If UI Components Exist)

Skip this step if no components have `type: frontend`.

Dispatch the Design/UX agent with:

**Designer prompt context:**
- Component list (frontend components only)
- Existing component-specs from design module (if found in Step 0):
  - `.ai/projects/[name]/design/component-specs/*.yml` — pre-existing visual specs
  - `.ai/projects/[name]/design/web-layout.yml` — overall page structure and zones
- Brand data (if available via brand-context-loader): colors, typography,
  visual identity, logo specs
- `knowledge/conventions.yml` — existing frontend conventions
- `dev-config.yml` — component library, icon library

**Instruction to Designer:** If an existing component-spec already covers a
frontend component fully, reference it rather than regenerating. Only produce new
specs where existing specs don't yet cover the component or need extending.

**Designer produces:**
```yaml
designer_specs:
  - component: "[references components[].name]"
    source: "existing_spec | new"   # new field: was this ported from design module?
    spec_ref: ".ai/projects/[name]/design/component-specs/[file].yml"  # if existing_spec
    visual_spec: "Layout, spacing, color usage, typography choices"
    wireframe_notes: "Rough layout description or ASCII wireframe"
    responsive_behavior: "How it adapts across breakpoints"
    interaction_patterns: "Hover states, transitions, loading states"
    accessibility_notes: "ARIA roles, keyboard navigation, contrast requirements"
```

**Designer must consider:**
- Consistency with existing UI patterns (from conventions.yml)
- Reuse of existing component-specs from the design module (avoid duplication)
- Web-layout zone constraints when placing components on pages
- Brand alignment (if brand data is loaded)
- Responsive behavior across breakpoints
- Accessibility requirements (WCAG compliance)

## Step 5: Present Designer's Specs to User

```
"The Designer has produced visual specs for [N] frontend components:

### [component name]
[If existing_spec:] ↳ Ported from design module: [spec_ref]
- Layout: [description]
- Colors: [usage]
- Responsive: [behavior]
- Interactions: [patterns]
- Accessibility: [notes]

[Repeat for each frontend component]

Do these visual specs look right? [Y/n/adjust]"
```

**If user adjusts:** Incorporate feedback, optionally re-dispatch Designer.
**If user confirms:** Proceed to Step 6.

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 6: Dispatch PO Agent

Dispatch the PO validation agent with:

**PO prompt context:**
- Original feature description (from user)
- Final component list (from Architect)
- Designer specs (if applicable)

**PO validates:**
```yaml
po_validation:
  status: "approved | revised | rejected"
  notes: "Feedback notes"
  completeness_check:
    - "[goal aspect]": "covered by [component] | missing"
  scope_assessment: "appropriate | too_large | too_small"
  missing_components: []  # Components PO thinks are needed but not proposed
  concerns: []  # Risks or issues PO identifies
```

**PO must assess:**
- Does the decomposition achieve the user's stated goal?
- Are there missing components that would be needed for the feature to work?
- Is the scope appropriate? (not so large it's undeliverable, not so small
  it doesn't achieve the goal)

## Step 7: Present PO Assessment to User

```
"PO assessment: [approved/revised/rejected]

Completeness: [assessment]
Scope: [appropriate/too_large/too_small]
[If concerns:] Concerns: [list]
[If missing:] Missing components: [list]

Proceed with this decomposition? [Y/n]"
```

**If rejected:** Go back to Step 2 with PO's feedback incorporated.
**If revised:** Incorporate revisions, present updated decomposition.
**If approved and user confirms:** Proceed to Step 8.

## Step 8: Write Decomposition to team-state.yml

Write the `decomposition` section of `.ai/projects/[name]/dev/team-state.yml`:

```yaml
decomposition:
  components:
    - name: "[from Architect]"
      description: "[from Architect]"
      boundaries: "[from Architect]"
      type: "[frontend/backend/shared/infrastructure]"
      files_affected:
        - "[path]"
  designer_specs:
    - component: "[name]"
      source: "[existing_spec | new]"
      spec_ref: "[path if existing_spec, else null]"
      visual_spec: "[from Designer]"
      wireframe_notes: "[from Designer]"
  po_validation:
    status: "[approved/revised/rejected]"
    notes: "[from PO]"
```

Also update:
- `build.status` → "decomposing" (during) → "planning" (after)
- `build.current_phase` → 1 (during) → 2 (after pass)
- `meta.updated_at` → current timestamp

## Step 9: Present Final Summary

```
## Decomposition Complete

**Feature:** [description]
**Components:** [N] ([frontend count] frontend, [backend count] backend,
  [shared count] shared, [infra count] infrastructure)
**PO Status:** [approved/revised]

### Components
1. [name] ([type]) — [one-line description]
   Files: [count] files affected
[Repeat]

### Contracts
- [component] ↔ [component]: [contract]
[Repeat]

[If UI:] ### Visual Specs
- [component]: [one-line visual summary] [↳ from design module if reused]
[Repeat]

Ready for Phase 2 (team planning). Run /agency:dev:build to continue.
```

**Save final state to findings.md (2-Action Rule checkpoint).**

## Error Handling

When errors occur during decomposition:

1. **Agent dispatch failures:** Log to state.yml errors array with the agent
   name and error. Retry once with simplified prompt. If retry fails, present
   the partial result to the user and ask for guidance.

2. **User rejects all proposals:** After 2 rejections of the same stage, ask
   the user to describe what they want in more detail. Do not loop indefinitely.

3. **Scope conflicts between Architect and PO:** PM resolves by: (a) presenting
   both perspectives to the user, (b) asking the user to choose, (c) recording
   the decision in findings.md.

4. **Design module conflict:** If an existing component-spec contradicts the
   Architect's proposal for the same component, surface both to the user and
   ask which takes precedence. Record the decision in findings.md.

5. **Before retrying:** Always check state.yml errors array for previous failed
   attempts. Never repeat the same approach.

## Commit Protocol

**Subagent mode** (dispatched via Task()):
1. Stage only team-state.yml and findings.md updates
2. Commit: `[plan_name]: feature-decomposer [task_id]`
3. Report commit SHA in task_complete

**Inline mode:** Commit after verification passes with descriptive message.

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- team-state.yml decomposition section exists and is non-empty
- Every component has name, description, boundaries, type (all non-empty)
- Every component has at least 1 files_affected entry
- po_validation.status is one of: approved, revised, rejected
- If any frontend component: designer_specs array has at least 1 entry

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Component boundaries are clear and non-overlapping
- files_affected paths are plausible for the project structure
- Designer specs (if present) are actionable, not vague; existing component-specs
  are correctly referenced (spec_ref points to a real file)
- PO validation reasoning is substantive
- Decomposition achieves the stated feature goal
- Design module reuse decisions are recorded in findings.md

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.
