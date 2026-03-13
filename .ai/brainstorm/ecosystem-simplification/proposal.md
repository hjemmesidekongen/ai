# Ecosystem Simplification Proposal

## The Problem

The hjemmesidekongen plugin ecosystem has grown to 35 commands, 130 skills, 19 agents, and 21 hooks across 5 plugins. This is 5-10x the complexity of comparable setups. Anthropic's own guidance warns that over-specified CLAUDE.md files cause Claude to ignore rules, and that more than 20-50 simultaneously enabled skills degrades performance.

The system was built for multi-user enterprise governance. It's used by one person. The complexity solves problems that don't exist.

## Guiding Principles

1. **Delete before simplify, simplify before reorganize.** Most things should go, not move.
2. **If Claude does it correctly without instruction, delete the instruction.**
3. **Lean into Claude Code's native capabilities.** Don't compete with `/simplify`, `/batch`, `/debug`, `/loop`, prompt hooks, agent hooks.
4. **The right number of skills is the minimum that changes Claude's behavior for the better.**
5. **Consumer products hide complexity, not expose it.**

---

## 1. CLAUDE.md: Ruthless Pruning

### Current State
110 rules across two CLAUDE.md files (86 global + 24 project). Claude reads all of this at session start. Important rules get buried.

### What to Cut

**Delete — Claude already does this correctly:**
- "Be careful not to introduce security vulnerabilities" — Claude's default behavior
- "Avoid over-engineering" — already in system prompt
- "Avoid backwards-compatibility hacks" — rare edge case, not worth a rule
- "Do not create files unless absolutely necessary" — Claude's default
- Most of "Tone and style" — Claude follows the operator profile without these
- "Use the Agent tool with specialized agents when the task at hand matches" — Claude reads agent descriptions
- Most tool usage instructions — Claude knows how to use its tools

**Delete — solved by hooks or irrelevant:**
- Error annotation tracing rules (6 rules) — if tracing matters, a hook should enforce it, not a rule Claude might forget
- Plan state hygiene rules (4 rules) — if plans matter, the plan skill should handle state, not CLAUDE.md
- Memory discipline rules (8 rules) — move to a memory skill that loads on demand
- Plugin maintenance / cache clearing — make the hook handle it silently
- Post-task documentation table — move to doc-checkpoint skill (it already exists)

**Keep — these genuinely change behavior:**
- Operator profile (role, working style, communication style) — ~15 rules
- "No AI trace" rules — Claude doesn't do this by default
- Git workflow preferences — concise, actionable
- Pencil design rules — domain-specific, can't be inferred
- Discovery workflow sequence (brainstorm → decide → plan → execute)
- Critical thinking / push-back instructions

### Before/After

**Before:** 110 rules, ~3,000 tokens loaded every session
**After:** ~35 rules, ~1,000 tokens loaded every session

**Before (CLAUDE.md excerpt):**
```markdown
## Technical defaults
I usually work on macOS.
I often work in monorepos.
I prefer maintainable, pragmatic solutions over clever complexity.
Prioritize code quality, readability, performance, and realistic implementation.
Prefer solutions that are robust in real team environments, not just theoretically elegant.
```

**After:**
```markdown
## Defaults
macOS. Monorepos. Pragmatic > clever.
```

---

## 2. Skills: From 130 to ~30

### Current State
130 skills across 5 plugins. Many are knowledge reference docs (smedjen has 24 tech skills like `react-patterns`, `nextjs-app-router`, etc.), meta-tooling (8 creator/reviewer skills), or rarely-used utilities.

### Classification

**Keep (core workflow, genuinely changes outcomes): ~20 skills**
- brainstorm-session — unique capability, no Claude equivalent
- plan-engine + dynamic-planner — core planning, no equivalent
- plan-verifier — quality gate
- verification-gate — prevents premature completion
- session-handoff — cross-session continuity
- file-ownership — prevents write conflicts in parallel work
- brand-strategy, brand-audit, brand-evolve, brand-loader — domain knowledge Claude can't infer
- visual-identity, design-tokens, design-loader, pencil-tokens — domain knowledge
- jira-ingestion, bulk-ingestion — external system integration
- qa-handover-generator — structured output Claude wouldn't produce otherwise
- project-profile-loader — external system config
- content-writer — orchestration skill
- smedjen-orchestrator — orchestration skill

