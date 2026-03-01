# Plugin Design Interview — Process Detail

## Prerequisites

Before starting this skill, read:
1. `docs/ecosystem-strategy.md` — Section 2 (The 8 Design Questions) and Section 6 (Brand Data Available)
2. `plugins/task-planner/resources/plugin-blueprint.md` — Section 1 (Every Plugin Must Answer These Questions)
3. `plugins/task-planner/resources/verification-registry.yml` — for Q7 (standard verification types)

## Pre-Interview: Load Brainstorm Decisions

Before starting the interview, call the decision-reader skill to check if the
user already made relevant decisions during a brainstorm session:

- **Project:** the plugin name being designed
- **Domains:** `technical`, `general`

If decisions are found, adjust the interview flow:

| Confidence | Behavior |
|------------|----------|
| **High** | Pre-fill the answer and show for quick confirmation: "From your brainstorm: [decision]. Still good? [Y/n]" — if confirmed, skip the question |
| **Medium** | Present as starting point: "You were leaning toward: [decision]. Go with this, or explore further?" — if accepted, use it; otherwise ask normally with the decision as context |
| **Low** | Mention as context when asking the question: "You mentioned [decision] during brainstorming. Let's discuss..." — then proceed with the normal question |
| **Not found** | Ask normally — this is the default behavior without brainstorming |

Use the decision-reader's `check_decision` method before each question to find
matching decisions. For example, before asking Q1 (what does it do), check for
decisions in the `technical` domain matching plugin purpose or scope.

At the end, note which decisions were applied in design.yml:

```yaml
decisions_applied: [d3, d4]
```

## Process

### Step 0 — Get the Idea

Ask the user:

```
"What plugin do you want to build? Give me a one-sentence description."
```

Capture the raw idea. This becomes the seed for Q1.

---

### Step 1 — Q1: What Does It Do?

Take the user's initial description and refine it to one crisp sentence.

Rules:
- If the sentence contains "and" joining two unrelated features → suggest splitting into two plugins
- If it's too vague ("manages content") → push for specificity ("generates SEO-optimized blog posts in brand voice")
- Compare scope against the brand-guideline plugin as a reference: 9 skills, 4 commands — roughly that scale

Ask:
```
"Here's what I'd refine it to: '[refined sentence]'.
Does this feel right as the scope, or should we narrow/expand?"
```

Wait for confirmation before proceeding.

---

### Step 2 — Q2: Who Uses It?

Ask about the user persona. Offer examples to anchor the conversation:

```
"Who's the primary user of this plugin?
- The same brand owner from brand-guideline?
- A developer building a product?
- A marketer running campaigns?
- A content writer producing articles?
- Someone else?"
```

Capture three things:
- **role** — their job title or function
- **technical_level** — "non-technical", "semi-technical", "developer"
- **cares_about** — what matters most to them (speed? quality? SEO? brand consistency?)

Confirm the persona summary with the user before proceeding.

---

### Step 3 — Q3: Does It Need Brand Context?

Ask:
```
"Does this plugin need brand data (colors, voice, audience, logo, etc.)?
- Yes → it depends on brand-guideline and uses brand-context-loader
- No → it's standalone, only depends on task-planner"
```

**If YES:**

Walk through the brand-reference.yml sections (from `docs/ecosystem-strategy.md` Section 6). For each skill identified so far (from the description), ask which sections it needs:

```
Available brand data sections:
  identity    — name, tagline, mission, vision, values, positioning, competitors
  audience    — segments, personas (goals, pain points, channels)
  voice       — spectrum, attributes, channel variations, vocabulary, writing samples
  colors      — palette (primary/secondary/accent/neutral with scales), semantic, dark mode
  typography  — fonts, type scale (h1-h6, body, small, caption)
  visual      — photography style, illustration style, iconography, shape language, layout
  logo        — type, variants, clear space, minimum sizes, misuse rules
  content     — spelling, date format, capitalization, content types, SEO, readability
  social      — platforms, content pillars, hashtags, engagement rules
  assets      — paths to all generated files (SVGs, PNGs, favicons, etc.)
```

Build a mapping: `skill_name → [section1, section2, ...]`

**If NO:**

Confirm: "So this plugin is standalone — only depends on task-planner. Correct?"

---

### Step 4 — Q4: What Are the Commands?

Suggest 2-4 slash commands based on the description. Follow the standard pattern:

| Pattern | Purpose | Example |
|---------|---------|---------|
| `[plugin]:generate` or `[plugin]:create` | Main workflow — the "do the thing" command | `/brand:generate` |
| `[plugin]:audit` | Check existing work against standards | `/brand:audit` |
| `[plugin]:update` or `[plugin]:add` | Incremental modification | `/site:add-page` |
| `[plugin]:export` | Format conversion or deployment | `/content:export` |

