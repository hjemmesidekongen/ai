# dev Plugin — Domain Addendum

## Domain Knowledge

### Multi-Agent Software Development

The dev plugin orchestrates multiple AI agents working in parallel to build software. This is fundamentally different from single-agent coding — the key challenges are coordination, not generation.

**Coordination problems in multi-agent systems:**
- **File conflicts:** Two agents editing the same file simultaneously produces merge conflicts or data loss. The file-ownership system prevents this by assigning exclusive write access per file per wave.
- **Context fragmentation:** Each agent operates in an isolated context window (via Task() dispatch). It cannot see what other agents are doing. This means every task must be self-contained — include all necessary context in the dispatch prompt.
- **Cascading failures:** When one task fails, transitively dependent tasks cannot proceed. The PM must perform impact analysis: which tasks are directly blocked, which are transitively blocked, and which independent tasks can still proceed.
- **Communication overhead:** In human teams, developers ask each other questions. AI agents cannot do this mid-task. All inter-agent communication must happen through structured artifacts (team-state.yml, knowledge files).

**What makes this work:**
- Pre-planning with file ownership (Phase 2) eliminates most coordination problems before they occur
- The completion gate (Phase 3) catches quality issues while the agent still has context — cheaper than catching them at code review
- Wave-based execution naturally sequences dependent work while parallelizing independent work

### Project Scanning and Framework Detection

Static analysis of a project to detect its technology stack is a pattern-matching exercise. The scanner must handle:

**Detection signals (strongest to weakest):**
1. Lock files — `pnpm-lock.yaml` definitively identifies pnpm
2. Config files — `next.config.js` definitively identifies Next.js
3. Package.json dependencies — `"next": "^14.0.0"` strongly suggests Next.js
4. Import patterns — `import { useState } from 'react'` confirms React usage
5. Directory structure — `app/` directory with `page.tsx` files suggests Next.js App Router

**Common pitfalls:**
- A project may have multiple frameworks (e.g., Next.js frontend + Express API). The scanner must detect all of them, not just the first match.
- Version detection from package.json may show range specifiers (`^14.0.0`). Report the range, not a fabricated exact version.
- Monorepos have multiple package.json files. The root package.json may not reflect the actual frameworks used in sub-packages.
- Some projects use custom build systems that don't match any known framework. The scanner must gracefully handle "unknown" rather than force-fitting a match.

### Knowledge Systems for AI Agents

The knowledge system is inspired by Lindquist's Lamarck approach — curated, tagged, maturity-tracked facts about the project.

**Key principles:**
- **Curate before saving:** Not every observation belongs in knowledge. A formatting change in a CSS file is not worth recording. A new API endpoint or architectural decision is.
- **Tag-based retrieval:** Agents receive only knowledge files whose tags match their task context. A backend developer working on database queries gets `database`, `api`, `patterns` tags — not `frontend`, `testing`.
- **Maturity lifecycle:** New observations start as `candidate`. After being confirmed across multiple scans, they're promoted to `established`, then `proven`. Contradicted or stale entries are `deprecated`. This prevents knowledge bloat.
- **Jaccard dedup:** Before adding a new entry, check similarity against existing entries. If Jaccard similarity > 0.8, the entry is a near-duplicate — update the existing one instead of creating a new one.
- **Positive framing:** Knowledge should say "do X" not "don't do Y." Empirical research (Lindquist, cceval benchmarks) shows that explicitly forbidding something increases that behavior due to cognitive priming.

### Model Tier Economics

Self-tiering is a cost optimization strategy. The key insight: most tasks don't need Opus.

**Cost ratios (approximate):**
- Haiku: 1x (baseline)
- Sonnet: ~5x Haiku
- Opus: ~15x Haiku

**Self-tiering flow:**
1. Every specialist agent receives its task brief at Haiku cost
2. At Haiku, the agent assesses: "Can I handle this at junior level, or do I need more capability?"
3. If the agent declares senior or principal, it's re-dispatched at the appropriate tier
4. If the agent fails at its declared tier, it auto-escalates one level
5. If it fails at Opus: blocked, escalate to PM → user

**The assessment at Haiku is cheap (~$0.001).** Even if 100% of tasks escalate past Haiku, the wasted cost is negligible. But in practice, 30-50% of tasks can be handled at Haiku (scaffolding, simple CRUD, formatting, configuration).

### The 4-Phase Execution Model

The dev plugin follows Decompose → Plan → Execute → Review. This is inspired by the Deep Trilogy (decompose → plan → implement) but differs in two critical ways:

1. **Multi-agent parallel execution** — the original Deep Trilogy is single-agent sequential
2. **PM-TL negotiation in Phase 2** — tech leads shape the wave plan, the PM doesn't plan alone

**Phase 1 (Decompose):** The creative phase. Architect defines boundaries, Designer produces visual specs, PO validates scope. This is where bad assumptions are caught — before any code is written.

**Phase 2 (Plan):** The coordination phase. TLs assign tasks with tiers, verify file ownership. This is where parallelism is unlocked — tasks that don't share files can run simultaneously.

**Phase 3 (Execute):** The production phase. Agents work in waves. The completion gate runs after each agent — not at the end. This is critical: catching a build failure while the agent has context costs 1 fix. Catching it at code review costs an investigation + fix + re-review.

**Phase 4 (Review):** The quality phase. Code reviewer checks the diff, QA validates against spec, PO checks end-goal alignment. This is the last gate before the user sees results.

---

## Quality Standards

