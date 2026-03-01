# Plugin Ecosystem Project

## What We're Building
A modular plugin ecosystem where plugins build on each other:
1. **task-planner** — Generic wave-based task planning with verification and QA (foundation)
2. **brand-guideline** — Agency-grade brand guideline generator
3. **seo-plugin** — SEO strategy and audit based on brand positioning
4. **Plugin generator** — Built into task-planner: `/plugin:create` and `/plugin:build`
5. **Plugin versioning** — Built into task-planner: `/plugin:version` and `/plugin:migrate`
6. Future plugins (website-builder, content-engine, etc.) — created via the generator

## Architecture Rules (ALWAYS follow these)
- Every plugin follows the blueprint: packages/task-planner/resources/plugin-blueprint.md
- task-planner is a dependency of ALL other plugins
- Plugins that need brand data also depend on brand-guideline
- Every skill has a checkpoint — no self-grading
- Every multi-step command uses the task-planner for wave execution
- Dual output: machine-readable YAML + human-readable documents
- QA agent reviews all final output — implementing agents never self-grade
- Multi-agent runs use file-ownership to prevent write conflicts
- State persists via state.yml — always check it at session start
- Every plugin output YAML gets a `_meta` block with version stamps
- Data loaders check version compatibility before loading — block on major mismatches
- Every plugin has migrations/ directory with MIGRATION-REGISTRY.yml and CHANGELOG.md

## Creating a New Plugin
When asked to build a new plugin, ALWAYS read these two files FIRST:
1. docs/ecosystem-strategy.md — design process, 8 questions, spec templates, quality standards
2. packages/task-planner/resources/plugin-blueprint.md — structure, checklist, verification

Workflow:
1. Read both files above
2. Walk through the 8 design questions interactively with the user
3. Generate spec documents in docs/ (implementation plan, addendum, execution guide)
4. Add the new plugin to this Progress checklist
5. Build one skill at a time, /compact between each

Or use `/plugin:create [name]` and `/plugin:build [name]` to automate.

## Project Structure
```
packages/
  task-planner/                    # Foundation plugin (complete)
    .claude-plugin/plugin.json
    commands/                      # plan-create, plan-execute, plan-status, plan-resume
                                   # plugin-create, plugin-build (Part 3)
                                   # plugin-migrate, plugin-version (Part 5)
    skills/                        # wave-decomposer, file-ownership, verification-runner
                                   # plugin-design-interview, plugin-spec-generator,
                                   # plugin-execution-guide-generator, plugin-scaffolder (Part 3)
                                   # version-meta-stamper, version-compatibility-checker,
                                   # migration-guide-generator (Part 5)
    agents/                        # qa-agent, worker-agent
    resources/
      plan-schema.yml
      verification-registry.yml
      plugin-blueprint.md          # Canonical plugin structure reference
    scripts/
      check-file-conflicts.sh
  brand-guideline/                 # Brand plugin (complete)
    .claude-plugin/plugin.json     # version: "1.0.0" (set in Part 5)
    commands/                      # brand-generate, brand-analyze, brand-audit, brand-switch
    skills/                        # 9 skills (identity through compile-and-export)
    migrations/                    # MIGRATION-REGISTRY.yml (added in Part 5)
    resources/
      templates/
        brand-reference-schema.yml
        state-schema.yml
        brand-manual-template.md
        brand-manual-template-docx-styles.yml
      schemas/archive/             # v1.0.0.yml archived schema (added in Part 5)
    CHANGELOG.md                   # (added in Part 5)
  seo-plugin/                      # SEO plugin (complete)
    .claude-plugin/plugin.json     # version: "1.0.0" (set in Part 5)
    commands/                      # seo-strategy, seo-audit, seo-content-brief, seo-export
    skills/                        # 7 skills (project-interview through compile-and-export)
    migrations/                    # MIGRATION-REGISTRY.yml (added in Part 5)
    resources/
      templates/
      examples/
      schemas/archive/             # v1.0.0.yml archived schema (added in Part 5)
    scripts/
    CHANGELOG.md                   # (added in Part 5)
shared/
  brand-context-loader/            # Shared skill — loads brand data for any plugin
                                   # Updated in Part 5 to call version-compatibility-checker
docs/
  implementation-plan-v2.md
  addendum-assets-and-accessibility.md
  brand-asset-manifest.md
  verification-memory-planning-spec.md
  ecosystem-strategy.md
  claude-code-execution-guide.md
  seo-plugin-implementation-plan.md
  seo-plugin-addendum.md
  seo-plugin-execution-guide.md
```

