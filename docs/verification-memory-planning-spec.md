# Verification, Memory & Planning Plugin Specification

## Three Critical Systems

This document covers three interconnected systems that underpin the entire plugin ecosystem:

1. **Verification & Checkpoints** — How the brand plugin (and all plugins) prove work was done correctly and don't lose track
2. **Memory & State Persistence** — How context survives across sessions, compactions, and multi-agent runs
3. **Task Planner Plugin** — A generic, reusable plugin that any other plugin calls when it needs to break work into waves, coordinate agents, and enforce QA

---

## 1. Verification & Checkpoints

### The Problem

Claude Code loses track during long tasks. Context compaction drops details. Agents report "done" when they're not. Without verification, you discover failures hours later.

### Architecture: Checkpoint-Gated State Machine

Every plugin command runs through a state machine. No phase advances until its checkpoint passes. The state is persisted to disk, so sessions can crash and resume.

```
[PHASE 1: Interview] ──checkpoint──▶ [PHASE 2: Generate] ──checkpoint──▶ [PHASE 3: Review]
       │                                     │                                    │
       ▼                                     ▼                                    ▼
   state.yml                             state.yml                            state.yml
   updated                               updated                              updated
```

### State File: `~/.claude/brands/[brand]/state.yml`

```yaml
# State file — source of truth for where we are
command: "brand:generate"
brand: "acme-corp"
started_at: "2026-02-28T14:30:00Z"
updated_at: "2026-02-28T15:12:00Z"

current_phase: "typography-color"
current_phase_number: 4
total_phases: 9

phases:
  - name: "identity-interview"
    number: 1
    status: "completed"           # pending | in_progress | completed | failed | skipped
    started_at: "2026-02-28T14:30:00Z"
    completed_at: "2026-02-28T14:42:00Z"
    checkpoint:
      type: "data_validation"
      passed: true
      details: "All required fields populated in brand-reference.yml: name, mission, values, positioning"
    artifacts:
      - "brand-reference.yml (identity section)"

  - name: "audience-personas"
    number: 2
    status: "completed"
    started_at: "2026-02-28T14:42:00Z"
    completed_at: "2026-02-28T14:55:00Z"
    checkpoint:
      type: "data_validation"
      passed: true
      details: "2 personas created with all required fields"
    artifacts:
      - "brand-reference.yml (audience section)"
      - "persona-card-1.md"
      - "persona-card-2.md"

  - name: "tone-of-voice"
    number: 3
    status: "completed"
    checkpoint:
      type: "data_validation"
      passed: true
      details: "Voice spectrum defined, do/don't examples provided, 3 writing samples generated"

  - name: "typography-color"
    number: 4
    status: "in_progress"
    started_at: "2026-02-28T15:05:00Z"
    checkpoint:
      type: "accessibility_validation"
      passed: null                # Not yet run
      checks:
        - "All color pairs computed"
        - "WCAG AA contrast ≥ 4.5:1 for body text"
        - "WCAG AA contrast ≥ 3:1 for large text"
        - "Colorblind safety notes for all colors"
        - "Dark mode variants validated"
        - "Font files accessible and licensed"

  - name: "visual-identity"
    number: 5
    status: "pending"
  - name: "logo-design"
    number: 6
    status: "pending"
  - name: "content-rules"
    number: 7
    status: "pending"
  - name: "social-media"
    number: 8
    status: "pending"
  - name: "compile-and-export"
    number: 9
    status: "pending"

# Recovery info
last_session_id: "session_abc123"
recovery_notes: |
  Phase 4 in progress. Primary palette selected (blue/slate/amber).
  Tint scales generated. Contrast matrix pending.
  Next step: compute accessible pairs and validate.
```

### Checkpoint Types

Each phase has a checkpoint type that matches the kind of work being done:

| Checkpoint Type | What It Verifies | Used By |
|----------------|-----------------|---------|
| `data_validation` | Required YAML fields are populated and non-empty | Identity, audience, voice, content rules |
| `accessibility_validation` | Contrast ratios pass WCAG AA, colorblind safety checked | Typography-color |
| `file_validation` | Expected SVG/PNG files exist and are valid | Logo design, favicons, app icons, icon library |
| `render_validation` | HTML preview renders without errors, images display | Visual identity, social media |
| `schema_validation` | brand-reference.yml passes against JSON schema | Compile & export |
| `lint_validation` | ESLint/Prettier passes on generated code | Web plugin (future) |
| `test_validation` | Test suite passes | Web plugin (future) |
| `build_validation` | Build completes without errors | Web plugin (future) |
| `manual_approval` | Human reviews and approves | Logo selection, final brand manual |

