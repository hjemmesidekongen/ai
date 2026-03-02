# Plugin Execution Guide Generator — Process Detail

## Prerequisites

Before running this skill, read:
1. `plugins/[plugin-name]/design.yml` — the approved design
2. `docs/[plugin-name]-implementation-plan.md` — full spec with skills, commands, schema, build order
3. `docs/[plugin-name]-addendum.md` — domain knowledge, quality standards, tools
4. `docs/[plugin-name]-asset-manifest.md` — asset details (only if design.yml defines assets)
5. `docs/ecosystem-strategy.md` — Section 4 (Skill Prompt Template)
6. `plugins/task-planner/resources/plugin-blueprint.md` — Sections 3 (Commands) and 4 (Skills)

## Process

### Step 1 — Collect Inputs

Read all prerequisite files. Extract and index the following data structures:

```
From design.yml:
  - name                      → [plugin-name]
  - description                → [one-sentence description]
  - needs_brand                → boolean
  - brand_sections_needed      → { skill → [sections] } (if needs_brand)
  - commands[]                 → array of command definitions
  - skills[]                   → array of skill definitions with depends_on, reads, writes, checkpoint
  - output.yaml.name           → [yaml filename]
  - output.yaml.storage_path   → [storage directory]
  - output.document.format     → md | docx | both
  - output.assets[]            → array of asset types (may be empty)
  - wave_plan[]                → wave groupings

From implementation plan:
  - Build order table          → ordered list of skills with rationale
  - Skills section             → expanded skill specs (process steps, inputs, outputs, checkpoints)
  - Commands section           → expanded command specs (input, execution strategy, output, recovery)
  - YAML schema                → full schema for the output file

From addendum:
  - Domain knowledge topics    → list of topics with content summaries
  - Quality standards          → table of standards with criteria
  - Common mistakes            → numbered list of mistakes

From asset manifest (if exists):
  - Asset list                 → files with formats, dimensions, generation methods
  - Generation scripts         → commands and dependencies
```

If any prerequisite file is missing (except asset manifest for plugins without assets), STOP and report the issue.

---

### Step 2 — Determine Step Numbering

Map every buildable unit to a numbered step. The numbering follows this fixed sequence:

```
Step 1:  Plugin scaffold + plugin.json
Step 2:  YAML schema + document templates
Step 3:  Skill — [first skill in build order]
Step 4:  Skill — [second skill in build order]
...
Step N:  Skill — [last skill in build order]
Step N+1: Command — [first command]
Step N+2: Command — [second command]
...
Step M:  End-to-end test
```

