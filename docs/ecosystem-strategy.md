# Plugin Ecosystem — Strategy & Design Reference

**Purpose:** Upload this file to any Claude conversation when designing a new plugin.
It contains the full architectural strategy, design process, and quality standards
so that every plugin is built to the same depth as the original brand-guideline plugin.

**Where this lives:** `docs/ecosystem-strategy.md` in the claude-plugins repo.
**When to use:** At the START of any conversation where you're designing a new plugin.

---

## 1. Ecosystem Architecture

```
┌──────────────────────────────────────────────────┐
│                  task-planner                      │
│  Wave planning · Verification · QA · File ownership│
└──────────┬───────────┬───────────┬────────────────┘
           │           │           │
    ┌──────▼──┐  ┌─────▼────┐  ┌──▼──────────┐
    │  brand  │  │ website  │  │ seo-plugin  │  ...
    │guideline│  │ builder  │  │             │
    └──┬──────┘  └────┬─────┘  └─────────────┘
       │              │
       │   ┌──────────▼───────────┐
       └──►│ brand-context-loader  │◄── shared skill
           │ (loads brand data)    │    any plugin can use
           └───────────────────────┘
```

**Dependency rules:**
- Every plugin depends on `task-planner`
- Plugins that need brand data also depend on `brand-guideline`
- `brand-context-loader` is a shared skill — any plugin can read brand-reference.yml through it
- Plugins never depend on each other sideways (website-builder doesn't depend on seo-plugin)
  — they communicate through shared data files

**Data flow:**
- Brand data: `.ai/brands/[brand-name]/brand-reference.yml`
- Site data: `.ai/sites/[site-name]/site-config.yml`
- SEO data: `.ai/seo/[project-name]/seo-strategy.yml`
- Each plugin writes to its own domain directory
- Plugins can READ other plugins' YAML files but never WRITE to them

---

## 2. The 8 Design Questions

Before writing any code, every new plugin must answer these. Spend real time
on these — they determine everything that follows.

### Q1: What does it do? (one sentence)
The elevator pitch. If you can't say it in one sentence, the plugin scope is too broad.
Split it into two plugins.

**Brand example:** "Generates agency-grade brand guidelines through an interactive process."

### Q2: Who uses it?
The user persona. This determines interview depth, technical vocabulary, and output format.

**Brand example:** "A founder or marketer who needs professional brand guidelines
but doesn't have agency budget."

### Q3: Does it need brand context?
If yes → depends on brand-guideline, uses brand-context-loader.
Map EXACTLY which sections of brand-reference.yml each skill needs.

**Brand example:** "No — it IS the brand plugin. But future plugins (website, content) depend on it."

### Q4: What are the slash commands?
Commands are the user-facing entry points. Keep them few (2-4 max).
- One "generate/create" command (the main workflow)
- One "audit" command (check existing work against the standard)
- Optionally: "add/update" (incremental), "export" (format conversion)

**Brand example:** `/våbenskjold:generate`, `/våbenskjold:analyze`, `/våbenskjold:audit`, `/våbenskjold:switch`

### Q5: What are the skills?
Skills are the internal building blocks commands call. Each skill:
- Does ONE thing well
- Has ONE checkpoint
- Writes to SPECIFIC files/sections (documented)
- Takes 15-30 min to build in Claude Code

**Brand example:** 9 skills — identity-interview, audience-personas, tone-of-voice,
typography-color, visual-identity, logo-design, content-rules, social-media, compile-and-export.

**Ordering principle:** Skills that inform later decisions come FIRST.
For brand: personality (voice) → aesthetics (visual). Never reverse.

### Q6: What does it produce?
Always dual output:
- Machine-readable: YAML file with documented schema (consumed by other plugins)
- Human-readable: Markdown + DOCX (the deliverable the user shares with their team)
- Assets: any generated files (SVGs, PNGs, code, configs)

**Brand example:**
- `brand-reference.yml` (machine-readable — schema in resources/templates/)
- `brand-manual.md` + `brand-manual.docx` (human-readable)
- `assets/` directory: ~85+ files (logos, icons, favicons, social images)

### Q7: What verification types does it need?
Map each skill to a checkpoint type. Then define the verification profile
(what runs after each wave, what runs at the end).

Standard types available:
| Type | What It Checks |
|------|---------------|
| `data_validation` | YAML fields exist and are non-empty |
| `file_validation` | Files exist, correct format/dimensions |
| `schema_validation` | YAML validates against JSON schema |
| `accessibility_validation` | WCAG contrast, colorblind safety |
| `web_lint` | ESLint + Prettier pass |
| `web_build` | Build succeeds |
| `web_test` | Tests pass, coverage met |
| `seo_audit` | Title, meta, structured data, sitemap |

If you need a NEW type, define it — the verification runner is extensible.

**Brand example:**
- After each wave: `data_validation`
- Final: `schema_validation` + `accessibility_validation` + `file_validation`
- QA: final only

### Q8: Can any work run in parallel?
Map dependencies between skills. Skills with no shared dependencies can wave together.
Draw the wave diagram.

**Brand example:**
```
Wave 1 (sequential): identity interview (interactive — needs user)
Wave 2 (sequential): audience personas (interactive)
Wave 3 (sequential): tone of voice (interactive)
Wave 4 (parallel): colors + typography (independent, same data inputs)
Wave 5 (parallel): visual identity + logo design (both need colors/typography)
Wave 6 (parallel): content rules + social media (independent)
Wave 7 (sequential): compile & export (needs all previous)
```

---

## 3. Spec Document Template

After answering the 8 questions, produce these deliverables (same format as
the brand-guideline specs):

### 3a. Implementation Plan
**File:** `docs/[plugin]-implementation-plan.md`
**Contains:**
- Plugin overview and architecture
- Full YAML schema for the plugin's main output file (every field, every type)
- Command definitions with execution strategies
- Skill list with dependencies and ordering rationale
- Build phases (what order to implement)

### 3b. Domain-Specific Addendum
**File:** `docs/[plugin]-addendum.md`
**Contains:**
- Deep domain knowledge Claude Code needs to do the work well
- Quality standards for this specific domain
- Tool and dependency requirements
- Validation criteria and tools

**Brand example:** `addendum-assets-and-accessibility.md` covered WCAG standards,
color theory, logo design process, software recommendations.

**Website example might cover:** Performance budgets, Core Web Vitals, responsive
breakpoints, component architecture patterns, testing strategy.

### 3c. Asset/Output Manifest (if applicable)
**File:** `docs/[plugin]-asset-manifest.md`
**Contains:**
- Complete list of every file the plugin generates
- Exact dimensions, formats, naming conventions
- Generation method (tool, script, template)
- Dependencies (ImageMagick, sharp-cli, etc.)

### 3d. Execution Guide
**File:** `docs/[plugin]-execution-guide.md` or added to the main `claude-code-execution-guide.md`
**Contains:**
- Step-by-step build instructions
- One complete prompt per skill (NOT "repeat this pattern")
- Each prompt specifies: which spec to read, step-by-step process, what data
  it reads, what it writes, checkpoint type + checks, CLAUDE.md update instruction
- Timeline with per-step estimates
- Tips and gotchas

---

## 4. Skill Prompt Template

Every skill prompt follows this structure. Never deviate.

```
Read [specific spec file] ([specific section]).
[If brand-dependent: Also read brand-reference.yml schema for available data.]

Create plugins/[plugin]/skills/[skill-name]/SKILL.md

This skill:
1. [Read X from Y file]
2. [Do something specific]
3. [If interactive: Ask the user Z — one question at a time, offer examples]
4. [Generate/compute output]
5. [Validate output]
6. [Write specific sections to specific file]

[If brand data needed:]
Brand data sections needed: [list exact sections]

[If it generates files:]
Files generated:
- [path/filename.ext] — [what it is]
- [path/filename.ext] — [what it is]

Output: writes [specific sections] of [specific file]
Checkpoint type: [type]
Required checks:
- [Specific check 1 — measurable, not vague]
- [Specific check 2]
- [Specific check 3]

Then update CLAUDE.md: check off this step in the Progress section 
and set "Next step" to the following step. Commit everything.
```

**Quality rules for prompts:**
- Every check must be MEASURABLE ("at least 3 values defined" not "values look good")
- Every file write must name the EXACT file and section
- If a skill reads data from a previous skill, say exactly which fields
- If a skill is interactive, say "one question at a time, offer examples"
- If a skill generates assets, list every file with dimensions/format
- Never use "etc." or "similar" — be exhaustive

---

## 5. Quality Standards (Non-Negotiable)

These apply to EVERY plugin. They were established during brand-guideline
design and must be maintained.

### 5a. Verification
- Every skill has a checkpoint with specific, measurable checks
- No skill self-grades — verification is a separate step
- Verification runs after every wave, not just at the end
- Failed verification blocks advancement (no skipping)

### 5b. QA
- QA agent reviews all final output
- QA agent NEVER implements — only reviews
- Structured YAML report with verdict (pass/fail/pass_with_warnings)
- Max 3 review rounds before human escalation
- QA focus areas are domain-specific (defined per plugin)

### 5c. State & Recovery
- state.yml tracks every phase: status, timestamps, checkpoint results, artifacts
- recovery_notes field contains human-readable context for session resumption
- Session start ALWAYS reads state.yml first
- Never restart completed phases
- Crash → resume from last completed wave

### 5d. File Ownership (Multi-Agent)
- No two agents write to the same file in the same wave
- Section-level ownership for shared YAML files
- Conflict detection script runs before each wave
- Single-agent mode is the default — multi-agent only when agent teams are enabled

### 5e. Accessibility
- WCAG 2.1 AA minimum for all visual output
- Body text: 4.5:1 contrast ratio
- Large text (18px+): 3:1 minimum
- UI components: 3:1 minimum
- Never rely on color alone — pair with icons/labels
- Colorblind safety notes for all primary colors
- Dark mode variants validated separately

### 5f. Dual Output
- Machine-readable YAML (documented schema, validated)
- Human-readable document (professional formatting)
- Both always generated — never just one

### 5g. Build Process
- One skill per Claude Code session
- `/compact` between sessions
- CLAUDE.md auto-updates after every step
- Git commit after every step
- Specs live in docs/ — Claude reads files, user doesn't paste content

### 5h. Versioning & Migration
- Every plugin starts at v1.0.0 with a migrations/ directory and CHANGELOG.md
- Every YAML output file gets a `_meta` block (plugin_version, schema_version, timestamps)
- Data loaders check version compatibility before loading project data
- Major version mismatches block execution until migrated
- Schema archived before every minor/major bump (for migration diffing)
- Migration chain: v1→v2→v3 applied step by step, never skipped
- Backups are mandatory before any migration
- Use `/plugin:version` to bump, `/plugin:migrate` to migrate projects

### 5i. Brainstorm & Discovery
- `/brainstorm:start [project]` starts a freeform sparring session — no structured questions
- Claude plays devil's advocate: push back, challenge assumptions, explore trade-offs
- `/brainstorm:decide` co-authors structured decisions.yml with the user when ready
- Each decision tagged by domain (brand-identity, seo, technical, etc.) and confidence (high/medium/low)
- Transcripts saved to .ai/projects/[project]/brainstorm-transcript-[date].md
- Plugin interview skills call the decision-reader to pre-fill from brainstorm decisions
- High confidence → quick confirmation. Medium → starting point. Low → context hint.
- No decisions file → interview runs normally (graceful fallback)

### 5j. Hooks & Context Engineering
- Every plugin defines hooks in plugin.json (PreToolUse, PostToolUse, SessionStart, Stop)
- **PreToolUse hook** re-reads state.yml before every Write/Edit/Bash — prevents goal drift after 50+ tool calls
- **PostToolUse hook** reminds to update state after file writes — prevents forgotten status updates
- **SessionStart hook** runs session-recovery.sh — detects resumed sessions, reports lost context
- **Stop hook** runs check-wave-complete.sh — prevents premature completion, Claude cannot stop until current skill is verified
- **2-Action Rule** for research skills: save findings to findings.md every 2 research operations
- **Error persistence**: all failures logged to state.yml errors array with what was tried and what to try next
- **Never repeat failures**: check errors before retrying — mutate approach if same method already failed
- findings.md stores intermediate research; persists across `/compact` and session restarts

---

## 6. Brand Data Available to All Plugins

Any plugin that depends on brand-guideline gets access to:

```yaml
# .ai/brands/[brand-name]/brand-reference.yml

identity:
  name, tagline, industry, year_founded
  mission, vision
  values: [{name, description}]
  positioning: {for, is_the, that, because}
  competitors: [{name, differentiator}]

audience:
  type: B2B | B2C | both
  segments: [{name, description}]
  primary_persona: [index]
  personas: [{name, age_range, job_title, location, goals, pain_points, 
              channels, decision_factors, quote}]

voice:
  spectrum: [{dimension, position, scale_min, scale_max}]
  attributes: [{attribute, do_examples, dont_examples}]
  channel_variations: {website, social, email, support}
  vocabulary: {use, never_use, jargon_policy}
  writing_samples: {homepage, social_post, email}

colors:
  palette:
    primary: {hex, scales: {50-900}, contrast_pairs, colorblind_notes}
    secondary: {same structure}
    accent: {same structure}
    neutral: {same structure}
  semantic: {success, warning, error, info}
  dark_mode: {same structure, validated}

typography:
  primary_font: {family, weights, source, license}
  secondary_font: {same}
  type_scale: {h1-h6, body, small, caption — each: size, weight, line_height, letter_spacing}

visual_identity:
  photography_style, illustration_style
  iconography: {style, stroke_width, corner_radius, viewbox}
  shape_language, spacing_philosophy
  layout: {grid, whitespace, image_treatment}

logo:
  type: wordmark | lettermark | abstract | combination | emblem
  variants: {paths to all SVG files}
  clear_space, minimum_sizes
  misuse_examples

brand_icon:
  variants: {paths to all SVG files}

content_rules:
  spelling, date_format, number_format, capitalization
  oxford_comma, abbreviation_policy
  content_types: [{type, rules}]
  seo: {keyword_approach, meta_rules, heading_hierarchy}
  readability_target

social_media:
  platforms: [{name, purpose, frequency, voice_adjustment}]
  content_pillars: []
  hashtag_strategy: {branded, industry, per_platform_count}
  profile_picture_variant
  engagement_rules: {response_time, tone, crisis_protocol}

assets:
  # Paths to all ~85+ generated files
  logo_svgs, logo_pngs, brand_icons, favicons, 
  app_icons_ios, app_icons_android, app_icons_pwa,
  social_images, icon_library
```

---

## 7. Workflow: Creating a New Plugin

### Option A: Fully Automated in Claude Code (recommended)

The task-planner has built-in commands that automate the entire plugin
creation pipeline. Optionally, brainstorm first:

```
/brainstorm plugin-architecture          # optional — explore scope & trade-offs
/plugin:create [plugin-name]             # design, spec, scaffold
/plugin:build [plugin-name]              # guided step-by-step build
```

This command:
1. Walks through all 8 design questions interactively
2. Generates the full spec documents (implementation plan, addendum, asset manifest)
3. Generates a complete execution guide with one prompt per skill
4. Scaffolds the plugin (directories, plugin.json, README)
5. Updates CLAUDE.md with the new plugin's progress checklist

Then build it step by step:

```
/plugin:build [plugin-name]
```

This reads the generated execution guide and walks you through each skill
one at a time, with verification checkpoints and automatic progress tracking.

### Option B: Design in claude.ai, Build in Claude Code

Use this when you want a more deliberate design phase with deeper discussion.

**Step 1:** Upload `docs/ecosystem-strategy.md` (this file) to a claude.ai conversation.

**Step 2:** Work through the 8 design questions (Section 2) interactively.
Push for specificity. Don't accept vague answers.

**Step 3:** Map brand data dependencies.
For each skill, list exactly which sections of brand-reference.yml it needs.
Use the schema in Section 6 as reference.

**Step 4:** Design the wave plan.
Draw the dependency graph. Group independent skills into parallel waves.
Interactive skills are always sequential and come first.

**Step 5:** Write the spec documents (Section 3).
Produce all deliverables: implementation plan, addendum, asset manifest,
execution guide with one full prompt per skill.

**Step 6:** Copy specs into the repo's docs/ directory.

**Step 7:** In Claude Code, either:
- Run `/plugin:create [name] --from-design docs/[name]-design.yml` to 
  scaffold from the existing design, or
- Follow the execution guide manually, one skill per session

### Option C: Hybrid

Design in claude.ai for the strategic thinking, then run `/plugin:create`
in Claude Code and point it at the design.yml you produced. It'll generate
the specs and execution guide from there without re-asking the 8 questions.

---

## 8. Cross-Plugin Integration Patterns

### Pattern: Reading another plugin's data
```markdown
# In a website-builder skill:
1. Load brand data via brand-context-loader
   Sections needed: colors, typography, visual_identity, logo
2. Load SEO data from .ai/seo/[project]/seo-strategy.yml (if exists)
   Sections needed: keywords, meta_rules
3. If SEO data doesn't exist, skip SEO integration and note it in output
```

### Pattern: A plugin enhancing another plugin's output
The seo-plugin might audit a site built by website-builder:
```markdown
# /seo:audit
1. Read site-config.yml from .ai/sites/[site]/
2. Crawl the site pages listed in site-config.yml
3. Produce seo-report.yml with per-page findings
4. The website-builder can later read seo-report.yml to fix issues
```

Plugins are loosely coupled. They share data through YAML files on disk.
No plugin directly invokes another plugin's commands.

### Pattern: A plugin that works with OR without brand data
```markdown
# In ecosystem.json:
"dependencies": ["task-planner"]  # brand-guideline is NOT required
"optional_dependencies": ["brand-guideline"]

# In the command:
1. Check if brand-reference.yml exists for the active brand
2. If yes: load it via brand-context-loader, apply brand tokens
3. If no: ask the user for basic style preferences inline
```

---

## 9. What NOT to Do

These are mistakes that were caught during the brand-guideline design process.
Don't repeat them.

1. **Don't build all skills in one session.** Context degrades. One skill per session.
2. **Don't write "repeat this pattern."** Write out every single prompt in full.
3. **Don't let aesthetics precede personality.** Identity → audience → voice → THEN visual.
4. **Don't skip verification.** Every skill gets a checkpoint. No exceptions.
5. **Don't let agents self-grade.** The implementing agent and the reviewing agent are never the same.
6. **Don't paste spec content into prompts.** Tell Claude Code to READ the file.
7. **Don't assume brand data exists.** Check. If it doesn't, either require it or provide a fallback.
8. **Don't use vague checks.** "Looks good" is not a check. "At least 3 values with >10 word descriptions" is.
9. **Don't forget dark mode.** 89% of mobile users. Favicons, logos, color schemes — all need dark variants.
10. **Don't skip the dry run.** Always test end-to-end before calling a plugin done.
