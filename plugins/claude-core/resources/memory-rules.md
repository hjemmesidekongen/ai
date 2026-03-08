# Memory Discipline Rules

Reference document for the claude-core memory management system.
Defines what goes where, when to prune, and how entries graduate.

## Three-File Memory Architecture

Memory is split across three files with distinct loading behavior:

| File | Purpose | Loaded | Max Size |
|------|---------|--------|----------|
| `CLAUDE.md` | Rules, behaviors, instructions | Always (session boot) | 200 lines |
| `MEMORY.md` | Facts, preferences, pointers | Always (session boot) | 150 lines |
| `decisions.yml` | Reasoning and context | On-demand (when relevant) | Unlimited |

Plus two supplementary files (never auto-loaded):

| File | Purpose | Location |
|------|---------|----------|
| `roadmap.yml` | Future ideas, deferred work | `.ai/roadmap.yml` |
| Topic files | Deep dives on specific subjects | `.ai/memory/{topic}.md` |

**Why three files, not one?** Both CLAUDE.md and MEMORY.md are loaded at every
session start. Anthropic truncates content after ~200 lines. Mixing rules with
facts with reasoning creates bloat that hits the truncation boundary fast.
Separating them keeps boot cost constant and each file focused.

**Why not a database?** Flat files are readable, diffable, and portable. No
infrastructure to maintain. The discipline is in the human rules, not the storage
technology.

## MEMORY.md Rules

Hard constraints for the auto-memory file:

1. **Max 150 lines.** Anthropic truncates after ~200. The 50-line buffer absorbs
   temporary growth between pruning cycles.

2. **Every entry must be one of:**
   - A fact ("Project X uses Bun, not npm")
   - A preference ("Always use single quotes in TypeScript")
   - A pointer to deeper docs ("Brand guidelines at .ai/projects/X/brand/")

3. **Forbidden content:**
   - Narrative ("we tried X then Y, finally Z worked") — put reasoning in decisions.yml
   - Implementation details that belong in code comments
   - Anything already stated in CLAUDE.md (no duplication)
   - Temporary debugging notes (use trace log instead)
   - Thinking-out-loud that was never confirmed as a decision

4. **Entry format:** Keep entries concise. One line per fact when possible.
   Group related entries under a `# Section` header. No prose paragraphs.

5. **Staleness:** An entry that hasn't been referenced or validated in 30+ days
   is a candidate for deletion. If it's still true, keep it. If nobody missed
   it, delete it.

## What Goes Where — Decision Tree

When Claude encounters something worth remembering, apply this tree in order:

```
Is it a behavior rule or instruction?
  YES → CLAUDE.md (if under 200 lines)
  NO  ↓

Is it a fact, preference, or pointer?
  YES → Is MEMORY.md under 150 lines?
    YES → MEMORY.md
    NO  → Topic file (.ai/memory/{topic}.md), plus a pointer in MEMORY.md
  NO  ↓

Is it reasoning about why a decision was made?
  YES → decisions.yml (in the relevant brainstorm session)
  NO  ↓

Is it a future idea or deferred feature?
  YES → roadmap.yml
  NO  ↓

Is it a recurring pattern that could be encoded?
  YES → Encode as a skill or code pattern, not a memory
  NO  → Don't store it. Not everything needs to persist.
```

**When in doubt: don't store.** Ask the user whether it's worth remembering.
Over-storing is worse than under-storing because it creates noise that degrades
every future session.

## Graduation Rules

Memory entries should move to better homes as the system matures. When an
entry graduates, delete it from MEMORY.md — the knowledge now lives somewhere
more permanent.

| Graduation Path | Action |
|-----------------|--------|
| Memory becomes a CLAUDE.md rule | Add to CLAUDE.md, delete from MEMORY.md |
| Memory becomes a skill | Encode in skill, delete from MEMORY.md |
| Memory becomes code or comments | Commit the code, delete from MEMORY.md |
| Memory is no longer true | Delete from MEMORY.md |
| Memory was never referenced in 30+ days | Review, then delete if not needed |

**Why graduate?** A fact stored in MEMORY.md is loaded every session but has no
enforcement mechanism. A rule in CLAUDE.md is loaded AND actively followed.
A skill is loaded AND executable. Graduation moves knowledge up the enforcement
ladder.

## Pruning Triggers

Pruning happens at three levels:

### Automated (via cron / hooks)
- **Session start hook:** Verify MEMORY.md is under 150 lines. If over, output
  a warning with the current line count.
- **Daily cron (memory-health-check.sh):** Count lines, flag entries with no
  recent reference, suggest graduation candidates. Report only — never auto-delete.

### Manual (future Phase 2)
- `/memory:health` command — on-demand health check with interactive pruning
- `/memory:graduate` command — move an entry to its proper home

### Organic
- During any session, if Claude notices a MEMORY.md entry that is stale,
  duplicated, or graduated elsewhere, it should propose deletion.

## Distinguishing Signal from Noise

Not everything the user says is worth storing. Classification guide:

| User Says | Classification | Action |
|-----------|---------------|--------|
| "I wonder if we should use Redis..." | Thinking out loud | Do NOT store |
| "Always use Bun instead of npm" | Explicit preference | Store in MEMORY.md |
| "Let's go with approach B because..." | Decision with reasoning | Store in decisions.yml |
| "We should add dark mode someday" | Future idea | Store in roadmap.yml |
| "That's wrong, do it this way" | Correction | Update existing entry or add to MEMORY.md |
| "Remember that the API key is in .env" | Pointer/fact | Store in MEMORY.md |
| "Hmm, what if we..." | Exploration | Do NOT store (wait for conclusion) |

**Key principle:** Wait for the conclusion. If the user is exploring options,
don't store the exploration — store the decision that comes out of it.

## Anti-Patterns

Common mistakes to avoid:

1. **Storing everything "just in case"** — Creates noise. Noise degrades
   retrieval quality for every future session.

2. **Narrative memory** — "First we tried X, then Y didn't work, so we went
   with Z." Just store: "Use Z for [reason]." Put the journey in decisions.yml.

3. **Duplicating CLAUDE.md** — If it's already a rule in CLAUDE.md, don't
   also store it in MEMORY.md. One source of truth.

4. **Storing temporary state** — "Currently debugging issue #42" is not a
   memory. It's session state that belongs in a trace or plan.

5. **Storing code** — Code belongs in files, not in memory. Store a pointer
   ("Utility for X is at src/utils/x.ts") not the implementation.

## Relationship to Other Systems

| System | Relationship |
|--------|-------------|
| CLAUDE.md Guardian (t4) | Validates any CLAUDE.md changes triggered by graduation |
| Tracing (t5-t8) | Errors go to trace log, not MEMORY.md |
| Roadmap (future t in Phase 2) | Future ideas go to roadmap.yml, not MEMORY.md |
| Planning (future Phase 2) | Plan state goes to plan.yml, not MEMORY.md |