For each command, capture:
- **name** — the slash command (e.g., `seo:strategy`)
- **purpose** — one sentence
- **interactive** — does it ask the user questions? (yes/no)
- **uses_planner** — does it use task-planner for wave execution? (yes/no)

Present the proposed commands and ask:
```
"Here are the commands I'd suggest:
1. /[plugin]:[cmd1] — [purpose] (interactive: yes, planner: yes)
2. /[plugin]:[cmd2] — [purpose] (interactive: no, planner: no)
...
Does this look right? Want to add, remove, or rename any?"
```

---

### Step 5 — Q5: What Are the Skills?

Based on the commands, decompose into skills. Each skill:
- Does ONE thing
- Has ONE checkpoint
- Writes to SPECIFIC files/sections

**Ordering principle:** Skills that produce decisions informing later work come FIRST. Interactive skills before autonomous ones.

For each skill, capture:
- **name** — kebab-case (e.g., `keyword-research`)
- **purpose** — one sentence
- **interactive** — does it need user input? (yes/no)
- **depends_on** — list of skills that must complete before this one
- **reads** — what data/files it consumes
- **writes** — what files/sections it produces

Ask for each skill:
```
"Does [skill-name] need user input (interactive), or can it run autonomously
from the data provided by previous skills?"
```

Present the full skill list with dependency arrows and confirm:
```
"Here's the skill breakdown:
1. [skill-1] (interactive) → writes [section] of [file]
2. [skill-2] (interactive) → writes [section] of [file]
3. [skill-3] (autonomous, depends on 1+2) → writes [section] of [file]
...
Does this decomposition make sense? Any skills missing or unnecessary?"
```

**Model tier hint:** After confirming the skill list, note which skills map to which model tier. This helps the user think about complexity and cost:

```
Model tier estimates:
  junior  (Haiku)  — [simple skills: scaffolding, template-based output]
  senior  (Sonnet) — [most skills: content generation, interviews, research] (default)
  principal (Opus) — [complex skills: QA, architecture, cross-plugin verification]
```

This is advisory only — the spec generator assigns final tiers downstream. But surfacing it here helps the user gauge whether the plugin is appropriately scoped.

Enforce minimums:
- At least 2 skills
- At least 1 interactive skill (the user should shape their plugin's output)

---

### Step 6 — Q6: What Does It Produce?

Define the dual output:

**a) Machine-readable YAML:**
- Schema name (e.g., `seo-strategy.yml`)
- Storage path (e.g., `~/.claude/seo/[project-name]/`)
- Brief description of what it contains

**b) Human-readable document:**
- Format: `.md`, `.docx`, or both
- What sections it contains

**c) Additional assets (if any):**
- Code files, images, configs, scripts
- Formats and naming conventions

Ask:
```
"Every plugin produces dual output:
1. A machine-readable YAML file (consumed by other plugins)
2. A human-readable document (the deliverable for humans)

For [plugin-name]:
- What should the YAML file be called and where should it live?
- What format for the human document? (Markdown, DOCX, or both?)
- Any additional assets generated? (code, images, configs?)"
```

---

### Step 7 — Q7: What Verification Types?

Read `plugins/task-planner/resources/verification-registry.yml` for the standard types.

Present the standard types:

```
Standard verification types:
  data_validation           — YAML fields exist and are non-empty
  file_validation           — Files exist, correct format/dimensions
  schema_validation         — YAML validates against JSON schema
  accessibility_validation  — WCAG contrast, colorblind safety
  web_lint                  — ESLint + Prettier pass
  web_build                 — Build succeeds
  web_test                  — Tests pass, coverage met
  seo_audit                 — Title, meta, structured data, sitemap
```

For each skill, ask which verification type applies. If none of the standard types fit, define a new one together:
```
"For [skill-name], which verification type fits?
If none of these work, we can define a custom type together."
```

For new types, capture:
- **name** — kebab-case
- **description** — what it checks
- **checks** — list of specific, measurable checks
- **tool** — `shell_command`, `yaml_validator`, `schema_validator`, or custom

Then define the **verification profile** for the plugin:
```yaml
verification_profile:
  after_each_wave: [types that run after every wave]
  final: [types that run at the very end]
  qa_frequency: "every_wave" | "final"
  qa_focus:
    - "[domain-specific quality criterion 1]"
    - "[domain-specific quality criterion 2]"
```

---

### Step 8 — Q8: Can Any Work Run in Parallel?

Map the dependency graph between skills. Group independent skills into waves.

Rules:
- Interactive skills are ALWAYS sequential (they need the user)
- Skills that read another skill's output must come AFTER that skill
- Skills with no shared dependencies CAN wave together (parallel)
- The final compilation/export skill always comes last

Draw the wave plan:
```
Wave 1 (sequential): [skill-a] — interactive, needs user
Wave 2 (sequential): [skill-b] — interactive, needs user
Wave 3 (parallel):   [skill-c] + [skill-d] — independent, both read wave 1+2 output
Wave 4 (sequential): [skill-e] — needs everything above
```

