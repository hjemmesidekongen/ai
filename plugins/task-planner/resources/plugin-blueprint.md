# Plugin Blueprint

## What This Is

This document is the canonical reference for creating new plugins in this ecosystem.
When someone says "build me a plugin for [X]", Claude Code reads this file AND
`docs/ecosystem-strategy.md`, then follows the process step by step.

- **This file** = structure rules, file layout, checklist
- **docs/ecosystem-strategy.md** = design process, 8 questions, spec templates, 
  brand-reference.yml schema, quality standards, cross-plugin patterns

**Read BOTH files before creating any new plugin.**

**Location:** `packages/task-planner/resources/plugin-blueprint.md`

---

## 1. Every Plugin Must Answer These Questions

Before writing a single file, the new plugin needs clear answers to:

1. **What does it do?** (one sentence)
2. **Who uses it?** (the user persona — same brand owner? developer? marketer?)
3. **Does it need brand context?** (if yes → depends on brand-guideline)
4. **What are the commands?** (slash commands the user invokes)
5. **What are the skills?** (multi-step workflows each command calls)
6. **What does it produce?** (files, YAML data, documents, code, assets?)
7. **What verification types does it need?** (lint? build? test? data validation? custom?)
8. **Can any work run in parallel?** (if yes → define waves and file ownership)

---

## 2. Required Plugin Structure

Every plugin follows this exact structure. No exceptions.

```
packages/[plugin-name]/
├── .claude-plugin/
│   └── plugin.json              # Manifest — name, version, dependencies, commands, skills, hooks
├── commands/
│   └── [command-name].md        # One file per slash command
├── skills/
│   └── [skill-name]/
│       └── SKILL.md             # One directory per skill
├── agents/                      # Optional — only if plugin needs specialized agents
│   └── [agent-name].md
├── migrations/
│   ├── MIGRATION-REGISTRY.yml   # Index of all migrations (empty at v1.0.0)
│   └── scripts/                 # Automated transform scripts per version bump
├── resources/
│   ├── templates/               # YAML schemas, document templates, configs
│   ├── schemas/
│   │   └── archive/             # Archived schemas per version (for migration diffing)
│   └── examples/                # Sample inputs and outputs
├── scripts/
│   ├── session-recovery.sh      # SessionStart hook: detect resumed session, show context
│   └── check-wave-complete.sh   # Stop hook: prevent premature stops, verify skill complete
├── CHANGELOG.md                 # Version history
└── README.md                    # What the plugin does, how to install, how to use
```

### plugin.json Format

```json
{
  "name": "[plugin-name]",
  "version": "1.0.0",
  "description": "[One sentence — what it does]",
  "commands": ["[list of command names without plugin prefix]"],
  "skills": ["[list of skill directory names]"],
  "agents": ["[list of agent filenames without .md]"],
  "dependencies": ["task-planner"],
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|Bash",
        "command": "cat state.yml 2>/dev/null | head -20 || true"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "echo '[plugin-name] File updated. If this completes a phase, update state.yml.'"
      }
    ],
    "SessionStart": [
      {
        "command": "scripts/session-recovery.sh"
      }
    ],
    "Stop": [
      {
        "command": "scripts/check-wave-complete.sh"
      }
    ]
  }
}
```

**Rules:**
- `dependencies` ALWAYS includes `task-planner` — every plugin uses it for planning and verification
- If the plugin needs brand data, add `brand-guideline` to dependencies
- The `name` field must be kebab-case
- `hooks` section is required for all plugins (see Section 13: Hooks & Context Engineering)

---

## 3. How Commands Work

A command is a markdown file in `commands/` that defines what happens when
the user types `/[plugin]:[command]`.

### Command Structure

