# Studio Skills for Dev-Engine — Autopilot

## Goal
Add knowledge skills to dev-engine covering content strategy, copywriting, SEO, marketing, and brand implementation. These are reference material loaded by agents during context assembly.

## Source of Truth (read EVERY iteration)
1. `.ai/brainstorm/studio-skills/decisions.yml` — 8 architecture decisions
2. `.ai/brainstorm/studio-skills/findings.md` — 15+ external reference skills to adapt
3. `.ai/brainstorm/studio-skills/learnings.md` — what you learned so far
4. `plugins/dev-engine/skills/react-patterns/SKILL.md` — template to follow (read before writing ANY skill)

## The Loop

You do NOT have a fixed plan. Every iteration is: discover → plan → build → learn.

### 1. Orient
- Read `learnings.md`
- Check what studio skills exist in `plugins/dev-engine/skills/`
- Identify the SINGLE most valuable skill to build next
- Priority signal: which skill would be most useful if brand + design plugins exist?

### 2. Research (mandatory before EACH skill)
- Read the SPECIFIC external-reference source listed in findings.md for this skill
- Read the FULL source file, not just the summary
- Read 2 existing dev-engine skills to refresh on conventions
- Understand the domain before writing a word

### 3. Plan ONE skill
- `/plan:create` for one skill. That's it.
- Include: SKILL.md structure, what goes in references/process.md, checkpoint definition

### 4. Build it
- SKILL.md ≤ 80 lines with proper frontmatter
- references/process.md for detailed content
- Adapt from external-reference, don't copy blindly — reformat to dev-engine conventions
- These are KNOWLEDGE skills (user_invocable: false, loaded by context-assembler)

### 5. Verify
- Valid frontmatter, checkpoint present, ≤80 lines
- Update dev-engine ecosystem.json with new skill

### 6. Commit
- One commit per skill. Descriptive. No AI attribution.

### 7. Learn
- Append to `learnings.md`: what you adapted, what didn't fit, patterns emerging across skills

### 8. Loop back to step 1.

## Key External References (read the actual files)
findings.md has the full list. Highest value:
- Copywriting: `external-references/antigravity-awesome-skills-main/skills/copywriting/SKILL.md`
- Copy editing: `external-references/antigravity-awesome-skills-main/skills/copy-editing/SKILL.md`
- SEO audit: `external-references/antigravity-awesome-skills-main/skills/seo-audit/SKILL.md`
- Content strategy: `external-references/antigravity-awesome-skills-main/skills/content-creator/`
- Marketing psych: `external-references/antigravity-awesome-skills-main/skills/marketing-psychology/SKILL.md`
- Social content: `external-references/antigravity-awesome-skills-main/skills/social-content/SKILL.md`
- Brand voice: `external-references/antigravity-awesome-skills-main/skills/brand-guidelines/SKILL.md`

## Constraints
- Knowledge skills only — reference material, not executors
- Follow dev-engine SKILL.md template exactly
- user_invocable: false
- No dependencies on brand or design plugins
- SKILL.md ≤ 80 lines
- No AI attribution

## Definition of Done
- 8+ studio knowledge skills in dev-engine/skills/
- Each has SKILL.md + references/process.md
- dev-engine ecosystem.json updated
- Skill count in project CLAUDE.md updated
- All frontmatter valid

You decide the order. You decide how many skills. You adapt as you learn.

<promise>STUDIO SKILLS COMPLETE AND VERIFIED</promise>
