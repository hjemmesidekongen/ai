# Agency Plugin — Port Coverage Audit

**Date:** 2026-03-03
**Auditor:** Self-review (principal tier, t40)
**Scope:** Verify all existing skills across brand-guideline, seo-plugin, and dev plugins are
accounted for (PORT or DEFERRED), all quality patterns are represented, and progressive
disclosure is enforced.

---

## Executive Summary

| Check | Result | Details |
|-------|--------|---------|
| Brand skills accounted for | PASS | 1 ported, 9 deferred |
| SEO skills accounted for | PASS | All 8 deferred |
| Dev skills accounted for | PASS | 8 ported, 3 deferred (+ 2 new) |
| Model tier on every skill | PASS | 20/20 SKILL.md files have model_tier |
| Progressive disclosure (<= 80 lines) | PASS | All 20 SKILL.md files ≤ 80 lines |
| References/process.md present | PASS | All 20 skills have process.md |
| Error logging (state.yml) | PARTIAL | 19/20 — asset-registry missing |
| Findings persistence (2-Action Rule) | PARTIAL | 12/20 — brand/design/content lacking |
| Design token compliance in code-review | PASS | Fully documented |
| Asset registry integration | PASS | All asset-producing skills reference it |
| Two-stage verification documented | PARTIAL | 8/20 — dev/devops only |
| Agent model tiers present | PASS | All 12 agents have model_tier |

**Overall verdict: PASS with notes.** The plugin is structurally complete and MVP-ready.
Three quality pattern gaps exist across brand, content, and design modules (findings
persistence, two-stage verification, one error logging gap) and are documented as
post-MVP recommendations below.

---

## 1. Brand-Guideline Skill Coverage

**Source:** `plugins/brand-guideline/.claude-plugin/ecosystem.json`
**Brand plugin skills (9):** identity-interview, audience-personas, tone-of-voice,
typography-color, visual-identity, logo-design, content-rules, social-media, compile-and-export

### Accounted for

| Skill | Status | Location |
|-------|--------|----------|
| identity-interview | DEFERRED | defer-01 (brand generation pipeline) |
| audience-personas | DEFERRED | defer-01 (brand generation pipeline) |
| tone-of-voice | DEFERRED | defer-01 (brand generation pipeline) |
| typography-color | DEFERRED | defer-01 (brand generation pipeline) |
| visual-identity | DEFERRED | defer-01 (brand generation pipeline) |
| logo-design | DEFERRED | defer-01 (brand generation pipeline) |
| content-rules | DEFERRED | defer-01 + defer-04 (content governance) |
| social-media | DEFERRED | defer-01 + defer-03 (social media templates) |
| compile-and-export | DEFERRED | defer-01 + defer-02 (brand manual export) |
| brand-context-loader (shared) | PORT → brand-loader | `plugins/agency/skills/brand/brand-loader/` |

**Result: PASS.** All 9 generation skills are deferred with rationale (Blik already has
brand-reference.yml — generation pipeline is not needed for MVP). The read path is
covered by brand-loader. The shared `brand-context-loader` from the original plugin
is effectively replaced by brand-loader.

---

## 2. SEO Plugin Skill Coverage

**Source:** `plugins/seo-plugin/.claude-plugin/ecosystem.json`
**SEO plugin skills (8):** project-interview, keyword-research, competitor-analysis,
technical-seo, on-page-optimization, content-strategy, link-building, compile-and-export

### Accounted for

| Skill | Status | Location |
|-------|--------|----------|
| project-interview | DEFERRED | defer-05 (SEO module — full pipeline) |
| keyword-research | DEFERRED | defer-05 + defer-06 (standalone option) |
| competitor-analysis | DEFERRED | defer-05 + defer-07 (standalone option) |
| technical-seo | DEFERRED | defer-05 + defer-08 (standalone option) |
| on-page-optimization | DEFERRED | defer-05 (SEO module — full pipeline) |
| content-strategy | DEFERRED | defer-05 + defer-09 (standalone option) |
| link-building | DEFERRED | defer-05 + defer-10 (standalone option) |
| compile-and-export | DEFERRED | defer-05 (SEO module — full pipeline) |

