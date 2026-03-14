# Skill Reviewer — Full Reference

## Review philosophy

Reviewers are read-only. Never modify the files under review. Produce a YAML verdict
documenting findings and recommendations. Enhancers (future) act on verdicts — reviewers
only judge.

## 8-Step review methodology

Adapted from the Anthropic skill-reviewer agent. Execute all 8 steps in sequence.

### Step 1: Location

Verify the skill lives in the correct place:
- Path follows `plugins/<plugin>/skills/<skill-name>/SKILL.md`
- Directory name is kebab-case
- Directory name matches the `name` field in frontmatter
- No nested skill directories (skills are flat under `skills/`)

### Step 2: Structure

Verify the skill has required files and organization:
- `SKILL.md` exists (mandatory)
- `references/process.md` exists if SKILL.md body references it
- All files referenced in SKILL.md body or frontmatter actually exist
- No orphan files (files in the skill directory not referenced anywhere)
- Directory structure follows conventions (`references/`, `scripts/`, `assets/`)

### Step 3: Description

Evaluate the frontmatter `description` field:
- Starts with action statement (not "This skill...")
- Contains 2-4 concrete trigger phrases
- Uses third person (no "you should", "you can")
- Under 50 words for the trigger portion
- Names specific artifacts or outputs
- Distinguishes from other skills (no overlap with siblings)

### Step 4: Content quality

Evaluate the depth and accuracy of skill content:
- SKILL.md body has: heading, purpose statement, "When to trigger" list, quick-reference table
- `references/process.md` has substantive content (not stubs)
- Tables have real data (not TODO/placeholder)
- Code examples are syntactically correct
- Instructions use imperative form (verb-first)
- Checklists cover critical paths
- No second person ("you should", "you can", "you need")

### Step 5: Progressive disclosure

Verify the three-tier structure is efficient:

