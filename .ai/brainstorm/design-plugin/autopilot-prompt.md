# Design Plugin Groundwork — Autopilot

## Goal
Build the foundation of a `design` plugin at `plugins/design/`. The plugin interprets brand strategy into concrete visual systems: color palettes, typography, spacing, design tokens. This is groundwork — scaffold, schemas, and core skills. Web design (Pencil) and component specs come later.

## Source of Truth
Read these at the START of every iteration:
- `.ai/brainstorm/design-plugin/decisions.yml` — 12 architecture decisions
- `.ai/brainstorm/brand-plugin/decisions.yml` — brand plugin decisions (design reads brand output)
- `.ai/brainstorm/brand-plugin/plan-prep.md` — brand output schemas (design consumes these)
- `.ai/brainstorm/design-plugin/learnings.md` — accumulated learnings (you write this)

## Iteration Loop

Every iteration:

1. **Read learnings.md** — what did previous iterations discover?
2. **Assess state** — what exists in `plugins/design/`? What's missing?
3. **Research if needed** — study existing plugins for conventions. Read external-references for design patterns. Check how design tokens are structured in real systems.
4. **Plan ONE wave** — use `/plan:create` for just the next logical step.
5. **Build it** — production quality. Real schemas, real skills.
6. **Verify** — valid YAML, checkpoints defined, ecosystem.json accurate.
7. **Commit** — one commit per wave. Descriptive message. No AI attribution.
8. **Reflect** — append to `learnings.md`.
9. **Continue or complete.**

## What to Build (in order of natural dependency)

### Foundation
- Plugin scaffold: plugin.json, ecosystem.json, directory structure, marketplace registration
- Output schemas: design token format, component spec format, screen index format

### Core Skills
- **visual-identity** — interactive skill. Reads brand guideline (if exists) or gathers direction from user. Produces color palette (with semantic mapping), typography system (families, scale, weights), spacing system. Output: .ai/design/{name}/visual-identity.yml
- **design-tokens** — reads visual-identity.yml, generates structured tokens in multiple formats: YAML source, CSS custom properties template, Tailwind theme template. Output: .ai/design/{name}/tokens/
- **design-loader** — read-only utility. Resolves design name, loads requested context layer. Like brand-loader but for design.

### Commands
- `/design:identity` — run visual-identity skill
- `/design:tokens` — generate design tokens from identity
- `/design:status` — show available designs and their state

## Constraints (non-negotiable)
- Design reads brand but NEVER writes to .ai/brand/. One-way data flow.
- Design outputs at .ai/design/{name}/ — not .ai/projects/.
- Depends only on claude-core. No imports from brand, agency, dev-engine, taskflow.
- Context resolution: if brand guideline exists, use it. If not, ask user for direction.
- SKILL.md ≤ 80 lines. Overflow → references/process.md.
- Every skill has a checkpoint section.
- Follow existing conventions from claude-core and dev-engine plugins.
- No Co-Authored-By, no AI attribution in commits.

## External References for Design
Read these when building skills:
- `external-references/agents-main/plugins/ui-design/skills/design-system-patterns/references/design-tokens.md` — token categories, naming, semantic mapping, governance
- `external-references/Agent-Skills-for-Context-Engineering-main/examples/digital-brain-skill/identity/` — how brand data is structured (design reads this)
- `external-references/claude-code-templates-main/cli-tool/components/skills/business-marketing/brand-guidelines-anthropic/SKILL.md` — brand-to-visual implementation example

## Token Schema Direction

Design tokens should follow DTCG (Design Tokens Community Group) conventions:
- Primitives: raw values (color.blue.500: #3b82f6)
- Semantics: purpose-mapped (color.primary: {$color.blue.500})
- Component-level: usage-specific (button.primary.background: {$color.primary})

Output formats: YAML source → CSS custom properties → Tailwind theme config

## Definition of Done
- Plugin scaffold complete (plugin.json, ecosystem.json, marketplace entry)
- 3 skills: visual-identity, design-tokens, design-loader
- 3 commands: /design:identity, /design:tokens, /design:status
- Token schema documented and valid
- Self-review passes
- All components match ecosystem.json

<promise>DESIGN PLUGIN GROUNDWORK COMPLETE AND VERIFIED</promise>
