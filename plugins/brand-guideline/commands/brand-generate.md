---
name: brand-generate
command: "/brand:generate"
description: "Generate a complete brand guideline through guided interview and automated asset creation"
arguments:
  - name: brand_name
    type: string
    required: false
    description: "Brand name. If omitted, the identity interview will ask for it."
  - name: resume
    type: boolean
    required: false
    default: false
    description: "Resume a previously interrupted brand generation."
  - name: brand
    type: string
    required: false
    description: "Brand slug to resume. If omitted with --resume, resumes the most recently active brand."
---

# /brand:generate

The main entry point for creating a brand guideline from scratch. Orchestrates a 9-phase pipeline that combines interactive interviews (phases 1-3) with automated generation (phases 4-9).

## Usage

```
/brand:generate                              # start a new brand
/brand:generate "Acme Corp"                  # start with a brand name
/brand:generate --resume                     # resume most recent brand
/brand:generate --resume --brand acme-corp   # resume specific brand
```

## Architecture

This command bridges two plugins:

- **brand-guideline** provides the 9 domain skills and brand-specific logic
- **task-planner** provides wave decomposition, file ownership, verification, and QA

The command splits execution into two stages:

```
Stage 1: Interactive (phases 1-3)       Stage 2: Automated (phases 4-9)
┌─────────────────────────┐             ┌─────────────────────────┐
│ identity-interview      │             │ /plan:create            │
│ audience-personas       │  ────────►  │ /plan:execute           │
│ tone-of-voice           │             │   with verification     │
│                         │             │   and QA gates           │
│ (requires user input)   │             │ (runs autonomously)     │
└─────────────────────────┘             └─────────────────────────┘
```

Phases 1-3 **cannot** be parallelized — they are interviews that require user input and each builds on the previous. Phases 4-9 **can** be parallelized where dependencies allow.

## Execution Steps

### Step 0: Check for Resume

Before starting anything, check if this is a resume:

**If `--resume` flag is set:**

1. Scan `.ai/brands/` for `state.yml` files with `command: "brand:generate"` and `status != "completed"`
2. If `--brand` is specified, look only in `.ai/brands/[brand]/state.yml`
3. If found: jump to **Step 7: Resume** (below)
4. If not found:
   ```
   No active brand generation found.
   Start a new one with `/brand:generate` or specify a brand with `--brand`.
   ```

**If no resume flag:** Check anyway for an active generation:

1. Scan `.ai/brands/*/state.yml` for `command: "brand:generate"` with `status: "in_progress"`
2. If found, ask the user:
   ```
   Found an in-progress brand generation for "[brand_name]" (phase [N] of 9).

   1. Resume it
   2. Start a new brand (the in-progress one will be paused)
   ```

### Step 1: Initialize Brand Directory

Create the brand directory structure:

```
.ai/brands/[brand-slug]/
├── brand-reference.yml     # written incrementally by each skill
├── state.yml               # execution state (created now)
├── assets/
│   ├── logo/svg/
│   ├── icons/
│   ├── favicons/
│   ├── app-icons/
│   └── social/
├── preview/
└── scripts/
```

**Brand slug:** Derive from the brand name (lowercase, kebab-case, alphanumeric + hyphens only). If no brand name provided yet, use a temporary slug like `new-brand-[timestamp]` and rename after the identity interview captures the name.

**Initialize state.yml:**

```yaml
command: "brand:generate"
brand: "[brand-slug]"
started_at: "[now]"
updated_at: "[now]"
current_phase: "identity-interview"
current_phase_number: 1
total_phases: 9
phases:
  - name: "identity-interview"
    number: 1
    status: "pending"
    checkpoint:
      type: "data_validation"
      passed: null
    artifacts: []
  - name: "audience-personas"
    number: 2
    status: "pending"
    checkpoint:
      type: "data_validation"
      passed: null
    artifacts: []
  - name: "tone-of-voice"
    number: 3
    status: "pending"
    checkpoint:
      type: "data_validation"
      passed: null
    artifacts: []
  - name: "typography-color"
    number: 4
    status: "pending"
    checkpoint:
      type: "accessibility_validation"
      passed: null
    artifacts: []
  - name: "visual-identity"
    number: 5
    status: "pending"
    checkpoint:
      type: "data_validation"
      passed: null
    artifacts: []
  - name: "logo-design"
    number: 6
    status: "pending"
    checkpoint:
      type: "file_validation"
      passed: null
    artifacts: []
  - name: "content-rules"
    number: 7
    status: "pending"
    checkpoint:
      type: "data_validation"
      passed: null
    artifacts: []
  - name: "social-media"
    number: 8
    status: "pending"
    checkpoint:
      type: "data_validation"
      passed: null
    artifacts: []
  - name: "compile-and-export"
    number: 9
    status: "pending"
    checkpoint:
      type: "schema_validation"
      passed: null
    artifacts: []
last_session_id: null
recovery_notes: null
```