```markdown
# /[plugin]:[command]

## Purpose
[What this command does in 1-2 sentences]

## Prerequisites
- [What must exist before this command runs]
- [What data it reads]

## Input
[What the user provides — arguments, flags, or interactive interview]

## Execution Strategy

### Interactive phases (cannot be parallelized)
1. [Phase that requires user input]
2. [Another interactive phase]

### Planned phases (use task-planner)
After interactive phases, call /plan:create with:
- Tasks: [list of tasks with dependencies]
- Verification profile: [which profile from verification-registry.yml]
- QA frequency: [every_wave | final]

Then call /plan:execute to run the plan.

## Output
[What files/data this command produces]

## Recovery
If interrupted, the command checks state.yml and resumes from
the last completed wave via /plan:resume.
```

**Rules:**
- Commands that do complex multi-step work MUST use the task-planner
- Commands that only read/report data (like an audit) can skip the planner
- Every command that modifies files must support recovery via state.yml

---

## 4. How Skills Work

A skill is a SKILL.md file that defines a focused, multi-step workflow.
Commands call skills. Skills don't call other skills directly.

### Progressive Disclosure Rule

SKILL.md files must be **under 80 lines** (including frontmatter). This keeps
the orchestrator's context window lean — skills are loaded frequently, and
200-line files waste attention on details that aren't needed until execution.

**When a skill needs more than 80 lines**, move detailed process steps to a
`references/` subdirectory:

```
skills/skill-name/
  SKILL.md              # Frontmatter + Context + Process Summary (~40-60 lines)
  references/           # On-demand detailed docs (plural, one level deep)
    process.md          # Full step-by-step execution instructions
    output-format.md    # YAML schema for outputs (optional)
    examples.md         # Example outputs, edge cases (optional)
```

**Rules:**
- Skills under 80 lines stay as a single file. No forced splitting.
- SKILL.md body must end with a pointer: "Before executing, read
  `references/process.md`" (only when `references/` exists)
- Frontmatter `description` must include BOTH what-it-does AND 3-5 trigger
  phrases. Under 1024 characters. No XML tags.

### Skill Template (Lean Format)

```yaml
---
name: example-skill
description: >
  Does X for Y. Use when user asks to Z, runs command A,
  or during B workflow step N of M.
---
```

```markdown
# Example Skill

Brief one-line purpose.

## Context
- Reads: [what this skill reads]
- Writes: [what this skill writes]
- Checkpoint: [type] ([specific checks])
- Dependencies: [list or none]

## Process Summary
1. Step one summary
2. Step two summary
3. Step three summary

## Execution
Before executing, read `references/process.md` for detailed
instructions, output formats, and edge case handling.
```

Skills that fit in 80 lines can inline their full process instead of using a
`references/` directory. The template above shows the split-file version —
single-file skills replace the "Execution" section with the full process steps.

### Description Quality Checklist

Before finalizing any SKILL.md frontmatter, verify:

- [ ] Does the description say **what the skill does**?
- [ ] Does it include **3-5 trigger phrases** a user or orchestrator might use?
- [ ] Is it **under 1024 characters**?
- [ ] Does it mention relevant **file types, commands, or workflow positions**?

### Skill Rules

- Every skill has a checkpoint — no exceptions
- Skills write to specific files/sections — document exactly what
- Skills that read brand data must specify which sections they need
- If a skill is interactive (asks the user questions), note it clearly — the planner
  cannot parallelize interactive skills

---

## 5. Verification Profiles

Every plugin registers a verification profile in the task-planner's
`verification-registry.yml`. This tells the planner what checks to run.

### How to Register

Add a new section to `packages/task-planner/resources/verification-registry.yml`:

```yaml
# Registered by: [plugin-name]
[profile_name]:
  after_each_wave:
    - [verification_type]
  final:
    - [verification_type]
    - [verification_type]
  qa_frequency: "every_wave" | "final"
  qa_focus:
    - "[What the QA agent should specifically look for]"
    - "[Domain-specific quality criteria]"
```

If the plugin needs a NEW verification type (not already in the registry),
add it:

