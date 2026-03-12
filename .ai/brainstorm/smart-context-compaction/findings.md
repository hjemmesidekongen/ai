# Findings — Smart Context Compaction & Memory

## Key Projects Discovered

### memory-mcp (yuvalsuede)
- **Repo**: https://github.com/yuvalsuede/memory-mcp
- **Article**: https://dev.to/suede/the-architecture-of-persistent-memory-for-claude-code-17d
- **Most relevant** — directly implements temporal decay + two-tier memory for Claude Code
- Two tiers: Tier 1 = auto-generated CLAUDE.md (~150 lines), Tier 2 = .memory/state.json (unlimited)
- Hook points: Stop, PreCompact, SessionEnd — reads conversation transcript from cursor position
- Decay by type: Architecture/Decisions/Patterns = permanent; Progress = 7-day half-life; Context = 30-day half-life
- Confidence scores 0–1: below 0.3 hidden from CLAUDE.md, still searchable
- Dedup: Jaccard similarity >60% token overlap → supersedes rather than appends
- LLM consolidation (Haiku) every 10 extractions or >80 memories
- Ranking: `confidence * accessCount` — determines what gets injected
- Fixed CLAUDE.md line budgets per section: Architecture 25, Decisions 25, Patterns 25, Gotchas 20, Progress 30, Context 15
- Cost: ~$0.001 per extraction. Full day: $0.05–$0.10 via Haiku
- 80% of sessions need only Tier 1; dedup called "the hard problem" — naive systems drown in duplicates within days

### mem0
- **Site**: https://mem0.ai/blog/claude-code-memory
- **Repo**: mem0ai (MCP server)
- Hybrid vector/KV/graph stores; semantic search on query/user_id
- Auto-inserts relevant memories via .mcp.json config
- Reported: 90% lower tokens, 91% faster responses, 10–11min tasks → 1–2min
- Cloud/self-hosted (Qdrant/pgvector); supports Anthropic
- Free tier: 10k memories; cloud dependency

### claude-mem
- **Repo**: https://github.com/thedotmack/claude-mem (also: https://github.com/hesreallyhim/awesome-claude-code/issues/167)
- ChromaDB vectors; compresses conversations 10x; semantic search; local-only (~/.claude-mem/)
- 1-line npm install; MCP integration loads at startup
- Smart Trash recovery feature
- Reported: 95% fewer tokens, 20x more tool calls before context limit
- No explicit decay mechanism — relies on retrieval relevance

### contextstream/claude-code
- **Site**: https://contextstream.io
- **Repo**: https://github.com/contextstream/mcp-server
- Local encrypted store: embeddings + metadata + graphs + decisions; codebase indexing
- Works across Claude Code, Cursor, VSCode
- Semantic search across conversations and decisions
- Persistent forever — no expiration mechanism mentioned
- Cross-tool memory: remembers TypeScript strict mode, PostgreSQL preference etc.

### Recall
- **Repo**: https://github.com/joseairosa/recall
- Redis store; workspace-organized; high-signal only (prefs/decisions/bugs)
- Selective storage to avoid bloat — opinionated about what's worth keeping
- No decay mechanism mentioned

### MCP Memory Keeper
- **LobeHub**: https://lobehub.com/mcp/mkreyman-mcp-memory-keeper
- SQLite (context.db); preserves history/decisions/progress
- Key-based queries; handles compaction in refactoring/debugging scenarios

### Supermemory for Claude Code
- **Repo**: https://github.com/supermemoryai/claude-supermemory
- Plugin using Supermemory for cross-session recall
- Early stage; limited implementation details

---

## Research on Context Compaction