**Initialize brand-reference.yml:**

```yaml
# Brand Reference — [brand name or "New Brand"]
# Auto-generated by /brand:generate
# Other plugins consume this file — do not restructure.
# Last updated: [today]
```

Report to user:

```
## Brand Guideline Generator

I'll walk you through building a complete brand guideline in 9 phases:

  1. Brand identity — name, mission, values, positioning
  2. Audience & personas — who you serve
  3. Tone of voice — how you sound
  4. Colors & typography — your visual palette
  5. Visual identity — imagery, layout, patterns
  6. Logo design — logo concepts and variants
  7. Content rules — writing guidelines
  8. Social media — platform strategy
  9. Compile & export — brand manual + assets

Phases 1-3 are interactive — I'll ask questions to understand your brand.
Phases 4-9 run automatically based on your answers.

Let's start with your brand identity.
```

### Step 2: Run Phase 1 — Identity Interview

Execute the `identity-interview` skill:

1. Update state: `phases[0].status → "in_progress"`, `phases[0].started_at → now`
2. Run the skill (follows its own interview flow from SKILL.md)
3. The skill writes `meta` and `identity` sections to `brand-reference.yml`
4. The skill runs its own checkpoint (data_validation)
5. On checkpoint pass:
   - Update state: `phases[0].status → "completed"`, `phases[0].completed_at → now`, `phases[0].checkpoint.passed → true`
   - Update state: `current_phase → "audience-personas"`, `current_phase_number → 2`
   - Record artifacts: `["brand-reference.yml#meta", "brand-reference.yml#identity"]`
   - Write recovery notes
6. On checkpoint fail: the skill handles retries internally (max 3 rounds). If it still fails after 3 rounds, mark phase as `failed` and stop.

**Brand slug update:** If the brand directory was created with a temporary slug, rename it now using `meta.brand_name` from brand-reference.yml.

### Step 3: Run Phase 2 — Audience & Personas

Execute the `audience-personas` skill:

1. Update state: `phases[1].status → "in_progress"`, `phases[1].started_at → now`
2. Run the skill (reads identity data, runs its own interview)
3. The skill writes the `audience` section to `brand-reference.yml` and creates `persona-card-*.md` files
4. The skill runs its own checkpoint (data_validation)
5. On checkpoint pass:
   - Update state: `phases[1].status → "completed"`, `current_phase → "tone-of-voice"`, `current_phase_number → 3`
   - Record artifacts: `["brand-reference.yml#audience", "persona-card-1.md", "persona-card-2.md", ...]`
   - Write recovery notes
6. On checkpoint fail: skill handles retries. If still fails, mark as `failed` and stop.

### Step 4: Run Phase 3 — Tone of Voice

Execute the `tone-of-voice` skill:

1. Update state: `phases[2].status → "in_progress"`, `phases[2].started_at → now`
2. Run the skill (reads identity + audience, runs its own interview)
3. The skill writes the `voice` section to `brand-reference.yml`
4. The skill runs its own checkpoint (data_validation)
5. On checkpoint pass:
   - Update state: `phases[2].status → "completed"`, `current_phase → "typography-color"`, `current_phase_number → 4`
   - Record artifacts: `["brand-reference.yml#voice"]`
   - Write recovery notes
6. On checkpoint fail: skill handles retries. If still fails, mark as `failed` and stop.

**Transition message:**

```
## Interactive phases complete!

I've captured your brand's identity, audience, and voice. Here's a quick summary:

Brand: [name] — [tagline]
Mission: [first 60 chars]...
Primary persona: [name] — [role]
Voice personality: [personality in 3 words]

Now I'll generate the remaining phases automatically:
  4. Colors & typography
  5. Visual identity
  6. Logo design
  7. Content rules
  8. Social media
  9. Compile & export

This uses the task planner to parallelize where possible.
```

### Step 5: Create Task Plan for Phases 4-9

Call `/plan:create` with the remaining phases structured as tasks:

```yaml
tasks:
  - id: "typography-color"
    name: "Generate color palette and typography system"
    depends_on: []
    files_written:
      - "brand-reference.yml#colors"
      - "brand-reference.yml#typography"
    files_read:
      - "brand-reference.yml#meta"
      - "brand-reference.yml#identity"
      - "brand-reference.yml#voice"
    estimated_minutes: 10
    skill: "typography-color"
    checkpoint: "accessibility_validation"

  - id: "visual-identity"
    name: "Generate visual identity system"
    depends_on: ["typography-color"]
    files_written:
      - "brand-reference.yml#visual"
    files_read:
      - "brand-reference.yml#identity"
      - "brand-reference.yml#voice"
      - "brand-reference.yml#colors"
      - "brand-reference.yml#typography"
    estimated_minutes: 10
    skill: "visual-identity"
    checkpoint: "data_validation"

  - id: "logo-design"
    name: "Generate logo concepts and SVG variants"
    depends_on: ["typography-color", "visual-identity"]
    files_written:
      - "brand-reference.yml#visual.logo"
      - "assets/logo/svg/*"
    files_read:
      - "brand-reference.yml#identity"
      - "brand-reference.yml#colors"
      - "brand-reference.yml#typography"
      - "brand-reference.yml#visual"
    estimated_minutes: 15
    skill: "logo-design"
    checkpoint: "file_validation"

  - id: "content-rules"
    name: "Generate content and writing rules"
    depends_on: ["typography-color"]
    files_written:
      - "brand-reference.yml#content"
    files_read:
      - "brand-reference.yml#identity"
      - "brand-reference.yml#voice"
      - "brand-reference.yml#audience"
    estimated_minutes: 8
    skill: "content-rules"
    checkpoint: "data_validation"

  - id: "social-media"
    name: "Generate social media guidelines"
    depends_on: ["content-rules", "logo-design"]
    files_written:
      - "brand-reference.yml#social"
    files_read:
      - "brand-reference.yml#identity"
      - "brand-reference.yml#voice"
      - "brand-reference.yml#audience"
      - "brand-reference.yml#content"
      - "brand-reference.yml#visual"
    estimated_minutes: 8
    skill: "social-media"
    checkpoint: "data_validation"

  - id: "compile-and-export"
    name: "Compile brand manual, generate assets and preview"
    depends_on: ["typography-color", "visual-identity", "logo-design", "content-rules", "social-media"]
    files_written:
      - "brand-manual.md"
      - "brand-manual.docx"
      - "scripts/generate-assets.sh"
      - "assets/favicons/site.webmanifest"
      - "assets/favicons/browserconfig.xml"
      - "html-head-snippet.html"
      - "preview/brand-preview.html"
    files_read:
      - "brand-reference.yml"
      - "state.yml"
      - "assets/**/*.svg"
    estimated_minutes: 15
    skill: "compile-and-export"
    checkpoint: "schema_validation"
    qa_review: true
```

**Plan configuration:**

```
/plan:create --name "brand-generate-[brand-slug]" --profile brand
```

The wave decomposer will produce waves like:

```
Wave 1: typography-color (independent)
Wave 2: visual-identity, content-rules (both depend on typography-color, no file overlap)
Wave 3: logo-design (depends on visual-identity)
Wave 4: social-media (depends on content-rules + logo-design)
Wave 5: compile-and-export (depends on everything, QA mandatory)
```

The exact wave structure depends on the decomposer's analysis. The key constraints are:
- `typography-color` must run first (colors feed into everything)
- `logo-design` needs both colors and visual identity
- `compile-and-export` is always last and has mandatory QA

Save the plan to `.ai/plans/brand-generate-[brand-slug]/`.

### Step 6: Execute the Plan

Call `/plan:execute` with the generated plan:

```
/plan:execute .ai/plans/brand-generate-[brand-slug]/plan.yml
```

The plan executor handles:
- Wave-by-wave execution with verification gates
- Fix-and-retry loops for failed checks (max 3 rounds per wave)
- QA review on the final wave (compile-and-export)
- State updates and recovery notes after each wave
- File ownership enforcement

**State sync:** After each wave completes, update the brand's `state.yml` to reflect which phases completed:

```
for each completed task in the wave:
  find the matching phase in state.yml
  update: status → "completed", completed_at → now, checkpoint.passed → true
  update: current_phase → next uncompleted phase name
  update: current_phase_number → next uncompleted phase number
```

