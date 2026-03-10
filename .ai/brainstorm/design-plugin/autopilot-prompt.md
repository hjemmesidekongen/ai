# Design Plugin Groundwork — Autopilot

## Goal
Build the foundation of a `design` plugin at `plugins/design/`. Interprets brand strategy into concrete visual systems: color palettes, typography, spacing, design tokens.

## Source of Truth (read EVERY iteration)
1. `.ai/brainstorm/design-plugin/decisions.yml` — 12 architecture decisions
2. `.ai/brainstorm/design-plugin/findings.md` — external reference templates and patterns
3. `.ai/brainstorm/brand-plugin/decisions.yml` — brand output format (design reads this)
4. `.ai/brainstorm/design-plugin/learnings.md` — what you learned so far

## The Loop

You do NOT have a fixed plan. Every iteration is: discover → plan → build → learn.

### 1. Orient
- Read `learnings.md`
- Check what exists in `plugins/design/`
- Identify the SINGLE most important thing to build next

### 2. Research (mandatory before every build)
- For the chunk you're about to build, read the SPECIFIC external-reference files from findings.md
- Study how existing plugins (claude-core, dev-engine) implement the same pattern
- Key references to actually READ before building:
  - Color: `external-references/agents-main/plugins/ui-design/skills/visual-design-foundations/references/color-systems.md`
  - Tokens: `external-references/agents-main/plugins/ui-design/skills/design-system-patterns/references/design-tokens.md`
  - DTCG: `external-references/agent-toolkit-main/skills/design-system-starter/templates/design-tokens-template.json`
  - Aesthetics: `external-references/anthropics:skills-main/skills/canvas-design/SKILL.md`
  - Frontend: `external-references/anthropics:skills-main/skills/frontend-design/SKILL.md`
  - Tailwind: `external-references/antigravity-awesome-skills-main/skills/tailwind-design-system/`
- Don't read everything — read what's relevant to THIS chunk

### 3. Plan ONE chunk
- `/plan:create` for the next thing only. 1-3 tasks max.
- Do NOT plan future chunks.

### 4. Build it
- Production quality. Real schemas based on research.
- Follow plugin conventions from claude-core/dev-engine.

### 5. Verify
- Valid YAML/JSON, checkpoints defined, ecosystem.json accurate
- SKILL.md ≤ 80 lines

### 6. Commit
- One commit per chunk. Descriptive. No AI attribution.

### 7. Learn
- Append to `learnings.md`: what you built, what surprised you, what applies to next chunk.

### 8. Loop back to step 1.

## Constraints
- Design reads brand but NEVER writes to .ai/brand/
- Design outputs at .ai/design/{name}/
- Depends only on claude-core
- Context resolution: if brand guideline exists use it, if not ask user
- SKILL.md ≤ 80 lines, checkpoint required
- No AI attribution

## Definition of Done
- Plugin scaffold (plugin.json, ecosystem.json, marketplace entry)
- Skills: visual-identity, design-tokens, design-loader
- Commands: /design:identity, /design:tokens, /design:status
- Token schema documented (DTCG-aligned)
- Self-review passes

You decide the order. You adapt as you learn.

<promise>DESIGN PLUGIN GROUNDWORK COMPLETE AND VERIFIED</promise>
