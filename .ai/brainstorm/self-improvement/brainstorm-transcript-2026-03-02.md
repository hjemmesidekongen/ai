# Brainstorm Session — self-improvement
**Date:** 2026-03-02
**Duration:** ~15 minutes (ongoing)

---

**User:** Wants to introduce "gradual self-improvement" to the plugin ecosystem. When plugins encounter issues, they should report back centrally so there's an overview. Also wants some risk assessment — maybe fix low-risk issues immediately. Acknowledges this "opens Pandora's box." Tired of seeing issues and having to report them manually while working on other stuff.

**Claude:** Identified three systems hiding in the idea:
1. Inline triage during execution (fix-or-log decision)
2. Issues backlog (central log)
3. Cron-like fixer (SessionStart hook that picks up backlog items)

Pushed back: dispatching subagents doesn't pollute parent context much, but costs latency and tokens. The triage should be smart (Sonnet), but fixes can be tiered. Also flagged the missing third outcome: "I fixed it and broke something else" — every auto-fix needs verification.

**User:** Agreed on subagent approach. Wants low-risk non-complicated issues fixed immediately, but NOT by Haiku — by something "more aware." Higher-risk issues should go to an issues log. Liked the idea of a cron-like hook that picks up one issue per session. Key frustration: "I'm tired of seeing issues in the plugins and then having to report them myself."

**Claude:** Asked for concrete examples of issues encountered.

**User:** Gave three real examples:
1. **Wrong output location** — a plan file ended up in `.claude/projects/-Users-mvn-Personal-hjemmesidekongen/memory/` instead of the correct `.ai/` directory
2. **Silent dependency failure** — Brand generation needed ImageMagick (not installed), hooks failed silently, execution continued, all PNGs looked like crap
3. **Hooks not working properly** — just continued as if everything was fine

**Claude:** Categorized these into three failure types:
- Category 1: Path resolution bugs (easiest — PostToolUse hook can validate output dirs)
- Category 2: Silent dependency failures (most dangerous — needs pre-flight checks, not self-healing)
- Category 3: Output quality (hardest — subjective, needs quality baselines)

Proposed two-layer architecture:
- **Layer 1: Pre-flight & runtime guards** (hooks that prevent issues — dependency checks, path validation, success verification)
- **Layer 2: Retrospective system** (issues that slip through get logged, triaged, auto-fixed or surfaced)

Argued: if Layer 1 is good, Layer 2's backlog stays small. Most examples would've been caught by better guards.

**User:** Wants the MORE ambitious version — a genuine learning/self-improvement system. Not just static guards, but a system that accumulates knowledge from failures and prevents future ones. "There might be errors I don't see" when running big commands. Wants the knowledge to compound over time.

