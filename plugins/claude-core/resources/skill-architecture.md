# Skill Architecture: 3-Tier Progressive Disclosure

Skills follow a hierarchical loading model for token efficiency. Content loads only when needed.

## The Three Tiers

### Tier 1: Metadata (Always in Memory)

Only `name` and `description` from YAML frontmatter. This is what the agent sees when deciding whether to activate a skill. ~100 tokens per skill.

**Implication**: The description is the skill's entire pitch. If it doesn't clearly state WHAT the skill does, WHEN to use it, and include searchable KEYWORDS, the skill is invisible regardless of content quality.

### Tier 2: SKILL.md Body (Loaded on Activate)

Core instructions loaded when the agent decides to use the skill. Must be ≤80 lines in this project.

**Contains**: When to trigger, quick overview, decision tables, essential workflow, pointers to references.

**Does NOT contain**: Full examples, detailed syntax, comprehensive checklists, historical context.

### Tier 3: References (Loaded on Demand)

Heavy content in `references/` directory. Loaded only when explicitly referenced from SKILL.md. No line limit.

**Contains**: Detailed process docs, full examples, syntax references, checklists, templates.

**Loading triggers**: SKILL.md must tell the agent when to load each reference file. Without explicit triggers, references sit unused (the "Orphan References" failure pattern).

## Loading Trigger Patterns

### Good: Embedded in Workflow

```markdown
### Creating a New Component
Before proceeding, read [references/component-template.md](references/component-template.md).
```

### Better: Conditional with "Do NOT Load"

```markdown
### If editing existing skill:
Read [references/migration-guide.md](references/migration-guide.md).
Do NOT load component-template.md — it's for new skills only.
```

### Bad: Listed at End

```markdown
## References
- process.md — detailed process
- template.md — templates
```

This is just a bibliography. The agent doesn't know WHEN to load which file.

## Directory Structure

```
skills/<name>/
  SKILL.md              # Tier 2: ≤80 lines, core guidance
  references/
    process.md          # Tier 3: Full specification, overflow from SKILL.md
    <topic>.md          # Tier 3: Additional reference material
  scripts/              # Automation scripts (optional)
  assets/               # Templates, schemas (optional)
```

## Five Skill Patterns

Skills fall into one of five patterns based on task type:

| Pattern | SKILL.md Lines | Freedom Level | Best For |
|---------|---------------|---------------|----------|
| **Mindset** | ~50 | High | Creative tasks, taste-dependent decisions |
| **Navigation** | ~30 | Variable | Multiple distinct scenarios, routes to sub-files |
| **Philosophy** | ~80 | High | Art/creation requiring originality and craft |
| **Process** | ~80 | Medium | Complex multi-step projects with checkpoints |
| **Tool** | ~80 | Low | Precise operations, decision trees, exact steps |

Choose the pattern based on task fragility: high consequence of error → lower freedom → Tool pattern. Low consequence → higher freedom → Mindset pattern.

## Compliance Checklist

For existing skills:

- [ ] SKILL.md ≤80 lines
- [ ] Heavy content in references/, not body
- [ ] Description answers WHAT + WHEN + KEYWORDS
- [ ] References have loading triggers in SKILL.md workflow
- [ ] Pattern is appropriate for the task type
- [ ] No redundant content (things Claude already knows)
- [ ] `triggers:` field present in frontmatter for lazy-load activation

## Token Budget

At scale with 30+ skills:

| Tier | Per Skill | 30 Skills | When Loaded |
|------|-----------|-----------|-------------|
| Tier 1 (metadata) | ~100 tokens | ~3,000 tokens | Always |
| Tier 2 (SKILL.md) | ~1,000 tokens | Only active skill | On activate |
| Tier 3 (references) | ~2,000-5,000 tokens | Only when needed | On demand |

Without progressive disclosure, loading all 30 skills fully would cost ~90,000-150,000 tokens — half the context window. With it, the baseline cost is ~3,000 tokens.
