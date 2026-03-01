# Plugin Spec Generator — Process Detail

## Prerequisites

Before running this skill, read:
1. `packages/[plugin-name]/design.yml` — the approved design from the interview
2. `docs/ecosystem-strategy.md` — Section 3 (Spec Document Template), Section 6 (Brand Data Available)
3. `packages/task-planner/resources/plugin-blueprint.md` — Sections 2–8
4. `packages/task-planner/resources/verification-registry.yml` — existing types and profiles

Also read the brand-guideline specs as reference examples of the output format:
- `docs/implementation-plan-v2.md` — reference implementation plan
- `docs/addendum-assets-and-accessibility.md` — reference domain addendum
- `docs/brand-asset-manifest.md` — reference asset manifest

## Process

### Step 1 — Read and Validate design.yml

Read `packages/[plugin-name]/design.yml`. Validate before proceeding:

```
Required fields:
  - name                    (string, kebab-case)
  - description             (string, one sentence)
  - persona.role            (string)
  - persona.technical_level (one of: non-technical, semi-technical, developer)
  - persona.cares_about     (string)
  - needs_brand             (boolean)
  - commands                (array, at least 1 entry)
  - skills                  (array, at least 2 entries)
  - output.yaml.name        (string)
  - output.yaml.storage_path(string)
  - output.document.format  (one of: md, docx, both)
  - verification_profile    (object with after_each_wave, final, qa_frequency, qa_focus)
  - wave_plan               (array, at least 2 waves)
  - status                  (must be "approved")

If needs_brand is true:
  - brand_sections_needed   (object, at least 1 skill→sections mapping)
```

If any required field is missing or `status` is not `approved`, STOP and report the issue. Do not generate specs from unapproved designs.

---

### Step 2 — Generate Implementation Plan

Write `docs/[plugin-name]-implementation-plan.md` with these sections:

#### Section a) Overview

```markdown
# Implementation Plan: [Plugin Name]

## Overview

**What it does:** [description from design.yml]
**Who it's for:** [persona.role] ([persona.technical_level]) — cares about [persona.cares_about]
**Dependencies:** task-planner[, brand-guideline if needs_brand]
**Commands:** [count] — [list command names]
**Skills:** [count] — [list skill names in wave order]
**Output:** [yaml name] + [document format]
```

#### Section b) Architecture

Draw an ASCII diagram showing how this plugin fits into the ecosystem.

**If needs_brand is true:**
```
┌──────────────────────────────┐
│         task-planner          │
│  Waves · Verification · QA   │
└──────────┬───────────────────┘
           │
    ┌──────▼──────────────────┐
    │    [plugin-name]         │
    │    [description]         │
    └──────┬──────────────────┘
           │
    ┌──────▼──────────────────┐
    │  brand-context-loader    │
    │  (loads brand data)      │
    └──────┬──────────────────┘
           │
    ┌──────▼──────────────────┐
    │   brand-reference.yml    │
    │   ~/.claude/brands/[x]/  │
    └─────────────────────────┘
```

**If needs_brand is false:**
```
┌──────────────────────────────┐
│         task-planner          │
│  Waves · Verification · QA   │
└──────────┬───────────────────┘
           │
    ┌──────▼──────────────────┐
    │    [plugin-name]         │
    │    [description]         │
    └─────────────────────────┘
```

Also include the data flow: where input data comes from, where output data is stored, and what other plugins can read the output.

#### Section c) YAML Schema

Generate the COMPLETE schema for the plugin's main output YAML file. Use the design.yml `output` section as the starting point and expand:

1. Add a `meta` section:
   ```yaml
   meta:
     plugin_name: "[plugin-name]"
     project_name: "[user's project name]"
     created_at: "ISO 8601 timestamp"
     updated_at: "ISO 8601 timestamp"
     version: "1.0"
     generated_by: "[plugin-name] v[version]"
   ```

2. For each section implied by the design.yml `output.document.sections`, create a YAML section with:
   - Realistic field names based on the domain
   - Type annotations (string, number, boolean, array, enum)
   - Description comments for non-obvious fields
   - Enum values where applicable