**Claude:** Outlined three options for where knowledge lives:
- **Option A: Knowledge file** (`.ai/issues/known-patterns.yml` — symptom→fix lookup, simple but dumb)
- **Option B: Enriched hooks** (system rewrites its own pre-flight checks — robust but Pandora's box of self-modifying code)
- **Option C: Hybrid** (knowledge file for fast pattern matching + periodic "hardening" pass that promotes proven patterns into code changes)

Proposed trust boundary tiers:
| Tier | Example | Auto-fix? |
|------|---------|-----------|
| Config/path | Wrong output dir, missing env var | Yes |
| Dependency | Missing ImageMagick | Yes — halt + tell user |
| Skill logic | Bad prompt producing garbage | No — log, propose, wait |
| Architecture | Schema design flaw | No — surface for review |

Raised key concern: self-modifying code needs versioning, rollback capability, and a trust boundary.

**Open questions for user:**
1. Comfortable with autonomous code changes (Option B) or prefer propose-and-review (Option C with human gate)?
2. Should this be a new plugin or built into task-planner?

---

**User:** Pointed out another example in real-time: "When I give you a command [save transcript], you should ask 'how could I fix that?' — not now, but for later so I won't have to ask again." This is a fourth failure category: behavioral/workflow gaps where the system works technically but the process is suboptimal. "I shouldn't have to tell you this twice" moments.

**Claude:** Named four failure categories:
1. Wrong location (mechanical bug)
2. Silent failure (missing guard)
3. Quality (output validation gap)
4. **Behavioral** (process/workflow gap — new)

Category 4 is the most interesting for self-improvement because it's about how Claude behaves, not code being broken. The knowledge store isn't just `symptom → fix` but also `user_correction → behavior_rule`.

Proposed three input channels:
1. Runtime errors (exceptions, missing deps, wrong paths)
2. Quality failures (bad output, malformed YAML)
3. User corrections ("you should have done X" / "remember this")

Two output channels:
1. Immediate — auto-fix known patterns during execution
2. Deferred — propose new patterns for approval, apply on session start

Noted tension with existing auto-memory system (MEMORY.md) — self-improvement knowledge base would be a structured, categorized version with typed patterns, approval status, and applicability metadata.

**User answers:**
1. **Autonomous** — but only when risk is low and "easy fix without risk of breaking something else." Defers to Claude on best practice for the exact rule.
2. **New plugin** — separate from task-planner.

**Claude:** Proposed the safety rule: auto-fix allowed when ALL THREE conditions met:
- Blast radius contained to single file
- Fix is reversible
- Verification check available

If any condition fails → queue for approval.

Key pattern: **"approve once, auto-fix forever"** — approval is a training mechanism that disappears over time as the system earns trust. Week 1: 10 proposals. Month 3: queue nearly empty.

Auto-fix tiers:
- **Auto-fix:** wrong dir (move file), missing dep (halt + tell user), malformed YAML (regenerate), known approved pattern
- **Propose once:** skill process changes, new pre-flight checks, schema/template modifications, any plugin source file change
- **Never auto-fix:** multi-plugin interactions, schema design, changes to reviewed output, architectural patterns

Proposed plugin structure:
- commands: improve-status, improve-review, improve-fix
- skills: issue-capture, triage, auto-fixer, pattern-promoter
- agents: sentinel-agent (background watcher)
- resources: knowledge-base.yml, approved-fixes.yml, backlog.yml

**User answers:**
- **Name:** "immune system" (or just "immune")
- **Scope:** General workspace — plugins, code, behavior, everything

**Claude:** Mapped out what "general workspace" scope means — three observation domains:
1. Plugin execution (already discussed)
2. General code work (wrong paths, silent build failures, git mishaps)
3. Claude's own behavior (not following CLAUDE.md, forgetting conventions, skipping steps)

Third bucket = spiciest. Immune system watches Claude itself = supervision layer.

Key implication: immune system must be loaded in EVERY session (always-on). Needs to be lightweight on the hot path.

Proposed two-speed architecture:
- **Fast path (inline):** PostToolUse bash script, pattern match against known issues. Cost: milliseconds, no agent.
- **Slow path (session boundaries):** SessionStart reviews pending-triage.yml, dispatches Sonnet-level sentinel agent for smart categorization.

95% of tool calls hit bash script. Only new issues trigger expensive agent path.

Raised concern: immune system becomes the most important plugin. If it has a bug = "autoimmune disorder." Needs to be the most reliable, well-tested component.

**User answer:** The immune system should watch itself.

**Claude:** Addressed the recursion/infinite loop risk with three safeguards:
1. **Circuit breaker** — hard limit of 2 self-fix attempts per session. Hardcoded, immutable. The one rule it can't change about itself.
2. **Separate self-check from self-fix** — can observe itself freely, but fixes to its own code ALWAYS go through propose-and-review, never auto-fix. The "approve once, auto-fix forever" pattern only applies to OTHER plugins.
3. **Canary test** — after any self-fix, runs basic self-test (can I detect? can I log? can I dispatch?). If canary fails, rollback immediately.

Trust hierarchy:
- Other plugins: auto-fix approved patterns, propose new ones
- Immune system itself: always propose, never auto-fix
- Circuit breaker: hardcoded, immutable

Proposed hook architecture:
- PostToolUse with `"matcher": "*"` — observes ALL tool calls, must be extremely fast (milliseconds, pattern match only)
- SessionStart — triage backlog, run auto-fixes
- Stop — session summary

Raised scoping question: behavior watching (enforcing CLAUDE.md rules) requires a mini rule engine. Parse CLAUDE.md → extract enforceable rules → check tool outputs against them. Is that v1 or v2?

**User:** Asked if the observe script should be written in Rust for speed. Also wants to build everything at once — "I'm in a thought process and I'd just like to get it out of the way."

**Claude:** Rust trade-offs:
- FOR: sub-millisecond compiled binary, no startup cost, perfect for pattern matching
- AGAINST: build complexity (compile step, toolchain), slower iteration, bash is probably 5-10ms which is fine for v1
- Recommendation: bash for v1, Rust upgrade when knowledge base grows large (which the immune system itself could flag)

On building everything at once — pushed back on HOW, not WHETHER:
- Option A: Design + build all at once (risky, no validation until deep in)
- Option B: Design everything now, build in smart layers but fast (spec captures full vision, build order validates each layer)

Proposed 7-layer build order:
1. Observation (PostToolUse hook + log)
2. Knowledge base + pattern matching
3. Auto-fixer + verification
4. Triage agent (sentinel)
5. Approval workflow + pattern promotion
6. Behavior rule engine (CLAUDE.md enforcement)
7. Self-monitoring + circuit breaker

**User answers:**
- Option B: full spec now, layered build in smart order
- (Bash vs Rust not explicitly answered — defaulting to bash for v1)

**Claude:** Surfaced 5 unexplored topics before locking decisions:
1. Knowledge base schema — exact fields for a pattern entry
2. Behavior rule engine — how to parse CLAUDE.md into enforceable rules
3. /improve:review UX — approval workflow experience
4. Cross-workspace portability — universal patterns vs project-specific
5. Relationship with existing state.yml error logging — consume, replace, or parallel?

**Open:** User deciding whether to explore more or move to /brainstorm:decide

---

## Emerging Themes
- "Self-improvement" not "learning system" — user wants the system to get better, not just smarter
- Trust boundary is the central design decision
- User frustration is about manual issue reporting during unrelated work — UX of interruption
- Silent failures are the worst category — worse than crashes
- The system needs quality baselines to judge "correct" output
- Fourth category: behavioral corrections ("I shouldn't have to tell you this twice")
- Three input channels (runtime, quality, user corrections) → one knowledge base → two output channels (immediate, deferred)
- Tension with existing auto-memory — this is a structured evolution of MEMORY.md
