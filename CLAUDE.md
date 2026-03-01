# Plugin Ecosystem Project

## What We're Building
A modular plugin ecosystem where plugins build on each other:
1. **task-planner** — Generic wave-based task planning with verification and QA (foundation)
2. **brand-guideline** — Agency-grade brand guideline generator
3. **seo-plugin** — SEO strategy and audit based on brand positioning
4. **Plugin generator** — Built into task-planner: `/plugin:create` and `/plugin:build`
5. **Plugin versioning** — Built into task-planner: `/plugin:version` and `/plugin:migrate`
6. **Brainstorm & discovery** — Built into task-planner: `/brainstorm:start` and `/brainstorm:decide`
7. Future plugins (website-builder, content-engine, etc.) — created via the generator

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
- Plugin interview skills check for brainstorm decisions.yml before asking from scratch
- Every plugin has hooks in plugin.json (PreToolUse, PostToolUse, SessionStart, Stop)
- PreToolUse re-reads state.yml before Write/Edit/Bash — prevents goal drift
- Stop hook prevents premature completion — Claude cannot stop until skill is verified
- Research skills write to findings.md — intermediate discoveries persist across /compact
- 2-Action Rule: save to findings.md every 2 research operations (search, read, question)
- All errors logged to state.yml errors array — never repeat a failed approach

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
    .claude-plugin/plugin.json     # includes hooks: PreToolUse, PostToolUse, SessionStart, Stop
    commands/                      # plan-create, plan-execute, plan-status, plan-resume
                                   # plugin-create, plugin-build (Part 3)
                                   # plugin-migrate, plugin-version (Part 5)
                                   # brainstorm-start, brainstorm-decide, brainstorm-status (Part 6)
    skills/                        # wave-decomposer, file-ownership, verification-runner
                                   # plugin-design-interview, plugin-spec-generator,
                                   # plugin-execution-guide-generator, plugin-scaffolder (Part 3)
                                   # version-meta-stamper, version-compatibility-checker,
                                   # migration-guide-generator (Part 5)
                                   # brainstorm-session, brainstorm-decision-writer,
                                   # decision-reader (Part 6)
    agents/                        # qa-agent, worker-agent
    migrations/                    # MIGRATION-REGISTRY.yml
    resources/
      plan-schema.yml
      state-schema.yml             # Canonical state.yml schema (includes errors array)
      verification-registry.yml
      plugin-blueprint.md          # Canonical plugin structure reference
      schemas/archive/             # v1.0.0.yml archived schema
    scripts/
      check-file-conflicts.sh
      session-recovery.sh          # SessionStart hook script
      check-wave-complete.sh       # Stop hook script
  brand-guideline/                 # Brand plugin (complete)
    .claude-plugin/plugin.json     # version: "1.0.0", includes hooks
    commands/                      # brand-generate, brand-analyze, brand-audit, brand-switch
    skills/                        # 9 skills (identity through compile-and-export)
    migrations/                    # MIGRATION-REGISTRY.yml
    resources/
      templates/
        brand-reference-schema.yml
        state-schema.yml
        brand-manual-template.md
        brand-manual-template-docx-styles.yml
      schemas/archive/             # v1.0.0.yml archived schema
    scripts/
      session-recovery.sh          # Brand-specific session recovery
      check-wave-complete.sh       # Brand-specific completion gate
    CHANGELOG.md
  seo-plugin/                      # SEO plugin (complete)
    .claude-plugin/plugin.json     # version: "1.0.0", includes hooks
    commands/                      # strategy, audit, content-brief, export (invoked as /seo:strategy etc.)
    skills/                        # 8 skills (project-interview through compile-and-export, plus link-building)
    migrations/                    # MIGRATION-REGISTRY.yml
    resources/
      templates/
      examples/
      schemas/archive/             # v1.0.0.yml archived schema
    scripts/
      session-recovery.sh          # SEO-specific session recovery
      check-wave-complete.sh       # SEO-specific completion gate
      validate-plugin.sh           # Plugin structure validator
    CHANGELOG.md
shared/
  brand-context-loader/            # Shared skill — loads brand data for any plugin
                                   # Calls version-compatibility-checker before loading
docs/
  implementation-plan-v2.md
  addendum-assets-and-accessibility.md
  brand-asset-manifest.md
  verification-memory-planning-spec.md
  ecosystem-strategy.md
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
- [x] Step 24-38: All SEO plugin steps complete

### Part 5: Plugin Versioning & Migration ✅
- [x] Step 39: Skill — version-meta-stamper
- [x] Step 40: Skill — version-compatibility-checker
- [x] Step 41: Skill — migration-guide-generator
- [x] Step 42: /plugin:migrate command
- [x] Step 43: /plugin:version command
- [x] Step 44: Retrofit all plugins to v1.0.0 + integration test