3. Every field must have a type. Every enum must list all valid values. No "etc." or "similar" — be exhaustive.

4. Target: at least 5 top-level sections, each with at least 3 typed fields.

**Reference:** Study the brand-reference.yml schema in `docs/implementation-plan-v2.md` for the expected level of detail and structure.

#### Section d) Commands

For each command from `design.yml.commands`, expand into:

```markdown
### /[command-name]

**Purpose:** [from design.yml]

**Input:**
- Arguments: [what the user provides]
- Flags: [optional flags like --brand, --format, --output]
- Interactive prompts: [if interactive: what questions are asked]

**Execution Strategy:**

Interactive phases (cannot be parallelized):
1. [Phase that requires user input — from the skills marked interactive]
2. [Another interactive phase if applicable]

Planned phases (use task-planner):
After interactive phases, call /plan:create with:
- Tasks: [list skills with their dependencies]
- Verification profile: [profile name]
- QA frequency: [from design.yml]

Then call /plan:execute to run the plan.

**Output:**
- [yaml file] — written to [storage_path]
- [document file] — written to [storage_path]
- [assets if any]

**Recovery:**
If interrupted, check state.yml at [storage_path] and resume from
the last completed wave via /plan:resume.
```

#### Section e) Skills

For each skill from `design.yml.skills`, expand the one-line purpose into a detailed specification:

```markdown
### Skill: [skill-name]

**Purpose:** [from design.yml, expanded]
**Interactive:** [yes/no]
**Depends on:** [list]

**Inputs:**
- Reads: [from design.yml.skills[].reads — expand with specific fields/sections]
- [If needs brand data:] Brand sections: [from brand_sections_needed]

**Process:**
1. [Read specific data from specific file/section]
2. [Validate/check prerequisites]
3. [If interactive: Ask the user specific questions — one at a time, offer examples]
4. [Process/compute/generate — describe what happens]
5. [Apply domain-specific quality rules]
6. [Format output according to schema]
7. [Write to specific section of specific file]
8. [Run checkpoint validation]

**Output:**
- Writes: [specific sections of specific files]
- [If it generates additional files: list them with paths]

**Checkpoint:**
- Type: [from design.yml]
- Checks:
  - [Specific measurable check 1 — e.g., "at least 5 keywords per category"]
  - [Specific measurable check 2 — e.g., "every entry has a description > 20 words"]
  - [Specific measurable check 3]
```

**Expansion rules:**
- Every skill MUST have at least 5 concrete process steps (aim for 5–10)
- Steps must reference specific files and sections by name
- Interactive skills must specify exactly what questions are asked
- Checks must be MEASURABLE — quantities, thresholds, existence checks
- No vague steps like "process the data" — say exactly what processing occurs
- If a skill reads from a previous skill's output, name the exact fields

#### Section f) Build Order

List all skills in the order they should be implemented, with model tier for each:

```markdown
## Build Order

| # | Skill | Model Tier | Rationale |
|---|-------|------------|-----------|
| 1 | [skill-name] | junior | [Why build this first] |
| 2 | [skill-name] | senior | [Why next] |
| ... | ... | ... | ... |
```

**Model tier assignment rules** (from `plugin-blueprint.md` Section 11a):
- **junior** (Haiku): scaffolding, template copying, simple file creation, schema writes, formatting. Output structure is predetermined.
- **senior** (Sonnet): skill implementation, command logic, content generation, integration. **Default tier** — use when in doubt.
- **principal** (Opus): architecture decisions, QA review, cross-plugin verification, brand coherence, complex planning.

**Assignment heuristics:**
- junior: difficulty=low AND risk=low AND task is primarily file creation/copying
- senior: difficulty=medium OR task requires content generation/reasoning (DEFAULT)
- principal: difficulty=high OR risk=high OR task is QA/verification OR task is cross-cutting

After the build order table, add a tier distribution summary:

