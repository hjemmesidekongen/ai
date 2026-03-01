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
│   └── plugin.json              # Manifest — name, version, dependencies, commands, skills
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
├── scripts/                     # Shell scripts for build/convert/validate
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
  "dependencies": ["task-planner"]
}
```

**Rules:**
- `dependencies` ALWAYS includes `task-planner` — every plugin uses it for planning and verification
- If the plugin needs brand data, add `brand-guideline` to dependencies
- The `name` field must be kebab-case

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

### Skill Structure

```markdown
# [Skill Name]

## Purpose
[What this skill does]

## Inputs
[What data it reads — which sections of which YAML files]

## Process
[Numbered steps — what Claude does in sequence]
1. Read [data] from [file]
2. [Do something]
3. [Ask the user something] (if interactive)
4. [Generate output]
5. [Write to file]

## Output
[What files/sections this skill writes to]

## Checkpoint
type: [checkpoint type from verification-registry.yml]
required_checks:
  - [Check 1]
  - [Check 2]
  - [Check 3]
on_fail: [What to do if checks fail]
on_pass: [Update state.yml and advance]
```

**Rules:**
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

last_session_id: "[session ID]"
recovery_notes: |
  [Human-readable notes about where we are and what's next.
   This is what Claude reads when resuming.]
```

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
2. Empty directories: commands/, skills/, agents/, resources/, scripts/
3. README.md
4. Register the verification profile in task-planner's verification-registry.yml

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

## 13. Brainstorm Integration

Every plugin can register brainstorm modes that let users explore ideas
before committing to decisions. This is optional but recommended for
plugins with creative or strategic decisions.

### Registering a Brainstorm Mode

Append to `packages/task-planner/resources/brainstorm-modes-registry.yml`:

```yaml
[mode-name]:
  registered_by: "[plugin-name]"
  description: "[what this brainstorm explores]"
  topics:
    - name: "[topic-id]"
      prompt: "[opening question]"
      techniques: ["[technique names from brainstorm-techniques.yml]"]
      constraints: ["[boundaries]"]
      depends_on: ["[other topic names]"]
  context_from:
    brand_reference: ["[sections to load]"]
    other_files: ["[paths]"]
  output_to: "brainstorm-sessions/[session-id].yml"
  feeds_into: ["[skill names that consume these decisions]"]
```

### Consuming Brainstorm Decisions

Skills listed in `feeds_into` should check for brainstorm sessions at startup:

```
1. Check state.yml for brainstorm_sessions with feeds_into including this skill
2. If found: read session, extract decisions, present to user for confirmation
3. If not found: proceed normally (brainstorming is always optional)
```

### When to Register Modes

Register modes when your plugin has decisions that benefit from:
- Exploring multiple options before committing
- Weighing trade-offs with the user
- Creative ideation (naming, visual direction, content angles)
- Strategic choices with non-obvious consequences