### Checkpoint Implementation

Each checkpoint is a function the skill calls before declaring "phase complete":

```yaml
# In the skill's SKILL.md, the checkpoint is defined:
checkpoint:
  type: accessibility_validation
  required_checks:
    - name: "contrast_matrix"
      verify: "All foreground/background pairs in brand-reference.yml have contrast_ratio field"
      fail_action: "Compute missing ratios before proceeding"
    - name: "wcag_aa_body"
      verify: "All body-text pairs have wcag_aa_normal: true"
      fail_action: "Suggest nearest accessible alternative color"
    - name: "wcag_aa_large"
      verify: "All large-text pairs have wcag_aa_large: true"
      fail_action: "Suggest nearest accessible alternative color"
    - name: "colorblind_notes"
      verify: "All primary colors have colorblind_notes for protanopia, deuteranopia, tritanopia"
      fail_action: "Generate missing notes"
    - name: "dark_mode"
      verify: "Dark mode section exists with validated pairs"
      fail_action: "Generate dark mode variants"
  on_fail: "Fix issues and re-run checkpoint. Do NOT advance to next phase."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
```

### Recovery Protocol

When a new session starts (or after compaction), the FIRST thing the plugin does:

1. Read `state.yml` for the active brand
2. Report current phase and what's pending
3. Read `recovery_notes` to reconstruct context
4. Resume from exactly where work stopped

This is enforced in the brand-context-loader skill:

```markdown
## Session Start Protocol (MANDATORY)

Before doing ANY work:
1. Check if `~/.claude/brands/[brand]/state.yml` exists
2. If yes: read it, report status to user, resume from current_phase
3. If no: this is a fresh brand, start from phase 1
4. NEVER skip this check. NEVER start a phase that has already been completed.
```

---

## 2. Memory & State Persistence

### The Problem

Claude Code has no memory between sessions. A brand guideline project spans multiple sessions. Without persistence, you re-explain everything each time.

### Multi-Layer Memory Strategy

We use four layers, each serving a different purpose:

```
Layer 1: state.yml          — Where we are (phase, checkpoint status)
Layer 2: brand-reference.yml — What we've decided (all brand data)
Layer 3: MEMORY.md          — What Claude learned (patterns, preferences)
Layer 4: Session memory      — Automatic background summaries
```

#### Layer 1: State File (state.yml)

Already covered above. This is the execution state — what phase, what's done, what's next. It's the "resume point."

#### Layer 2: Brand Reference (brand-reference.yml)

This is the cumulative output of all completed phases. Each phase writes its section to this file. It's both the deliverable AND the memory of decisions made.

Why this works: Every future session reads brand-reference.yml at startup. The data IS the memory. No separate "remember this" step needed.

#### Layer 3: Auto Memory (MEMORY.md)

Claude Code's built-in auto memory writes to `~/.claude/projects/[project]/memory/MEMORY.md`. This captures patterns Claude discovers — user preferences, naming conventions, style choices that aren't in the brand reference.

The plugin should prompt Claude to save to memory at key moments:

```markdown
## Memory Save Triggers

After completing each phase, save to auto memory:
- "User prefers [X] style of communication during interviews"
- "Brand uses American English spelling"
- "User wants minimal questions — prefers Claude to make decisions and present for approval"
- "User is the brand owner, not an agency working for a client"
```

#### Layer 4: Session Memory (automatic)

Claude Code's session memory runs in the background and writes summaries to `~/.claude/projects/[hash]/[session-id]/session-memory/summary.md`. This happens automatically — no plugin config needed.

The key benefit: when you `/compact`, the session summary is pre-written so compaction is instant and lossless.

### Memory for Multi-Agent Runs

When using agent teams, each teammate gets its own context window. They share NO memory. The only coordination channels are:

1. **Task files on disk** (`~/.claude/tasks/[team]/`)
2. **SendMessage** (direct messages between agents)
3. **The brand directory itself** (`~/.claude/brands/[brand]/`)