### Claude Code Hook Events (confirmed)
- `PreCompact`: fires before compaction, stdin JSON has `trigger: "manual" | "auto"`
- `SessionStart` with `matcher: "compact"`: fires when session resumes after compaction
- Known bug: SessionStart compact stdout injection may not reliably inject to context
- Hooks cannot trigger `/compact` programmatically — user or model action only
- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`: env var, 0–1 float, controls when auto-compact fires (default ~0.78–0.80)
- `DISABLE_AUTO_COMPACT=true`: undocumented env var, kills auto-compact entirely (dangerous)
- Issue #24058 "Let Claude trigger compaction via tool call" — marked COMPLETED in API beta, not yet in Claude Code CLI

### Sources on compaction best practices
- https://decodeclaude.com/compaction-deep-dive/ — custom focus hints, handoff documents, project-level compact instructions
- https://agenticcoding.substack.com/p/32-claude-code-tips-basics-to — disable auto-compact to reclaim ~45k tokens (22.5% of 200k)
- https://m.academy/lessons/compact-conversations-claude-code/ — proactive compact before context runs low, trust compaction system
- https://blog.jetbrains.com/research/2025/12/efficient-context-management/ — JetBrains/NeurIPS 2025: observation masking beats summarization; 10-turn rolling window optimal for coding agents
- https://eval.16x.engineer/blog/llm-context-management-guide — disable unused tools, trim CLAUDE.md, start fresh per task
- https://lethain.com/agents-context-compaction/ — context compaction strategies for agentic workflows

### External Plugin Pattern (additionalContext injection)
- Source: `/Users/mvn/Personal/hjemmesidekongen-ai/external-references/claude-code-main/plugins/`
- Both `learning-output-style` and `explanatory-output-style` use SessionStart → `hookSpecificOutput.additionalContext`
- Shell script outputs JSON: `{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "..."}}`
- This is the delivery mechanism for smart injection — proven to work

---

## Key Design Decisions Emerging

### Compaction trigger map (natural boundaries)
| Trigger event | Artifact written |
|---|---|
| Skill complete | `*/skills/*/SKILL.md` |
| Command complete | `*/commands/*.md` |
| Agent complete | `*/agents/*.md` |
| Hook complete | hook `.sh` + registered |
| Plan created | `.ai/plans/*/state.yml` (new) |
| Wave complete | `state.yml` wave → done |
| Brainstorm concluded | `decisions.yml` written |
| Research done | `findings.md` written |
| Review complete | reviewer output written |
| Domain switch | any |

### Three-layer injection architecture
1. **Workspace memory** — global patterns, permanent decisions, cross-project conventions. Always injected (~200 tokens)
2. **Project memory** — memory-mcp model, confidence*access ranked, decaying by type. Tier 1 budgeted (~150 lines)
3. **Compact snapshot** — point-in-time working state written PreCompact, consumed on SessionStart compact, self-deletes after

### Compact recovery: seamless resume (not clean restart)
- Snapshot carries: current task (1 line), next step, files actively modified (paths only), session decisions, open blockers
- No file contents in snapshot — Claude reads files it needs; snapshot says *which* files matter
- Lean by design: ~300–500 tokens max

### Side effects catalogued
- Staleness without TTL: entries look authoritative but are contextually wrong → solved by memory-mcp decay model
- Circular reasoning: injected patterns become unchallenged constraints → mitigated by permanent-only-for-deliberate-decisions rule
- Confident-but-wrong resume: seamless recovery on stale snapshot → mitigated by lean snapshot + file re-read
- Snapshot corruption window: PreCompact fires mid-write → mitigated by boundary-triggered (not auto-triggered) compact
- Injection conflicts: multiple plugins inject conflicting context → needs explicit priority: CLAUDE.md > MEMORY.md > compact snapshot > project memory > workspace memory
- Cross-project contamination: patterns from one project pollute another → scoping tags per entry + workspace vs. project tier separation
- Size creep: permissive matching accumulates over months → fixed section budgets + Haiku consolidation pass
- Trigger false positives: path-matching fires on non-completion writes → completion events, not file-write events
- Sequential dependency loss: cross-skill contracts not captured in snapshot → snapshot must include active conventions, not just task state
- Trust calibration: episodic patterns injected with same weight as CLAUDE.md rules → explicit confidence labels in injection format

---

## What's Not Yet Built (roadmap gaps relevant here)
- Episodic memory layer (roadmap item): "we tried X on project Y, it failed because Z"
- Friction-driven feedback capture: moments when output doesn't match expectations
- Self-improvement / immune system: behavioral corrections, pattern promotion, sentinel agent
- Smart session recovery with relevance filtering (current session-recovery.sh is static)
- PreCompact hook (nothing currently registered)
- Compact snapshot writer/reader pair
