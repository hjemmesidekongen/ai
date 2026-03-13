# Brainstorm: Workflow Optimisation
**Date:** 2026-03-12

## Key Decisions Reached

### 1. Mindset skill → CLAUDE.md (not a separate skill)
Cognitive operating principles belong directly in CLAUDE.md since they need to be always-loaded. Code quality standards also stay in CLAUDE.md as style guide rules. No separate mindset skill file needed — CLAUDE.md *is* the mindset.

### 2. Skill vs Agent boundary clarified
- **Skill = knowledge** — loaded into context, shapes decisions, never executes independently
- **Agent = delegation** — separate Claude instance, own context, isolated execution, returns results
- Test: "Can the same Claude apply this, or does it need isolated execution?"

### 3. Commands become optional aliases, not required rails
The intelligence lives in skills + CLAUDE.md routing + hooks. Commands are convenience shortcuts that compose skills in sequence. Freestyle and command mode should produce identical quality.

### 4. Three-layer architecture
```
CLAUDE.md           → routing ("when to plan, when to review, when to verify")
Core skills         → operating principles ("how to plan, how to review")
Knowledge skills    → domain expertise ("Tailwind, Prisma, SEO") — auto-detected from project context
Agents              → isolated execution workers
Hooks               → enforcement ("must review, must verify")
```

### 5. Knowledge skills auto-activate from project context
No CLAUDE.md mention needed for tech-specific skills. If there's a `tailwind.config.ts`, Tailwind skill is relevant. A lightweight scan at task start maps project → relevant skills.

### 6. Review is one orchestration + specialized agents
One review process that picks dimensions. Existing agents (test-engineer, frontend-dev, code-reviewer, content-writer) load relevant knowledge skills per review pass. Not five separate review agents.

### 7. Iterative simplification with research
- Dedicated roadmap and plan for simplifying the ecosystem
- One change at a time, debate effects, implement, verify
- Track what helped, what didn't, what got worse
- Learn as we go — curated list of simplifications

### 8. Start with mindset in CLAUDE.md
First concrete action: add cognitive operating principles to CLAUDE.md and clean up existing content. Then build the simplification roadmap.

## Open Items for Future Sessions
- Planning threshold heuristic (1 file → just do it, 3+ files → plan)
- Auto-detection mechanism for knowledge skills
- Which commands can be dissolved vs. kept as shortcuts
- Hook enforcement scope (what must never be skipped)
- `docs/opportunities.md` vs alternative locations for systemic backlog
