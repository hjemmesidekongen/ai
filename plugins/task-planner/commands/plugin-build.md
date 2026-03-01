---
name: plugin-build
command: "/plugin:build"
description: "Guided step-by-step build of a plugin from its execution guide"
arguments:
  - name: plugin-name
    type: string
    required: true
    description: "Kebab-case name of the plugin to build (must already be scaffolded via /plugin:create)"
  - name: step
    type: number
    required: false
    description: "Jump to a specific step number instead of the next uncompleted step"
  - name: status
    type: boolean
    required: false
    default: false
    description: "Show current build progress and exit"
---

# /plugin:build

Reads a plugin's generated execution guide and walks the user through building it step by step. Each step builds one skill or command, runs its verification checkpoint, updates CLAUDE.md progress, and prompts for `/compact` before the next step.

This command does NOT use the task-planner for its own execution — it IS the guided build experience for plugins that WILL use the planner when their commands run.

No checkpoint needed — this is a driver command that orchestrates steps which have their own checkpoints.

## Usage

```
/plugin:build seo-plugin
/plugin:build website-builder --step 4
/plugin:build content-engine --status
```

## Prerequisites

Before running, read:
1. `plugins/task-planner/resources/plugin-blueprint.md` — Section 9 (New Plugin Creation)
2. `docs/ecosystem-strategy.md` — Section 7 (Workflow: Creating a New Plugin)

## Execution Steps

### Step 1: Verify Prerequisites

Check that the plugin has been fully created by `/plugin:create`:

1. **design.yml exists:** `plugins/[plugin-name]/design.yml` must exist and have `status: approved`
2. **Execution guide exists:** `docs/[plugin-name]-execution-guide.md` must exist
3. **Implementation plan exists:** `docs/[plugin-name]-implementation-plan.md` must exist
4. **Plugin scaffold exists:** `plugins/[plugin-name]/.claude-plugin/plugin.json` must exist

If any are missing, stop and report:

```
Plugin [name] is not fully created. Missing:
  - [list missing files]

Run /plugin:create [name] first to generate all required artifacts.
[If only execution guide is missing:]
Or run /plugin:create [name] --from-design plugins/[name]/design.yml
to regenerate from the existing design.
```

---

### Step 2: Check Progress

Read `CLAUDE.md` and find the plugin's progress section.

**Parse the checklist:**
- Find the `### Part N: [Plugin Name]` section
- Read each `- [x]` (completed) and `- [ ]` (pending) line
- Find the `Next step:` line

**Determine the current step:**
- If `--step` is provided: use that step number (validate it exists in the execution guide)
- If `--status` is provided: show progress summary and exit (see Status Display below)
- Otherwise: use the step indicated by the `Next step:` line in CLAUDE.md

**If all steps are already checked off:**

```
Plugin [name] is fully built! All [N] steps completed.

To verify everything works together, run the end-to-end test:
  Follow the final step in docs/[name]-execution-guide.md
```

Exit — nothing to do.

**Status Display (--status):**

```
Plugin: [name]
Progress: [completed]/[total] steps ([percentage]%)

Completed:
  [x] Step N: [title]
  [x] Step N+1: [title]
  ...

Remaining:
  [ ] Step N+K: [title]
  [ ] Step N+K+1: [title]
  ...

Next step: Step [N+K] — [title]
```

---

### Step 3: Load Current Step from Execution Guide

Read `docs/[plugin-name]-execution-guide.md`.

1. Find the section for the current step number (e.g., `### Step 4: Skill — keyword-research`)
2. Extract the full prompt block between the `---` delimiters
3. Extract metadata:
   - **Title** — the step heading
   - **What** — the one-sentence purpose
   - **Interactive** — yes/no
   - **Depends on** — list of prerequisite skills

4. Read any spec files referenced in the prompt:
   - `docs/[plugin-name]-implementation-plan.md` (always)
   - `docs/[plugin-name]-addendum.md` (if referenced)
   - `docs/[plugin-name]-asset-manifest.md` (if referenced)