**Convert to `.claude/rules/` files: ~10 skills**
Tech knowledge skills (react-patterns, nextjs-app-router, tailwind-v4, etc.) work better as rules that auto-load based on file type:
```
.claude/rules/react.md        → triggers on *.tsx, *.jsx
.claude/rules/nextjs.md       → triggers on app/**/*.ts
.claude/rules/tailwind.md     → triggers on *.css, tailwind.config.*
```
Rules are lighter than skills — no frontmatter overhead, no description scanning, auto-activate by file pattern.

**Delete — Claude does this without instruction:**
- writing-clearly-and-concisely — Claude writes well by default
- reducing-entropy — "delete dead code" is a prompt, not a skill
- error-handling-patterns — Claude knows error handling
- systematic-debugging — Claude debugs systematically by default
- root-cause-debugging — same
- hypothesis-generator — Claude naturally generates hypotheses
- Most security/accessibility knowledge skills — Claude has this knowledge built in

**Delete — meta-tooling overhead:**
- skill-creator, hook-creator, command-creator, agent-creator, plugin-creator — write skills manually in a template
- skill-reviewer, hook-reviewer, plugin-reviewer, agent-reviewer — use `/simplify` or manual review
- mcp-creator — write MCP configs manually
- instinct-extractor, instinct-evolve — over-engineering the learning loop
- reasoning-trace-optimizer — nice idea, rarely used
- prompt-optimizer — Claude already optimizes prompts when asked

**Delete — duplicates Claude Code built-ins:**
- parallel-reviewer → Claude Code's `/simplify` does this
- auto-doc → doc-checkpoint already exists, and Claude updates docs when asked
- roadmap-capture — save ideas in a file, no skill needed
- agent-teams — Claude dispatches agents without a preset catalog

**Delete — smedjen knowledge skills that Claude already knows:**
- typescript-modern, nodejs-patterns, http-protocols, package-managers
- nestjs-patterns, prisma-patterns, vue-patterns, nuxt-patterns
- auth-patterns, web-security-owasp, api-security
- expo-* skills (12 skills!) — consider keeping 2-3 Expo-specific ones if active Expo work
- storybook-patterns, vite-patterns, turborepo-patterns, eslint-config
- git-advanced-workflows — Claude knows git

### Before/After

**Before:** 130 skills (all loaded as descriptions at session start)
**After:** ~20-25 skills + ~10 file-triggered rules

---

## 3. Commands: From 35 to ~12

### Current State
35 commands across 5 plugins. Users must remember plugin prefixes.

### What to Keep

**Planning (4):**
- `brainstorm` (merge brainstorm-start + brainstorm-decide into one command with subcommands)
- `plan` (merge plan-create + plan-dynamic + plan-execute + plan-status + plan-resume into one with subcommands: `plan create`, `plan run`, `plan status`)
- `autopilot` (merge autopilot-run + autopilot-cancel)
- `review` (rename full-review)

**Task management (4):**
- `task` (merge all herold commands: `task list`, `task start`, `task ingest`, `task done`, `task pr`)
- No separate `task-docs` — incorporate into `task start` auto-loading
- No separate `task-ingest-bulk` — `task ingest` handles both single and bulk

**Brand + Design (3):**
- `brand` (merge all våbenskjold commands: `brand create`, `brand audit`, `brand evolve`, `brand status`)
- `design` (merge all segl commands: `design identity`, `design tokens`, `design status`, `design page`)