### Part 6: Brainstorm & Discovery ✅
- [x] Step 45: Skill — brainstorm-session
- [x] Step 46: Skill — brainstorm-decision-writer
- [x] Step 47: /brainstorm:start, /brainstorm:decide, /brainstorm:status commands
- [x] Step 48: Skill — decision-reader utility
- [x] Step 49: Update existing interview skills to read decisions
- [x] Step 50: Test brainstorm-to-plugin flow end-to-end

### Retrofit: Context Engineering (pending — do BEFORE new plugins)

Adds hooks, findings persistence, error tracking, and session recovery to all
existing plugins. Parts 1-6 were built before these patterns existed. This
retrofit brings them up to the current standard defined in plugin-blueprint.md
Sections 8 and 13.

Reference: packages/task-planner/resources/plugin-blueprint.md Sections 8, 13

- [x] R1: task-planner — hooks + scripts
  - Add hooks section to .claude-plugin/plugin.json (PreToolUse, PostToolUse, SessionStart, Stop)
  - Create scripts/session-recovery.sh (detect resumed session, report state + git diff)
  - Create scripts/check-wave-complete.sh (verify current skill complete before allowing stop)
  - Test: run session-recovery.sh with and without state.yml
  - Test: run check-wave-complete.sh with in_progress vs completed status

- [x] R2: task-planner — state schema + error persistence
  - Create resources/state-schema.yml (canonical schema for all plugins)
  - Add errors array to schema (timestamp, skill, error, attempted_fix, result, next_approach)
  - Update verification-runner SKILL.md to log failures to state.yml errors
  - Update plan-execute command to read errors before retrying failed waves

- [x] R3: brand-guideline — hooks + scripts + findings
  - Add hooks section to .claude-plugin/plugin.json
  - Create scripts/session-recovery.sh (reads brand state.yml)
  - Create scripts/check-wave-complete.sh (checks brand skill completion)
  - Update identity-interview SKILL.md: add findings.md + 2-Action Rule + error logging
  - Update audience-personas SKILL.md: add findings.md + 2-Action Rule + error logging
  - Update tone-of-voice SKILL.md: add findings.md reference
  - Update compile-and-export SKILL.md: reference findings.md as additional context

- [x] R4: seo-plugin — hooks + scripts + findings
  - Add hooks section to .claude-plugin/plugin.json
  - Create scripts/session-recovery.sh (reads seo state.yml)
  - Create scripts/check-wave-complete.sh (checks seo skill completion)
  - Update project-interview SKILL.md: add findings.md + 2-Action Rule
  - Update keyword-research SKILL.md: add findings.md + 2-Action Rule (research-heavy)
  - Update competitor-analysis SKILL.md: add findings.md + 2-Action Rule (research-heavy)
  - Update technical-seo SKILL.md: add findings.md + error logging

- [x] R5: plugin generator — update scaffold templates
  - Update plugin-scaffolder skill to generate hooks in plugin.json by default
  - Update plugin-scaffolder to create scripts/session-recovery.sh and check-wave-complete.sh
  - Update plugin-execution-guide-generator to include findings/errors instructions in skill prompts
  - This ensures all FUTURE plugins get context engineering from day one

- [x] R6: README updates
  - Create packages/brand-guideline/README.md (missing entirely)
  - Update packages/task-planner/README.md (add hooks, findings, errors, session recovery sections)
  - Update packages/seo-plugin/README.md (add hooks, findings, brainstorm, versioning sections)

- [x] R7: Integration test
  - Run /brand:generate on a test brand — verify hooks fire, findings.md created, errors logged
  - Simulate a failure — verify error persisted in state.yml
  - Run /compact then resume — verify session-recovery.sh reports context
  - Verify check-wave-complete.sh blocks premature stop
  - Verify plugin-scaffolder generates hooks + scripts for new plugins

### Ecosystem Standards

- [x] S1: Progressive disclosure rule — SKILL.md 80-line limit, references/ overflow pattern, lean skill template, description quality checklist (blueprint Section 4)
- [x] S2: Model tier schema — model_tier field in plan-schema.yml, mapping table + heuristics in blueprint Section 11a
- [x] S3: Wave decomposer — Step 5a assigns model_tier to tasks using assignment rules + name-based heuristics
- [x] S4: Worker agent — reads model_tier from task, surfaces recommendation in completion report
- [x] S5: Execution guide generator — per-skill prompts include model tier and references/ pointers

- [x] S6: Brand-guideline progressive disclosure — all 9 skills split into lean SKILL.md (≤80 lines) + references/process.md, frontmatter descriptions enriched with trigger phrases

- [x] S7: SEO-plugin progressive disclosure — all 8 skills split into lean SKILL.md (≤80 lines) + references/process.md, frontmatter descriptions enriched with trigger phrases

- [x] S8: Task-planner progressive disclosure — all 13 skills split into lean SKILL.md (≤80 lines) + references/process.md, frontmatter descriptions enriched with trigger phrases. Full verification pass: line counts, description quality, references integrity, model tier system, plugin.json validity — all pass.

