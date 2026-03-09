# Agent Orchestration Reference

How to discover, dispatch, and collect results from agents in Claude Code.

## Agent Discovery

Agents live in `plugins/<plugin>/agents/<name>.md`. Each agent file has
YAML frontmatter defining its identity + a markdown body defining its behavior.

Agents are auto-discovered from the filesystem by Claude Code. The `ecosystem.json`
file is documentation-only — it is not consumed at runtime. Registration in
ecosystem.json is for human tracking and validation tooling, not for discovery.

## Agent Frontmatter Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Kebab-case, 3-50 chars. Must match filename |
| `description` | string | yes | Purpose + 2-4 trigger phrases. Primary matching surface |
| `model` | string | yes | `inherit`, `haiku`, `sonnet`, or `opus` |
| `color` | string | yes | Terminal output color: blue/cyan/green/yellow/magenta/red |
| `tools` | array | no | Restrict to specific tools. Omit for all tools |
| `model_tier` | string | no | Our tier label: junior/senior/principal |
| `capabilities` | array | no | 2-4 short capability descriptions |

## Tier Selection Guide

| Tier | Model | When to use | Examples |
|------|-------|-------------|---------|
| junior | haiku | Mechanical, repetitive, no judgment | File validation, syntax checks, boilerplate |
| senior | sonnet | Judgment needed, multi-step reasoning | Code review, quality assessment, audits |
| principal | opus | Architectural, cross-cutting, security | Security audit, design decisions, orchestration |

Default to `inherit` unless the agent has a strong reason for a specific model.
Leadership agents (tech leads, architects) use `opus`. Workers use `haiku` or
`sonnet` based on task risk.

## Dispatch Patterns

### Single Agent

```
Agent tool → subagent_type: "<agent-name>" → prompt with task context
```

The simplest pattern. Dispatch one agent with a focused task.

### Parallel Batch

Multiple Agent tool calls in a single message for independent work:

```
Message contains:
  Agent(subagent_type="skill-auditor", prompt="Audit skills A, B, C...")
  Agent(subagent_type="security-auditor", prompt="Scan plugin X...")
  Agent(subagent_type="plugin-validator", prompt="Validate plugin X...")
```

All three run concurrently. Results arrive independently.

### Sequential Chain

Agent A output feeds into Agent B prompt:

```
result_A = Agent(subagent_type="skill-auditor", prompt="...")
# Parse result_A for findings
Agent(subagent_type="skill-creator", prompt="Fix these findings: {result_A}")
```

Use when later agents depend on earlier results.

### Wave-Based

Execute waves from a plan, dispatching agents per-wave:

```
For each wave in plan:
  If wave.parallel:
    Dispatch all wave tasks as parallel Agent calls
  Else:
    Dispatch tasks sequentially
  Collect all results before advancing to next wave
```

## Dispatch Prompt Template

When dispatching an audit or review agent, include:

```
Context: [what plugin/skill/component is being reviewed]
Task: [what to validate — specific checks, scope]
Standards: [reference to process.md, checklist, or conventions doc]
Output format: [YAML verdict / findings report / severity categories]
Scope constraints: [read-only, specific files, specific directories]
```

Be specific about scope. Broad prompts produce broad (unfocused) results.

## Collecting Results

Each agent returns a single message with findings. Parse for:

- **Verdict**: PASS / FAIL / APPROVE / BLOCK / NEEDS_IMPROVEMENT
- **Severity counts**: critical, high/warning, medium, low/info
- **Specific issues**: file path, line number, description, remediation
- **Recommendation**: what to do next

### Aggregation for Gate Decisions

When running multiple agents for a quality gate:

| Agent Result | Gate Impact |
|-------------|-------------|
| Any CRITICAL/BLOCK | Gate fails — fix before proceeding |
| Only WARNING/MEDIUM | Gate passes with notes — fix soon |
| Only INFO/LOW | Gate passes clean |

## Error Handling

| Situation | Response |
|-----------|----------|
| Agent fails to return | Retry once with more specific prompt |
| Agent returns partial results | Accept what's there, note gaps |
| Agent returns unexpected format | Extract key fields manually |
| Three failures on same task | Escalate to manual review |

### Tier Escalation

If an agent fails at its assigned tier:
1. haiku fails → re-dispatch at sonnet
2. sonnet fails → re-dispatch at opus
3. opus fails → manual review required

## Claude-Core Agents

| Agent | Purpose | Model | Dispatch For |
|-------|---------|-------|-------------|
| `plugin-validator` | Full plugin structure validation | inherit | Plugin releases, post-creation checks |
| `skill-auditor` | Deep skill quality review | inherit | Batch skill audits, post-creation review |
| `security-auditor` | Infrastructure security scan | opus | Pre-release security gates, hook changes |