5. **Validate dependencies:** Check that all skills listed in "Depends on" have their corresponding steps checked off in CLAUDE.md. If any dependency is not yet built:

```
Step [N] depends on [skill-name], which hasn't been built yet.

Either:
a) Build the dependency first: /plugin:build [name] --step [dep-step-number]
b) Continue anyway (not recommended — checkpoint may fail)
```

Wait for the user's choice.

---

### Step 4: Present the Step

Show the user what's about to happen:

```
Step [N]: [title]

What: [one-sentence purpose]
Interactive: [yes/no]
Depends on: [list or "none"]

This step will:
  - Read: [list of files the prompt reads]
  - Create: [what files/directories will be created]
  - Write to: [what sections of what files]

Ready to proceed?
```

Wait for explicit confirmation. If the user wants to review the execution guide first, respect that and show them the path: `docs/[plugin-name]-execution-guide.md`.

---

### Step 5: Execute the Step

Once the user confirms:

1. **Execute the prompt** from the execution guide — follow it exactly as written
2. The prompt will:
   - Read the relevant spec sections
   - Create the skill SKILL.md (or command .md, or schema, etc.)
   - Run the checkpoint validation
   - Update CLAUDE.md (check off the step, advance "Next step")
   - Commit everything

3. **If the checkpoint fails:**
   - Show what checks failed and why
   - Attempt auto-fix per the checkpoint's `on_fail` instructions
   - Re-run validation
   - If it fails again: report the issue and ask the user to review

4. **If the checkpoint passes:**
   - The step's prompt already handles checking off CLAUDE.md and committing
   - Proceed to Step 6 (transition)

5. **Track failure count:** If the same step fails verification 3 times:

```
Step [N] has failed verification 3 times.

Options:
a) Review the spec: docs/[name]-implementation-plan.md (the "[skill]" section)
b) Review the addendum: docs/[name]-addendum.md
c) Skip this step and move on: /plugin:build [name] --step [N+1]
d) Stop and investigate manually
```

---

### Step 6: Transition

After the step completes successfully:

1. **Show completion message:**

```
Step [N] complete: [title]

Progress: [completed]/[total] steps ([percentage]%)
Next: Step [N+1] — [next title]

/compact before continuing to the next step.
```

2. **If this was the last step before the end-to-end test:**

```
All skills and commands are built!

Final step: End-to-end test
  Run /plugin:build [name] to execute the test step.
```

3. **If all steps including the test are complete:**

```
Plugin [name] is fully built and tested!

## Summary
- Skills: [N] built and verified
- Commands: [N] created
- Schema: verified
- End-to-end test: passed

The plugin is ready to use. Try:
  /[plugin]:[main-command]
```

## Error Handling

| Error | Action |
|-------|--------|
| Plugin directory doesn't exist | Report error: "Run /plugin:create [name] first" |
| design.yml missing or not approved | Report error: "Run /plugin:create [name] first" |
| Execution guide missing | Report error: "Run /plugin:create [name] first, or regenerate with --from-design" |
| Implementation plan missing | Report error: "Run /plugin:create [name] first" |
| `--step` number out of range | Report valid range and ask user to choose a valid step |
| Step dependency not built | Warn user, offer to build dependency first or continue anyway |
| Execution guide malformed (can't parse steps) | Warn and suggest regenerating: "/plugin:create [name] --from-design plugins/[name]/design.yml" |
| Checkpoint fails 3 times | Offer options: review spec, skip step, or stop |
| CLAUDE.md progress section missing | Create it from the execution guide (same logic as /plugin:create Step 7) |

## Recovery

This command is stateless — it reads progress from CLAUDE.md every time it runs. No state.yml needed.

- **Interrupted mid-step:** The step may be partially built. Check what files exist, then either:
  - Re-run the same step: `/plugin:build [name] --step [N]` (it will overwrite)
  - Continue to next step if the checkpoint passes: `/plugin:build [name]`
- **CLAUDE.md out of sync:** Manually check/uncheck steps to match actual file state
- **Execution guide regenerated:** Safe to do at any time — step numbers may change, so verify CLAUDE.md alignment