```markdown
### Model Tier Distribution

| Tier | Count | Tasks |
|------|-------|-------|
| Junior (Haiku) | N | scaffolding, templates, ... |
| Senior (Sonnet) | N | implementation, commands, ... |
| Principal (Opus) | N | QA, architecture, ... |
```

Rules for build order:
- Skills that define the schema or core data model come FIRST
- Interactive skills that gather user input come before autonomous skills that process it
- Skills with no dependencies can be built in any order — pick the one that exercises the most code paths first
- The final compilation/export skill is ALWAYS last
- Every task MUST have a `model_tier` — no omissions

---

### Step 3 — Generate Domain Addendum

Write `docs/[plugin-name]-addendum.md` with these sections:

#### Section a) Domain Knowledge

Research the domain using available knowledge. Write a reference guide that Claude Code needs to do the work well.

Structure:
```markdown
# [Plugin Name] — Domain Addendum

## Domain Knowledge

### [Topic 1 — e.g., "How Search Engines Rank Pages"]
[2-4 paragraphs of relevant domain knowledge]

### [Topic 2 — e.g., "Keyword Research Methodology"]
[2-4 paragraphs]

### [Topic N]
[Continue for all relevant topics]
```

The depth should match the plugin's complexity. A simple plugin might need 2 topics. A complex one (like SEO or website-builder) might need 6-8.

#### Section b) Quality Standards

Domain-specific quality criteria that every skill must enforce:

```markdown
## Quality Standards

| Standard | Criteria | How to Verify |
|----------|----------|---------------|
| [Standard 1] | [Specific criteria] | [How to check] |
| [Standard 2] | [Specific criteria] | [How to check] |
```

These come from the design.yml `verification_profile.qa_focus` items, expanded with industry context.

#### Section c) Tools and Dependencies

```markdown
## Tools and Dependencies

| Tool | Purpose | Required/Optional | Install Command |
|------|---------|-------------------|-----------------|
| [tool] | [what it's used for] | Required | [install command] |
```

Include both runtime dependencies (npm packages, CLI tools) and development dependencies (testing frameworks, linters).

#### Section d) Validation Criteria

```markdown
## Validation Criteria

| Metric | Target | Industry Benchmark | Tool |
|--------|--------|-------------------|------|
| [metric] | [target value] | [what's standard] | [how to measure] |
```

Quantitative where possible. Reference industry standards.

#### Section e) Common Mistakes

```markdown
## Common Mistakes to Avoid

1. **[Mistake]** — [Why it's wrong]. Instead: [What to do].
2. **[Mistake]** — [Why it's wrong]. Instead: [What to do].
```

At least 5 mistakes. These should be domain-specific, not generic programming mistakes.

---

### Step 4 — Generate Asset Manifest (if applicable)

Check `design.yml.output.assets`. If the array is non-empty, write `docs/[plugin-name]-asset-manifest.md`.

**If no assets are defined, skip this step entirely.** Do not create an empty manifest.

Structure:

```markdown
# [Plugin Name] — Asset Manifest

## Overview

The /[main-command] produces all assets below. They are saved to:
[directory tree showing the file layout]

## Asset List

### [Category 1 — e.g., "Generated Code Files"]

| File | Format | Dimensions/Size | Generation Method | Dependencies |
|------|--------|----------------|-------------------|--------------|
| [path/filename] | [ext] | [if applicable] | [how it's generated] | [tools needed] |

### [Category 2]
[continue for each category]

## Generation Scripts

### [Script 1]
Purpose: [what it does]
Command: [how to run it]
Input: [what it reads]
Output: [what it produces]
```

**Reference:** Study `docs/brand-asset-manifest.md` for the expected level of detail.

---

### Step 5 — Register Verification Profile

Read `packages/task-planner/resources/verification-registry.yml`.

#### 5a) Check for new verification types

Compare `design.yml.verification_profile.after_each_wave` and `design.yml.verification_profile.final` against the existing types in the registry.

If any type is NOT already registered:

```yaml
[new_type_name]:
  description: "[What it checks]"
  registered_by: "[plugin-name]"
  checks:
    - "[Specific check 1]"
    - "[Specific check 2]"
  tool: "shell_command" | "yaml_validator" | "schema_validator" | "[custom]"
```