**Utility (1):**
- `scan` (rename dev-scan — the only smedjen command that's independently useful)

### Drop These Commands
- `trace-full` — make tracing a setting, not a command
- `roadmap-add`, `roadmap-view` — edit .ai/roadmap.yml directly
- `prompt-create` — Claude already writes good prompts when asked
- `dev-run` — this is what Claude does by default when you give it a task; orchestration is Claude's core capability
- `content-write` — merge into a mode flag or skill trigger

### Before/After

**Before:** `/kronen:plan-create`, `/kronen:plan-execute`, `/kronen:plan-status`, `/kronen:plan-resume`
**After:** `/plan create`, `/plan run`, `/plan status`

**Before:** `/herold:task-ingest`, `/herold:task-ingest-bulk`, `/herold:task-start`, `/herold:task-status`, `/herold:task-list`, `/herold:task-done`, `/herold:task-pr`, `/herold:task-docs`
**After:** `/task ingest`, `/task start`, `/task list`, `/task done`, `/task pr`

**Before:** `/våbenskjold:brand-create`, `/våbenskjold:brand-audit`, `/våbenskjold:brand-evolve`, `/våbenskjold:brand-apply`, `/våbenskjold:brand-status`
**After:** `/brand create`, `/brand audit`, `/brand evolve`, `/brand status`

---

## 4. Hooks: From 21 to ~8

### Current State
21 hooks, all in kronen. Mix of essential infrastructure, nice-to-have guardrails, and redundant safety nets.

### What to Keep

**Essential infrastructure (4):**
- `session-recovery` (SessionStart) — context restoration after compaction
- `precompact-snapshot` (PreCompact) — saves state before /compact
- `session-context-stop` (Stop) — captures state on exit
- `cache-clear` (Stop) — prevents stale plugin behavior

**Valuable gates (3):**
- `prevent-direct-push` (PreToolUse) — safety net, zero friction
- `autopilot-stop-hook` (Stop) — keeps autopilot loops alive
- `trace-light` (PostToolUse) — lightweight tracing, invisible

**Consider keeping (1):**
- `prompt-grade` (UserPromptSubmit) — catches vague high-stakes prompts. Convert to prompt-based hook (simpler than bash script).

### Delete

- `compact-gate-pre` + `compact-gate-post` — context management should be Claude's responsibility, not a gate system
- `scope-guard` — advisory, rarely changes behavior
- `tdd-gate` — enforce via skill instruction when doing TDD, not globally
- `plan-gate` — advisory, adds noise
- `debug-window` — nice-to-have, not essential
- `claude-md-guardian` — check CLAUDE.md manually
- `strategic-compact-trigger` — Claude manages context fine
- `observation-recorder` — feeds instinct system being deleted
- `memory-health-daily` — manage memory manually
- `pencil-swarm-check` — move to design skill's first step
- `check-wave-complete` — plan skill should check this
- `verification-gate-stop` — verification skill should enforce this
- `check-trace-written` — tracing is optional
- `doc-stale-check` — check docs manually or via skill
- `port-dedup-check` — one-time validation, not per-session

### Before/After

**Before:** 21 hooks firing on every session (some on every tool call)
**After:** 7-8 hooks, mostly invisible infrastructure

---

## 5. Agents: From 19 to ~9

### Current State
19 agents (12 in kronen, 7 in smedjen). Kronen agents are mostly meta-tooling reviewers and validators.

### Keep (smedjen development agents — they do real work):
- architect
- backend-dev
- frontend-dev
- test-engineer
- code-reviewer
- content-writer

### Keep (kronen infrastructure — useful for complex plans):
- tdd-orchestrator
- context-manager
- error-detective

### Delete:
- plugin-validator — validate manually
- skill-auditor — part of deleted meta-tooling
- security-auditor — Claude does security review by default
- component-reviewer — part of deleted meta-tooling
- architect-reviewer — merge into architect agent
- refactoring-specialist — Claude refactors without a specialist
- knowledge-synthesizer — over-engineering
- incident-responder — over-engineering
- agent-reviewer — part of deleted meta-tooling
- app-security-auditor (smedjen) — Claude does this

---

## 6. Plugins: From 5 to 3

### Current State
5 plugins with varying complexity. Users must know which plugin owns what.

### Proposed Structure

**Plugin 1: kronen (core)**
What it keeps: planning, brainstorm, verification, session management, tracing, hooks
Skills: ~8 | Commands: ~4 | Agents: 3 | Hooks: 7-8

**Plugin 2: smedjen (build)**
What it keeps: development agents, task management (absorb herold), project scanning, content writing
Skills: ~8 | Commands: ~5 | Agents: 6 | Hooks: 0

**Plugin 3: segl (design)**
What it keeps: brand (absorb våbenskjold), visual identity, design tokens, Pencil integration
Skills: ~8 | Commands: ~3 | Agents: 0 | Hooks: 0

### Why Merge Herold into Smedjen
Herold's task management (Jira ingestion, PR creation, QA handover) is part of the development workflow. Separating it into its own plugin forces users to remember two plugins for one workflow. Merge task management into smedjen.

### Why Merge Våbenskjold into Segl
Brand strategy and visual identity are sequential steps in the same workflow. No user invokes brand without eventually invoking design. One plugin, one workflow.

---

## 7. State Management: Simplify .ai/

### Current State
```
.ai/
  context/          # snapshot.yml
  projects/         # per-project state.yml, brand/, design/
  brainstorm/       # sessions and decisions
  plans/            # wave plan state files
  prompts/          # prompt templates
  roadmap.yml
  traces/           # trace-light.log
  design/           # Pencil files
```

### Proposed
```
.ai/
  context/          # snapshot.yml (keep — session recovery)
  plans/            # plan state (keep — active planning)
  brainstorm/       # sessions (keep — brainstorm state)
  brand/            # brand artifacts (flatten from projects/)
  design/           # design artifacts (keep)
  roadmap.yml       # keep
  traces/           # trace-light.log only
```

Delete: `projects/` (flatten into top-level), `prompts/` (unused overhead).

---

## 8. Progressive Disclosure

### The Consumer Product Pattern

**Level 0 — Just talk to Claude.** No commands, no skills. Claude reads the lean CLAUDE.md and works effectively for 80% of tasks.

**Level 1 — Simple commands.** `/plan`, `/task`, `/brand`, `/design`, `/review`. Five words to remember. Each command guides you through its workflow interactively.

**Level 2 — Subcommands.** `/plan create`, `/plan run`, `/task ingest --bulk`. Power user features that don't pollute the simple surface.

**Level 3 — Skills and agents.** For users who want to customize: add skills to `.claude/skills/`, configure agents, modify hooks. This is the extension layer, not the default experience.

### What This Means in Practice

A user should be able to:
1. Open Claude Code in the project
2. Say "fix the bug in the auth module"
3. Claude does it — no commands, no skills, no ceremony

The skills and commands exist for structured workflows that benefit from process:
- Planning multi-step features
- Ingesting work from Jira
- Creating brand identities
- Designing in Pencil

---

## Prioritized Action List

### Phase 1: Prune (Low effort, high impact)
1. **Prune CLAUDE.md** — delete rules Claude follows without instruction. Target: 110 → 35 rules. (2 hours)
2. **Delete meta-tooling skills** — remove all creator/reviewer skills and agents. (1 hour)
3. **Delete knowledge skills Claude already knows** — typescript, nodejs, security, accessibility, most expo skills. (1 hour)
4. **Remove redundant hooks** — go from 21 to 8. (1 hour)
5. **Convert tech knowledge skills to .claude/rules/** — react, nextjs, tailwind as file-triggered rules. (2 hours)

### Phase 2: Consolidate (Medium effort, medium impact)
6. **Merge commands** — collapse 35 commands into ~12 with subcommand patterns. (4 hours)
7. **Merge herold into smedjen** — task management becomes part of the build plugin. (3 hours)
8. **Merge våbenskjold into segl** — brand + design in one plugin. (3 hours)
9. **Flatten .ai/ state management** — simplify directory structure. (1 hour)

### Phase 3: Polish (Medium effort, high polish)
10. **Rewrite remaining skill descriptions** — make them crisp, discoverable, unambiguous. (2 hours)
11. **Convert bash hooks to prompt/agent hooks** where judgment is needed. (2 hours)
12. **Write a 1-page quick start** — not as a doc file, but as the first section of CLAUDE.md. (1 hour)
13. **Test the simplified setup** — run through common workflows and verify nothing broke. (3 hours)

### Expected Outcome
| Metric | Before | After | Reduction |
|--------|--------|-------|-----------|
| Skills | 130 | ~25 | 80% |
| Commands | 35 | ~12 | 66% |
| Hooks | 21 | ~8 | 62% |
| Agents | 19 | ~9 | 53% |
| Plugins | 5 | 3 | 40% |
| CLAUDE.md rules | 110 | ~35 | 68% |
| Context tokens at startup | ~3,000 | ~1,000 | 67% |

---

## Open Questions for Discussion

1. **Usage data.** We're guessing which skills are used. Before deleting, should we add lightweight analytics for 2 weeks to see actual usage?
2. **Expo skills.** Are you actively building Expo apps? If not, all 12 can go. If yes, keep 2-3.
3. **Tracing.** Is trace-light.log actively used for debugging? If not, that hook can go too.
4. **Platform basics.** The jira-basics, confluence-basics, slack-basics, bitbucket-basics, outlook-basics skills in kronen — are these used? They feel misplaced in the core plugin.
5. **Plugin naming.** If we go to 3 plugins, do we keep the Danish names (kronen, smedjen, segl) or switch to functional names (core, build, design)?

---

## The North Star

After simplification, a new session should feel like opening a sharp tool, not entering a cockpit. The system should be invisible when you're free-styling and powerful when you're commanding. No ceremony for simple tasks. Clear structure for complex ones.
