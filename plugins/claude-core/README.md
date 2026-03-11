# Claude Core

**The foundation that makes Claude Code actually intelligent.**

Claude Core transforms Claude Code from a stateless coding assistant into a
persistent, self-improving development partner. It handles the things you
shouldn't have to think about: remembering what matters, tracing what happened,
protecting your configuration, and keeping everything organized.

Every other plugin in hjemmesidekongen/ai builds on top of this.

---

## What's Inside

### Smart Memory Management

Claude forgets everything between sessions. Core fixes that — but without
bloating your context or slowing things down.

- **Three-layer memory** — rules (CLAUDE.md), facts (MEMORY.md), and reasoning
  (decisions.yml). Each loaded at the right time, never all at once.
- **150-line discipline** — MEMORY.md stays lean. When a fact becomes a skill
  or a rule, it graduates and gets deleted. No memory hoarding.
- **Daily health checks** — automated pruning catches stale entries before they
  pile up. You get notified, never surprised.
- **Smart capture** — Claude distinguishes between your thinking-out-loud and
  actual decisions. Not everything you say becomes a permanent memory.

### CLAUDE.md Guardian

Your CLAUDE.md file is the single most important file in your workspace. Every
session starts by reading it. One bad rule cascades into everything.

- **Automatic validation** — every edit to CLAUDE.md triggers a review:
  contradiction check, redundancy check, consequence analysis.
- **"Is there another way?"** — the guardian doesn't just check for problems,
  it considers alternatives before committing changes.
- **Boot sequence protection** — keeps your configuration lean, correct, and
  free of conflicts that would confuse Claude in future sessions.

### Always-On Tracing

When something goes wrong, you need to know exactly what happened and why.
Not a vague memory of it — the actual trace.

- **Light mode (always on)** — every tool invocation logged: timestamp, what
  ran, pass/fail, duration, error summary. Near-zero overhead.
- **Full mode (opt-in)** — toggle on for active development. Captures decision
  reasoning, intermediate outputs, file changes, and token usage.
- **Real-time error annotation** — when errors happen, Claude documents them
  *immediately*: what went wrong, how to reproduce it, expected vs actual
  output, severity, and a suggested fix. No after-the-fact guessing.
- **Pre-completion review** — before marking any task done, the trace is
  automatically reviewed for unresolved issues. Critical errors block
  completion. Nothing ships with known problems.

### Planning and Brainstorming

Structure thinking before building. These were re-implemented from scratch in
claude-core (previously split across task-planner and agency plugins).

- **Wave planning** — break work into dependency-ordered waves with file ownership
  isolation. Tasks in the same wave run in parallel safely.
- **Brainstorm sessions** — open-ended sparring where Claude pushes back on weak
  reasoning. Formalize conclusions into structured decisions.
- **Brainstorm decision reader** — load past brainstorm decisions relevant to the
  current task. Filter by domain, sort by confidence. Utility for any skill or agent.
- **Roadmap capture** — when out-of-scope ideas surface, Claude adds them to
  `roadmap.yml` automatically. Tagged, categorized, searchable.

### Autonomous Agents

Three validation agents that run independently as subagents for quality gates:

- **Plugin Validator** — full plugin structure and registry validation
- **Skill Auditor** — deep skill quality review against conventions
- **Security Auditor** — infrastructure security scan (hooks, scripts, configs)

See `resources/agent-orchestration.md` for dispatch patterns and tier selection.

### Session Lifecycle

- **Session recovery** — on startup, reports active plan state and project context.
  No more "where was I?" after reopening.
- **Stop hooks** — warns if there's work in progress before ending a session.
  Checks both plan state and agency project state.
- **Trace reflection check** — reminds about missing reflections in agency traces.

### Status Bar

Invisible state causes invisible mistakes. The status bar makes key context
visible at a glance.

- Active project name
- Trace level (light or full)
- Memory usage approaching limit
- Missing initialization warnings

---

## Architecture

Claude Core is the only plugin that other plugins can reference. This
enforces clean isolation:

```
claude-core          ← foundation (always installed)
  ├── claude-toolkit ← builder tools (skill/plugin creation, opt-in)
  ├── development    ← domain plugin
  ├── marketing      ← domain plugin
  └── devops         ← domain plugin
```

Domain plugins never talk to each other directly. Cross-domain workflows are
orchestrated by the planner. If you uninstall devops, development still works
— you just lose the deploy capability.

See [ARCHITECTURE.md](ARCHITECTURE.md) for technical details: directory layout,
hook patterns, naming conventions, state file locations, and testing requirements.

---

## Quick Start

Claude Core is installed globally and activates automatically.

```bash
# Verify it's active
claude /status

# Toggle full tracing for a development session
claude /trace:full

# Check memory health
claude /memory:health
```

---

## What's Coming

Claude Core is built in phases. Each feature is implemented, tested, and
validated before the next one begins.

| Phase | Status | What's Included |
|-------|--------|----------------|
| **Phase 1** | Complete | Tracing (light + full), memory discipline, CLAUDE.md guardian, status bar, error annotation, pre-completion review |
| **Phase 2** | Complete | Planning (create/execute/status/resume), brainstorm (start/decide), roadmap capture, brainstorm-decision-reader |
| **Phase 3** | Complete | Creator skills (hook/command/skill/agent/plugin/MCP), reviewer skills (hook/skill/plugin), plugin-settings, doc-checkpoint |
| **Phase 4** | Complete | Eval infrastructure, hardening audit, 3 validation agents, agent orchestration |

For the full roadmap across all plugins: [`.ai/roadmap.yml`](../../.ai/roadmap.yml)

---

## Part of hjemmesidekongen/ai

Claude Core is one piece of a larger system designed to make Claude Code
work the way a professional development team does:

| Plugin | Purpose |
|--------|---------|
| **Claude Core** | Foundation — memory, tracing, planning, governance |
| **Claude Toolkit** | Builder tools — create and test skills, plugins, commands |
| **Development** | Code generation, review, QA, scaffolding |
| **Marketing** | Brand, SEO, content, social media |
| **DevOps** | Deployment, CI/CD, monitoring |

Each plugin is independent, removable, and tested in isolation. Install only
what you need.
