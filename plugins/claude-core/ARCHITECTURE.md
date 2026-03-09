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
│   ├── plugin.json          # Plugin manifest — hooks, metadata
│   └── ecosystem.json       # Component registry
├── scripts/                 # Shell scripts for hooks
│   ├── claude-md-guardian.sh    # PostToolUse: CLAUDE.md edit validation
│   ├── trace-light.sh          # PostToolUse: append-only tool trace
│   ├── memory-health-check.sh  # Memory bloat/stale detection
│   ├── session-recovery.sh     # SessionStart: report plan + project state
│   ├── check-wave-complete.sh  # Stop: warn if plan/project work in progress
│   ├── check-trace-written.sh  # Stop: remind about missing trace reflections
│   ├── doc-stale-check.sh        # Stop: warn if plugin files changed without doc updates
│   ├── port-dedup-check.sh       # Stop: warn if component duplicated across plugins
│   ├── strategic-compact-trigger.sh # PostToolUse: suggest /compact at depth thresholds
│   ├── verification-gate-stop.sh    # Stop: remind to run proof before claiming done
│   └── cache-clear.sh            # Stop: clear plugin cache at session end
├── commands/                # User-invocable commands (markdown)
│   ├── brainstorm-start.md
│   ├── brainstorm-decide.md
│   ├── plan-create.md
│   ├── plan-execute.md
│   ├── plan-status.md
│   ├── plan-resume.md
│   ├── roadmap-add.md
│   ├── roadmap-view.md
│   └── trace-full.md
├── agents/                  # Autonomous validation agents
│   ├── plugin-validator.md    # Full plugin structure validation
│   ├── skill-auditor.md       # Deep skill quality review
│   └── security-auditor.md    # Infrastructure security scan
├── skills/                  # Re-usable skills (SKILL.md + references/)
│   ├── brainstorm-session/
│   ├── brainstorm-decision-writer/
│   ├── brainstorm-decision-reader/
│   ├── doc-checkpoint/
│   ├── hook-creator/
│   ├── command-creator/
│   ├── skill-creator/
│   ├── agent-creator/
│   ├── plugin-creator/
│   ├── mcp-creator/
│   ├── hook-reviewer/
│   ├── skill-reviewer/
│   ├── plugin-reviewer/
│   ├── verification-gate/
│   ├── plugin-settings/
│   ├── plan-engine/
│   ├── plan-verifier/
│   └── roadmap-capture/
├── resources/               # Static resources, formats, rules
│   ├── error-annotation-format.yml
│   ├── memory-rules.md
│   ├── agent-orchestration.md # How to discover, dispatch, and use agents
│   ├── plan-schema.yml      # Canonical plan schema
│   ├── state-schema.yml     # Canonical state schema
│   └── brainstorm-schema.yml
├── ARCHITECTURE.md          # This file
└── README.md
```

## plugin.json Structure

```json
{
  "name": "claude-core",
  "version": "0.2.0",
  "hooks": {
    "PostToolUse": ["claude-md-guardian.sh (Write|Edit)", "compact-gate-post.sh (Write|Edit)", "trace-light.sh (all)", "strategic-compact-trigger.sh (all)"],
    "SessionStart": ["session-recovery.sh"],
    "Stop": ["check-wave-complete.sh", "check-trace-written.sh", "doc-stale-check.sh", "port-dedup-check.sh", "cache-clear.sh"]
  }
}
```

**Hook inventory:**

| Hook | Script | Trigger | Behavior |
|------|--------|---------|----------|
| PostToolUse | `claude-md-guardian.sh` | Write\|Edit on CLAUDE.md | Advisory: validate edits |
| PostToolUse | `trace-light.sh` | All tools | Append trace entry (<30ms) |
| PostToolUse | `strategic-compact-trigger.sh` | All tools | Suggest /compact at depth thresholds (<10ms) |
| Stop | `verification-gate-stop.sh` | Session end | Remind to run proof before claiming done |
| SessionStart | `session-recovery.sh` | Session start | Report plan + project state |
| Stop | `check-wave-complete.sh` | Session end | Warn if work in progress (informational) |
| Stop | `check-trace-written.sh` | Session end | Remind about missing reflections |
| Stop | `doc-stale-check.sh` | Session end | Warn if plugin files changed without doc updates |
| Stop | `port-dedup-check.sh` | Session end | Warn if skill/command exists in multiple plugins |
| Stop | `cache-clear.sh` | Session end | Clear plugin cache (dev workspace only) |

**Hook rules:**
- Scripts must execute in <100ms (ideally <50ms)
- Fail gracefully (exit 0 on error, never block Claude)
- Output guidance text — Claude reads it and decides action
- Never modify files silently; advise, Claude acts
- Stop hooks may exit 2 to signal active work (non-blocking warning)

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Scripts | `kebab-case.sh` | `trace-light.sh` |
| Commands | `kebab-case.md` | `trace-full.md` |
| Skills | `kebab-case/SKILL.md` | `planning/SKILL.md` |
| Resources | `kebab-case.{yml,md}` | `error-annotation-format.yml` |
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
| Context snapshot | `.ai/context/snapshot.yml` | Enriched session state — survives compaction. Sections: workspace, project, working_state, session_trail (intent, decisions_modified, next_step), probes. Target: <80 lines. |

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
- `0.1.0` — Phase 1 (foundation: tracing, memory, guardian)
- `0.2.0` — Phase 2 (planning, brainstorm, roadmap) + migration cleanup
- `0.3.0` — Phase 4 gate (hardening audit, 3 agents, eval validation)
- `1.0.0` when all phases are complete and battle-tested
- Breaking changes bump MINOR during 0.x (pre-1.0)

## Migration from Legacy Plugins

Claude-core consolidates functionality previously split across task-planner and agency.
The "Ship of Theseus" migration replaces skills one at a time while keeping legacy
plugins as scaffolding for their unique features.

**Migrated to claude-core (removed from legacy):**
- Planning: plan-engine, plan-verifier (from task-planner's wave-decomposer, file-ownership, verification-runner, spec-compliance-reviewer)
- Brainstorm: brainstorm-session, brainstorm-decision-writer (from both task-planner and agency)
- Utilities: brainstorm-decision-reader (from both), session-recovery, check-wave-complete, check-trace-written (from both)
- Schemas: plan-schema.yml, state-schema.yml (from task-planner)

**Remaining in task-planner:** plugin-* commands/skills, version-* skills, agents
**Remaining in agency:** brand/design/content/dev/devops skills, agency:* commands, agents (security-reviewer ported as security-auditor)

## Agent Architecture

Claude-core provides autonomous validation agents for plugin quality gates.

| Agent | Purpose | Model | Tools |
|-------|---------|-------|-------|
| `plugin-validator` | Full plugin structure and registry validation | inherit | Read, Grep, Glob, Bash |
| `skill-auditor` | Deep skill quality review against conventions | inherit | Read, Grep, Glob |
| `security-auditor` | Infrastructure security scan (hooks, scripts, configs) | opus | Read, Grep, Glob, Bash |

**Agent directory:** `plugins/claude-core/agents/`
**Orchestration guide:** `resources/agent-orchestration.md`

Agents are auto-discovered from the filesystem. The ecosystem.json `agents` array
is for documentation and validation tooling, not runtime discovery.

### Agents vs Reviewer Skills

Reviewer skills (hook-reviewer, skill-reviewer, plugin-reviewer) provide the
review *methodology* — checklists, standards, process steps. Agents are the
*autonomous execution* of those review processes. An agent can apply a reviewer
skill's standards without human invocation, running independently as a subagent.

### Eval Sub-agents

The `skill-creator` skill has 3 eval agents under `skills/skill-creator/agents/`.
These are scoped sub-agents for eval infrastructure, not top-level plugin agents.
They do not appear in `ecosystem.json`.
