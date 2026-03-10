# Studio Skills for Dev-Engine — Autopilot

## Goal
Add 6-8 knowledge skills to dev-engine under a "studio" domain. These skills teach agents how to do brand-aware, design-aware, content-aware work. They're reference material loaded by context-assembler, not standalone executors.

## Source of Truth
Read these at the START of every iteration:
- `.ai/brainstorm/studio-skills/decisions.yml` — 8 architecture decisions
- `.ai/brainstorm/brand-plugin/decisions.yml` — brand output format (studio consumes this)
- `.ai/brainstorm/design-plugin/decisions.yml` — design output format (studio consumes this)
- `.ai/brainstorm/studio-skills/learnings.md` — accumulated learnings (you write this)
- `plugins/dev-engine/skills/react-patterns/SKILL.md` — template to follow (read this before writing ANY skill)

## Iteration Loop

Every iteration:

1. **Read learnings.md** — what did previous iterations discover?
2. **Assess state** — which studio skills exist in `plugins/dev-engine/skills/`? What's missing?
3. **Research** — for the skill you're about to build, read relevant external-references first. Understand the domain before writing the skill.
4. **Plan ONE skill** — use `/plan:create` for just one skill at a time.
5. **Build it** — follow dev-engine SKILL.md conventions exactly. Study 2-3 existing skills first.
6. **Verify** — valid frontmatter, ≤80 lines, checkpoint defined, references/process.md for overflow.
7. **Update ecosystem.json** — add the new skill to dev-engine's component registry.
8. **Commit** — one commit per skill. Descriptive message. No AI attribution.
9. **Reflect** — append to `learnings.md`.
10. **Continue or complete.**

## Skills to Build (order by independence — no dependencies between them)

1. **brand-voice-implementation** — how to apply brand voice in UI microcopy, error messages, loading states, confirmations, empty states. When to be formal vs casual. Platform-specific tone. References brand voice.yml schema.

2. **content-strategy-patterns** — content pillar strategy, editorial calendars, content types (blog, social, email, video), repurposing matrix, pre-publishing checklists. Adapt from: `external-references/antigravity-awesome-skills-main/skills/content-creator/references/content_frameworks.md`

3. **marketing-plan-patterns** — campaign structure, messaging frameworks, audience segmentation, channel strategy, marketing psychology basics. Reference: `external-references/claude-code-templates-main/cli-tool/components/skills/business-marketing/marketing-psychology/SKILL.md`

4. **seo-fundamentals** — technical SEO (meta, schema, sitemap), keyword strategy, E-E-A-T framework, content gap analysis, on-page optimization. Reference: `external-references/agents-main/plugins/seo-analysis-monitoring/agents/seo-authority-builder.md`

5. **sitemap-planning** — information architecture, page hierarchy, user flows, navigation patterns, URL structure, content mapping to pages.

6. **design-to-code-patterns** — translating design specs/tokens into components. Token consumption, responsive implementation, component variant mapping, accessibility in branded components.

7. **brand-consistency-checking** — auditing content/code against brand guidelines. Voice consistency, visual consistency, messaging alignment. Checklist-based verification.

8. **web-copywriting** — headlines, CTAs, microcopy, error messages, onboarding copy, notification text. Conversion-focused writing patterns. Tone calibration per context.

## Constraints (non-negotiable)
- These are KNOWLEDGE skills — reference material, not executors. Like react-patterns, not like task-decomposer.
- Follow dev-engine SKILL.md template exactly (frontmatter, sections, checkpoint).
- SKILL.md ≤ 80 lines. Overflow → references/process.md.
- No dependencies on brand or design plugins existing. Skills describe patterns generically — they reference .ai/brand/ and .ai/design/ conventions but don't import anything.
- user_invocable: false (knowledge skills are loaded by context-assembler, not run directly).
- model_tier: junior or senior (knowledge, not creative judgment).
- No Co-Authored-By, no AI attribution in commits.

## External References to Study
- `external-references/antigravity-awesome-skills-main/skills/content-creator/` — content frameworks, brand guidelines reference
- `external-references/claude-code-templates-main/cli-tool/components/skills/business-marketing/` — content-creator, marketing-psychology
- `external-references/agents-main/plugins/seo-analysis-monitoring/` — SEO patterns
- `external-references/agents-main/plugins/content-marketing/` — content marketing agent
- `external-references/agents-main/plugins/ui-design/skills/design-system-patterns/` — design tokens consumption

## Definition of Done
- 6-8 studio knowledge skills in plugins/dev-engine/skills/
- Each skill has SKILL.md + references/process.md
- dev-engine ecosystem.json updated with all new skills
- Skill count in project CLAUDE.md updated
- Self-review passes for all skills
- All frontmatter valid and consistent

<promise>STUDIO SKILLS COMPLETE AND VERIFIED</promise>
