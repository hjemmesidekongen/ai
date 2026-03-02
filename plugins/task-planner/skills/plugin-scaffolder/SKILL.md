---
name: plugin-scaffolder
description: >
  Creates the physical directory structure, plugin.json manifest, hook scripts,
  and README.md for a new plugin based on design.yml. Produces the empty scaffold
  that downstream build steps (schema, skills, commands) populate. Use when
  scaffolding a new plugin, running /plugin:build step 1, creating plugin
  directory structure, or generating plugin.json manifest.
interactive: false
depends_on:
  - plugin-execution-guide-generator
reads:
  - plugins/[plugin-name]/design.yml
  - docs/[plugin-name]-implementation-plan.md (for tools/dependencies from addendum)
  - docs/[plugin-name]-addendum.md (for tools/dependencies and domain context)
  - plugins/task-planner/resources/plugin-blueprint.md (Section 2: Required Plugin Structure)
writes:
  - plugins/[plugin-name]/.claude-plugin/plugin.json
  - plugins/[plugin-name]/commands/ (empty directory)
  - plugins/[plugin-name]/skills/[skill-name]/ (per-skill dirs with lean SKILL.md stubs + references/ for complex skills)
  - plugins/[plugin-name]/agents/ (empty directory, only if design.yml specifies agents)
  - plugins/[plugin-name]/resources/templates/ (empty directory)
  - plugins/[plugin-name]/resources/examples/ (empty directory)
  - plugins/[plugin-name]/scripts/ (empty directory)
  - plugins/[plugin-name]/README.md
checkpoint_type: file_validation
---

# Plugin Scaffolder

Autonomous skill that reads the approved `design.yml` and creates the complete
directory structure for a new plugin. After this skill runs, the plugin exists
on disk and is ready for schema creation and skill implementation.

## Context

- Reads: design.yml (approved), addendum.md (Section c), plugin-blueprint.md (Sections 2, 5)
- Writes: plugin.json (with hooks), scripts/session-recovery.sh, scripts/check-wave-complete.sh, README.md, all directories
- Checkpoint: file_validation (plugin.json valid JSON with hooks, all dirs exist, scripts executable, no placeholder text)
- Dependencies: plugin-execution-guide-generator

## Process Summary

1. Validate prerequisites — design.yml status must be "approved"; implementation-plan.md, addendum.md, execution-guide.md must all exist
2. Create directory structure — .claude-plugin/, commands/, skills/ (with per-skill subdirs using progressive disclosure: lean SKILL.md + references/ for complex skills), resources/templates/, resources/examples/, scripts/; agents/ only if design.yml defines agents
3. Generate plugin.json and ecosystem.json — plugin.json has name/version/description/hooks only (Claude Code schema); ecosystem.json has commands/skills/agents/dependencies from design.yml; dependencies include task-planner and brand-guideline if needs_brand; command names stripped of plugin prefix
4. Generate hook scripts — session-recovery.sh (reports state.yml phase, status, errors, findings, git diff) and check-wave-complete.sh (blocks stop if current skill not completed); both chmod +x
5. Generate README.md — overview, prerequisites (Required tools only), commands table, output, how it works (wave structure), brand data usage if needs_brand, installation, data storage
6. Verify brand context loader exists if needs_brand — STOP if shared/brand-context-loader/SKILL.md is missing
7. Update CLAUDE.md progress checklist — check off scaffold step, advance "Next step" pointer

## Execution

Read `references/process.md` for the complete process, output formats, and quality rules.