Rules:
- Skills are numbered in BUILD ORDER (from the implementation plan's Build Order table), not wave order
- Commands come after all skills are built
- The end-to-end test is always the final step
- If the plugin has assets, the skill that generates them has additional file-generation instructions in its prompt

Count the total steps and record the mapping:
```
step_number → { type: "scaffold" | "schema" | "skill" | "command" | "test", name: "..." }
```

---

### Step 3 — Generate Per-Skill Prompts

For EACH skill in build order, generate a complete, self-contained prompt. Every prompt follows this exact structure:

```markdown
### Step [N]: Skill — [skill-name]

> **What:** [one-sentence purpose from implementation plan]
> **Interactive:** [yes/no]
> **Depends on:** [list of skills that must be built first]
> **Model tier:** [junior|senior|principal] ([Haiku|Sonnet|Opus])

**Prompt:**

---

Read `docs/[plugin-name]-implementation-plan.md` (the "[skill-name]" section under Skills).
[If brand-dependent:] Also read the brand-reference.yml schema in `docs/ecosystem-strategy.md` Section 6 to know what brand data is available.
[If domain-specific knowledge needed:] Read `docs/[plugin-name]-addendum.md` ([specific section name]).
[If reads another skill's output:] Read the "[other-skill-name]" section in the implementation plan to understand the data this skill consumes.

Create `plugins/[plugin-name]/skills/[skill-name]/SKILL.md`
[If skill exceeds 80 lines:] Also create `plugins/[plugin-name]/skills/[skill-name]/references/process.md` with the detailed execution steps. The SKILL.md body must end with: "Before executing, read `references/process.md` for detailed instructions, output formats, and edge case handling."

The SKILL.md must include these context engineering sections:

**Findings Persistence** (add before the main process):
```
During [skill activity], write intermediate discoveries to the findings file:

~/.claude/[domain]/[project-name]/findings.md

**What to save:** [skill-specific items — e.g., user responses, research results, generation rationale]

**2-Action Rule:** After every 2 research operations ([skill-specific actions]), IMMEDIATELY save key findings to findings.md before continuing.

**Format:**
[Skill-specific markdown template with relevant heading structure]

This file persists across /compact and session restarts. If context is lost, findings survive.
```

**Error Logging** (add after findings persistence):
```
When errors occur during [skill activity] (validation failures, checkpoint failures, unexpected issues):

1. Log the error to state.yml errors array immediately
2. Before retrying any approach, check errors for previous failed attempts
3. Never repeat a failed approach — mutate strategy instead
4. The verification-runner logs checkpoint failures automatically
```

This skill:
1. [Concrete step — e.g., "Read `[output-yaml].yml` section `meta` to get project name and verify the file exists"]
2. [Concrete step — e.g., "Read `[output-yaml].yml` section `[section]` to get [specific fields]"]
3. [If interactive: "Ask the user [specific question] — one question at a time, offer examples from the addendum's domain knowledge"]
4. [Processing step — e.g., "Generate [N] items for the `[section].[field]` array, each with fields: name (string), description (string, >20 words), priority (enum: high|medium|low)"]
5. [Validation step — e.g., "Validate that every generated item has all required fields populated and descriptions exceed 20 words"]
6. [Quality step — e.g., "Cross-reference against [addendum quality standard] to ensure [specific criterion]"]
7. [Write step — e.g., "Write the completed data to `[output-yaml].yml` section `[section-name]`"]
8. [Checkpoint step — e.g., "Run checkpoint validation: verify all required checks pass"]

[If brand data needed:]
Brand data sections needed: [exact section names from brand_sections_needed]

[If generates files:]
Files generated:
- [exact/path/filename.ext] — [what it is, format, dimensions if applicable]
- [exact/path/filename.ext] — [what it is]

Output: writes `[section-name]` section of `[output-yaml].yml`
[If also writes to document:] Also writes `[section-name]` section of `[document-name].md`

Checkpoint type: [type from design.yml skill checkpoint]
Required checks:
- [Measurable check 1 — copied from implementation plan, with quantities/thresholds]
- [Measurable check 2]
- [Measurable check 3]

Commit Protocol (Subagent Mode):
When running as a subagent (dispatched via Task()):
1. Stage only files in your ownership list
2. Commit with message: `[plan_name]: [skill-name] [[task_id]]`
3. Include commit SHA in your task_complete report
When running inline: commit after verification passes.

Verification (Two-Stage):
Stage 1 — Spec Compliance (Haiku):
  Run spec-compliance-reviewer against this skill's outputs.
  Checks file existence, schema presence, non-empty content, file ownership, state consistency.
  If FAIL: fix structural issues before proceeding. Do NOT run Stage 2.
Stage 2 — Quality Review (Opus):
  Only runs after Stage 1 passes.
  Run qa-reviewer against this skill's outputs for content quality, brand coherence, and completeness.
  If FAIL: address quality issues. If PASS_WITH_NOTES: review notes, decide whether to address.

Completion Gate (Code Tasks Only):
If this skill produces code files (.ts, .js, .py, etc.), the worker agent runs
a completion gate before committing: build, lint, and test commands from
project_context. Content-only skills (YAML, Markdown, SVG) skip the gate.
The orchestrator provides project_context in the dispatch template.

Then update CLAUDE.md: check off this step in the Progress section and set "Next step" to the following step. Commit everything.

---
```

**Expansion rules for prompts:**

1. **Process steps are NEVER vague.** Every step must name the specific file, section, action, question, or quantity.
2. **Steps from the implementation plan are the starting point, not the final form.** Add exact file paths, field names from the YAML schema, measurable quantities, and cross-references.
3. **Brand data is explicit.** List exact section names; reference the brand-reference.yml schema location.
4. **Checkpoints are copied verbatim** from the implementation plan's skill section, then made measurable if vague. Minimum 2 checks per skill, aim for 3-5.
5. **No placeholder patterns.** Each prompt is fully self-contained.
6. **Model tier is assigned.** Use `model_tier` from task plan if provided, otherwise: junior (Haiku) for scaffolding/template-copying; senior (Sonnet) for interview/research/content generation (DEFAULT); principal (Opus) for QA/verification/architecture. See `plugin-blueprint.md` Section 11a. If the skill is domain-specialist work (SEO, DevOps, security, design), consider model_tier: "self" — the worker self-assesses complexity at Haiku cost.
7. **Progressive disclosure is respected.** If a skill will need more than 80 lines in its SKILL.md, the prompt instructs creation of a `references/process.md`. See `plugin-blueprint.md` Section 4.
8. **Context engineering is mandatory.** Every skill prompt MUST include findings persistence (path, what to save, 2-Action Rule, format template) and error logging (4 standard rules) placed BEFORE the main process steps.
9. **Two-stage verification is mandatory.** Every skill prompt MUST include the two-stage verification block after the checkpoint section: Stage 1 (spec-compliance-reviewer, Haiku) gates Stage 2 (qa-reviewer, Opus). Stage 1 failure skips Stage 2 and marks `failed_spec`. Stage 2 failure marks `failed_quality`.
10. **Positive framing is used.** Instructions use "advance only after checks pass" instead of "do not advance until checks pass". See plugin-blueprint.md Section 4.

---

### Step 4 — Generate Scaffold Prompt

Generate the Step 1 prompt for scaffolding:

```markdown
### Step 1: Plugin scaffold + plugin.json

**Prompt:**

---

Read `plugins/task-planner/resources/plugin-blueprint.md` (Section 2: Required Plugin Structure).

Create the plugin scaffold:

1. Create directory structure:
   ```
   plugins/[plugin-name]/
   ├── .claude-plugin/
   │   └── plugin.json
   ├── commands/
   ├── skills/
   ├── agents/
   ├── resources/
   │   ├── templates/
   │   └── examples/
   ├── scripts/
   └── README.md
   ```

2. Write `plugins/[plugin-name]/.claude-plugin/plugin.json` (Claude Code schema only):
   ```json
   {
     "name": "[plugin-name]",
     "version": "1.0.0",
     "description": "[description from design.yml]",
     "hooks": {
       "PreToolUse": [{ "matcher": "Write|Edit|Bash", "hooks": [{ "type": "command", "command": "cat state.yml 2>/dev/null | head -20 || true" }] }],
       "PostToolUse": [{ "matcher": "Write|Edit", "hooks": [{ "type": "command", "command": "echo '[plugin-name] File updated. If this completes a phase, update state.yml.'" }] }],
       "SessionStart": [{ "hooks": [{ "type": "command", "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/session-recovery.sh" }] }],
       "Stop": [{ "hooks": [{ "type": "command", "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-wave-complete.sh" }] }]
     }
   }
   ```

   Write `plugins/[plugin-name]/.claude-plugin/ecosystem.json` (ecosystem metadata):
   ```json
   {
     "commands": [list all command names from design.yml],
     "skills": [list all skill names from design.yml],
     "agents": [],
     "dependencies": ["task-planner"[, "brand-guideline" if needs_brand]]
   }
   ```

3. Create `plugins/[plugin-name]/scripts/session-recovery.sh` and `plugins/[plugin-name]/scripts/check-wave-complete.sh` (see plugin-blueprint.md Section 13 for templates). Make both executable with `chmod +x`.

4. Write `plugins/[plugin-name]/README.md` with:
   - Plugin name and description
   - Installation: "This plugin is part of the claude-plugins ecosystem"
   - Usage: list all commands with one-line descriptions
   - Dependencies: task-planner[, brand-guideline if needs_brand]

Checkpoint type: file_validation
Required checks:
- plugin.json exists and is valid JSON
- plugin.json contains hooks (PreToolUse, PostToolUse, SessionStart, Stop)
- All directories exist (commands/, skills/, agents/, resources/templates/, resources/examples/, scripts/)
- scripts/session-recovery.sh exists and is executable
- scripts/check-wave-complete.sh exists and is executable
- README.md exists and lists all commands
- ecosystem.json exists and is valid JSON
- ecosystem.json dependencies includes "task-planner"
[If needs_brand:] - ecosystem.json dependencies includes "brand-guideline"

Then update CLAUDE.md: check off this step in the Progress section and set "Next step" to the following step. Commit everything.

---
```

---

### Step 5 — Generate Schema + Templates Prompt

Generate the Step 2 prompt for creating the YAML schema and document templates:

```markdown
### Step 2: YAML schema + document templates

**Prompt:**

---

Read `docs/[plugin-name]-implementation-plan.md` (the "YAML Schema" section).
Also read `plugins/brand-guideline/resources/templates/brand-reference-schema.yml` as a reference for schema structure.

Create `plugins/[plugin-name]/resources/templates/[yaml-name]-schema.yml`:
[Paste the COMPLETE YAML schema from the implementation plan — every field, every type, every enum value]

Create `plugins/[plugin-name]/resources/templates/[document-name]-template.md`:
[Generate a markdown template with all document sections as headings, with placeholder content describing what goes in each section]

[If format includes docx:]
Create `plugins/[plugin-name]/resources/templates/[document-name]-docx-styles.yml`:
[Generate document styling config following the pattern in `plugins/brand-guideline/resources/templates/brand-manual-template-docx-styles.yml`]

[If design.yml defines a state schema:]
Create `plugins/[plugin-name]/resources/templates/state-schema.yml`:
[Generate state.yml schema following the pattern in `plugins/brand-guideline/resources/templates/state-schema.yml`]

Checkpoint type: file_validation
Required checks:
- Schema file exists and contains at least 5 top-level sections
- Every field in the schema has a type annotation
- Template file exists and has a heading for every document section from design.yml
[If docx:] - DOCX styles file exists with page, headings, body, tables, and footer sections
[If state schema:] - State schema file exists

Then update CLAUDE.md: check off this step in the Progress section and set "Next step" to the following step. Commit everything.

---
```

---

### Step 6 — Generate Command Prompts

For EACH command in design.yml, generate a complete prompt:

```markdown
### Step [N]: Command — /[plugin]:[command-name]

**Prompt:**

---

Read `docs/[plugin-name]-implementation-plan.md` (the "/[plugin]:[command-name]" section under Commands).
Read `plugins/task-planner/resources/plugin-blueprint.md` (Section 3: How Commands Work).

Create `plugins/[plugin-name]/commands/[command-name].md`

This command:
1. [Purpose — from implementation plan]
2. [Prerequisites — what must exist]
3. [Input — arguments, flags, interactive prompts]
4. [Execution strategy — which skills run in which order, how the planner is invoked]
5. [Output — what files are produced and where]
6. [Recovery — how to resume if interrupted]

The command file must follow this structure:
- Purpose section
- Prerequisites section
- Input section (arguments, flags, interactive prompts)
- Execution Strategy section with interactive phases and planned phases
- Output section listing all produced files
- Recovery section referencing state.yml

[If the command uses the task-planner:]
The Execution Strategy must include a /plan:create call with:
- Tasks: [list skills with dependencies from design.yml]
- Verification profile: [profile name from design.yml]
- QA frequency: [from design.yml]

Checkpoint type: data_validation
Required checks:
- Command file exists at the correct path
- Contains all 6 sections: purpose, prerequisites, input, execution strategy, output, recovery
- Execution strategy references the correct skills in the correct order
[If uses planner:] - /plan:create call specifies verification profile and QA frequency

Then update CLAUDE.md: check off this step in the Progress section and set "Next step" to the following step. Commit everything.

---
```

---

### Step 7 — Generate End-to-End Test Prompt

Generate the final step prompt:

```markdown
### Step [M]: End-to-end test

**Prompt:**

---

Dry-run test of /[plugin]:[main-command] with a fictional project.

1. Create a test scenario:
   - Project name: "test-[plugin-name]"
   - [If needs brand:] Use an existing brand or create a minimal test brand-reference.yml
   - [Plugin-specific test inputs]

2. Walk through every phase:
   - [For each skill in wave order:]
     - Run skill [skill-name]
     - Show the data written to [output-yaml].yml section [section-name]
     - Show checkpoint result (pass/fail with details)
   - [For each wave:]
     - Show state.yml after wave completion
     - Show verification results

3. Verify final output:
   - [output-yaml].yml exists and validates against schema
   - [document-name].[format] exists and has all sections
   [If assets:] - All assets listed in the manifest exist
   - state.yml shows all phases completed
   - QA report generated with verdict

4. Test recovery:
   - Simulate interruption after wave [N]
   - Resume via /plan:resume
   - Verify it picks up from the correct wave

Checkpoint type: manual_approval
Required checks:
- All skills execute without errors
- Final YAML output validates against schema (at least [N] top-level sections populated)
- Final document has all [N] sections with content
- State.yml shows all phases as "completed"
- Recovery test successfully resumes from interrupted wave
[If assets:] - All [N] assets generated at correct paths

Then update CLAUDE.md: check off this step in the Progress section and set "Next step" to the following step. Commit everything.

---
```

---

### Step 8 — Generate CLAUDE.md Progress Checklist

Create the progress checklist that will be added to CLAUDE.md when the plugin is scaffolded:

```markdown
### Part [N]: [Plugin Name] (in progress)
- [ ] Step 1: [plugin-name] scaffold + plugin.json
- [ ] Step 2: YAML schema + document templates
[For each skill in build order:]
- [ ] Step [N]: Skill — [skill-name]
[For each command:]
- [ ] Step [N]: Command — /[plugin]:[command-name]
- [ ] Step [M]: End-to-end test

Next step: Step 1 — [plugin-name] scaffold
```

---

### Step 9 — Assemble the Execution Guide

Write `docs/[plugin-name]-execution-guide.md` with this structure:

```markdown
# Execution Guide: [Plugin Name]

## Reality Check

Building [plugin-name] is a [N]-step process. Each step builds one skill or
command, with a checkpoint at the end. You'll need approximately [estimate]
sessions in Claude Code, doing one skill per session with `/compact` between.

**Rules:**
- One skill per Claude Code session
- `/compact` between sessions
- CLAUDE.md auto-updates after every step
- Git commit after every step
- Specs live in docs/ — Claude reads files, don't paste content
- If a step fails its checkpoint, fix it before moving on

## Prerequisites

Before starting, these spec documents must exist in docs/:
- `[plugin-name]-implementation-plan.md` — generated by plugin-spec-generator
- `[plugin-name]-addendum.md` — generated by plugin-spec-generator
[If assets:] - `[plugin-name]-asset-manifest.md` — generated by plugin-spec-generator

## Steps

[Step 1: Scaffold prompt — from Step 4 above]
[Step 2: Schema prompt — from Step 5 above]
[Steps 3-N: Skill prompts — from Step 3 above, in build order]
[Steps N+1 to M-1: Command prompts — from Step 6 above]
[Step M: End-to-end test prompt — from Step 7 above]

## After Each Skill

After completing each step:
1. Verify the checkpoint passes
2. CLAUDE.md is updated (step checked off, "Next step" advanced)
3. Everything is committed to git
4. Run `/compact` to clear context before the next step

## CLAUDE.md Progress Checklist

Add this to the Progress section of CLAUDE.md:

[Checklist from Step 8 above]

## Timeline

| Step | Name | Type | Model Tier | Estimated Effort |
|------|------|------|------------|-----------------|
| 1 | Scaffold + plugin.json | Setup | junior | Quick (5 min) |
| 2 | Schema + templates | Setup | junior | Medium (15 min) |
[For each skill:]
| [N] | [skill-name] | Skill ([interactive/autonomous]) | [junior/senior/principal] | [estimate based on complexity] |
[For each command:]
| [N] | /[plugin]:[command] | Command | senior | Medium (15 min) |
| [M] | End-to-end test | Test | principal | Medium-Long (20-30 min) |

**Total estimated effort:** [sum] across [count] sessions

## Tips

1. **Read the spec, don't memorize it.** Every prompt tells you which file and section to read.
   Claude Code reads the file — you don't need to paste content.

2. **One skill per session.** Context degrades over long sessions. Build one skill,
   commit, `/compact`, start fresh.

3. **Checkpoints are gates.** If a checkpoint fails, the skill is not done.
   Fix the issues before moving to the next step.

4. **Build order matters.** Skills are ordered so each one can use the previous
   skill's output. Don't skip ahead.

5. **Interactive skills need the user.** If a skill is marked interactive,
   the user must be present to answer questions. Plan accordingly.

6. **Brand data is loaded, not asked.** If the plugin uses brand data,
   the brand-context-loader handles finding and loading it.
   Skills declare what sections they need — the loader provides them.

7. **Recovery works.** If a session crashes, check state.yml.
   It records exactly where you left off. Use `/plan:resume` to continue.
```

---

### Step 10 — Quality Validation

Before writing the final file, validate the generated execution guide:

1. **Completeness check:**
   - Count skills in design.yml → count skill prompts in guide → must match exactly
   - Count commands in design.yml → count command prompts in guide → must match exactly
   - Scaffold prompt exists (Step 1)
   - Schema prompt exists (Step 2)
   - End-to-end test prompt exists (final step)

2. **Prompt quality check (for EVERY skill prompt):**
   - Contains spec file reference with section name
   - Contains `Create plugins/[plugin-name]/skills/[skill-name]/SKILL.md` instruction
   - Contains model tier recommendation (junior, senior, or principal) in the header
   - Contains findings persistence instructions (findings.md path, 2-Action Rule, format template)
   - Contains error logging instructions (4 standard rules)
   - Contains numbered process steps (at least 5)
   - Contains checkpoint type and at least 2 measurable checks
   - Contains CLAUDE.md update instruction
   - If interactive: contains "one question at a time, offer examples"
   - If brand-dependent: contains brand data sections list
   - If reads previous skill output: names exact fields
   - If skill will exceed 80 lines: contains `references/process.md` creation instruction
   - Contains two-stage verification block (Stage 1 spec compliance + Stage 2 quality review)
   - Contains commit protocol section (subagent mode: stage owned files, commit with plan name, report SHA)

3. **Exhaustiveness check:**
   - Search the entire guide for: "etc.", "similar", "and so on", "repeat this pattern", "same as above", "follow the same structure"
   - If ANY of these phrases are found, expand them into concrete content

4. **Timeline check:**
   - Timeline table has one row per step
   - Row count matches total step count
   - Effort estimates are present for every row
   - Total is computed

5. **CLAUDE.md checklist check:**
   - Checklist has one checkbox per step
   - Step names match the guide section headers
   - "Next step" line is present

If any check fails, fix the issue in the guide before writing.

---

## Checkpoint

```
type: data_validation
required_checks:
  - Every skill from design.yml has its own dedicated prompt section
    (no "repeat this pattern" or "same as above")
  - Every prompt contains all 11 required elements:
    spec file reference, create instruction, model tier recommendation,
    findings persistence section, error logging section, numbered process steps,
    checkpoint with type and checks, commit protocol (subagent mode),
    two-stage verification block, output declaration, CLAUDE.md update line
  - Every skill prompt has at least 5 numbered process steps
    that reference specific files and sections (not vague)
  - Every checkpoint has at least 2 measurable checks
    (quantities, thresholds, existence checks — not "looks good")
  - Scaffold prompt (Step 1) generates correct directory structure
    and plugin.json and ecosystem.json with accurate dependencies
  - Schema prompt (Step 2) references the full YAML schema
    from the implementation plan
  - Command prompts reference the correct skills and execution order
  - End-to-end test prompt covers all skills, verification, and recovery
  - Timeline table is present with one row per step and effort estimates
  - CLAUDE.md progress checklist is generated with correct step count
  - No instances of "etc.", "similar", "and so on", "repeat this pattern",
    "same as above", or "follow the same structure" anywhere in the guide
on_fail: >
  Report which checks failed. For missing prompts, generate them from
  the implementation plan. For vague steps, expand with specific file paths,
  section names, and measurable quantities. For forbidden phrases, replace
  with concrete content. Re-run validation after fixes.
on_pass: >
  Update state.yml: mark plugin-execution-guide-generator as completed.
  Report: "Execution guide generated. Ready for Step 20 — plugin scaffolder."
```

## Quality Rules

1. **One full prompt per skill. No exceptions.** Every skill gets a complete, self-contained prompt. "Repeat this pattern" is forbidden — write it out every time.
2. **Prompts reference specs, not content.** Tell Claude Code to READ the file. Don't paste the spec content into the prompt.
3. **Process steps are concrete.** Every step names specific files, sections, and fields. "Process the data" is not a step.
4. **Checks are measurable.** "Output looks good" is not a check. Quantities, thresholds, existence checks only.
5. **Interactive skills are explicit.** If a skill asks the user questions, the prompt must say "one question at a time, offer examples" and specify what questions are asked.
6. **Brand data is declared.** If a skill needs brand data, the prompt lists exact section names from brand-reference.yml.
7. **File paths are resolved.** All `[plugin-name]` placeholders are replaced with the actual plugin name. All file paths are complete.
8. **Build order is respected.** Skills are ordered by the implementation plan's Build Order table. Dependencies are satisfied before dependents.
9. **The guide is self-contained.** Someone with access to the repo and the spec documents should be able to follow the guide from Step 1 to completion without any additional context.
10. **No forward references between prompts.** Each prompt stands alone. It may reference spec documents, but never another prompt in the guide.
11. **Context engineering is baked in.** Every skill prompt includes findings persistence (with 2-Action Rule) and error logging sections. The scaffold prompt generates hooks in plugin.json and hook scripts in scripts/. No plugin should ship without these patterns.
12. **Positive framing in instructions.** Generated skill prompts use positive instructions ("advance only after checks pass") rather than negative ones ("do not advance until checks pass"). See plugin-blueprint.md Section 4.
