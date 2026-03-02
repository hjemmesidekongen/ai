---
name: plugin-create
command: "/plugin:create"
description: "(plugin) Design, spec, and scaffold a new plugin through the full creation pipeline"
arguments:
  - name: plugin-name
    type: string
    required: true
    description: "Kebab-case name for the new plugin (e.g., seo-plugin, website-builder)"
  - name: from-design
    type: string
    required: false
    description: "Path to an existing design.yml — skips the interactive design interview"
---

# /plugin:create

Orchestrates the entire plugin creation pipeline: design interview, spec generation, execution guide, and scaffold. After this command completes, the plugin exists on disk with full documentation and is ready for `/plugin:build`.

This command does NOT use the task-planner for wave execution — it runs sequentially because each step depends on the previous step's output. But the plugins it creates WILL use the task-planner when their commands run.

## Usage

```
/plugin:create seo-plugin
/plugin:create website-builder
/plugin:create content-engine --from-design docs/content-engine-design.yml
```

## Prerequisites

Before running, read:
1. `plugins/task-planner/resources/plugin-blueprint.md` — Section 9 (New Plugin Creation)
2. `docs/ecosystem-strategy.md` — Section 7 (Workflow: Creating a New Plugin)

## Execution Steps

### Step 1: Validate Plugin Name

Check the provided `plugin-name`:

1. **Kebab-case:** Must match `/^[a-z][a-z0-9]*(-[a-z0-9]+)*$/`. If not, suggest a corrected name and ask the user to confirm.
2. **No conflicts:** Check that `plugins/[plugin-name]/` does not already exist. If it does, report the conflict and ask the user to choose a different name or confirm they want to continue (which would add to the existing directory).
3. **Reserved names:** Must not be `task-planner` or `brand-guideline` — these are built-in plugins that already exist.

If validation fails, stop and report the issue. Do not proceed with an invalid name.

---

### Step 2: Create Plugin Directory

```bash
mkdir -p plugins/[plugin-name]
```

This is the only directory created at this point. The scaffolder skill (Step 6) creates the full internal structure.

---

### Step 3: Run Design Interview (or Load Existing Design)

**If `--from-design` is provided:**

1. Read the file at the provided path
2. Validate it has all required fields (see plugin-design-interview SKILL.md for the schema)
3. Validate `status` is `approved`
4. Copy it to `plugins/[plugin-name]/design.yml` (if not already there)
5. Show the user a summary of the loaded design:

```
Loaded existing design from [path]:
  Name: [name]
  Description: [description]
  Commands: [count] — [list]
  Skills: [count] — [list]
  Brand data: [yes/no]
  Waves: [count]
```

**If `--from-design` is NOT provided:**

1. Call the `plugin-design-interview` skill
   - Read: `plugins/task-planner/skills/plugin-design-interview/SKILL.md`
   - Follow its 10-step process (Q1–Q8, produce design, user review)
   - The skill writes `plugins/[plugin-name]/design.yml`
2. After the interview completes, confirm with the user before proceeding:

```
Design interview complete. design.yml written to plugins/[plugin-name]/design.yml.

Ready to generate specs, execution guide, and scaffold?
(This will create ~4 documents in docs/ and the plugin directory structure.)
```

Wait for explicit confirmation. If the user wants to stop here and review the design first, respect that.

---

### Step 4: Generate Specs

Call the `plugin-spec-generator` skill:
- Read: `plugins/task-planner/skills/plugin-spec-generator/SKILL.md`
- Follow its 6-step process

This produces:
- `docs/[plugin-name]-implementation-plan.md` — full implementation specification
- `docs/[plugin-name]-addendum.md` — domain knowledge, quality standards, tools
- `docs/[plugin-name]-asset-manifest.md` — only if design.yml defines assets
- Updated `plugins/task-planner/resources/verification-registry.yml` — new verification profile

After completion, show the user a summary:

```
Specs generated:
  - docs/[name]-implementation-plan.md
    YAML schema: [N] sections, [M] total fields
    Commands: [N] expanded
    Skills: [N] with [total] process steps
  - docs/[name]-addendum.md
    Domain topics: [N]
    Quality standards: [N]
    Common mistakes: [N]
  [If assets:]
  - docs/[name]-asset-manifest.md
    Assets: [N] files across [M] categories
  - Verification profile registered: [profile-name]
```

---

### Step 5: Generate Execution Guide

Call the `plugin-execution-guide-generator` skill:
- Read: `plugins/task-planner/skills/plugin-execution-guide-generator/SKILL.md`
- Follow its process