- [x] S9: Plugin generator pipeline — scaffolder creates progressive disclosure structure (lean SKILL.md + references/ for complex skills), spec generator includes model_tier on every task with tier distribution summary, design interview surfaces tier awareness during Q5

### Two-Stage Verification

- [x] V1: spec-compliance-reviewer skill — Stage 1 mechanical checks (file existence, schema presence, non-empty, file ownership, state consistency). Includes references/process.md and references/check-templates.md.
- [x] V2: Blueprint updated — two-stage verification flow documented in Section 5, new status values (failed_spec, failed_quality, passed_with_notes) added to state.yml schema
- [x] V3: qa-agent updated to act as Stage 2 — only runs after Stage 1 passes, 5 quality checks, 3 verdict levels
- [x] V4: verification-runner updated to orchestrate two-stage flow, plan-execute updated with combined 4c step
- [x] V5: Generators produce two-stage verification — execution guide generator includes two-stage block in per-skill prompts (10 required elements), spec generator produces split verification tasks (spec compliance junior + quality review principal with dependency). Full verification pass: all 6 check groups pass. spec-compliance-reviewer added to plugin.json.
- [x] V6: Integration test — packages/task-planner/tests/v6-two-stage-integration.md. Covers: Stage 1 FAIL (Stage 2 skipped, phase → failed_spec), Stage 1 PASS with Stage 2 gate logic (PASS → complete, PASS_WITH_NOTES → passed_with_notes, FAIL → failed_quality), qa_review:false shortcut (Stage 2 skipped when not required), retry behavior (Stage 1 re-runs on failed_spec fix; Stage 1 result cached on failed_quality retry). Decision matrix documents all 5 paths.

### Two-Stage Verification ✅ Complete

### Subagent-Driven Execution (pending)

Upgrades plan-execute to dispatch each task as an isolated subagent via Task()
tool. Parallel dispatch for independent tasks, per-task commits, model tier
enforcement. Pattern adapted from obra/superpowers.

Reference: docs/subagent-execution-plan.md

- [x] SE1: Prompt templates — worker-dispatch.md, spec-review-dispatch.md, quality-review-dispatch.md in resources/prompts/
- [x] SE2: Schema updates — add base_sha, commit_sha, execution_mode to plan-schema.yml; add commit_range to state-schema.yml
- [x] SE3: plan-execute step 4b rewrite — Task() dispatch per task, model tier mapping, subagent report collection
- [x] SE4: Per-task spec compliance dispatch — spec-compliance-reviewer as Haiku subagent after each task/wave
- [x] SE5: Git-scoped quality review — qa-agent receives BASE_SHA..HEAD_SHA, review scoped to wave diff
- [x] SE6: Worker agent update — commit protocol, structured report, self-review checklist, Q&A section
- [x] SE7: State management — orchestrator records commit SHAs, writes commit_range, error context from subagent reports
- [x] SE8: Parallel wave dispatch — multiple Task() calls in same turn when wave.parallel == true
- [x] SE9: Plugin blueprint update — Section 15: Subagent Execution
- [x] SE10: Plugin generator updates — execution guide generator + spec generator aware of subagent dispatch
- [ ] SE11: Integration test — sequential dispatch (2-wave plan)
- [ ] SE12: Integration test — parallel dispatch (parallel wave)
- [ ] SE13: Integration test — failure and retry
- [ ] SE14: Integration test — model tier enforcement

## Specs
Read the relevant spec BEFORE implementing. Do NOT try to build everything at once.

| File | What It Covers |
|------|---------------|
| docs/ecosystem-strategy.md | Full ecosystem architecture, 8 design questions, spec templates, brand-reference.yml schema, quality standards, versioning rules, hooks & context engineering (Section 5j) |
| docs/implementation-plan-v2.md | Brand plugin phases, YAML schemas, command definitions, skill list |
| docs/addendum-assets-and-accessibility.md | WCAG standards, color theory, logo process, software stack |
| docs/brand-asset-manifest.md | Complete asset list (~85 files), dimensions, generation scripts |
| docs/verification-memory-planning-spec.md | Checkpoints, state.yml, memory layers, task-planner design, QA agent |
| docs/seo-plugin-implementation-plan.md | SEO plugin skills, commands, YAML schema, build order |
| docs/seo-plugin-addendum.md | SEO domain knowledge, quality standards, common mistakes |
| docs/seo-plugin-execution-guide.md | Step-by-step SEO plugin build guide (15 steps) |
<!-- execution guide and planning analysis are maintained in claude.ai sessions, not yet committed to repo -->
| docs/subagent-execution-plan.md | Subagent dispatch architecture, prompt templates, schema changes, model tier mapping, parallel dispatch, integration tests |
| packages/task-planner/resources/plugin-blueprint.md | Plugin structure rules, file layout, checklist, verification profiles, versioning, hooks & context engineering (Section 13), brainstorm integration (Section 14) |