```yaml
[new_verification_type]:
  description: "[What it checks]"
  registered_by: "[plugin-name]"
  checks:
    - "[Specific check 1]"
    - "[Specific check 2]"
  tool: "shell_command" | "yaml_validator" | "schema_validator" | "[custom]"
```

### Standard Verification Types Available

| Type | What It Checks | Use When |
|------|---------------|----------|
| `data_validation` | YAML fields exist and are non-empty | Any skill that writes YAML |
| `file_validation` | Files exist, correct format/dimensions | Any skill that generates files |
| `schema_validation` | YAML validates against JSON schema | Final compilation step |
| `accessibility_validation` | WCAG contrast, colorblind safety | Color/design work |
| `web_lint` | ESLint + Prettier pass | Web code generation |
| `web_build` | npm run build succeeds | Web projects |
| `web_test` | npm test passes, coverage met | Web projects |
| `seo_audit` | Title, meta, structured data, sitemap | SEO work |

---

## 6. Dual Output Requirement

Every plugin produces TWO forms of output:

1. **Machine-readable YAML** — consumed by other plugins
   - Stored in a predictable location
   - Follows a documented schema
   - Example: `brand-reference.yml`, `seo-report.yml`, `site-config.yml`

2. **Human-readable document** — the deliverable
   - Markdown and/or DOCX
   - Professional formatting, clear sections
   - Example: `brand-manual.md`, `seo-report.md`, `site-spec.md`

**Why:** The YAML lets plugins build on each other's output without parsing
human-formatted text. The document is what the user shares with their team.

---

## 7. Brand Context Integration

If the plugin needs brand data (colors, voice, audience, logo, etc.):

1. Add `brand-guideline` to `dependencies` in plugin.json
2. In every skill that needs brand data, start with:
   ```
   Read brand-reference.yml via the brand-context-loader skill.
   Specifically, load these sections: [list sections needed]
   ```
3. The brand-context-loader handles finding the right brand directory
   and loading the data. Your skill just declares what it needs.

### Accessing Brand Data

```
Brand directory: ~/.claude/brands/[brand-name]/
Main file: brand-reference.yml
Available sections:
  - identity (name, mission, values, positioning)
  - audience (personas, segments)
  - voice (spectrum, attributes, do/don't, writing samples)
  - colors (palette, scales, contrast pairs, dark mode)
  - typography (fonts, type scale, weights)
  - visual_identity (style, iconography rules, layout, shape language)
  - logo (variants, clear space, minimum sizes, misuse rules)
  - content_rules (writing standards, SEO guidelines, content types)
  - social_media (platforms, pillars, hashtags, engagement rules)
  - assets (file paths for all generated assets)
```

---

## 8. State Management

Every plugin that does multi-step work stores state at:

```
~/.claude/[domain]/[project-name]/state.yml
```

For brand: `~/.claude/brands/[brand-name]/state.yml`
For a website: `~/.claude/sites/[site-name]/state.yml`
For SEO: `~/.claude/seo/[project-name]/state.yml`

### State File Format

```yaml
command: "[plugin]:[command]"
project: "[name]"
started_at: "[ISO timestamp]"
updated_at: "[ISO timestamp]"

current_phase: "[skill name]"
current_phase_number: [N]
total_phases: [N]

phases:
  - name: "[skill name]"
    number: 1
    status: "completed"     # pending | in_progress | completed | failed | skipped
    started_at: "[ISO timestamp]"
    completed_at: "[ISO timestamp]"
    checkpoint:
      type: "[checkpoint type]"
      passed: true
      details: "[what was verified]"
    artifacts:
      - "[file that was created]"

errors:
  - timestamp: "[ISO timestamp]"
    skill: "[skill name]"
    error: "[what went wrong]"
    attempted_fix: "[what was tried]"
    result: "resolved | partial | unresolved"
    next_approach: "[what to try next, if unresolved]"

last_session_id: "[session ID]"
recovery_notes: |
  [Human-readable notes about where we are and what's next.
   This is what Claude reads when resuming.]
```