This means the brand-reference.yml and state.yml ARE the shared state. Agents read them, do their work, write their output, update state. No complex memory synchronization needed.

### MCP Memory Server (Optional Power User Setup)

For users who want semantic search across sessions, the plugin should document integration with `mcp-memory-service` or `claude-mem`:

```json
// In settings.json — optional
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "mcp-memory-service"]
    }
  }
}
```

This enables `memory_store` and `memory_search` tools that persist across sessions in SQLite with vector search. Useful but not required — layers 1-4 cover the core needs.

---

## 3. Task Planner Plugin

### Purpose

A **generic, reusable plugin** that any other plugin calls when it needs to:

- Break complex work into dependency-aware waves
- Assign tasks to parallel agents without file conflicts
- Enforce verification checkpoints between waves
- Run QA review before any wave is marked complete

This is NOT brand-specific. The SEO plugin, website builder plugin, social media plugin — they all consume the planner.

### Plugin Structure

```
task-planner/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── plan-create.md          # /plan:create — Generate a wave plan from requirements
│   ├── plan-execute.md         # /plan:execute — Run the plan (single or multi-agent)
│   ├── plan-status.md          # /plan:status — Show current state
│   └── plan-resume.md          # /plan:resume — Continue after session break
├── skills/
│   ├── wave-decomposer/
│   │   └── SKILL.md            # Breaks tasks into dependency-aware waves
│   ├── file-ownership/
│   │   └── SKILL.md            # Assigns file ownership to prevent conflicts
│   ├── verification-runner/
│   │   └── SKILL.md            # Runs the right checkpoint for each task
│   └── qa-reviewer/
│       └── SKILL.md            # Dedicated QA agent that reviews all completed work
├── agents/
│   ├── qa-agent.md             # Agent definition for the QA reviewer
│   └── worker-agent.md         # Template for domain-specific workers
├── resources/
│   ├── plan-schema.yml         # Schema for plan files
│   └── verification-registry.yml  # Maps task types to verification methods
└── scripts/
    └── check-file-conflicts.sh # Validates no two tasks claim the same file
```

### Plugin Manifest

```json
// plugin.json (Claude Code schema)
{
  "name": "task-planner",
  "version": "1.0.0",
  "description": "Generic wave-based task planning with verification and QA. Used by other plugins to plan and execute complex work.",
  "hooks": { ... }
}

// ecosystem.json (ecosystem metadata)
{
  "commands": ["plan-create", "plan-execute", "plan-status", "plan-resume"],
  "skills": ["wave-decomposer", "file-ownership", "verification-runner", "qa-reviewer"],
  "agents": ["qa-agent", "worker-agent"],
  "dependencies": []
}
```

### How Other Plugins Use the Planner

The brand plugin doesn't contain its own planning logic. Instead:

```markdown
# In brand-guideline's /brand:generate command:

## Execution Strategy

1. Run the identity interview (interactive — cannot be parallelized)
2. Once interview data is captured, call the task-planner:
   - Input: The remaining 8 phases with their dependencies
   - The planner decomposes into waves
   - The planner assigns file ownership
   - The planner executes with verification gates between waves
3. After all waves complete, the QA agent reviews the full output
```

Another example — a future website builder plugin:

```markdown
# In website-builder's /site:build command:

## Execution Strategy

1. Load brand context (brand-context-loader)
2. Gather site requirements (pages, features, CMS choice)
3. Call task-planner with:
   - Tasks: scaffold, components, pages, API routes, styling, content, tests
   - Verification type: "web" (triggers ESLint, build, test suite)
   - The planner handles everything from here
```

### Wave Decomposition

The `wave-decomposer` skill takes a list of tasks with dependencies and produces execution waves:

```yaml
# Input to wave-decomposer:
tasks:
  - id: "t1"
    name: "Generate color palette"
    depends_on: []
    files_written: ["brand-reference.yml#colors"]
    estimated_minutes: 5

  - id: "t2"
    name: "Generate typography system"
    depends_on: []
    files_written: ["brand-reference.yml#typography"]
    estimated_minutes: 5

  - id: "t3"
    name: "Generate logo concepts"
    depends_on: ["t1", "t2"]   # Needs colors and fonts first
    files_written: ["assets/logo/svg/*"]
    estimated_minutes: 15

  - id: "t4"
    name: "Generate icon library"
    depends_on: ["t1"]          # Needs colors, not fonts
    files_written: ["assets/icons/*"]
    estimated_minutes: 10

  - id: "t5"
    name: "Generate favicons"
    depends_on: ["t3"]          # Needs logo mark first
    files_written: ["assets/favicons/*"]
    estimated_minutes: 5

  - id: "t6"
    name: "Generate app icons"
    depends_on: ["t3"]          # Needs logo mark
    files_written: ["assets/app-icons/*"]
    estimated_minutes: 5

  - id: "t7"
    name: "Generate social images"
    depends_on: ["t3"]          # Needs logo
    files_written: ["assets/social/*"]
    estimated_minutes: 5

  - id: "t8"
    name: "Compile brand manual"
    depends_on: ["t1","t2","t3","t4","t5","t6","t7"]
    files_written: ["brand-manual.md", "brand-manual.docx"]
    estimated_minutes: 10
```

Output:

```yaml
# Output from wave-decomposer:
plan:
  name: "brand-generate-acme-corp"
  total_tasks: 8
  total_waves: 4
  estimated_minutes: 40

  waves:
    - wave: 1
      parallel: true
      tasks: ["t1", "t2"]
      rationale: "No dependencies — colors and typography are independent"
      verification:
        type: "data_validation"
        checks: ["brand-reference.yml colors section complete", "brand-reference.yml typography section complete"]

    - wave: 2
      parallel: true
      tasks: ["t3", "t4"]
      depends_on_waves: [1]
      rationale: "Both need wave 1 outputs. Logo and icons don't touch same files."
      verification:
        type: "file_validation"
        checks: ["SVG logos exist and are valid", "Icon SVGs exist with consistent viewBox"]

    - wave: 3
      parallel: true
      tasks: ["t5", "t6", "t7"]
      depends_on_waves: [2]
      rationale: "All need logo mark from wave 2. Each writes to separate directories."
      verification:
        type: "file_validation"
        checks: ["Favicon SVG has dark mode media query", "iOS icons all sizes present", "OG image is 1200x630"]

    - wave: 4
      parallel: false
      tasks: ["t8"]
      depends_on_waves: [1, 2, 3]
      rationale: "Final compilation — needs all previous outputs"
      verification:
        type: "schema_validation"
        checks: ["brand-reference.yml validates against schema", "brand-manual.md has all sections"]
      qa_review: true   # Triggers the QA agent after this wave
```

### File Ownership — Preventing Agent Conflicts

The `file-ownership` skill is the critical safety mechanism. It ensures no two agents write to the same file.

```yaml
# file-ownership-registry.yml (generated per plan)
ownership:
  - agent: "color-agent"
    wave: 1
    owns:
      - "brand-reference.yml#colors"    # Section-level ownership
    reads:
      - "brand-reference.yml#identity"  # Read-only access

  - agent: "typography-agent"
    wave: 1
    owns:
      - "brand-reference.yml#typography"
    reads:
      - "brand-reference.yml#identity"

  - agent: "logo-agent"
    wave: 2
    owns:
      - "assets/logo/**"
    reads:
      - "brand-reference.yml#colors"
      - "brand-reference.yml#typography"

  - agent: "icon-agent"
    wave: 2
    owns:
      - "assets/icons/**"
    reads:
      - "brand-reference.yml#colors"

# Conflict detection rule:
# Before a plan is executed, verify that within each wave,
# no two agents have overlapping "owns" paths.
# Between waves, ownership is sequential — no conflict possible.
```

**Section-level ownership for shared files:**

The brand-reference.yml is a single file that multiple phases write to. Instead of file-level locking, we use section-level ownership. Each agent owns a YAML section (delimited by top-level keys). The planner enforces that within a wave, no two agents write to the same section.

For truly shared files where section ownership isn't possible, tasks writing to that file must be in different waves (sequential, not parallel).

### Verification Runner

The `verification-runner` skill is a dispatcher. It takes the verification type from the plan and runs the appropriate checks.

