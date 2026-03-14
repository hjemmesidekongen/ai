# Opportunities

Systemic improvements surfaced during sessions. Claude adds entries here when
errors reveal fragility or refactors are out of scope for the current task.

Reviewed at the start of each planning wave.

## Format

Each entry: what was observed, why it matters, and where to look.

```
### [short title]
- **Observed:** what happened
- **Impact:** why it matters
- **Location:** file or component affected
- **Added:** date
```

## Entries

### context-manager plan-dispatch mode
- **Observed:** context-manager's context_package format doesn't align with plan-engine Build phase expectations
- **Impact:** Plan-dispatched agents may receive mismatched context packages
- **Location:** plugins/kronen/agents/context-manager.md
- **Added:** 2026-03-13

### plan-verification-gate YAML parsing robustness
- **Observed:** Hook uses sed/awk for YAML parsing — fragile with complex plan.yml structures
- **Impact:** Edge cases with inline arrays, quoted values, or nested structures may bypass the gate
- **Location:** plugins/kronen/scripts/plan-verification-gate.sh
- **Added:** 2026-03-13

### Command frontmatter convention drift
- **Observed:** Some commands use `argument-hint`, others use `usage` in frontmatter
- **Impact:** Inconsistent schema across commands
- **Location:** plugins/kronen/commands/
- **Added:** 2026-03-13

### Agent schema: explicit no-tools marker
- **Observed:** `tools: []` is ambiguous — reviewers flag it as both "no tools" and "wildcard access"
- **Impact:** Zero-tool agents (plan-verifier, plan-classifier) trigger false positives in reviews
- **Location:** Agent frontmatter schema
- **Added:** 2026-03-13

### Agents should take implementation notes during plan waves
- **Observed:** During config-rules-distribution plan, details about why decisions were made and what edge cases were handled are top-of-mind during implementation but lost by documentation time. Writing docs after the fact produces generic descriptions instead of capturing the real reasoning.
- **Impact:** Documentation quality suffers. The blog post and internal docs in Wave 5 won't capture the nuance of why specific security mitigations were chosen, why scope was reduced, etc.
- **Proposed:** Add a doc-notes pattern to the plan-engine: task agents write brief implementation notes to `artifacts/{wave}-{task}-notes.md` alongside their concerns files. These notes are raw material for the documentation wave, not polished docs. The notes capture: decisions made during implementation, edge cases discovered, things that were harder/easier than expected, "if I were explaining this to someone" observations.
- **Location:** plugins/kronen/skills/plan-engine/
- **Added:** 2026-03-14

### Config system: deferred items from config-rules-distribution plan
- **Observed:** The following items were explicitly deferred during the config consolidation plan. Each needs its own decision before implementation.
- **Deferred items:**
  - Profile creation command (`/kronen:profile-create`)
  - Profile switching command (`/kronen:profile-switch`)
  - Profile inheritance (custom profile extends work with overrides)
  - Multi-plugin profile coordination (smedjen, segl, herold shipping their own flags)
  - Conflict audit — checking user CLAUDE.md for rules contradicting plugin rules (v2)
  - `WARN_ON_WEAKEN` tier for semi-sensitive flags (log when weakened, don't block)
  - Named profile presets as separate files (`.ai/profiles/`)
  - Remaining ~/CLAUDE.md sections extraction (tracing, memory, Pencil, etc. — each moves when its feature area is specifically worked on)
- **Location:** plugins/kronen/scripts/rules-sync.sh, plugins/kronen/resources/profiles/
- **Added:** 2026-03-14

### Eval harness doesn't detect plugin skill triggering
- **Observed:** `run_eval.py` creates temporary command files to register skills, but this doesn't work for skills registered through plugin ecosystem.json. All positive trigger cases show 0% trigger rate despite the skill working correctly in real sessions.
- **Impact:** Cannot run automated A/B description optimization on plugin skills — only standalone skills work with the harness.
- **Location:** plugins/kronen/skills/skill-creator/scripts/run_eval.py
- **Added:** 2026-03-14

## Stale path references in ~/CLAUDE.md

- `plugins/claude-core/resources/error-annotation-format.yml` (Error annotation section, line 167) — should be `plugins/kronen/resources/error-annotation-format.yml`
- `plugins/claude-core/resources/memory-rules.md` (Memory discipline section, line 177) — should be `plugins/kronen/resources/memory-rules.md`

Logged: 2026-03-14. Source: config-rules-distribution plan, Wave 2.