This produces:
- `docs/[plugin-name]-execution-guide.md` — step-by-step build guide with one complete prompt per skill

After completion, show the user:

```
Execution guide generated:
  - docs/[name]-execution-guide.md
    Total steps: [N]
    Estimated build time: [from guide]
    First skill to build: [name]
```

---

### Step 6: Scaffold the Plugin

Call the `plugin-scaffolder` skill:
- Read: `plugins/task-planner/skills/plugin-scaffolder/SKILL.md`
- Follow its 7-step process

This creates:
- `plugins/[plugin-name]/.claude-plugin/plugin.json`
- `plugins/[plugin-name]/commands/` (empty)
- `plugins/[plugin-name]/skills/` (empty)
- `plugins/[plugin-name]/agents/` (empty, only if design.yml defines agents)
- `plugins/[plugin-name]/resources/templates/` (empty)
- `plugins/[plugin-name]/resources/examples/` (empty)
- `plugins/[plugin-name]/scripts/` (empty)
- `plugins/[plugin-name]/README.md`

---

### Step 7: Update CLAUDE.md

Read `CLAUDE.md` and make three updates:

**a) Add the new plugin to the Project Structure section:**

Under the `plugins/` tree, add:

```
  [plugin-name]/                   # [description from design.yml]
    .claude-plugin/plugin.json
    commands/
    skills/
    [agents/]                      # only if applicable
    resources/
      templates/
      examples/
    scripts/
```

**b) Add a new Progress section for the plugin:**

Generate the progress checklist from the execution guide. Each step in the execution guide becomes a checklist item:

```markdown
### Part N: [Plugin Name] (in progress)
- [ ] Step N+0: Plugin scaffold + plugin.json
- [ ] Step N+1: Schema + templates
- [ ] Step N+2: Skill — [first-skill-name]
- [ ] Step N+3: Skill — [second-skill-name]
...
- [ ] Step N+M: [main-command] command
- [ ] Step N+M+1: End-to-end test
```

Use the next available Part number and continue the step numbering from the last used step number.

**c) Set the "Next step":**

```
Next step: Step [N+0] — [first step description for the new plugin]
```

---

### Step 8: Present Summary

Show the user the complete summary of everything created:

```
Plugin [name] is designed and scaffolded.

## What was created

### Design
- plugins/[name]/design.yml — your design decisions

### Specs
- docs/[name]-implementation-plan.md — full specification
- docs/[name]-addendum.md — domain knowledge and quality standards
[If assets:]
- docs/[name]-asset-manifest.md — asset generation plan

### Build Guide
- docs/[name]-execution-guide.md — step-by-step build instructions

### Scaffold
- plugins/[name]/ — plugin directory structure
- plugins/[name]/.claude-plugin/plugin.json — plugin manifest
- plugins/[name]/README.md — plugin documentation

### Updated
- CLAUDE.md — progress checklist added
- verification-registry.yml — verification profile registered

## Next steps

To build it, either:
a) Follow docs/[name]-execution-guide.md step by step
b) Run /plugin:build [name] to start guided building

Build one skill at a time. /compact between each skill.
```

## Error Handling

| Error | Action |
|-------|--------|
| Plugin name is not kebab-case | Suggest corrected name, ask user to confirm |
| Plugin directory already exists | Ask user: continue adding to it, or choose a different name? |
| Name is reserved (task-planner, brand-guideline) | Report error, ask for a different name |
| `--from-design` file not found | Report error, ask user to check the path |
| `--from-design` file missing required fields | List the missing fields, ask user to fix the design file |
| `--from-design` file status is not "approved" | Ask user to approve the design first (update status field) |
| Design interview cancelled by user | Stop gracefully — no cleanup needed, design.yml may be partial |
| User declines to proceed after interview | Stop — design.yml is saved, user can resume later with `--from-design` |
| Spec generation fails validation | Report which checks failed, attempt auto-fix per spec-generator skill |
| Upstream skill not found (SKILL.md missing) | Report which skill is missing — this means the task-planner is incomplete |
| brand-context-loader missing (when needs_brand) | Report error — brand-guideline plugin must be built first |

## Recovery

This command is sequential and does not use state.yml for recovery. However, each step produces durable artifacts:

- If interrupted after Step 3: `design.yml` exists. Re-run with `--from-design plugins/[name]/design.yml`
- If interrupted after Step 4: specs exist. The scaffolder can still run independently
- If interrupted after Step 6: everything exists except CLAUDE.md updates. Manually add the progress checklist

The `--from-design` flag is the primary recovery mechanism — it lets you skip the interactive interview and jump straight to spec generation.