**Result: PASS.** All 8 SEO skills are deferred under defer-05 (full pipeline), with
6 of 8 also having individual deferred entries for standalone port paths. The SEO
module (`agency/skills/seo/`) does not exist yet — this is by design.

---

## 3. Dev Plugin Skill Coverage

**Source:** `plugins/dev/.claude-plugin/ecosystem.json`
**Dev plugin skills (11):** project-scanner, config-generator, knowledge-initializer,
feature-decomposer, team-planner, agent-dispatcher, tier-assigner, completion-gate,
code-review, qa-validation, delta-scanner

### Accounted for

| Skill | Status | Location |
|-------|--------|----------|
| project-scanner | PORT | `plugins/agency/skills/dev/project-scanner/` |
| config-generator | PORT | `plugins/agency/skills/dev/config-generator/` |
| knowledge-initializer | DEFERRED | defer-15 (multi-project knowledge base) |
| feature-decomposer | PORT | `plugins/agency/skills/dev/feature-decomposer/` |
| team-planner | PORT | `plugins/agency/skills/dev/team-planner/` |
| agent-dispatcher | PORT | `plugins/agency/skills/dev/agent-dispatcher/` |
| tier-assigner | DEFERRED | defer-16 (superseded by task-planner model_tier) |
| completion-gate | PORT | `plugins/agency/skills/dev/completion-gate/` |
| code-review | PORT | `plugins/agency/skills/dev/code-review/` |
| qa-validation | PORT | `plugins/agency/skills/dev/qa-validation/` |
| delta-scanner | DEFERRED | defer-17 (incremental re-scan optimization) |

**NEW skills (no source in dev plugin):**

| Skill | Module | Rationale |
|-------|--------|-----------|
| scaffold | dev | New: generates project file/folder structure from config |
| storybook-generator | dev | New: generates Storybook setup and story stubs |

**Result: PASS.** 8 of 11 dev skills ported, 3 deferred with documented rationale.
2 new agency-specific skills added to the dev module.

**Dev agents comparison:**

Dev plugin had 15 agents (5 leadership + 10 specialist). Agency has 12 agents
(5 leadership + 7 specialist). Missing from dev → agency:
- mobile-developer (deferred — Blik is web-only)
- seo-expert (deferred — SEO module deferred)
- designer (merged into design-ux in agency)

All 12 agency agents have `model_tier` specified.

---

## 4. Quality Pattern Verification

### 4a. Model Tier on Every Skill

All 20 SKILL.md files contain `model_tier` in frontmatter. Distribution:

| Tier | Count | Skills |
|------|-------|--------|
| junior | 3 | brand-loader, asset-registry, project-scanner |
| senior | 10 | app-copy, ux-writing, design-tokens, web-layout, config-generator, scaffold, storybook-generator, agent-dispatcher, deploy-config, deploy-execute |
| principal | 7 | logo-assets, component-specs, feature-decomposer, team-planner, qa-validation, code-review, completion-gate* |

*completion-gate is listed as junior in its SKILL.md.

**Result: PASS.**

### 4b. Findings Persistence (2-Action Rule)

Skills that reference `findings.md` or the 2-Action Rule (in SKILL.md or references/process.md):

| Status | Skills |
|--------|--------|
| PRESENT | agent-dispatcher, code-review, completion-gate, config-generator, feature-decomposer, project-scanner, qa-validation, scaffold, storybook-generator, team-planner, deploy-config, deploy-execute (12/20) |
| MISSING | brand-loader, app-copy, ux-writing, asset-registry, component-specs, design-tokens, logo-assets, web-layout (8/20) |

**Result: PARTIAL — GAP IDENTIFIED.**

The brand, content, and design module skills (8 of 20) do not reference the findings.md
pattern or the 2-Action Rule. For non-research-heavy skills (asset-registry, brand-loader)
this gap is lower risk. For logo-assets, design-tokens, component-specs, and web-layout —
which involve iterative specification work — the omission increases context loss risk
during `/compact` or session interruption.

