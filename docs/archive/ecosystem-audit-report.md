# Ecosystem Audit Report

**Date:** 2026-03-01
**Auditor:** Claude Code (READ-ONLY audit)
**Scope:** All 3 plugins (task-planner, brand-guideline, seo-plugin), shared infrastructure, docs, schemas

---

## Summary

| Metric | Count |
|--------|-------|
| Total checks | 142 |
| Passed | 122 |
| Issues | 16 |
| Missing | 4 |

**Overall health: 86% pass rate.** The ecosystem is structurally sound. Most issues are plugin.json declaration drift (commands/skills added to disk but never registered in the manifest). Two documentation files referenced in CLAUDE.md don't exist on disk. task-planner is missing migrations/ infrastructure that the other two plugins have.

---

## Critical Issues (must fix)

### C1. task-planner plugin.json missing 5 commands
**File:** `plugins/task-planner/.claude-plugin/plugin.json`
**Problem:** Commands added in Parts 3 and 6 were never registered in the `commands` array.
**Missing:** `brainstorm-decide`, `brainstorm-start`, `brainstorm-status`, `plugin-build`, `plugin-create`
**Impact:** These commands won't be discoverable by the plugin system.

### C2. task-planner plugin.json missing 7 skills (and has 1 ghost)
**File:** `plugins/task-planner/.claude-plugin/plugin.json`
**Problem:** Skills added in Parts 3 and 6 were never registered. `qa-reviewer` is declared but doesn't exist on disk.
**Missing:** `brainstorm-decision-writer`, `brainstorm-session`, `decision-reader`, `plugin-design-interview`, `plugin-execution-guide-generator`, `plugin-scaffolder`, `plugin-spec-generator`
**Ghost:** `qa-reviewer` (declared in JSON, no matching directory)

### C3. brand-guideline plugin.json missing 3 skills
**File:** `plugins/brand-guideline/.claude-plugin/plugin.json`
**Problem:** Three core skills used in `/brand:generate` are not declared.
**Missing:** `compile-and-export`, `identity-interview`, `logo-design`

### C4. Two docs files referenced in CLAUDE.md don't exist
**Files:**
- `docs/claude-code-execution-guide.md` — referenced at CLAUDE.md lines 112, 248
- `docs/planning-with-files-analysis.md` — referenced at CLAUDE.md lines 116, 184, 252
**Impact:** CLAUDE.md instructs readers to consult these files, but they can't be found.

---

## Non-Critical Issues (should fix)

### N1. CLAUDE.md says seo-plugin has "7 skills" — it has 8
The `link-building` skill exists on disk and in plugin.json but CLAUDE.md's project structure comment says "7 skills (project-interview through compile-and-export)".

### N2. seo-plugin `resources/examples/` directory missing
CLAUDE.md lists this directory but it doesn't exist on disk. Either create it or remove the reference.

### N3. seo-plugin has undocumented `validate-plugin.sh` script
`plugins/seo-plugin/scripts/validate-plugin.sh` (22KB) exists but isn't listed in CLAUDE.md's project structure.

### N4. task-planner missing migrations/ infrastructure
Violates Quality Standard #12 ("Every plugin has a migrations/ directory"). brand-guideline and seo-plugin both have:
- `migrations/MIGRATION-REGISTRY.yml`
- `resources/schemas/archive/v1.0.0.yml`

task-planner has neither. It does have `CHANGELOG.md` and `version: "1.0.0"` in plugin.json.

### N5. seo-plugin command naming convention
Commands on disk use short names (`strategy.md`, `audit.md`, `content-brief.md`, `export.md`) without the `seo-` prefix. This matches plugin.json (which stores stripped names) but differs from CLAUDE.md's notation (`seo-strategy`, `seo-audit`, etc.). Not a bug — just a documentation inconsistency.

### N6. plugin-version command has limited recovery
All other multi-step commands have explicit Recovery sections. `plugin-version` only has re-entry detection for partially-completed bumps (lines 318-331) but no formal rollback documentation.

### N7. Utility skills lack checkpoint documentation
6 skills are utility/infrastructure skills that intentionally have no checkpoint section. They work correctly but could benefit from an explicit note in their frontmatter:
- `verification-runner`, `decision-reader`, `version-meta-stamper`, `version-compatibility-checker`, `migration-guide-generator` (task-planner)
- `brand-context-loader` (shared)

---

## Detailed Results

### 1. File Existence

**task-planner (38 items):**
- plugin.json: ✅
- 11 commands: ✅ all present
- 13 skill directories with SKILL.md: ✅ all present
- 2 agent files: ✅ both present
- 4 resource files: ✅ all present
- 3 scripts: ✅ all present
- README.md: ✅

**brand-guideline (22 items):**
- plugin.json: ✅
- 4 commands: ✅ all present
- 9 skill directories: ✅ all present
- migrations/MIGRATION-REGISTRY.yml: ✅
- 4 template files: ✅ all present
- schemas/archive/v1.0.0.yml: ✅
- 2 scripts: ✅ both present
- CHANGELOG.md: ✅
- README.md: ✅