This keeps `state.yml` (brand-specific state) and the plan's state file (task-planner state) in sync.

### Step 7: Resume (When Resuming an Interrupted Generation)

When resuming a previously interrupted brand generation:

1. Read `.ai/brands/[brand]/state.yml`
2. Read `.ai/brands/[brand]/brand-reference.yml`
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
## Resuming brand generation: [brand_name]

**Progress:** [N] of 9 phases completed
**Last active:** [time ago]

### Completed
  Phase 1 ✓ Identity interview
  Phase 2 ✓ Audience & personas
  Phase 3 ✓ Tone of voice

### Resuming from
  Phase 4 ● Typography & colors (was in progress)

### Remaining
  Phase 5 ○ Visual identity
  Phase 6 ○ Logo design
  Phase 7 ○ Content rules
  Phase 8 ○ Social media
  Phase 9 ○ Compile & export
```

5. Resume based on where we stopped:

**If stopped during an interactive phase (1-3):**

Re-read brand-reference.yml to see what data exists. The skill's checkpoint will tell us what's missing. Re-run the skill — it should detect existing data and skip questions that are already answered.

**If stopped during an automated phase (4-9):**

Check if a plan file exists in `.ai/plans/brand-generate-[brand]/`:
- If yes: call `/plan:resume` with that plan file
- If no: jump to **Step 5** (create the plan) and continue from there

The plan resume handles all the complexity of partial wave completion, output verification, and re-execution.

### Step 8: Completion Report

After all 9 phases complete and the final QA passes:

1. Update state:
   ```yaml
   current_phase: "compile-and-export"
   current_phase_number: 9
   updated_at: "[now]"
   # All phases should now show status: "completed"
   ```

2. Report to user:

```
## Brand Guideline Complete: [Brand Name]

All 9 phases completed. QA approved.

### What was generated

**Documents:**
  brand-reference.yml — machine-readable brand data (for plugins)
  brand-manual.md — human-readable brand manual
  brand-manual.docx — formatted Word document (if pandoc available)

**Assets:**
  assets/logo/svg/ — logo variants (full, mark, wordmark × color/mono/reversed)
  assets/favicons/ — favicon stack (SVG, ICO, PNG sizes, apple-touch-icon)
  assets/app-icons/ — iOS and Android app icons
  assets/social/ — social media templates and profile images
  assets/icons/ — brand icon library

**Web integration:**
  assets/favicons/site.webmanifest — PWA manifest
  assets/favicons/browserconfig.xml — Windows tile config
  html-head-snippet.html — copy-paste HTML for your site's <head>

**Preview:**
  preview/brand-preview.html — interactive brand preview (open in browser)

### Location
  .ai/brands/[brand-slug]/

### Next steps
  - Open preview/brand-preview.html in your browser to review
  - Copy html-head-snippet.html into your site's <head>
  - Run `scripts/generate-assets.sh` if PNG conversion didn't run
  - Use `/brand:audit` to check for gaps
  - Use `/brand:switch [brand]` to load this brand into other plugins
```

## Error Handling

| Error | Action |
|-------|--------|
| Brand directory already exists (not resume) | Ask: overwrite, resume, or pick a different name |
| Interactive phase fails after 3 retry rounds | Mark phase as `failed`, save state, report what's missing |
| Plan creation fails | Report the error. User can fix and re-run `/brand:generate --resume` |
| Plan execution fails | Plan executor handles retries. After 3 rounds, escalate to user |
| QA rejects final output | Fix-and-retry loop runs. After 3 rounds, present issues for manual review |
| Session interrupted mid-interview | State saved after each phase. `/brand:generate --resume` continues |
| Session interrupted mid-plan | Plan state saved after each wave. `/brand:generate --resume` calls `/plan:resume` |
| Brand slug collision | Append a numeric suffix: `acme-corp-2` |

## State File Lifecycle

The `state.yml` file is the source of truth for resume. It's updated at these points:

```
Step 1:  Created with all phases "pending"
Step 2:  Phase 1 → "in_progress" → "completed"
Step 3:  Phase 2 → "in_progress" → "completed"
Step 4:  Phase 3 → "in_progress" → "completed"
Step 5:  No state change (plan creation is internal)
Step 6:  Phases 4-9 → "in_progress" → "completed" (synced from plan state)
Step 8:  All phases "completed", recovery_notes updated
```

Recovery notes are written after each phase completes, capturing enough context for a new session to reconstruct where things stand without re-reading the full brand-reference.yml.
