# Skill Creator — Full Reference

## Skill anatomy

Every skill lives under `plugins/<plugin>/skills/<skill-name>/` and follows this structure:

```
skills/<skill-name>/
  SKILL.md              # Frontmatter + brief body (mandatory)
  references/
    process.md          # Full spec, tables, examples (primary overflow target)
    *.md                # Additional reference material
  scripts/
    *.sh                # Automation scripts
  assets/
    *.yml, *.json       # Templates, schemas, static resources
```

SKILL.md is the only mandatory file. Everything else is optional and created as needed.

## Frontmatter fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | string | Yes | — | Kebab-case identifier matching the directory name |
| `description` | string | Yes | — | Multi-line description with trigger phrases (see below) |
| `user_invocable` | boolean | Yes | — | `true` if triggered by a slash command, `false` if internal |
| `interactive` | boolean | Yes | — | `true` if the skill requires back-and-forth with the user |
| `depends_on` | list | Yes | `[]` | Other skills this skill requires (by name) |
| `reads` | list | Yes | `[]` | Glob patterns of files this skill reads |
| `writes` | list | Yes | `[]` | Glob patterns of files this skill creates or modifies |
| `checkpoint` | object | Yes | — | Verification gate (see checkpoint pattern below) |
| `model_tier` | string | Yes | — | `junior`, `senior`, or `principal` — see selection guide below |
| `_source` | object | Yes | — | Provenance tracking (see below) |

### model_tier selection

Pick the lowest tier that can reliably complete the skill's task:

| Tier | When to use |
|------|-------------|
| `junior` | Mechanical tasks: file validation, syntax checks, format compliance, boilerplate generation |
| `senior` | Judgment tasks: multi-file analysis, code review, quality assessment, debugging |
| `principal` | Architectural tasks: security review, cross-system design, orchestration decisions |

Default to `junior`. Escalate only when the task genuinely requires reasoning depth.
See `resources/agent-orchestration.md` for the full three-tier decision matrix.

### _source block

Every skill must declare its origin:

```yaml
_source:
  origin: "claude-core"              # Plugin that owns this skill
  inspired_by: "https://..."         # Source URL if adapted from external
  ported_date: "2026-03-09"          # Date of initial creation/port
  iteration: 1                       # Increment on major revisions
  changes: "Brief description..."    # What was adapted/changed
```

For original skills (not ported), set `inspired_by: null` and describe the motivation
in `changes`.

## Description writing

The `description` field controls when Claude activates the skill. Format depends on
invocability:

### User-invocable skills

Start with "Use this skill when the user asks to..." followed by specific actions:

```yaml
description: >
  Use this skill when the user asks to create a new project, initialize project
  scaffolding, or set up a workspace from scratch.
```

### Internal (non-user-invocable) skills

Start with an action statement, then "Use when..." with specific scenarios:

```yaml
description: >
  Create new Claude Code skills with correct SKILL.md structure, frontmatter fields,
  progressive disclosure, and resource organization. Use when building skills for any
  plugin, structuring skill content, or validating skill files.
```

### Description rules

- Write in third person — never "you should" or "you can"
- Include 2-4 concrete trigger phrases that map to real situations
- Name the specific artifacts or outputs the skill produces
- Keep under 50 words for the trigger portion

### Examples of good vs bad descriptions

| Quality | Description |
|---------|-------------|
| Good | "Validate hook scripts for correct exit codes, JSON output, and event matching. Use when creating hooks, debugging hook failures, or reviewing hook changes." |
| Bad | "This skill helps you with hooks." |
| Bad | "You should use this when you need to work with hooks and want to make sure they are correct." |

## Content organization

### What stays in SKILL.md

- Frontmatter (all fields)
- One-line purpose statement
- "When to trigger" bullet list (4-6 items)
- Quick-reference table (one table max)
- Pointer to `references/process.md`

### What goes to references/process.md

- Detailed field tables with types and defaults
- Code examples and templates
- Multi-step processes
- Common mistakes tables
- Testing protocols
- Checklists

### What goes to other references/*.md

- Domain-specific deep dives (e.g., `references/events.md` for hook events)
- Large template collections
- API documentation

### What goes to scripts/

- Automation that the skill's process references
- Validation scripts
- Generation scripts

### What goes to assets/

- YAML/JSON templates
- Schema definitions
- Static resources the skill copies or references

## The 80-line rule

SKILL.md must not exceed 80 lines total, including frontmatter.

### How to count