Ask:
```
"Here's the wave structure:
[wave diagram]
Does this ordering make sense? Any skills that should move earlier or later?"
```

Enforce minimums:
- At least 2 waves (if everything is sequential, that's fine — but there should be at least an interactive phase and a generation phase)

---

### Step 9 — Produce Design Summary

After all 8 questions are answered, compile the structured design summary.

Write to `plugins/[plugin-name]/design.yml`:

```yaml
# ============================================================
# Plugin Design — [Plugin Name]
# ============================================================
# Generated by: plugin-design-interview skill
# Date: [ISO 8601 date]
# Status: awaiting_review
#
# This file is consumed by:
#   - plugin-spec-generator (produces implementation plan + addendum)
#   - plugin-execution-guide-generator (produces build guide)
#   - plugin-scaffolder (creates directories + plugin.json)
# ============================================================

name: "[plugin-name]"
description: "[one sentence from Q1]"

persona:
  role: "[from Q2]"
  technical_level: "[non-technical | semi-technical | developer]"
  cares_about: "[from Q2]"

needs_brand: true | false

# Only populated if needs_brand is true
brand_sections_needed:
  skill_name_1:
    - identity
    - audience
  skill_name_2:
    - colors
    - typography

commands:
  - name: "[plugin]:[command]"
    purpose: "[one sentence]"
    interactive: true | false
    uses_planner: true | false

skills:
  - name: "[skill-name]"
    purpose: "[one sentence]"
    interactive: true | false
    depends_on: []
    reads:
      - "[file or section]"
    writes:
      - "[file or section]"
    checkpoint:
      type: "[verification type]"
      checks:
        - "[specific measurable check 1]"
        - "[specific measurable check 2]"

output:
  yaml:
    name: "[filename].yml"
    storage_path: "~/.claude/[domain]/[project-name]/"
    description: "[what it contains]"
  document:
    format: "md" | "docx" | "both"
    sections:
      - "[Section 1 name]"
      - "[Section 2 name]"
  assets:
    - type: "[code | image | config]"
      format: "[file extension]"
      description: "[what it is]"

verification_profile:
  after_each_wave:
    - "[verification type]"
  final:
    - "[verification type]"
  qa_frequency: "every_wave" | "final"
  qa_focus:
    - "[domain-specific quality criterion]"

wave_plan:
  - wave: 1
    parallel: false
    skills:
      - "[skill-name]"
    verification:
      - "[type]"
  - wave: 2
    parallel: true
    skills:
      - "[skill-a]"
      - "[skill-b]"
    verification:
      - "[type]"
```

---

### Step 10 — User Review

Present the design summary to the user for review:

```
"Here's the complete design for [plugin-name]:

**What it does:** [description]
**User:** [role] ([technical_level]) — cares about [cares_about]
**Brand data:** [yes/no]
**Commands:** [count] — [list names]
**Skills:** [count] — [list names in wave order]
**Output:** [yaml name] + [document format]
**Waves:** [count] — [wave summary]

Review the full design.yml at plugins/[plugin-name]/design.yml.
Does everything look correct? Any changes before we generate the specs?"
```

Wait for explicit confirmation. If the user requests changes, update design.yml and re-present.

Once confirmed, update the `status` field in design.yml from `awaiting_review` to `approved`.

---

## Checkpoint

```
type: data_validation
required_checks:
  - All 8 questions have non-empty answers in design.yml
  - At least 1 command defined in commands array
  - At least 2 skills defined in skills array
  - Every skill has a checkpoint.type and at least 1 checkpoint.checks entry
  - Wave plan has at least 2 waves
  - If needs_brand is true: brand_sections_needed is populated for every
    skill that reads brand data (every skill listed must have at least 1 section)
  - status field is "approved" (user confirmed)
on_fail: >
  Re-present the design summary to the user. Highlight which checks failed.
  Ask the user to help resolve the gaps. Update design.yml and re-validate.
on_pass: >
  Update state.yml: mark plugin-design-interview as completed.
  Report: "Design approved. Ready for /plugin:create Step 2 — spec generation."
```

## Quality Rules

1. **One question at a time.** Never ask Q2 before Q1 is confirmed.
2. **Offer examples.** Every question includes concrete examples from the brand-guideline plugin.
3. **Push for specificity.** Reject vague answers ("handles content" → "generates SEO-optimized blog posts").
4. **Measurable checks only.** "At least 3 personas defined" — not "personas look good."
5. **Confirm each answer.** Summarize and wait for user approval before moving on.
6. **Respect the ordering principle.** Skills that inform later decisions come first.
7. **Brand sections are explicit.** If a skill needs brand data, name the exact sections — no "all of it."
8. **No forward references.** design.yml is self-contained. Downstream skills read it; this skill reads nothing from the new plugin.