| Standard | Criteria | How to Verify |
|----------|----------|---------------|
| Build integrity | Project builds successfully after every agent's changes | Run `commands.build` from dev-config.yml, exit code 0 |
| Lint compliance | Zero lint errors after every agent's changes | Run `commands.lint` from dev-config.yml, exit code 0 |
| Test coverage | Related tests pass for all changed files | Run `commands.test_related` with changed file list |
| File ownership | No agent modifies files owned by another agent in the same wave | Check team-state.yml file_ownership against git diff per task |
| Tier appropriateness | Model tier matches task complexity — no Opus for scaffolding, no Haiku for architecture | Compare declared tier reasoning against actual task complexity |
| Knowledge quality | Knowledge entries are curated (not noise), tagged (findable), and deduplicated | Jaccard check < 0.8, tags non-empty, maturity assigned |
| Spec alignment | Implementation matches decomposition spec at ≥ 70% alignment | QA validation spec_alignment score |
| Convention adherence | Code follows detected project conventions (naming, imports, patterns) | Code reviewer checks against conventions.yml |
| Security baseline | No OWASP top 10 vulnerabilities introduced | Code reviewer security scan section |
| Prompt conciseness | Agent prompts are short and positively framed | Review dispatch prompts — ≤ 4 key instruction lines per agent |

---

## Tools and Dependencies

| Tool | Purpose | Required/Optional | Install Command |
|------|---------|-------------------|-----------------|
| Node.js | Runtime for JS/TS projects | Required (if JS/TS project) | `brew install node` or `nvm install --lts` |
| Git | Version control, commit tracking | Required | Pre-installed on macOS |
| Claude Code CLI | Agent dispatch via Task() tool | Required | Already installed (this is Claude Code) |
| ESLint / Biome | Linting (detected from project) | Optional (project-dependent) | Auto-detected from project |
| Prettier / Biome | Formatting (detected from project) | Optional (project-dependent) | Auto-detected from project |
| Jest / Vitest / Playwright | Testing (detected from project) | Optional (project-dependent) | Auto-detected from project |
| TypeScript | Type checking (if TS project) | Optional (project-dependent) | Auto-detected from project |

**Note:** The dev plugin does not install dependencies — it detects what the project already uses. All tools are project-dependent and read from dev-config.yml.

---

## Validation Criteria

| Metric | Target | Industry Benchmark | Tool |
|--------|--------|-------------------|------|
| Build success rate | 100% after completion gate | N/A — must always pass | `commands.build` exit code |
| Lint pass rate | 100% after completion gate | N/A — must always pass | `commands.lint` exit code |
| Related test pass rate | 100% after completion gate | N/A — must always pass | `commands.test_related` exit code |
| File conflict rate | 0% — no overlapping file ownership | 0% (hard requirement) | file-ownership check script |
| Spec alignment score | ≥ 70% for pass, ≥ 90% ideal | 80% typical for agency work | QA validation calculation |
| Tier escalation rate | < 30% of tasks escalate past initial tier | 20-40% is healthy | Track tier changes in team-state.yml |
| Knowledge dedup accuracy | Jaccard threshold 0.8 — no near-duplicates | N/A (custom metric) | Jaccard similarity computation |
| Scan speed | < 30 seconds for projects with < 10,000 files | Yek: 230x faster than Repomix | scan.scan_duration_ms |
| Agent fix-while-fresh rate | > 80% of completion gate failures fixed on first attempt | N/A (custom metric) | Track retry count in gate results |

---

## Common Mistakes to Avoid

1. **Dispatching agents without file ownership verification.** Two agents editing the same file in a parallel wave will conflict. Always run file-ownership check before dispatch. Instead: verify file_ownership in team-state.yml has no duplicates within the same wave.

2. **Loading all knowledge for every agent.** Knowledge files should be tag-filtered — a backend agent working on database queries doesn't need frontend component knowledge. Instead: filter knowledge files by tags that match the task context.

3. **Using Opus for every task.** The tier system exists to optimize cost. Simple scaffolding, configuration, and template tasks are Haiku-appropriate. Instead: use the tier-assigner's complexity assessment — files affected, ambiguity, risk level.

4. **Catching failures at code review instead of completion gate.** If an agent's code doesn't build, catching it at review (Phase 4) means the agent has lost context. Instead: run build/lint/test immediately after each agent completes (Phase 3) and fix while context is fresh.

5. **Scanning everything on every delta scan.** The hash-based approach only processes changed files. Re-analyzing unchanged files wastes time. Instead: compare SHA-256 hashes first, only analyze files with mismatched hashes.

6. **Storing decisions as knowledge.** The knowledge system stores facts about the project (patterns, conventions, architecture). Session decisions (what the team decided to build and why) belong in team-state.yml, not knowledge files. Instead: maintain clear separation between agent knowledge (`.claude/knowledge/`) and session state (`team-state.yml`).

7. **Promoting knowledge entries too quickly.** A pattern seen once is a `candidate`. Only promote to `established` after seeing it confirmed in multiple scans. Premature promotion leads to stale knowledge being treated as authoritative. Instead: follow the maturity lifecycle strictly — candidate → established (2+ confirmations) → proven (3+ scans, stable).

8. **Ignoring the PM's impact analysis for blocked tasks.** When a task fails, dependent tasks are transitively blocked, but independent tasks can proceed. Halting everything because one task failed wastes the work capacity of unblocked agents. Instead: PM identifies blocked vs. unblocked tasks, continues unblocked work, presents options to user.

9. **Letting specialists communicate directly.** The communication chain (User ↔ PM ↔ TLs ↔ Specialists) exists to prevent coordination chaos. If a frontend agent needs something from a backend agent, that flows through the TLs. Instead: route all cross-team communication through the appropriate Tech Lead.

10. **Hardcoding framework detection logic.** New frameworks emerge regularly. The scanner should be pattern-based (config file → framework mapping), not a rigid if-else chain. Instead: maintain a detection registry that maps config file patterns to frameworks, easy to extend.