### Error Persistence Rules

The `errors` array in state.yml survives `/compact` and session restarts.
Every plugin must follow these rules:

1. **Log ALL errors.** If something fails, add it to `errors` immediately.
2. **Never repeat failures.** Before attempting an approach, check `errors`
   for previous attempts. If the same approach already failed, mutate.
3. **Track resolution.** When an error is fixed, update `result` to "resolved"
   but keep the entry — it documents what was tried.
4. **Verification runner writes errors.** When a checkpoint fails,
   the verification-runner logs it to state.yml automatically.

### Findings File

During research-heavy skills (interviews, competitor analysis, keyword
research), intermediate discoveries are written to a findings file:

```
~/.claude/[domain]/[project-name]/findings.md
```

For brand: `~/.claude/brands/[brand-name]/findings.md`
For SEO: `~/.claude/seo/[project-name]/findings.md`

**findings.md** stores:
- Research discoveries and source URLs
- Competitor analysis notes
- Technical decisions with rationale
- User responses and clarifications during interviews
- Any information gathered before the final YAML is written

**Rules:**
- Skills that do research MUST write to findings.md, not just keep it in context
- **2-Action Rule:** After every 2 research operations (web search, file read,
  user question), IMMEDIATELY save key findings to findings.md before continuing
- findings.md persists across sessions — if context is lost, findings survive
- The compile/export skill can reference findings.md for additional context
- findings.md stays as a permanent research archive after the project is complete

---

## 9. New Plugin Creation

### Automated (recommended)

The task-planner has built-in commands for creating new plugins:

```
/plugin:create [plugin-name]
```

This runs the full pipeline automatically:
1. **Design interview** — walks through all 8 design questions interactively
2. **Spec generation** — produces implementation plan, domain addendum, asset manifest
3. **Execution guide** — generates a complete step-by-step build guide with one full prompt per skill
4. **Scaffold** — creates the plugin's directory structure, plugin.json, README
5. **CLAUDE.md update** — adds the new plugin to the progress checklist

Then build with:

```
/plugin:build [plugin-name]
```

This reads the generated execution guide and walks you through building
each skill one at a time, with verification checkpoints and progress tracking.

### Manual Fallback

If the automated commands aren't available yet (e.g., you're building
the task-planner itself), follow this sequence:

#### Phase A: Design (plan mode)

```
Read packages/task-planner/resources/plugin-blueprint.md and 
docs/ecosystem-strategy.md. Help me answer the 8 design questions 
for a [plugin-name] plugin.
```

Output: design.yml with all 8 answers.

#### Phase B: Scaffold

```
Based on the design, create the plugin scaffold following the blueprint:
1. packages/[plugin-name]/.claude-plugin/plugin.json
   (include hooks: PreToolUse, PostToolUse, SessionStart, Stop — see blueprint Section 13)
2. Empty directories: commands/, skills/, agents/, resources/, scripts/
3. scripts/session-recovery.sh and scripts/check-wave-complete.sh
   (follow the patterns from blueprint Section 13)
4. README.md
5. Register the verification profile in task-planner's verification-registry.yml

Then update CLAUDE.md: check off this step in the Progress section and set 
"Next step" to the following step. Commit everything.
```

#### Phase C: Schema & Templates

```
Create the YAML schema for [plugin-name]'s main output file.
Also create any document templates needed.
Store in packages/[plugin-name]/resources/templates/

Then update CLAUDE.md: check off this step in the Progress section and set 
"Next step" to the following step. Commit everything.
```

#### Phase D: Skills (one at a time)

For each skill, use this prompt template:

```
Read packages/task-planner/resources/plugin-blueprint.md (sections 4 and 5).
[If brand-dependent: Also read the brand-reference.yml schema to know what 
brand data is available.]

Create packages/[plugin-name]/skills/[skill-name]/SKILL.md

This skill:
1. [Step 1]
2. [Step 2]
3. [Step 3]
...

[If it needs brand data:]
Brand data needed: [list sections from brand-reference.yml]

[If it does research (interviews, competitor analysis, web search):]
Research & findings:
- Write intermediate discoveries to findings.md in the project directory
- 2-Action Rule: after every 2 research operations, save to findings.md immediately
- Check findings.md from previous skills for relevant context

Error handling:
- Log failures to state.yml errors array (timestamp, skill, error, attempted_fix)
- Before retrying: check state.yml errors for previous attempts on this skill

Output: [what files/sections it writes]
Checkpoint type: [type]
Required checks:
- [Check 1]
- [Check 2]

Then update CLAUDE.md: check off this step in the Progress section and set 
"Next step" to the following step. Commit everything.
```

**Important:** `/compact` between each skill.

#### Phase E: Commands

```
Create the slash commands in packages/[plugin-name]/commands/.
Each command follows the structure defined in the blueprint (section 3).
Commands that do complex work must use /plan:create and /plan:execute.

Then update CLAUDE.md: check off this step in the Progress section and set 
"Next step" to the following step. Commit everything.
```

#### Phase F: Test

```
Dry-run test of /[plugin]:[main-command] with a fictional project.
Walk through every phase, show state.yml at each stage, show verification 
results, show QA report. Fix any issues.

Then update CLAUDE.md: check off this step in the Progress section and set 
"Next step" to the following step. Commit everything.
```

---

## 10. Plugin Examples: What Future Plugins Look Like

### Website Builder Plugin

```yaml
name: website-builder
does: "Generates a complete website from brand guidelines"
needs_brand: true
dependencies: [task-planner, brand-guideline]
commands:
  - site:create     # Full site generation (scaffold → build → deploy-ready)
  - site:add-page   # Add a page to existing site
  - site:audit      # Audit existing site against brand
skills:
  - tech-stack-selector    # Choose framework (Next.js, Astro, etc.)
  - site-architecture      # Define pages, routes, navigation
  - component-generator    # Generate UI components in brand style
  - page-builder           # Generate individual pages with content
  - style-system           # Generate CSS/Tailwind config from brand tokens
  - seo-integration        # If seo-plugin installed, apply recommendations
  - build-and-test         # Build project, run tests
verification_profile:
  after_each_wave: [web_lint, web_build]
  after_feature_waves: [web_test]
  final: [web_lint, web_build, web_test, accessibility_validation]
  qa_frequency: every_wave
  qa_focus:
    - "Components match brand visual identity"
    - "All pages are accessible (WCAG AA)"
    - "No regressions in test suite"
    - "Performance budget met (Lighthouse > 90)"
```

### SEO Plugin

```yaml
name: seo-plugin
does: "Generates SEO strategy and audits based on brand positioning"
needs_brand: true
dependencies: [task-planner, brand-guideline]
commands:
  - seo:strategy   # Generate full SEO strategy from brand data
  - seo:audit      # Audit a URL or sitemap
  - seo:content    # Generate SEO-optimized content briefs
skills:
  - keyword-research       # Identify target keywords from brand positioning
  - competitor-analysis    # Analyze competitor SEO
  - on-page-strategy       # Title, meta, heading, schema recommendations
  - content-planning       # Content calendar with SEO focus
  - technical-audit        # Crawl and audit site structure
verification_profile:
  after_each_wave: [data_validation]
  final: [schema_validation, seo_audit]
  qa_frequency: final
  qa_focus:
    - "Keywords align with brand positioning and audience"
    - "Recommendations are actionable and specific"
    - "No conflicting recommendations across sections"
```

### Content Plugin