**Recommendation:** Add findings.md references to all 8 non-dev/devops skills in a
follow-up pass (see Section 7).

### 4c. Error Logging (state.yml errors array)

Skills that reference error logging to state.yml:

| Status | Skills |
|--------|--------|
| PRESENT | brand-loader, app-copy, ux-writing, component-specs, design-tokens, logo-assets, web-layout, agent-dispatcher, code-review, completion-gate, config-generator, feature-decomposer, project-scanner, qa-validation, scaffold, storybook-generator, team-planner, deploy-config, deploy-execute (19/20) |
| MISSING | asset-registry (1/20) |

**Result: PARTIAL — MINOR GAP.**

The asset-registry skill is a utility skill with no checkpoint (`checkpoint: none`).
Its error handling is documented in process.md via a dedicated Error Handling table
(invalid type/format → reject; duplicate ID → update). The omission of a state.yml
errors array reference is acceptable for a utility skill but should be noted.

**Recommendation:** Add a brief error logging note to asset-registry process.md.

### 4d. Design Token Compliance

The code-review skill has comprehensive design token compliance documentation:
- Reads design tokens from `.ai/projects/[name]/design/tokens/`
- Audits all UI files for hardcoded color, spacing, and typography values
- Reports `design_token_violations` count
- Checkpoint includes `design_token_compliance` verification field
- Tech leads (frontend-tech-lead) specifically call out design token validation

**Result: PASS.**

### 4e. Asset Registry Integration

Skills that produce assets and reference asset-registry.yml:

| Module | Skills with asset registry integration |
|--------|----------------------------------------|
| brand | brand-loader (reads), all brand content skills (writes brand-reference.yml) |
| design | asset-registry (manages), logo-assets (registers SVGs), design-tokens (registers token files), component-specs (registers specs), web-layout (registers layouts) |
| content | app-copy (registers copy YAML), ux-writing (registers microcopy) |
| dev | storybook-generator (registers story files) |
| devops | deploy-config (registers deploy manifests) |

**Result: PASS.** Asset-producing skills across all modules reference asset-registry.yml.

### 4f. Two-Stage Verification

Skills with documented two-stage verification (Stage 1 spec compliance + Stage 2 quality):

| Status | Skills |
|--------|--------|
| PRESENT | agent-dispatcher, code-review, config-generator, feature-decomposer, project-scanner, qa-validation, team-planner, deploy-config (8/20) |
| MISSING | brand-loader, app-copy, ux-writing, asset-registry, component-specs, design-tokens, logo-assets, web-layout, completion-gate, scaffold, storybook-generator, deploy-execute (12/20) |

**Result: PARTIAL — GAP IDENTIFIED.**

Two-stage verification is documented only in dev module skills (plus deploy-config).
Brand, content, and design module skills do not include the two-stage verification
block in their process.md files. Utility skills (asset-registry) and execution
skills (completion-gate, deploy-execute) may appropriately omit it, but the 5
active-output skills (logo-assets, design-tokens, component-specs, web-layout,
app-copy, ux-writing) should include it.

**Recommendation:** Add two-stage verification blocks to the 6 active-output skills
that are missing it.

---

## 5. Progressive Disclosure Enforcement

All 20 SKILL.md files are within the 80-line limit:

| Lines | Skills |
|-------|--------|
| ≤ 60 | brand-loader (60), asset-registry (53), deploy-execute (62) |
| 61–70 | app-copy (73), ux-writing (73), component-specs (69), deploy-config (73), completion-gate (73), scaffold (72), web-layout (72) |
| 71–79 | design-tokens (77), logo-assets (79), code-review (77), config-generator (78), feature-decomposer (77), qa-validation (75), storybook-generator (80) |
| = 80 | project-scanner (80), team-planner (80), agent-dispatcher (79) |

**At the 80-line limit:** project-scanner (80), team-planner (80), storybook-generator (80).
These are at the ceiling but not over — PASS.