```yaml
# verification-registry.yml
# Maps verification types to concrete checks

verification_types:
  data_validation:
    description: "Verify YAML data is complete and valid"
    checks:
      - "Required fields exist and are non-empty"
      - "Values match expected types (string, number, array)"
      - "Cross-references resolve (e.g., color names used in pairs exist in palette)"
    tool: "yaml_validator"   # Built-in — Claude reads and checks YAML

  accessibility_validation:
    description: "Verify WCAG compliance"
    checks:
      - "All color pairs have contrast_ratio computed"
      - "All body text pairs pass 4.5:1"
      - "All large text pairs pass 3:1"
      - "Colorblind safety notes present"
    tool: "contrast_calculator"   # Script in plugin

  file_validation:
    description: "Verify expected files exist and are well-formed"
    checks:
      - "All expected files in the manifest exist on disk"
      - "SVGs are valid XML with viewBox attribute"
      - "PNGs are correct dimensions"
      - "No zero-byte files"
    tool: "file_checker"   # Shell script

  schema_validation:
    description: "Validate brand-reference.yml against JSON schema"
    checks:
      - "YAML parses without errors"
      - "All required top-level sections present"
      - "All cross-references valid"
    tool: "schema_validator"   # Script using ajv or similar

  # Domain-specific verification types (registered by consuming plugins):

  web_lint:
    description: "Run ESLint + Prettier on generated code"
    registered_by: "website-builder"
    checks:
      - "npx eslint . --max-warnings 0"
      - "npx prettier --check ."
    tool: "shell_command"

  web_build:
    description: "Verify project builds without errors"
    registered_by: "website-builder"
    checks:
      - "npm run build exits 0"
      - "No TypeScript errors"
      - "Bundle size within budget"
    tool: "shell_command"

  web_test:
    description: "Run test suite"
    registered_by: "website-builder"
    checks:
      - "npm test exits 0"
      - "Coverage meets threshold"
    tool: "shell_command"

  seo_audit:
    description: "Validate SEO requirements"
    registered_by: "seo-plugin"
    checks:
      - "All pages have unique title and meta description"
      - "H1 present on every page"
      - "Structured data validates"
      - "Sitemap.xml generated"
    tool: "seo_checker"
```

**Extensibility:** Each consuming plugin registers its own verification types in this registry. The planner doesn't need to know the details — it just calls the verification runner with the type name, and the runner dispatches to the right tool.

### QA Agent

Every plan has a final QA step. This is a **dedicated agent** that reviews all completed work before the plan is marked done. It never does implementation work — it only reviews.

```markdown
# agents/qa-agent.md

---
name: qa-reviewer
description: "Reviews completed work against requirements. Never implements — only audits."
agent_type: "review"
---

## Role

You are a QA reviewer. Your ONLY job is to verify that completed work
matches the requirements. You never write code, generate assets, or
modify files. You READ and REPORT.

## Review Protocol

For each completed wave, perform these checks:

### 1. Requirements Traceability
- Read the original plan and task descriptions
- Read the completed output
- Verify every requirement in the task is satisfied
- Flag any requirement that was missed or partially completed

### 2. Cross-Reference Integrity
- If the task references data from a previous wave, verify the references are correct
- Example: If logo uses "Brand Blue #2563EB", verify that color exists in brand-reference.yml

### 3. Domain-Specific Checks
Based on the plan's verification_type, run the appropriate automated checks
and report results.

### 4. Output Quality
- Are files well-organized in the expected directory structure?
- Are naming conventions followed?
- Is there any orphaned or duplicate content?

## Report Format

```yaml
qa_report:
  plan: "[plan name]"
  wave_reviewed: [wave number]
  reviewed_at: "[timestamp]"
  status: "pass" | "fail" | "pass_with_warnings"

  checks:
    - name: "Requirements coverage"
      status: "pass"
      notes: "All 5 requirements satisfied"

    - name: "Contrast validation"
      status: "fail"
      notes: "Warning text on yellow (#F59E0B) background fails AA at 2.1:1"
      fix_required: true
      suggested_fix: "Darken to #B45309 (ratio 4.7:1) or use dark text instead"

    - name: "File completeness"
      status: "pass_with_warnings"
      notes: "All expected files present. logo-mark-mono.svg is 23KB — consider optimizing under 15KB."

  verdict: "fail"
  blocking_issues: 1
  warnings: 1
  must_fix_before_proceeding:
    - "Fix warning text contrast on yellow background"