```bash
wc -l plugins/<plugin>/skills/<skill-name>/SKILL.md
```

All lines count: frontmatter delimiters (`---`), blank lines, comments, content.

### How to split when over budget

1. Move tables (except one quick-reference) to `references/process.md`
2. Move code examples to `references/process.md`
3. Move step-by-step processes to `references/process.md`
4. Reduce "When to trigger" to 4-6 items max
5. Replace inline detail with a pointer: "See `references/process.md` for..."

### Target line distribution

| Section | Lines |
|---------|-------|
| Frontmatter (including `---` delimiters) | 25-40 |
| Blank line after frontmatter | 1 |
| Heading + purpose | 3 |
| When to trigger | 6-8 |
| Quick-reference table | 8-12 |
| Brief guidance | 2-4 |
| Pointer to references | 3-4 |

## Writing style

All skill content uses imperative/infinitive form. Never use second person.

### Do / Don't

| Do | Don't |
|----|-------|
| "Create the frontmatter block" | "You should create the frontmatter block" |
| "Validate all required fields" | "You need to validate all required fields" |
| "Run the checkpoint before marking complete" | "You can run the checkpoint..." |
| "Keep SKILL.md under 80 lines" | "Make sure you keep SKILL.md under 80 lines" |
| "See references/process.md for details" | "You can find more details in..." |

### Verb-first pattern

Start instructions and list items with a verb:

- **Create** the skill directory structure
- **Write** frontmatter with all required fields
- **Move** overflow content to references/process.md
- **Register** the skill in ecosystem.json
- **Run** checkpoint verification
- **Clear** plugin cache after changes

## Progressive disclosure

Skills load in three tiers to minimize context consumption:

### Tier 1 — Metadata (~100 words)

The frontmatter `description` field. Claude reads this to decide whether to activate
the skill. Keep it focused: action statement + trigger phrases.

### Tier 2 — SKILL.md body (<80 lines)

Loaded when the skill activates. Contains just enough to start work: when to trigger,
quick-reference table, pointer to references. Sufficient for simple cases.

### Tier 3 — Bundled resources (unlimited)

Loaded on demand when the skill needs deeper guidance. `references/process.md` is the
primary overflow target. Additional references, scripts, and assets load as needed.

### Context efficiency

- Tier 1 is always loaded — keep descriptions tight
- Tier 2 loads on activation — respect the 80-line budget
- Tier 3 loads on demand — put all detailed content here
- Never duplicate content across tiers

## Resource organization

### references/ naming

| File | Purpose |
|------|---------|
| `process.md` | Primary overflow: full spec, tables, examples, checklist |
| `examples.md` | Extended examples if process.md examples aren't enough |
| `<topic>.md` | Domain-specific deep dive (e.g., `events.md`, `schemas.md`) |

### scripts/ conventions

- Filename: `<verb>-<noun>.sh` (e.g., `validate-skill.sh`, `generate-template.sh`)
- Header: `#!/usr/bin/env bash` + `set -euo pipefail`
- Use `$CLAUDE_PROJECT_DIR` for project paths, `$CLAUDE_PLUGIN_ROOT` for plugin paths
- Exit 0 on success, non-zero on failure

### assets/ usage

- YAML templates: `<name>-template.yml`
- JSON schemas: `<name>-schema.json`
- Reference as relative paths from the skill directory

## Checkpoint pattern

Every skill must define a checkpoint for verification. The checkpoint prevents
self-grading — a separate verification pass confirms the work is correct.

### Structure

```yaml
checkpoint:
  type: data_validation          # or: test_execution, manual_review
  required_checks:
    - name: "check_identifier"
      verify: "What to verify (human-readable)"
      fail_action: "What to do if verification fails"
```

### Verification types

| Type | When to use | Example |
|------|-------------|---------|
| `data_validation` | Output files must match a schema or set of rules | Frontmatter fields present, YAML valid |
| `test_execution` | Automated tests can verify correctness | Script runs clean, output matches expected |
| `manual_review` | Human judgment needed | Design quality, copy tone |

### required_checks format

Each check needs three fields:

- `name` — snake_case identifier, unique within the checkpoint
- `verify` — plain-English statement of what must be true
- `fail_action` — concrete remediation step, often referencing a specific file or section

Include 2-5 checks per skill. Cover the critical paths — not every edge case.

## Registration

After creating a skill, register it in the plugin's ecosystem.json.

### ecosystem.json skills array

Add the skill name (matching the directory name) to the `skills` array:

```json
{
  "skills": [
    "existing-skill-a",
    "existing-skill-b",
    "new-skill-name"
  ]
}
```

### User-invocable commands

If the skill is user-invocable (`user_invocable: true`), also add a command entry:

1. Create `commands/<command-name>/COMMAND.md` with the command definition
2. Add the command name to the `commands` array in ecosystem.json

Internal skills (`user_invocable: false`) do not need command entries.

## 7-step creation workflow (TDD-first)

### Step 0 — Write baseline eval (TDD)

Before writing any skill content, write the evaluation first.

**Why:** Skills written before tests are optimised to pass the tests you wrote,
not to fix actual behavior gaps. Baseline-first ensures the skill targets real
violations, not invented ones.

**How:**

1. Create `evals.json` in the skill directory with test cases representing the
   behavior you want the skill to produce. See `references/schemas.md`.

2. Run the eval **without** the skill active:
   ```bash
   python3 scripts/run_eval.py --skill-dir plugins/<plugin>/skills/<skill-name> --no-skill
   ```

3. Record which cases fail (violations). These are your red tests.

4. Write SKILL.md (Step 3) targeting those specific violations — not generic
   "best practice" content.

5. Run the eval **with** the skill:
   ```bash
   python3 scripts/run_eval.py --skill-dir plugins/<plugin>/skills/<skill-name>
   ```

6. All previously failing cases should now pass (green). Previously passing
   cases should still pass (no regression).

**Loophole closing:** After the skill passes, run the eval with one adversarial
variant per violation: can the behavior still occur through an indirect path?
If yes, add that case to evals.json and iterate.

---

### Step 1 — Define purpose and triggers

Determine what the skill does, when it activates, and whether it's user-invocable
or internal. Draft the description with trigger phrases.

### Step 2 — Create directory structure

```bash
mkdir -p plugins/<plugin>/skills/<skill-name>/references
```

Create additional directories (`scripts/`, `assets/`) only if needed.

### Step 3 — Write SKILL.md

1. Write frontmatter with all required fields (use the field table above)
2. Add brief body: heading, purpose, "When to trigger", quick-reference table
3. Add pointer to `references/process.md`
4. Verify line count: `wc -l SKILL.md` — must be ≤80

### Step 4 — Write references/process.md

Move all detailed content here:
- Full specification tables
- Code examples and templates
- Step-by-step processes
- Common mistakes and troubleshooting
- Validation checklist

### Step 5 — Register in ecosystem.json

Add the skill name to the plugin's `ecosystem.json` skills array.
If user-invocable, create the corresponding command.

### Step 6 — Run checkpoint verification

Execute each `required_checks` item from the frontmatter checkpoint:
- Verify SKILL.md frontmatter is valid with all required fields
- Verify line count is within budget
- Verify description has concrete triggers
- Verify references exist for overflow content
- Run skill-auditor agent to validate the created skill passes all checks
- Clear plugin cache: `rm -rf ~/.claude/plugins/cache/local-workspace/`

## Common mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| SKILL.md over 80 lines | Context bloat on every activation | Move tables and examples to references/process.md |
| Missing `_source` block | No provenance tracking, harder to maintain | Add _source with origin, ported_date, iteration, changes |
| Vague description without triggers | Skill never activates when needed | Add "Use when..." phrases with specific scenarios |
| Using second person ("you should") | Violates style convention, inconsistent tone | Rewrite in imperative form ("Create...", "Validate...") |
| Duplicating content across SKILL.md and references | Maintenance burden, inconsistencies | Keep SKILL.md as pointer, details only in references/ |
| Missing checkpoint | No verification gate, self-grading risk | Add checkpoint with 2-5 required_checks |
| Not registering in ecosystem.json | Skill invisible to the plugin system | Add skill name to the skills array |
| Missing `depends_on` for dependent skills | Activation order issues, missing context | List all skill dependencies by name |
| Forgetting to clear plugin cache | Stale skill version loads | Run `rm -rf ~/.claude/plugins/cache/local-workspace/` |
| Description over 50 words | Wasted context in Tier 1 metadata | Tighten to action + 2-4 trigger phrases |

## Validation checklist

Before committing any skill:

- [ ] SKILL.md has valid YAML frontmatter (parses without errors)
- [ ] All required fields present: name, description, user_invocable, interactive, depends_on, reads, writes, checkpoint, model_tier, _source
- [ ] `name` matches directory name (kebab-case)
- [ ] `description` has concrete trigger phrases ("Use when...")
- [ ] `description` uses third person (no "you should", "you can")
- [ ] `_source` block has origin, ported_date, iteration, changes
- [ ] SKILL.md ≤80 lines total (including frontmatter)
- [ ] Overflow content in `references/process.md`, not crammed into SKILL.md
- [ ] All body text uses imperative/infinitive form
- [ ] `checkpoint` has 2-5 `required_checks` with name, verify, fail_action
- [ ] Skill registered in `ecosystem.json` skills array
- [ ] If user-invocable: command exists in `commands/` and `ecosystem.json`
- [ ] `references/process.md` exists if SKILL.md references it
- [ ] Plugin cache cleared after creation

## Evaluation and benchmarking

### Evaluation modes

| Mode | What it tests | Input | Output |
|------|---------------|-------|--------|
| Trigger eval | Does the skill description activate the skill? | `evals.json` with `should_trigger` flags | Pass/fail per query |
| Task eval | Can the skill complete realistic tasks? | `evals.json` with `expectations` | Grading report |
| Benchmark | Statistical comparison across runs | Multiple eval runs | `benchmark.json` + `benchmark.md` |
| Description optimization | Iterative trigger phrase improvement | 20 trigger queries (mixed) | Improved description |

### Running evaluations

Create `evals.json` in the skill directory with test cases (see `references/schemas.md` for format).

```bash
# Run a single evaluation
python3 scripts/run_eval.py --skill-dir plugins/<plugin>/skills/<skill-name>

# Run eval + improvement loop (max 5 iterations, early exit on all_passed)
python3 scripts/run_loop.py --skill-dir plugins/<plugin>/skills/<skill-name>

# Aggregate multiple runs into a benchmark
python3 scripts/aggregate_benchmark.py --results-dir <output-dir>
```

### Eval-improve loop

`run_loop.py` automates iterative skill improvement:

1. Split evals into train (60%) and test (40%) using stratified sampling
2. Run train set — grade results with `agents/grader.md`
3. If failures exist, use `agents/analyzer.md` to identify weaknesses
4. Apply improvements to SKILL.md or references
5. Re-run train set — repeat until all pass or max 5 iterations
6. Run test set as final holdout validation

The train/test split prevents overfitting to specific eval queries. Early exit triggers when all train evals pass.

### Description optimization

`improve_description.py` focuses specifically on trigger accuracy:

1. Create 20 trigger queries — mix of should-trigger (10) and should-not-trigger (10)
2. Run each query through `claude -p` with the skill installed
3. Check if the skill activated (or correctly did not activate)
4. Pass failures to Claude for description rewrite
5. Re-test, iterate up to 5 times

Safety net: descriptions are capped at 1024 characters to prevent context bloat.

### Grading pipeline

Three agents handle evaluation analysis:

| Agent | Role | Output |
|-------|------|--------|
| `agents/grader.md` | Grade expectations against transcripts, verify claims, score instruction-following | `grading.json` |
| `agents/comparator.md` | Blind A/B comparison between two skill versions | `comparison.json` |
| `agents/analyzer.md` | Unblind results, extract strengths/weaknesses, prioritize improvements | `analysis.json` |

The grader evaluates each expectation independently with pass/fail + evidence. The comparator receives unlabeled outputs and scores on a 1-10 rubric. The analyzer identifies causal links between skill changes and outcome differences.

### Benchmarking

`aggregate_benchmark.py` computes statistical significance across multiple runs:

- Computes mean +/- stddev for pass rates, tool usage, timing
- Compares with-skill vs without-skill (baseline) performance
- Generates `benchmark.json` (machine-readable) and `benchmark.md` (human-readable)
- Surfaces per-assertion stability and cross-eval variance

### HTML tools

| File | Purpose |
|------|---------|
| `assets/eval_review.html` | Interactive eval set editor — add, edit, delete, toggle should_trigger, export |
| `assets/viewer.html` | Benchmark results viewer — load and compare benchmark.json files |
| `scripts/generate_report.py` | Generate live HTML report from run_loop output with auto-refresh |

### Schemas

See `references/schemas.md` for the 8 JSON schemas used by the eval pipeline:
evals, history, grading, metrics, timing, benchmark, comparison, analysis.

### Critical: timing data capture

`timing.json` MUST be saved immediately from subagent completion notifications. The notification
callback is the only opportunity to capture wall-clock timing and token counts. If missed,
timing data is lost permanently — there is no way to reconstruct it after the fact.