```yaml
name: content-engine
does: "Generates brand-consistent content at scale"
needs_brand: true
dependencies: [task-planner, brand-guideline]
commands:
  - content:create    # Generate a piece of content
  - content:batch     # Generate multiple pieces from a content plan
  - content:audit     # Audit existing content against brand voice
skills:
  - content-brief          # Generate a detailed brief for any content type
  - content-writer         # Write the actual content in brand voice
  - content-reviewer       # Review content against brand rules
  - content-optimizer      # SEO and readability optimization
verification_profile:
  after_each_wave: [data_validation]
  final: [data_validation]
  qa_frequency: every_wave
  qa_focus:
    - "Tone matches brand voice spectrum"
    - "Readability score within target range"
    - "All claims sourced where required"
    - "Content follows brand content rules"
```

---

## 11. Quality Standards

These apply to EVERY plugin:

1. **Every skill has a checkpoint.** No self-grading. No "trust me, it's done."
2. **Every multi-step command uses the task-planner.** Wave decomposition, verification gates, QA review.
3. **Every output has dual format.** Machine-readable YAML + human-readable document.
4. **Every prompt ends with CLAUDE.md update.** Progress is tracked automatically.
5. **Every session starts by reading state.** If state.yml exists, resume. Never start over.
6. **File ownership is explicit.** In multi-agent mode, no two agents write to the same file in the same wave.
7. **QA agent reviews final output.** Implementing agents never mark their own work as complete.
8. **Brand data flows through brand-context-loader.** No re-asking the user for brand information that's already in brand-reference.yml.
9. **Skills are built one at a time.** One session per skill, `/compact` between them.
10. **Specs live in docs/, not in prompts.** Tell Claude to read the file, don't paste content.
11. **Every plugin output is version-stamped.** All YAML output files get a `_meta` block with plugin version and schema version.
12. **Every plugin has a migrations/ directory.** Even if empty at v1.0.0. Contains MIGRATION-REGISTRY.yml and per-version migration definitions.
13. **Data loaders check version compatibility.** Before loading project data, verify the file version matches the plugin version. Block on major mismatches.
14. **Every plugin has hooks.** PreToolUse re-reads state before actions. Stop hook prevents premature completion. SessionStart runs recovery check. (See Section 13.)
15. **Research skills write to findings.md.** Intermediate discoveries go to disk, not just context. Findings survive `/compact`.
16. **2-Action Rule for research.** After every 2 research operations (search, read, question), IMMEDIATELY save findings to findings.md.
17. **All errors are persisted in state.yml.** Failed approaches are logged with what was tried and what to try next. Claude reads errors before retrying.
18. **Never repeat failed approaches.** Check state.yml errors before attempting anything. If the same approach already failed, mutate the strategy.
19. **Session recovery runs at startup.** The SessionStart hook detects resumed sessions and reports what may have been lost since last state.yml update.

---

## 11a. Model Tier Assignment

Every task in a plan can specify a `model_tier` that determines which model
runs it. This optimizes cost — not every task needs the most capable model.

### Model Tier Mapping

| Tier | Model | Cost (input/output per M) | When to Use |
|------|-------|---------------------------|-------------|
| junior | Haiku 4.5 | $1/$5 | File creation, template copying, scaffolding, schema writes, formatting. Output structure is predetermined. |
| senior | Sonnet 4.5+ | $3/$15 | Skill implementation, command logic, content generation, integration. Default tier — use when in doubt. |
| principal | Opus 4.5+ | $15/$75 | Architecture decisions, QA review, cross-plugin verification, brand coherence, complex planning. |

### Assignment Heuristics (for wave-decomposer)

The wave-decomposer should assign `model_tier` based on these rules:

- **junior**: difficulty=low AND risk=low AND task is primarily file creation/copying
- **senior**: difficulty=medium OR task requires content generation/reasoning (DEFAULT)
- **principal**: difficulty=high OR risk=high OR task is QA/verification OR task is cross-cutting

When `model_tier` is omitted, it defaults to `senior`.

---

