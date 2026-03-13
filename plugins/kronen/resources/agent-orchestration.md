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

### Three-Tier Decision Matrix

Use this matrix to select model tier for any dispatch. Match the first row that fits.

| Signal | Tier | Rationale |
|--------|------|-----------|
| Read-only scan, counting, pattern match, format check | junior | No judgment, fast, cheap |
| Single-file edit, template fill, boilerplate generation | junior | Mechanical, low risk |
| Multi-file implementation, logic decisions, test writing | senior | Judgment needed |
| Code review with reasoning, quality assessment, debugging | senior | Multi-step analysis |
| Architecture decision, security review, cross-system design | principal | Max reasoning depth |
| Orchestration of other agents, critical gate decisions | principal | Accountability required |

**Cost impact**: junior is ~20x cheaper than principal. Default to junior and escalate
only when the task genuinely requires judgment or reasoning depth. Escalating haiku
to sonnet when haiku fails costs less than starting at opus for every task.

### Quick selection heuristic

- _Can I specify the output format completely?_ → junior
- _Does it require reading across 3+ files and forming a judgment?_ → senior
- _Would an architect make a different call than a developer?_ → principal

### Trigger-Based Dispatch

Skills may declare a `triggers:` array in their frontmatter with activation keywords.
When selecting a skill to dispatch, match context keywords against trigger lists
before falling back to description scanning. Triggers reduce false-positive activations
and allow precise targeting when multiple skills cover adjacent domains.

```yaml
# Dispatch based on triggers, then description
triggers: ["hypothesis", "parallel investigation", "3 hypotheses"]
```

Dispatch the skill whose triggers best match the current task context. When no
triggers match, use description similarity as the fallback.

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

## Per-Task Reviewer Pattern

For complex implementation tasks, use a 3-stage loop per task:
implementer → spec-reviewer → quality-reviewer. Each stage is a fresh
agent that reads the prior stage's artifact file.

### When to use

- High-risk implementation tasks (new skills, hooks, schema changes)
- Tasks where spec compliance is critical before quality review
- Multi-wave plans where later waves depend on correct earlier outputs

### Stage structure

```
Implementer
  → writes .ai/plans/<name>/artifacts/<wave>-<task>-output.md
  → verified via verification-gate before reporting done

Spec Reviewer (reads implementer artifact)
  → checks: does output match task spec? files written correctly?
  → writes .ai/plans/<name>/artifacts/<wave>-<task>-spec-review.md
  → verdict: PASS | FAIL (with specific issues)

Quality Reviewer (reads both artifacts — only if spec review passes)
  → checks: content quality, completeness, edge cases, consistency
  → writes .ai/plans/<name>/artifacts/<wave>-<task>-quality-review.md
  → verdict: PASS | PASS_WITH_NOTES | FAIL
```

### Coordinator reads all three artifacts directly

Never paraphrase reviewer responses. Read the artifact files:
```
Read tool → .ai/plans/<name>/artifacts/<wave>-<task>-spec-review.md
Read tool → .ai/plans/<name>/artifacts/<wave>-<task>-quality-review.md
```

Advance state based on the verdict fields in those files.

### Fallback

For simple, low-risk tasks (schema updates, doc edits), a single
implementer without reviewer loop is sufficient.

---

## Forward-Message Pattern

**The problem:** When sub-agents return results, the coordinator synthesizes their output into a summary before acting. This paraphrasing loses ~50% of the signal — the telephone game. Each synthesis step degrades fidelity.

**The fix:** Sub-agents write findings directly to shared artifact files on disk. The coordinator reads from disk instead of relying on the response text.

### Convention

Artifact files go in `.ai/plans/<name>/artifacts/`:

```
.ai/plans/my-plan/artifacts/
  wave1-task1-findings.md
  wave1-task2-findings.md
  wave2-task1-findings.md
```

### Sub-agent responsibility

At the end of every research or analysis task, write a findings file:

```markdown
# Findings: <task-name>

## Summary
One sentence.

## Key Results
- Finding 1
- Finding 2

## Recommendations
- Action A
- Action B
```

### Coordinator responsibility

**Never paraphrase sub-agent responses when the artifact file is available.**

Read the file directly:
```
Read tool → .ai/plans/<name>/artifacts/wave1-task1-findings.md
```

This preserves full fidelity. The sub-agent's exact words and structure reach
the next stage without degradation.

### When to apply

- Any parallel wave with 2+ agents writing independent findings
- Research tasks where findings feed into implementation tasks
- Any agent chain longer than 2 steps

### When NOT to apply

- Single-step tasks with no downstream consumers
- Tasks where the output is a file change (not a findings report)

---

## Context Hub Pattern (E2)

When orchestrating multi-agent workflows, the coordinator should assemble shared
context once and pass it forward — not have each sub-agent independently discover
context from scratch.

### The problem

Without a hub, each sub-agent reads state.yml, snapshot.yml, and findings files
independently. This wastes tokens, produces inconsistent context (if files change
mid-workflow), and leads to divergent interpretations.

### The fix

The coordinator (plan-engine, or any orchestrating skill) reads shared state
files once before dispatching sub-agents, then includes the relevant context in
each agent's prompt.

### What to assemble

Before dispatching any wave of sub-agents, read:

| Source | What it provides |
|--------|-----------------|
| `.ai/plans/<name>/state.yml` | Current plan progress, completed tasks, errors |
| `.ai/plans/<name>/plan.md` | Implementation rules, sync constraints, what NOT to do |
| `.ai/context/snapshot.yml` | Session context (branch, dirty files, active plan) |
| `.ai/plans/<name>/artifacts/*.md` | Prior wave outputs (forward-message pattern) |

### How to pass

Include assembled context in each sub-agent's prompt:

```
"You are implementing task <id>: <name>.

Context:
  Plan rules: [plan.md content]
  Prior outputs: [relevant artifact contents]
  Current state: [wave progress, errors to avoid]

Task: [task description]
Output: write to .ai/plans/<name>/artifacts/<wave>-<task>-output.md"
```

### When to apply

- Any orchestrated workflow with 2+ parallel agents
- Wave-based plan execution (plan-engine)
- Sequential chains where later agents need earlier context

### When NOT to apply

- Single agent dispatch with no shared state
- Read-only agents that don't need workflow context (e.g., skill-auditor on a standalone audit)

---

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
| `component-reviewer` | Pre-commit component validation | inherit | After hook-creator, skill-creator, or agent-creator |
