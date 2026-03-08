# Claude Core — Architecture

Single source of truth for plugin structure, conventions, and contracts.
All features must conform to this document.

## Purpose

Claude Core is the foundation plugin. It provides capabilities that all other
plugins depend on: tracing, memory management, planning, brainstorming, agent
orchestration, roadmap capture, and CLAUDE.md governance.

It is always installed. Other plugins (claude-toolkit, development, marketing,
devops) depend on it but never on each other.

## Plugin Hierarchy

```
claude-core          ← always installed, foundation for everything
claude-toolkit       ← opt-in, builder tools (skill/plugin/command creation)
development          ← domain plugin, depends only on claude-core
marketing            ← domain plugin, depends only on claude-core
devops               ← domain plugin, depends only on claude-core
```

**Rule:** Domain plugins never reference each other. Cross-domain flows are
orchestrated by the planner. Outputs are "isolated enrichments" — one plugin
produces files another can read, but never depends on.

## Directory Layout

```
plugins/claude-core/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest — hooks, metadata
├── scripts/                 # Shell scripts for hooks and automation
│   ├── claude-md-guardian.sh
│   ├── trace-light.sh
│   ├── pre-completion-review.sh
│   └── memory-health-check.sh
├── commands/                # User-invocable commands (markdown)
│   └── trace-full.md
├── skills/                  # Re-usable skills (SKILL.md + references/)
│   └── (Phase 2+: planning, brainstorm, etc.)
├── resources/               # Static resources, formats, rules
│   ├── error-annotation-format.yml
│   └── memory-rules.md
├── tests/                   # Test results and validation scripts
│   └── phase-1-results.yml
├── ARCHITECTURE.md          # This file
└── README.md                # User-facing documentation
```

## plugin.json Structure

```json
{
  "name": "claude-core",
  "version": "0.1.0",
  "description": "Foundation plugin — tracing, memory, CLAUDE.md governance, planning, orchestration",
  "author": { "name": "mvn" },
  "hooks": {
    "PreToolUse": [...],
    "PostToolUse": [...],
    "SessionStart": [...],
    "Stop": [...]
  }
}
```

**Hook registration rules:**
- Every hook script must execute in <100ms (ideally <50ms)
- Hook scripts must fail gracefully (exit 0 on error, never block Claude)
- Hooks output guidance text — Claude reads it and decides action
- A hook must never modify files silently; it advises, Claude acts

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Scripts | `kebab-case.sh` | `trace-light.sh` |
| Commands | `kebab-case.md` | `trace-full.md` |
| Skills | `kebab-case/SKILL.md` | `planning/SKILL.md` |
| Resources | `kebab-case.{yml,md}` | `error-annotation-format.yml` |
| Tests | `phase-N-results.yml` | `phase-1-results.yml` |
| State files | `kebab-case.yml` in `.ai/` | `.ai/traces/trace-config.yml` |

## State File Locations

All runtime state lives in `.ai/` (project-scoped), never in the plugin directory.

| State | Location | Purpose |
|-------|----------|---------|
| Trace config | `.ai/traces/trace-config.yml` | Light/full toggle, session info |
| Trace log (light) | `.ai/traces/trace-light.log` | Append-only light trace |
| Trace sessions (full) | `.ai/traces/sessions/trace-full-{date}.yml` | Per-session full trace |
| Plans | `.ai/plans/{name}/plan.yml` | Wave execution plans |
| Brainstorm | `.ai/brainstorm/{name}/` | Transcripts, decisions |
| Roadmap | `.ai/roadmap.yml` | All future ideas and deferred work |
| Memory | `~/.claude/projects/{project}/memory/MEMORY.md` | Auto-memory |

## Hook Design Pattern

Hooks are **advisory, not imperative**. They output text that Claude reads as
part of the tool result. Claude then decides what to do.

```bash
#!/bin/bash
# Pattern: detect condition → output advisory → exit 0
if [[ condition ]]; then
    echo "⚠️ Advisory: [what happened]. Consider: [suggestion]."
fi
exit 0  # ALWAYS exit 0 — never block
```

**Why advisory?** Imperative hooks that block or modify files silently are
fragile and hard to debug. Advisory hooks leverage Claude's judgment while
ensuring the hook's concern is surfaced.

## Testing Requirements

Every feature must have:
1. **Test criteria** — defined before building (in plan.yml)
2. **Functional test** — does it work as specified?
3. **Uninstall test** — does removing it break anything else?
4. **Performance test** — hooks <100ms, scripts <500ms
5. **Test results** — stored in `tests/` directory

## CLAUDE.md Governance

CLAUDE.md is the most sensitive file in the workspace. Rules:
- Every edit triggers the guardian hook (validation)
- Guardian checks: contradictions, redundancy, consequences, alternatives
- Max 200 lines per CLAUDE.md file (Anthropic truncates after this)
- Pointers to detailed docs instead of inline explanations
- Project-level CLAUDE.md for project-specific context (brand paths, etc.)

## Memory Architecture

Three files with distinct purposes:

| File | Purpose | Loaded | Max Size |
|------|---------|--------|----------|
| CLAUDE.md | Rules, behaviors | Always | 200 lines |
| MEMORY.md | Facts, preferences, pointers | Always | 150 lines |
| decisions.yml | Reasoning, context | On-demand | Unlimited |

Plus `roadmap.yml` for future ideas (on-demand, never auto-loaded).

**Graduation rule:** When a memory entry becomes a skill or CLAUDE.md rule,
delete it from MEMORY.md. The knowledge graduated to a better home.

## Tracing Architecture

Two levels, always-on light + opt-in full:

| Level | What's Captured | Storage | Cost |
|-------|----------------|---------|------|
| Light | timestamp, tool, pass/fail, duration, error one-liner | `.ai/traces/trace-light.log` (append) | Near-zero |
| Full | light + decision context, intermediate outputs, file changes | `.ai/traces/sessions/trace-full-{date}.yml` | Moderate |

**Error annotation format:** When errors occur, Claude writes structured
entries with: explanation, reproduction, expected vs actual, severity, fix
suggestion. Captured in the moment, not after the fact.

### Relationship to Agency Traces

Agency traces are domain-skill observability — per-skill decisions, uncertainty flags,
and reflections stored in `.ai/projects/<name>/traces/`. Claude-core traces are universal
tool-level logging in `.ai/traces/`. The two systems are independent and complementary:
claude-core captures what happened (every tool invocation), agency captures why it
happened (skill-level reasoning within a project context).

## Version Policy

- Semver: `MAJOR.MINOR.PATCH`
- Phase 1 ships as `0.1.0` (foundation, not feature-complete)
- `1.0.0` when Phases 1-3 are complete and battle-tested
- Breaking changes bump MINOR during 0.x (pre-1.0)