```

## Gate Behavior

- If verdict is "pass": wave is complete, advance to next wave
- If verdict is "pass_with_warnings": advance, but log warnings for later cleanup
- If verdict is "fail": route blocking issues back to the implementing agent
  with the suggested fix. Re-run QA after fixes. Max 3 rounds before escalating
  to human review.
```

### Complete Execution Flow

Putting it all together — here's what happens when a plugin calls `/plan:execute`:

```
1. PLAN LOADED
   └─ Read plan.yml, verify structure, display to user

2. WAVE 1 (parallel)
   ├─ Check file ownership — no conflicts? ✓
   ├─ Spawn agents (or run sequentially in single-agent mode)
   │   ├─ Agent A: color palette
   │   └─ Agent B: typography
   ├─ Both complete
   ├─ VERIFICATION: data_validation
   │   ├─ Colors section complete? ✓
   │   └─ Typography section complete? ✓
   ├─ QA REVIEW (if wave.qa_review is true, or every N waves)
   │   └─ QA agent reviews wave 1 output
   ├─ Update state.yml: wave 1 = completed
   └─ Write recovery notes

3. WAVE 2 (parallel)
   ├─ Check file ownership — no conflicts? ✓
   ├─ Spawn agents
   │   ├─ Agent C: logo design (reads colors + typography)
   │   └─ Agent D: icon library (reads colors)
   ├─ Both complete
   ├─ VERIFICATION: file_validation
   │   ├─ Logo SVGs exist and valid? ✓
   │   └─ Icon SVGs exist with correct viewBox? ✓
   ├─ Update state.yml: wave 2 = completed
   └─ Write recovery notes

4. WAVE 3 (parallel)
   ├─ Agents E, F, G: favicons, app icons, social images
   ├─ VERIFICATION: file_validation
   └─ Update state.yml

5. WAVE 4 (sequential)
   ├─ Agent H: compile brand manual
   ├─ VERIFICATION: schema_validation
   ├─ QA REVIEW (mandatory — final wave)
   │   ├─ QA agent reviews ENTIRE output
   │   ├─ Requirements traceability across all waves
   │   ├─ Cross-reference integrity
   │   └─ Domain checks
   ├─ If QA fails: fix and re-run (up to 3 rounds)
   ├─ If QA passes: mark plan complete
   └─ Update state.yml: plan = completed

6. PLAN COMPLETE
   └─ Report to user: all phases done, all verifications passed, QA signed off
```

### Domain-Specific Verification Profiles

Different plugin types have different verification needs. The planner supports "verification profiles" that plugins declare:

```yaml
# Verification profiles — each plugin registers one

profiles:
  brand:
    after_each_wave:
      - data_validation        # Check YAML is complete
    final:
      - schema_validation      # Full schema check
      - accessibility_validation  # WCAG compliance
      - file_validation        # All assets exist
    qa_frequency: "final"      # QA reviews only at the end
    qa_focus:
      - "Brand consistency across all outputs"
      - "Accessibility compliance"
      - "File naming conventions"

  web:
    after_each_wave:
      - web_lint               # ESLint + Prettier
      - web_build              # Build succeeds
    after_feature_waves:
      - web_test               # Tests pass
    final:
      - web_lint
      - web_build
      - web_test
      - seo_audit              # If SEO plugin installed
      - accessibility_validation
    qa_frequency: "every_wave"  # QA reviews after EVERY wave
    qa_focus:
      - "Code quality and best practices"
      - "Test coverage for new features"
      - "No regressions in existing tests"
      - "Accessibility of UI components"
      - "Performance budgets met"

  seo:
    after_each_wave:
      - data_validation
    final:
      - seo_audit
      - schema_validation
    qa_frequency: "final"
    qa_focus:
      - "All recommendations are actionable"
      - "Data sources cited"
      - "No conflicting recommendations"

  content:
    after_each_wave:
      - data_validation
    final:
      - schema_validation
    qa_frequency: "every_wave"
    qa_focus:
      - "Tone matches brand voice"
      - "No factual claims without sources"
      - "Readability scores within target"
      - "All content follows brand content rules"
```

### Single-Agent vs. Multi-Agent Execution