## 12. Plugin Versioning

Every plugin tracks its version and supports migration of project data when
the plugin is updated.

### Required Structure

```
packages/[plugin-name]/
  .claude-plugin/
    plugin.json              # "version": "1.0.0"
  migrations/
    MIGRATION-REGISTRY.yml   # Index of all migrations
    v1.0.0-to-v1.1.0.md     # Migration guide per version bump
    v1.1.0-to-v2.0.0.md
    scripts/
      v1.0.0-to-v1.1.0.sh   # Automated transform script
      v1.1.0-to-v2.0.0.sh
  resources/
    schemas/
      archive/
        v1.0.0.yml           # Archived schema per version (for diffing)
        v1.1.0.yml
  CHANGELOG.md               # Human-readable version history
```

### Version Stamping

Every YAML output file (brand-reference.yml, seo-strategy.yml, etc.) must 
include a `_meta` block:

```yaml
_meta:
  plugin_name: "brand-guideline"
  plugin_version: "1.0.0"
  schema_version: "1.0.0"
  created_at: "2026-03-01T12:00:00Z"
  updated_at: "2026-03-01T12:00:00Z"
  migrated_from: null
```

The final skill in any plugin's generation pipeline must call the 
version-meta-stamper to add/update this block.

### Compatibility Checking

Data loaders (like brand-context-loader) must call the 
version-compatibility-checker before loading data:
- **Exact/patch match:** proceed
- **Minor mismatch:** warn, suggest migration, proceed
- **Major mismatch:** block, require migration

### Bumping Versions

Use `/plugin:version [name] bump [major|minor|patch]`:
- Archives the current schema
- Generates migration files (for minor/major)
- Updates CHANGELOG.md

### Migrating Projects

Use `/plugin:migrate [name] --project [project]`:
- Backs up the project first (always)
- Applies migration chain step by step
- Runs verification after migration
- Supports --dry-run and --rollback

### Semver Rules
- **Patch** (1.0.0 → 1.0.1): Bugfix only. No schema change. No migration needed.
- **Minor** (1.0.0 → 1.1.0): New fields added. Backwards compatible. Auto-safe migration.
- **Major** (1.0.0 → 2.0.0): Breaking changes (fields removed/renamed/restructured). Requires user review.

---

## 13. Hooks & Context Engineering

Hooks are Claude Code lifecycle events that run automatically. Every plugin
uses hooks to maintain context, prevent drift, and enforce completion.

### Why Hooks Matter

After 50+ tool calls, Claude's original goals are at the TOP of the context
window (far from attention). Recent tool outputs are at the BOTTOM (where
attention is). Goals get "lost in the middle." Hooks fix this by re-injecting
key state into the attention window at critical moments.

### Required Hooks

Every plugin must define these in plugin.json:

**PreToolUse** — Re-read state before every action
```
matcher: "Write|Edit|Bash"
command: "cat [state-file] 2>/dev/null | head -20 || true"
```
- Runs before every Write, Edit, or Bash tool call
- Re-injects current phase/wave/objectives into the attention window
- Prevents goal drift during long execution sequences
- Plugin-specific: brand-guideline reads state.yml, seo-plugin reads
  its own state, etc.

**PostToolUse** — Remind to update state after writes
```
matcher: "Write|Edit"
command: "echo '[plugin-name] File updated. If this completes a phase, update state.yml.'"
```
- Gentle reminder after every file write
- Prevents the common failure of completing work but not updating state

**SessionStart** — Recovery check on session start
```
command: "scripts/session-recovery.sh"
```
- Detects if this is a resumed session (after `/compact` or `/clear`)
- Reports: current phase, last state update, pending errors, git changes
- Claude reads this output and orients before doing any work

**Stop** — Completion gate before Claude stops
```
command: "scripts/check-wave-complete.sh"
```
- Runs when Claude tries to finish
- Checks state.yml: is the current skill/phase marked complete + verified?
- If not complete: returns error message, Claude must keep working
- If complete: allows stop
- Prevents premature "I'm done!" when work is still in progress