#### 5b) Register the verification profile

Append to `verification-registry.yml`:

```yaml
# ──────────────────────────────────────────────
# Registered by: [plugin-name]
# ──────────────────────────────────────────────
[plugin-name]_profile:
  after_each_wave:
    - [type from design.yml]
  final:
    - [type from design.yml]
  qa_frequency: "[from design.yml]"
  qa_focus:
    - "[from design.yml]"
    - "[from design.yml]"
```

---

### Step 6 — Cross-Reference Validation

Before finalizing, validate consistency across all generated documents:

1. **Skills match:** Every skill in design.yml appears in the implementation plan AND has a build order entry
2. **Commands match:** Every command in design.yml appears in the implementation plan with full expansion
3. **Schema covers output:** The YAML schema has sections for every `output.document.sections` entry in design.yml
4. **Verification aligns:** Every skill's checkpoint type exists in verification-registry.yml
5. **Brand sections match:** If `needs_brand` is true, every skill that appears in `brand_sections_needed` has those sections listed in its "Inputs" in the implementation plan
6. **Dependencies consistent:** The dependency chain in the implementation plan matches the `depends_on` arrays in design.yml
7. **Wave plan matches:** The build order in the implementation plan is consistent with the wave plan in design.yml

If any inconsistency is found, fix it in the generated documents before writing them.

---

## Checkpoint

```
type: data_validation
required_checks:
  - Implementation plan contains all 6 sections:
    overview, architecture, YAML schema, commands, skills, build order
  - Build order table includes a model_tier column with valid values (junior|senior|principal) for every task
  - A "Model Tier Distribution" summary section follows the build order table
  - YAML schema has at least 5 top-level sections, each with at least 3 typed fields
  - Every command in design.yml has a corresponding expanded section in the plan
    with purpose, input, execution strategy, output, and recovery
  - Every skill in the plan has at least 5 concrete process steps
    (not vague — each step names specific files, sections, or actions)
  - Every skill checkpoint has measurable checks
    (quantities, thresholds, existence checks — not "looks good")
  - Domain addendum has all 5 sections:
    domain knowledge, quality standards, tools, validation criteria, common mistakes
  - Domain addendum has at least 2 domain knowledge topics with 2+ paragraphs each
  - Domain addendum has at least 5 common mistakes listed
  - If design.yml defines assets: asset manifest exists with file list and generation methods
  - Verification profile is registered in verification-registry.yml
  - Cross-reference validation passes (Step 6 — all 7 consistency checks)
on_fail: >
  Report which checks failed. For missing sections, generate them.
  For inconsistencies, identify the source of truth (design.yml) and fix
  the generated documents. Re-run validation after fixes.
on_pass: >
  Update state.yml: mark plugin-spec-generator as completed.
  Report: "Specs generated. Ready for Step 19 — execution guide generation."
```

## Quality Rules

1. **design.yml is the source of truth.** If the spec contradicts design.yml, the spec is wrong.
2. **No vague process steps.** "Process the data" is not a step. "Read keywords from seo-strategy.yml section `keywords.primary` and filter by search_volume > 100" is a step.
3. **No vague checks.** "Output looks good" is not a check. "At least 5 keywords per category, each with search_volume and difficulty fields populated" is a check.
4. **Schema fields are typed.** Every field in the YAML schema must have a type annotation. Every enum must list all valid values.
5. **Match the reference quality.** The generated specs should match the depth and specificity of `docs/implementation-plan-v2.md` and `docs/addendum-assets-and-accessibility.md`.
6. **Domain knowledge is actionable.** The addendum teaches Claude Code what it needs to know — not a textbook, but practical guidance for building this specific plugin.
7. **Asset manifests are exhaustive.** If assets are defined, every single file must be listed with exact path, format, dimensions (where applicable), and generation method. No "etc." or "similar files."
8. **Cross-references are validated.** Skills, commands, verification types, and brand sections must be consistent across design.yml and all generated documents.