The planner supports both modes:

**Single-agent mode** (default — no agent teams needed):
- Waves execute sequentially
- Within a wave, tasks run one at a time
- Still gets all verification and QA benefits
- Works everywhere, costs less

**Multi-agent mode** (agent teams enabled):
- Each wave spawns parallel agents
- File ownership enforced via the registry
- Agents communicate via task files on disk
- Team lead stays in delegate mode (coordination only)
- Recommended: 3-5 agents max per wave

The planner automatically selects mode based on environment:

```yaml
execution_mode:
  if: "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS is set"
  then: "multi_agent"
  else: "single_agent"
  override: "/plan:execute --mode single"   # Force single even if teams available
```

---

## 4. Updated Plugin Ecosystem Architecture

### How the Plugins Relate

```
┌─────────────────────────────────────────────────┐
│                  task-planner                     │
│  (generic — wave decomposition, verification,    │
│   file ownership, QA agent)                      │
│                                                   │
│  Consumed by ALL domain plugins                  │
└────────────────────┬────────────────────────────┘
                     │
        ┌────────────┼────────────────┐
        │            │                │
        ▼            ▼                ▼
┌──────────────┐ ┌──────────┐ ┌──────────────┐
│ brand-       │ │ website- │ │ seo-         │
│ guideline    │ │ builder  │ │ plugin       │
│              │ │          │ │              │
│ Uses:        │ │ Uses:    │ │ Uses:        │
│ - planner    │ │ - planner│ │ - planner    │
│ - brand-ctx  │ │ - brand  │ │ - brand-ctx  │
│              │ │ - planner│ │              │
└──────────────┘ └──────────┘ └──────────────┘

┌─────────────────────────────────────────────────┐
│             brand-context-loader                  │
│  (shared skill — loads brand-reference.yml       │
│   and state.yml for any plugin)                  │
└─────────────────────────────────────────────────┘
```

### Dependency Chain

```json
// brand-guideline/ecosystem.json
{
  "dependencies": ["task-planner"]
}

// website-builder/ecosystem.json
{
  "dependencies": ["task-planner", "brand-guideline"]
}

// seo-plugin/ecosystem.json
{
  "dependencies": ["task-planner", "brand-guideline"]
}
```

### Build Order (Revised)

```
Phase 1: task-planner plugin
  ├─ wave-decomposer skill
  ├─ file-ownership skill
  ├─ verification-runner skill
  ├─ qa-reviewer skill + qa-agent
  ├─ /plan:create command
  ├─ /plan:execute command
  ├─ /plan:status command
  └─ /plan:resume command

Phase 2: brand-guideline plugin
  ├─ brand-context-loader skill (shared)
  ├─ state.yml schema + checkpoint definitions
  ├─ 9 domain skills with checkpoint types
  ├─ /brand:generate (calls task-planner internally)
  ├─ /brand:analyze
  ├─ /brand:audit
  └─ Asset generation skills (logo, favicon, icons, etc.)

Phase 3: Future plugins
  ├─ website-builder (registers web_lint, web_build, web_test verifications)
  ├─ seo-plugin (registers seo_audit verification)
  └─ content-plugin (registers content-specific QA focus)
```

---

## 5. Summary: What Differentiates This System

| Feature | Without Planner | With Planner |
|---------|----------------|--------------|
| Task tracking | Manual / ad hoc | Persistent state.yml survives crashes |
| Verification | Hope it's right | Checkpoint gates — no advancing without passing |
| Multi-agent safety | Agents overwrite each other's files | File ownership registry prevents conflicts |
| QA | Self-reported "done" | Dedicated QA agent reviews all output |
| Cross-session resume | Start over, re-explain everything | Read state.yml + recovery_notes, continue |
| Domain flexibility | Each plugin reinvents planning | Register verification profile, planner handles the rest |
| Parallel execution | Manual agent spawning | Automatic wave-based parallelism |
| Failure recovery | Lost work | Fix and re-run from last checkpoint |

### The Core Principle

**Every task must prove it's done. No self-grading.**

The implementing agent does the work. A separate verification step confirms it. A separate QA agent reviews it. Three independent confirmations before anything is marked complete. This is what makes the system trustworthy for long-running, multi-session, multi-agent work.