### Plugin-Specific Hooks

Plugins can add hooks beyond the required set. Examples:

**brand-guideline** might add:
```json
"PreToolUse": [
  {
    "matcher": "Write|Edit|Bash",
    "command": "cat ~/.claude/brands/$(cat ~/.claude/active-brand.yml 2>/dev/null)/state.yml 2>/dev/null | head -20 || true"
  }
]
```

**seo-plugin** might add a PostToolUse hook that validates SEO-specific
output after every write.

### Hook Scripts

Two scripts are required in every plugin's `scripts/` directory:

**scripts/session-recovery.sh:**
```bash
#!/bin/bash
echo "=== Session Recovery Check ==="
if [ -f state.yml ]; then
  echo "State file found."
  echo "Current phase: $(grep 'current_phase:' state.yml 2>/dev/null)"
  echo "Last updated: $(stat -c %Y state.yml 2>/dev/null || stat -f %m state.yml 2>/dev/null)"
  ERRORS=$(grep -c '  - timestamp:' state.yml 2>/dev/null || echo 0)
  echo "Logged errors: $ERRORS"
  echo "Git changes since last commit:"
  git diff --stat HEAD 2>/dev/null || echo "  (not a git repo)"
else
  echo "No state.yml found. Fresh start."
fi
```

**scripts/check-wave-complete.sh:**
```bash
#!/bin/bash
STATUS=$(grep 'status:' state.yml 2>/dev/null | tail -1 | awk '{print $2}' | tr -d '"')
SKILL=$(grep 'current_phase:' state.yml 2>/dev/null | awk '{print $2}' | tr -d '"')

if [ "$STATUS" != "completed" ] && [ "$STATUS" != "verified" ]; then
  echo "⚠️  Current skill '$SKILL' is not complete (status: $STATUS)."
  echo "Please complete the current skill and run verification before stopping."
  exit 1
fi
echo "✅ Current skill complete. Safe to stop."
exit 0
```

---

## 14. Brainstorm Integration

Every plugin's interview skills check for brainstorm decisions before
asking questions from scratch. This is handled by the decision-reader
utility skill in task-planner.

### How It Works

1. User runs `/brainstorm:start [project]` and spars with Claude
2. User runs `/brainstorm:decide` — they co-author decisions.yml together
3. Each decision is tagged with a domain and confidence level
4. When a plugin's interview skill starts, it calls decision-reader
5. decision-reader returns relevant decisions filtered by domain
6. The interview skill adapts based on confidence:
   - **high** → Pre-fill answer, show for quick confirmation
   - **medium** → Present as starting point, allow changes
   - **low** → Mention as context, still ask the full question
   - **not found** → Ask normally (brainstorming is always optional)

### Standard Decision Domains

Plugins consume decisions tagged with these domains:

| Domain | Consumed By |
|--------|-------------|
| brand-identity | brand-guideline (identity-interview) |
| brand-audience | brand-guideline (audience-personas) |
| brand-voice | brand-guideline (tone-of-voice) |
| brand-visual | brand-guideline (typography-color, visual-identity, logo-design) |
| seo | seo-plugin (project-interview, keyword-research) |
| website | website-builder (when built) |
| content | content-engine (when built) |
| technical | task-planner (plugin-design-interview) |
| business | any plugin needing business context |
| general | any plugin |

### Adding Brainstorm Support to a New Plugin

When creating a new plugin, its interview skills should include this as
the first step:

```
Before starting the interview, call the decision-reader skill:
- Project: [the project/brand name]
- Domains: [relevant domains for this skill]

If decisions are found, adapt the interview accordingly.
If no decisions are found, proceed with the normal interview flow.
```

This is a small addition — typically 5-10 lines at the top of the
interview skill's SKILL.md.