**seo-plugin (21 items):**
- plugin.json: ✅
- 4 commands: ✅ all present
- 8 skill directories: ✅ all present (including link-building)
- migrations/MIGRATION-REGISTRY.yml: ✅
- resources/templates/: ✅ (3 files: seo-strategy-schema.yml, seo-strategy-template.md, state-schema.yml)
- resources/examples/: ❌ MISSING
- schemas/archive/v1.0.0.yml: ✅
- 3 scripts: ✅ (includes extra validate-plugin.sh)
- CHANGELOG.md: ✅
- README.md: ✅

**shared:**
- brand-context-loader/SKILL.md: ✅

**docs (10 items):**
- ecosystem-strategy.md: ✅
- implementation-plan-v2.md: ✅
- addendum-assets-and-accessibility.md: ✅
- brand-asset-manifest.md: ✅
- verification-memory-planning-spec.md: ✅
- claude-code-execution-guide.md: ❌ MISSING
- seo-plugin-implementation-plan.md: ✅
- seo-plugin-addendum.md: ✅
- seo-plugin-execution-guide.md: ✅
- planning-with-files-analysis.md: ❌ MISSING

**Unexpected files on disk (not in CLAUDE.md):**
- ⚠️ `plugins/seo-plugin/skills/link-building/` — undocumented skill
- ⚠️ `plugins/seo-plugin/scripts/validate-plugin.sh` — undocumented script
- ⚠️ `docs/ecosystem-strategy.md` — exists but also listed, just noting extra `.DS_Store` and `plugin-blueprint.md` in docs/

---

### 2. plugin.json Consistency

| Check | task-planner | brand-guideline | seo-plugin |
|-------|:---:|:---:|:---:|
| File exists | ✅ | ✅ | ✅ |
| Valid JSON | ✅ | ✅ | ✅ |
| Commands match disk | ⚠️ 6/11 | ✅ 4/4 | ✅ 4/4 |
| Skills match disk | ⚠️ 6/13 (+1 ghost) | ⚠️ 6/9 | ✅ 8/8 |
| Agents match disk | ✅ 2/2 | ✅ (none) | ✅ (none) |
| Dependencies correct | ✅ [] | ✅ [task-planner] | ✅ [task-planner, brand-guideline] |
| Version semver | ✅ 1.0.0 | ✅ 1.0.0 | ✅ 1.0.0 |
| Hooks section | ✅ all 4 | ✅ all 4 | ✅ all 4 |
| Hook scripts exist | ✅ | ✅ | ✅ |
| shared_skills (ecosystem.json) | N/A | ✅ [brand-context-loader] | ✅ [brand-context-loader] |
| brand_directory (ecosystem.json) | N/A | ✅ | ✅ |
| data_directory (ecosystem.json) | N/A | N/A | ✅ |

---

### 3. Skill Completeness

**30 total skills audited across ecosystem.**

| Plugin | Skills | SKILL.md | Checkpoint | Output Section |
|--------|:---:|:---:|:---:|:---:|
| task-planner | 13 | 13/13 ✅ | 8/13 ✅ (5 utility) | 13/13 ✅ |
| brand-guideline | 9 | 9/9 ✅ | 9/9 ✅ | 9/9 ✅ |
| seo-plugin | 8 | 8/8 ✅ | 8/8 ✅ | 8/8 ✅ |
| shared | 1 | 1/1 ✅ | 0/1 (utility) | 1/1 ✅ |

All checkpoint types used by skills are registered in `verification-registry.yml`:
- `data_validation` — 21 skills ✅
- `accessibility_validation` — 1 skill (typography-color) ✅
- `file_validation` — 5 skills ✅
- `schema_validation` — 2 skills ✅
- `manual_approval` — registered, unused ✅
- `seo_audit` — registered by seo-plugin ✅

---

### 4. Command Completeness

**19 total commands across ecosystem.**

| Plugin | Commands | Skill refs | Recovery |
|--------|:---:|:---:|:---:|
| task-planner | 11/11 ✅ | 11/11 ✅ | 10/11 ✅ (plugin-version partial) |
| brand-guideline | 4/4 ✅ | 4/4 ✅ | 4/4 ✅ (2 intentionally non-resumable) |
| seo-plugin | 4/4 ✅ | 4/4 ✅ | 4/4 ✅ (3 single-pass, no recovery needed) |

Commands without recovery sections are appropriately single-pass or read-only:
- `plan-status`, `brainstorm-status` — read-only queries
- `brand-analyze`, `brand-audit`, `brand-switch` — single-pass or config
- `seo:audit`, `seo:content-brief`, `seo:export` — single-pass

---

### 5. Cross-Reference Integrity

