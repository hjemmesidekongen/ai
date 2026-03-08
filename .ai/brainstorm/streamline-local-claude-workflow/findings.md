# Findings — Streamline Local Claude Workflow

## Memory Research (2025-2026)

### Anthropic's Official System
- Two-layer: CLAUDE.md (explicit instructions) + auto-memory (observed patterns)
- Auto-memory stores in `~/.claude/projects/<project>/memory/`
- MEMORY.md entrypoint + topic files (debugging.md, patterns.md, etc.)
- Target <200 lines per CLAUDE.md, use imports for overflow
- Path-scoped rules: different standards for test files vs components

### Community Best Practices
- **Friction-driven feedback**: capture moments when output doesn't match expectations → translate into instructions → add to memory → iterate
- **External references pattern**: concise pointers in MEMORY.md → detailed docs in knowledge base files (saves tokens)
- **Structured organization**: global rules, domain-specific memories, role-scoped instructions
- **Claude-Mem plugin**: ~10x token efficiency through compression
- **contextstream/claude-code**: persistent memory with auto-restoration across sessions

### Competing Tools Approaches
- **Cursor**: implicit memory through codebase analysis (less control, less burden)
- **Windsurf**: three-layer — Rules, Workflows, Memories (most explicit separation)
- **Copilot**: git-aware pattern recognition
- **Cline**: open architecture, supports vector DB / graph memory backends

### Working Memory vs Long-Term Memory
- **Working memory**: conversation + current files + recent tool outputs. Managed via selective injection, hierarchical summarization, sliding windows
- **Long-term memory** has 3 subtypes:
  1. **Episodic**: specific events/outcomes (what worked, what failed)
  2. **Semantic**: facts, rules, conceptual understanding
  3. **Procedural**: learned skills, effective workflows
- Compaction: Claude Code summarizes old context when approaching window limit, preserving architecture decisions + unresolved bugs
- Sub-agent architecture: distribute complexity across agents with clean context windows

### Key Technical Patterns
- Vector DB for semantic retrieval (Pinecone, Weaviate, Chroma)
- Graph RAG for relational reasoning (multi-step logic)
- Prompt caching: up to 85% latency reduction, 10x cost difference
- Code execution via MCP: 98.7% token reduction (150K → 2K) for data-heavy ops
- Structured note-taking: agents write to external storage, pull back when needed

### 2026 Outlook
- Memory is now "fundamental infrastructure" not a feature
- MCP fastest-adopted standard ever (OpenAI, Google, Microsoft, AWS adopted)
- Multi-agent orchestration requires isolated memory + shared coordination
- Memory Composer modules for separation/compositionality in multi-agent systems

## User Guide Writing Skill (supercent-io)
- 4 doc types: Quick Start, How-To, FAQ, Tutorial
- Must include: screenshots, numbered steps, plain language
- Directory structure: docs/getting-started.md, how-to/, tutorials/, faq.md, images/
- User wants BOTH user-facing onboarding AND developer-facing docs, maintained simultaneously

## Claude AI (Web UI) Compatibility
- User wants skills/functionality available in Claude AI web interface too
- Need to research what's portable between Claude Code CLI and Claude AI

## Build Methodology (from brainstorm)
- One skill at a time, thoroughly tested before moving on
- A/B split testing (like Anthropic's create-skill approach)
- Test results stored alongside the skill (co-located)
- Re-testable: can always come back and retest ("is it still as good?")
- Source attribution in skill frontmatter (_source block with origin, date, version hash)

## CLAUDE.md as Connection Layer
- Plugins don't reference each other directly
- CLAUDE.md contains project-specific pointers: "when working with brand X, look in .ai/projects/X/brand/"
- brand.md (or similar) acts as an index: assets, tone of voice, color tokens, etc.
- This is how design outputs flow to development without coupling the plugins

## Project Scanning / Init
- Scan function that detects: platforms, frameworks, structure, dependencies
- Generates overview (Mermaid diagrams or similar) for AI to understand project
- Should be part of claude-core so it's always available

## Tracing Must Come First
- Enable tracing/logging BEFORE building other skills
- Real-time error annotation: what went wrong, why, proposed solution — captured immediately
- Prevents context loss between sub-agents
- Error log = shared knowledge layer across agents

## Re-implement, Don't Port
- Don't copy-paste from agency/task-planner — re-think each piece
- Get a thorough overview of what exists and what it achieves
- Ask: "Can this be done better with what we know now?"
- For each skill re-implemented: note what was left out (MVP vs iteration 2)
- While developing, capture improvement ideas → roadmap
- Take inspiration from existing code when relevant, but don't default to same approach

## Cron/Loop Opportunities
- Memory pruning: daily check for MEMORY.md bloat, stale entries
- Roadmap review: weekly prompt to review backlog items
- CLAUDE.md health check: periodic validation for contradictions
- Trace cleanup: expire old light trace entries

## Status Bar / Toolbar
- Show tracing level (light/full) in status bar
- Show project initialization status
- Show active project name
- Other relevant state at a glance

## Memory Design Decisions
- Three files: CLAUDE.md (rules), MEMORY.md (facts, <150 lines), decisions.yml (reasoning, on-demand)
- Roadmap.yml for future ideas (auto-capture behavior)
- No vector DB / graph RAG — keep it simple
- Pruning discipline: entries graduate to skills/rules, then get deleted from memory
- "Not everything user says is an instruction" — distinguish thinking-out-loud from decisions