## Progress

### Part 1: Task Planner ✅
- [x] Step 1: Planner scaffold + plugin.json
- [x] Step 2: Plan schema + verification registry
- [x] Step 3: Wave decomposer skill
- [x] Step 4: File ownership skill + conflict script
- [x] Step 5: Verification runner skill
- [x] Step 6: QA agent + worker agent template
- [x] Step 7: Plan commands (create, execute, status, resume)
- [x] Step 8: Planner dry-run test

### Part 2: Brand Guideline ✅
- [x] Step 9: Brand plugin scaffold + brand-context-loader
- [x] Step 10a: Skill — identity-interview
- [x] Step 10b: Skill — audience-personas
- [x] Step 10c: Skill — tone-of-voice
- [x] Step 10d: Skill — typography-color
- [x] Step 10e: Skill — visual-identity
- [x] Step 10f: Skill — logo-design
- [x] Step 10g: Skill — content-rules
- [x] Step 10h: Skill — social-media
- [x] Step 10i: Skill — compile-and-export
- [x] Step 11: /brand:generate command
- [x] Step 12: End-to-end test
- [x] Step 13: Brand manual template + docx styles
- [x] Step 14: /brand:analyze command
- [x] Step 15: /brand:audit command
- [x] Step 16: /brand:switch command + update brand-context-loader

### Part 3: Plugin Generator ✅
- [x] Step 17: Skill — plugin-design-interview
- [x] Step 18: Skill — plugin-spec-generator
- [x] Step 19: Skill — plugin-execution-guide-generator
- [x] Step 20: Skill — plugin-scaffolder
- [x] Step 21: /plugin:create command
- [x] Step 22: /plugin:build command
- [x] Step 23: Test plugin generator end-to-end

### Part 4: SEO Plugin ✅ (built via /plugin:create)
- [x] Step 24: seo-plugin scaffold + plugin.json
- [x] Step 25: YAML schema + document templates
- [x] Step 26: Skill — project-interview
- [x] Step 27: Skill — keyword-research
- [x] Step 28: Skill — competitor-analysis
- [x] Step 29: Skill — technical-seo
- [x] Step 30: Skill — on-page-optimization
- [x] Step 31: Skill — content-strategy
- [x] Step 32: Skill — link-building
- [x] Step 33: Skill — compile-and-export
- [x] Step 34: Command — /seo:strategy
- [x] Step 35: Command — /seo:audit
- [x] Step 36: Command — /seo:content-brief
- [x] Step 37: Command — /seo:export
- [x] Step 38: End-to-end test

### Part 5: Plugin Versioning & Migration ✅
- [x] Step 39: Skill — version-meta-stamper
- [x] Step 40: Skill — version-compatibility-checker
- [x] Step 41: Skill — migration-guide-generator
- [x] Step 42: /plugin:migrate command
- [x] Step 43: /plugin:version command
- [x] Step 44: Retrofit all plugins to v1.0.0 + integration test

All parts complete. Use /plugin:create and /plugin:build to add new plugins.

## Specs
Read the relevant spec BEFORE implementing. Do NOT try to build everything at once.

| File | What It Covers |
|------|---------------|
| docs/ecosystem-strategy.md | Full ecosystem architecture, 8 design questions, spec templates, brand-reference.yml schema, quality standards, versioning rules |
| docs/implementation-plan-v2.md | Brand plugin phases, YAML schemas, command definitions, skill list |
| docs/addendum-assets-and-accessibility.md | WCAG standards, color theory, logo process, software stack |
| docs/brand-asset-manifest.md | Complete asset list (~85 files), dimensions, generation scripts |
| docs/verification-memory-planning-spec.md | Checkpoints, state.yml, memory layers, task-planner design, QA agent |
| docs/claude-code-execution-guide.md | Step-by-step build instructions with per-skill prompts (Parts 1-5) |
| docs/seo-plugin-implementation-plan.md | SEO plugin skills, commands, YAML schema, build order |
| docs/seo-plugin-addendum.md | SEO domain knowledge, quality standards, common mistakes |
| docs/seo-plugin-execution-guide.md | Step-by-step SEO plugin build guide (15 steps) |
| packages/task-planner/resources/plugin-blueprint.md | Plugin structure rules, file layout, checklist, verification profiles, versioning requirements |