| Check | Status | Details |
|-------|--------|---------|
| CLAUDE.md spec table files exist | ⚠️ 9/11 | Missing: claude-code-execution-guide.md, planning-with-files-analysis.md |
| plugin-blueprint.md Section 13 | ✅ | "Hooks & Context Engineering" at line 724 |
| plugin-blueprint.md Section 14 | ✅ | "Brainstorm Integration" at line 832 |
| plugin-blueprint.md all sections | ✅ | Sections 1-14 all present |
| ecosystem-strategy.md 5a-5j | ✅ | All 10 subsections present |
| brand-reference-schema.yml sections | ✅ | 9 top-level sections (meta, identity, visual, typography, colors, voice, audience, content, social) |
| Brand skills → schema section refs | ✅ | All 9 skills reference correct sections |

---

### 6. Schema Alignment

| Schema | Status | Details |
|--------|--------|---------|
| plan-schema.yml | ✅ | Defines waves, tasks, verification, file ownership, recovery |
| verification-registry.yml | ✅ | Core types + domain-specific, seo_plugin_profile registered |
| brand-reference-schema.yml | ✅ | 825+ lines, 9 sections, includes accessibility (contrast pairs, colorblind) |
| state-schema.yml (canonical) | ✅ | Errors array with timestamp/skill/error/attempted_fix/result/next_approach |
| seo-strategy-schema.yml | ✅ | 626 lines, complete SEO data structure |
| brand state-schema.yml | ✅ | Plugin-specific extension of canonical |
| seo state-schema.yml | ✅ | Plugin-specific extension of canonical |

---

### 7. Version & Migration Infrastructure

| Check | task-planner | brand-guideline | seo-plugin |
|-------|:---:|:---:|:---:|
| migrations/ dir | ❌ | ✅ | ✅ |
| MIGRATION-REGISTRY.yml | ❌ | ✅ | ✅ |
| CHANGELOG.md | ✅ | ✅ | ✅ |
| schemas/archive/ | ❌ | ✅ | ✅ |
| schemas/archive/v1.0.0.yml | ❌ | ✅ | ✅ |
| plugin.json version | ✅ 1.0.0 | ✅ 1.0.0 | ✅ 1.0.0 |

---

### 8. Shared Infrastructure

| Check | Status | Details |
|-------|--------|---------|
| brand-context-loader/SKILL.md exists | ✅ | Well-structured, 267 lines |
| References version-compatibility-checker | ✅ | Lines 126-159 |
| Resolution order defined | ✅ | explicit → active-brand.yml → only brand → ask (lines 36-72) |
| Section access patterns documented | ✅ | Lines 165-193 |

---

### 9. Blueprint vs Reality

| Check | Status | Details |
|-------|--------|---------|
| Section 13 exists | ✅ | "Hooks & Context Engineering" at blueprint line 724 |
| Section 14 exists | ✅ | "Brainstorm Integration" at blueprint line 832 |
| All plugins have all 4 hooks | ✅ | PreToolUse, PostToolUse, SessionStart, Stop verified in all 3 |
| decision-reader skill exists | ✅ | 267 lines, implements both modes |
| Quality standards 1-19 | ✅ | All 19 listed at blueprint lines 624-646 |

---

### 10. Documentation Staleness

| Check | Status | Details |
|-------|--------|---------|
| References to brainstorm-modes-registry.yml | ✅ | None found (correctly removed) |
| References to brainstorm-techniques.yml | ✅ | None found (correctly removed) |
| References to brainstorm-engine | ✅ | None found (correctly replaced) |
| Dangling file references in CLAUDE.md | ⚠️ | 2 files referenced but missing (see C4) |
| Stale content in any doc | ✅ | No outdated patterns detected |

---

## Recommendations (prioritized)

### Priority 1 — Fix plugin.json declarations
1. **task-planner plugin.json**: Add 5 missing commands, add 7 missing skills, remove `qa-reviewer` ghost entry
2. **brand-guideline plugin.json**: Add 3 missing skills (`compile-and-export`, `identity-interview`, `logo-design`)

### Priority 2 — Fix CLAUDE.md references
3. Either create `docs/claude-code-execution-guide.md` and `docs/planning-with-files-analysis.md`, or remove their references from CLAUDE.md's project structure and specs table

### Priority 3 — Structural consistency
4. Create `plugins/task-planner/migrations/` with `MIGRATION-REGISTRY.yml` and `resources/schemas/archive/v1.0.0.yml` to match other plugins
5. Create `plugins/seo-plugin/resources/examples/` (empty dir) or remove from CLAUDE.md
6. Update CLAUDE.md to mention `link-building` skill (8 skills, not 7)

### Priority 4 — Documentation polish
7. Add explicit "no checkpoint needed — utility skill" notes to the 6 utility skills
8. Document `validate-plugin.sh` in CLAUDE.md or seo-plugin README
9. Clarify seo-plugin command naming convention in CLAUDE.md (short names on disk vs prefixed names in docs)
