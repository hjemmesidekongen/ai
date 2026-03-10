# Brand Plugin Build — Autopilot

## Goal
Build a complete, production-quality `brand` plugin at `plugins/brand/`. The plugin produces brand guidelines (voice, tone, values, positioning, dos/donts). It never produces design artifacts.

## Source of Truth
Read these at the START of every iteration:
- `.ai/brainstorm/brand-plugin/decisions.yml` — 18 final architecture decisions
- `.ai/brainstorm/brand-plugin/plan-prep.md` — skill specs, schemas, suggested order
- `.ai/brainstorm/brand-plugin/findings.md` — templates to adapt from external-references
- `.ai/brainstorm/brand-plugin/learnings.md` — accumulated learnings (you write this)

## Iteration Loop

Every iteration:

1. **Read learnings.md** — what did previous iterations discover?
2. **Assess state** — what exists in `plugins/brand/`? What's missing?
3. **Research if needed** — if the next piece requires studying patterns (e.g., how plugin.json hooks work, how a specific template is structured), do the research NOW, before planning.
4. **Plan ONE wave** — use `/plan:create` for just the next logical step. Keep it small.
5. **Build it** — production quality. Study existing plugins for conventions before writing.
6. **Verify** — files valid, checkpoint defined, ecosystem.json accurate, skills ≤80 lines.
7. **Commit** — one commit per wave. Descriptive message. No AI attribution.
8. **Reflect** — append to `learnings.md`: what worked, what surprised you, what to do differently next.
9. **Continue or complete** — if more to build, keep going. If plugin is complete and verified, output promise.

## Constraints (non-negotiable)
- Brand = strategy only. No hex codes, no CSS, no design tokens.
- Brand truth lives at `.ai/brand/{name}/` — not `.ai/projects/`.
- Depends only on claude-core. Zero imports from agency/dev-engine/taskflow.
- SKILL.md ≤ 80 lines, overflow → references/process.md.
- Every skill has a checkpoint section.
- Follow existing conventions from claude-core and dev-engine plugins.
- No Co-Authored-By, no AI attribution in commits.

## External References
Adapt templates from (read the actual files, don't guess):
- `external-references/Agent-Skills-for-Context-Engineering-main/examples/digital-brain-skill/identity/` — voice.md, brand.md, values.yaml
- `external-references/antigravity-awesome-skills-main/skills/content-creator/references/brand_guidelines.md`
- `external-references/superpowers-main/skills/brainstorming/SKILL.md`

## Definition of Done
- Plugin scaffold complete (plugin.json, ecosystem.json, marketplace entry)
- 4 skills: brand-strategy, brand-audit, brand-evolve, brand-loader
- 5 commands: /brand:create, /brand:audit, /brand:evolve, /brand:apply, /brand:status
- Output schemas defined and documented
- Self-review passes (use plugin-validator agent)
- All components match ecosystem.json

<promise>BRAND PLUGIN COMPLETE AND VERIFIED</promise>