All 20 skills have a corresponding `references/process.md` file.

**Result: PASS.**

---

## 6. Two-Stage Verification Support — Global Documentation

The agency plugin does not have a standalone `resources/verification-profile.yml` file.
Two-stage verification is documented at the skill level (process.md) rather than as a
plugin-level profile.

This is a gap relative to the task-planner blueprint standard (Section 5, V1-V6), which
calls for a verification profile in `resources/`.

**Result: PARTIAL — LOW PRIORITY GAP.**

The pattern exists in the codebase (task-planner has it), and the agency plugin's
verification behavior inherits from the task-planner dependency. A verification-profile.yml
would make the agency plugin self-documenting but is not required for functional operation.

---

## 7. Gap Analysis & Recommendations

### Critical (blocks MVP quality)
None identified. The plugin is functionally complete.

### High Priority (address before second project)

**GAP-01: Findings persistence missing in brand/content/design modules**
- Affected: brand-loader, app-copy, ux-writing, asset-registry, component-specs,
  design-tokens, logo-assets, web-layout
- Risk: Context loss during `/compact` or session interruption when building a brand
  or design system
- Fix: Add findings.md reference and 2-Action Rule to each skill's SKILL.md (1-2 lines
  each) and brief persistence section to process.md

**GAP-02: Two-stage verification missing in 6 active-output skills**
- Affected: logo-assets, design-tokens, component-specs, web-layout, app-copy, ux-writing
- Risk: Output quality gating is inconsistent — dev outputs are gated, design/content outputs are not
- Fix: Add two-stage verification block to each process.md (~10 lines each)

### Medium Priority (before third project or agency scale)

**GAP-03: asset-registry missing error logging to state.yml**
- Affected: asset-registry
- Risk: Silent failures on asset registration not tracked
- Fix: Add 2-line error logging note to asset-registry SKILL.md

**GAP-04: verification-profile.yml not present**
- Affected: Plugin self-documentation
- Risk: Inconsistency with blueprint standard (V1)
- Fix: Create `plugins/agency/resources/verification-profile.yml` modeled on
  task-planner's verification-registry.yml

### Low Priority (post-MVP)

**GAP-05: Mobile developer and SEO expert agents deferred**
- When to address: When Blik launches mobile app or SEO module is ported (defer-05)

**GAP-06: Analytics, Media, and CI/CD modules not built**
- Covered by defer-11 through defer-20 in deferred-backlog.yml

---

## 8. Deferred Backlog Completeness

The deferred-backlog.yml covers 20 items across 5 modules:

| Module | Items | Notes |
|--------|-------|-------|
| brand | 4 | defer-01 through defer-04 |
| seo | 6 | defer-05 through defer-10 (full + standalone breakouts) |
| analytics | 2 | defer-11 through defer-12 (new — no source plugin) |
| media | 2 | defer-13 through defer-14 (new — no source plugin) |
| dev | 3 | defer-15 through defer-17 (knowledge-init, tier-assigner, delta-scanner) |
| devops | 3 | defer-18 through defer-20 (CI/CD, IaC, monitoring) |

All deferred items include: trigger condition, priority (high/medium/low), effort
estimate (small/medium/large), source plugin reference where applicable, and notes.

**Result: PASS.** The backlog is comprehensive and actionable.

---

## Appendix A: File Reference

| File | Purpose |
|------|---------|
| `plugins/brand-guideline/.claude-plugin/ecosystem.json` | Brand skill source list |
| `plugins/seo-plugin/.claude-plugin/ecosystem.json` | SEO skill source list |
| `plugins/dev/.claude-plugin/ecosystem.json` | Dev skill source list |
| `plugins/agency/.claude-plugin/ecosystem.json` | Agency skill manifest |
| `plugins/agency/resources/deferred-backlog.yml` | 20 deferred items with triggers |
| `plugins/agency/skills/` | 20 SKILL.md files across 5 modules |
| `plugins/agency/agents/dev/` | 12 agent definitions |
| `plugins/agency/commands/` | 8 command definitions |
