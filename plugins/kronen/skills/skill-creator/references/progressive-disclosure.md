# Progressive Disclosure for Skill Creation

When creating skills, follow the 3-tier architecture. This ensures token efficiency at scale.

## Tier Structure

1. **Frontmatter** (always loaded): `name`, `description`, `triggers` — the skill's entire pitch
2. **SKILL.md body** (on activate): ≤80 lines, core guidance, decision tables, reference pointers
3. **references/** (on demand): detailed docs, examples, templates, checklists

## What Goes Where

### In SKILL.md (Tier 2, ≤80 lines)

- When to trigger the skill
- Quick overview of what it does
- Decision table or selection guide (if multiple paths)
- Essential workflow steps (high-level)
- Pointers to reference files with loading triggers
- Key anti-patterns (brief NEVER list)

### In references/ (Tier 3, no limit)

- `process.md` — full specification, detailed workflow, comprehensive checklists
- Topic-specific files — syntax references, examples, templates
- Anything that would push SKILL.md over 80 lines

## Loading Trigger Rules

Every reference file mentioned in SKILL.md must have a loading trigger — a clear instruction for WHEN to load it.

**Pattern**: Embed the trigger in the workflow step where the reference is needed:

```markdown
### Before creating a component
Read [references/component-spec.md](references/component-spec.md) for the full template.
```

**Anti-pattern**: Listing references at the end without context:

```markdown
## References
- process.md
- template.md
```

This creates orphan references — the agent doesn't know when to load them.

## "Do NOT Load" Guidance

For skills with multiple references, add negative triggers to prevent over-loading:

```markdown
### For new skills only:
Read [references/creation-template.md](references/creation-template.md).
Do NOT load migration-guide.md — that's for modifying existing skills.
```

## Line Budget Strategy

With an 80-line budget:
- ~5 lines: frontmatter close + title
- ~10 lines: when to trigger + overview
- ~30 lines: core workflow or decision table
- ~15 lines: reference pointers with loading triggers
- ~10 lines: key anti-patterns
- ~10 lines: buffer

If the core workflow alone exceeds 40 lines, move detailed steps to `references/process.md` and keep only the high-level summary in SKILL.md.

## Naming Conventions

| File | Purpose |
|------|---------|
| `references/process.md` | Primary overflow — full specification |
| `references/<topic>.md` | Topic-specific detail (e.g., `syntax.md`, `examples.md`) |
| `scripts/<name>.sh` | Automation scripts |
| `assets/<name>` | Templates, schemas |

## Validation

After creating a skill, verify:
1. `wc -l SKILL.md` ≤ 80
2. Every reference file has a loading trigger in SKILL.md
3. Description answers WHAT + WHEN + KEYWORDS
4. `triggers:` frontmatter field populated with activation keywords