| Tier | Location | Budget | Check |
|------|----------|--------|-------|
| 1: Metadata | frontmatter `description` | ~100 words | Tight, specific triggers |
| 2: Body | SKILL.md body | ≤80 lines total | Sufficient for simple cases |
| 3: Resources | references/*.md | Unlimited | All detail lives here |

Flag:
- Content in SKILL.md that belongs in references/ (body too dense)
- Content duplicated across tiers
- Tier 3 content that could be condensed into Tier 2 (too sparse)
- References loaded always when they should be on-demand

### Step 6: Supporting files

Verify all referenced files:
- `references/process.md` exists and has substantive content
- Any `scripts/*.sh` files have correct shell headers
- Any `assets/*.yml` files parse as valid YAML
- File sizes are reasonable (not empty, not excessively large)
- No unreferenced files in the skill directory

### Step 7: Issue identification

Classify all findings by severity:

| Severity | Meaning | Examples |
|----------|---------|---------|
| **critical** | Blocks loading or causes incorrect behavior | Missing required frontmatter field, name mismatch, SKILL.md >80 lines |
| **warning** | Degrades quality or maintainability | Vague description, missing _source, weak checkpoint |
| **info** | Improvement opportunity | Better trigger phrases, tighter description, additional examples |

### Step 8: Recommendations

Generate actionable recommendations:
- Each recommendation maps to a specific finding
- Recommendations include the specific file and section to change
- Prioritized by severity (critical first)
- Estimate effort: trivial (1-2 edits), moderate (section rewrite), significant (structural change)
- Use before/after format for concrete improvements

#### Before/after format

Each recommendation that involves content changes should include a before/after example:

```yaml
finding: "Description uses second person"
file: "SKILL.md"
section: "frontmatter.description"
before: |
  description: >
    You can use this skill to validate hooks for correct exit codes
    and JSON output. You should run it when creating hooks.
after: |
  description: >
    Validate hook scripts for correct exit codes, JSON output, and event
    matching. Use when creating hooks, debugging hook failures, or reviewing
    hook changes.
effort: trivial
```

```yaml
finding: "Checkpoint fail_action is vague"
file: "SKILL.md"
section: "frontmatter.checkpoint.required_checks[1]"
before: |
  fail_action: "Fix the issue"
after: |
  fail_action: "Add missing name field to frontmatter per skill-creator spec"
effort: trivial
```

Not all recommendations need before/after — use it when the fix is non-obvious
or when showing the contrast makes the improvement clear.

#### Positive findings

Include a `strengths` section in the verdict noting what the skill does well:

```yaml
strengths:
  - "Description has 4 specific trigger phrases covering core use cases"
  - "Checkpoint checks map directly to the skill's critical outputs"
  - "Progressive disclosure is efficient — SKILL.md at 62 lines, heavy detail in references/"
```

Positive findings help skill authors understand what to preserve during edits.
Skip generic praise — each strength should reference a specific, observable quality.

## Stage 1: Spec Compliance

Mechanical checks. All must pass.

### Check 1: SKILL.md line count

```bash
wc -l plugins/<plugin>/skills/<name>/SKILL.md
```

Must be ≤80 lines. All lines count: frontmatter delimiters, blank lines, content.

### Check 2: Required frontmatter fields

All fields must be present and non-empty:

| Field | Type check |
|-------|-----------|
| `name` | String, kebab-case, matches directory name |
| `description` | String, non-empty |
| `user_invocable` | Boolean |
| `interactive` | Boolean |
| `depends_on` | Array (may be empty) |
| `reads` | Array (may be empty) |
| `writes` | Array (may be empty) |
| `checkpoint` | Object with `type` and `required_checks` |
| `model_tier` | One of: `junior`, `senior`, `principal` |
| `_source` | Object with `origin`, `ported_date`, `iteration`, `changes` |

### Check 3: Name consistency

The `name` field in frontmatter must exactly match:
- The skill's directory name
- The entry in `ecosystem.json` skills array

### Check 4: _source block

Must contain:
- `origin` — plugin name that owns this skill
- `ported_date` — date string
- `iteration` — positive integer
- `changes` — non-empty description string

`inspired_by` is optional (null for original skills).

### Check 5: Checkpoint structure

Must have:
- `type` — one of: `data_validation`, `test_execution`, `manual_review`
- `required_checks` — array with 2-5 entries
- Each check has: `name` (snake_case), `verify` (string), `fail_action` (string)

### Check 6: Ecosystem registration

Skill name must appear in the plugin's `ecosystem.json` `skills` array.

### Check 7: Referenced files exist

Every file path mentioned in SKILL.md body must exist on disk:
- `references/process.md` (if referenced)
- `scripts/*.sh` (if referenced)
- `assets/*.yml` (if referenced)

### Check 8: No second person

Scan all skill files for second-person pronouns and phrases:
- "you should", "you can", "you need", "you must"
- "your" (when addressing the reader)

These violate the imperative style convention.

### Check 9: Debugging reference (smedjen tech skills only)

For skills in the smedjen plugin whose triggers include framework or tool names
(react, nextjs, vue, nuxt, nestjs, prisma, nodejs, typescript, playwright,
storybook, vite, tailwind, expo-*, e2e-testing):

```bash
test -f plugins/smedjen/skills/<name>/references/debugging.md
```

Must exist and contain at least 3 debugging scenarios with framework-specific
tools and commands. Skip for non-tech skills (orchestration, discipline, studio).

### Stage 1 output

```yaml
spec_compliance:
  status: pass | fail
  checks:
    line_count: { status: pass|fail, lines: 0, limit: 80 }
    required_fields: { status: pass|fail, missing: [] }
    name_consistency: { status: pass|fail, detail: "" }
    source_block: { status: pass|fail, missing: [] }
    checkpoint_structure: { status: pass|fail, detail: "" }
    ecosystem_registration: { status: pass|fail, detail: "" }
    referenced_files: { status: pass|fail, missing: [] }
    no_second_person: { status: pass|fail, violations: [] }
    debugging_reference: { status: pass|fail|skipped, detail: "" }
  failed_count: 0
```

## Stage 2: Quality Review

Judgment-based evaluation. Only runs after Stage 1 passes.

### Description trigger quality

- Are trigger phrases specific enough to activate correctly?
- Could the description cause false activation on unrelated topics?
- Do trigger phrases cover the skill's core use cases?
- Is the action statement clear and distinct from similar skills?

### Tier efficiency

- Is SKILL.md body dense enough to be useful but light enough to stay in budget?
- Does references/process.md carry the right level of detail?
- Is there content in SKILL.md that should be in references/ (or vice versa)?
- Would loading this skill waste context on irrelevant content?

### Content depth

- Does process.md have tables, examples, and checklists?
- Are code examples syntactically correct and realistic?
- Are common mistakes documented with consequences and fixes?
- Is there a validation checklist at the end?

### Duplication across tiers

- Does the SKILL.md body repeat frontmatter description content?
- Does process.md duplicate SKILL.md tables or lists?
- Are there redundant instructions across files?

### Checkpoint coverage

- Do the 2-5 checks cover the skill's critical outputs?
- Would a check catch the most common failure modes?
- Are `fail_action` values actionable (not just "fix it")?

### depends_on accuracy

- Are all actual dependencies listed?
- Are listed dependencies actually required (not just related)?
- Would removing a dependency break the skill?

### model_tier appropriateness

| Tier | Appropriate when |
|------|-----------------|
| `junior` | Mechanical, template-driven, no judgment |
| `senior` | Requires domain knowledge, some judgment |
| `principal` | Requires cross-cutting judgment, architectural decisions |

Flag if the tier seems mismatched with the skill's complexity.

### Stage 2 output

```yaml
quality_review:
  status: pass | pass_with_notes | fail
  findings:
    - area: "description|tiers|content|duplication|checkpoint|dependencies|model_tier"
      severity: info | warning | critical
      detail: "Description of finding"
      fix_required: true | false
  summary: "Brief overall assessment"
```

## Verdict format

```yaml
skill_review:
  skill: "<skill-name>"
  plugin: "<plugin-name>"
  reviewed_at: "<timestamp>"
  status: pass | pass_with_notes | fail
  spec_compliance:
    status: pass | fail
    checks: { ... }
    failed_count: 0
  quality_review:
    status: pass | pass_with_notes | fail
    findings: []
    summary: ""
  strengths:
    - "Specific observable quality that the skill does well"
  recommendations:
    - severity: critical | warning | info
      area: ""
      detail: ""
      file: ""
      effort: trivial | moderate | significant
```

## Common findings

| Finding | Severity | Category | Fix |
|---------|----------|----------|-----|
| SKILL.md over 80 lines | critical | spec | Move tables/examples to references/process.md |
| Missing required frontmatter field | critical | spec | Add the field per skill-creator spec |
| Name doesn't match directory | critical | spec | Rename to match |
| Missing _source block | critical | spec | Add _source with all required fields |
| Not registered in ecosystem.json | critical | spec | Add to skills array |
| Weak checkpoint (1 check or >5 checks) | warning | spec | Adjust to 2-5 focused checks |
| Vague description without triggers | warning | quality | Add "Use when..." with specific scenarios |
| Second person in content | warning | style | Rewrite in imperative form |
| Content duplicated across tiers | warning | efficiency | Keep in one tier only |
| Missing references/process.md | warning | structure | Create with substantive content |
| Description over 50 words | info | efficiency | Tighten trigger portion |
| model_tier mismatch | info | quality | Adjust tier to match complexity |
| Missing common mistakes table | info | completeness | Add to process.md |
| No checklist in process.md | info | completeness | Add validation checklist |
| Orphan files in skill directory | info | cleanliness | Remove or reference them |

## Review checklist

Quick-reference for manual reviews:

- [ ] SKILL.md exists and is ≤80 lines
- [ ] All required frontmatter fields present
- [ ] `name` matches directory name
- [ ] `_source` has origin, ported_date, iteration, changes
- [ ] `description` has concrete trigger phrases (2-4)
- [ ] `description` under 50 words for trigger portion
- [ ] No second person in any skill files
- [ ] `checkpoint` has 2-5 required_checks
- [ ] `depends_on` lists actual dependencies
- [ ] `model_tier` matches skill complexity
- [ ] Registered in ecosystem.json skills array
- [ ] All referenced files exist on disk
- [ ] references/process.md has tables, examples, checklists
- [ ] No content duplication across SKILL.md and references/
- [ ] Body uses imperative/verb-first style
- [ ] Quick-reference table present in SKILL.md body
- [ ] Pointer to references/process.md present
