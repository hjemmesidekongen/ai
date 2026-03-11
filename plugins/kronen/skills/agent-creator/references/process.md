# Agent Creator — Full Reference

## Agent vs command

| Dimension | Agent | Command |
|-----------|-------|---------|
| **Invocation** | Auto-triggered by description matching user intent | Explicit `/plugin:command` by user |
| **Autonomy** | Runs independently as subagent, makes decisions | Single action, returns immediately |
| **Scope** | Multi-step workflows, parallel execution | Focused, deterministic operations |
| **State** | Maintains own conversation context | Stateless — runs and exits |
| **Model** | Configurable per agent (inherit/haiku/sonnet/opus) | Inherits session model |
| **Tool access** | Restricted via `tools` array | Full session tool access |
| **Best for** | Research, review, orchestration, specialist work | Data lookups, file generation, status checks |

**Decision rule:** If the task requires reasoning across multiple steps, judgment calls, or autonomous work — make it an agent. If it is a deterministic operation triggered by explicit user action — make it a command.

## Required frontmatter fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `name` | string | 3-50 chars, lowercase, hyphens only | Agent identifier. Kebab-case, role-based (e.g. `software-architect`, `qa-lead`) |
| `description` | string | 10-5000 chars | Purpose + 2-4 triggering examples. This is the primary matching surface |
| `color` | string | One of: blue, cyan, green, yellow, magenta, red | Terminal color for agent output |
| `model` | string | `inherit`, `haiku`, `sonnet`, `opus` | Model to use. Default: `inherit` |
| `model_tier` | string | `junior`, `senior`, `principal` | Our tier system label (see Tier System section) |
| `tools` | array | Valid tool names | Restrict agent to specific tools. Omit for all tools |
| `capabilities` | array | Short strings | 2-4 bullet capabilities for ecosystem documentation |

### Optional fields

| Field | Type | Description |
|-------|------|-------------|
| `timeout` | number | Max execution time in seconds |
| `max_turns` | number | Maximum conversation turns before forced stop |

## Name conventions

### Rules
- Kebab-case only: `frontend-tech-lead`, not `frontendTechLead`
- 3-50 characters
- Role-based names that describe what the agent does
- No generic names (`helper`, `worker-1`, `agent-a`)

### Naming patterns

| Pattern | Examples | When to use |
|---------|----------|-------------|
| `{role}` | `software-architect`, `qa-lead` | Leadership / orchestration agents |
| `{domain}-{role}` | `frontend-tech-lead`, `backend-worker` | Domain-scoped specialists |
| `{function}-{qualifier}` | `security-reviewer`, `documentation-specialist` | Cross-cutting concerns |

Avoid abbreviations. `documentation-specialist` over `doc-spec`.

## Description and triggering examples

The description is the primary mechanism for agent activation. Claude matches user intent against agent descriptions to decide which agent to spawn.

### Format

```yaml
description: >
  [One sentence: what this agent does and owns.]
  Use when [trigger 1] — [specific scenario],
  [trigger 2] — [specific scenario],
  [trigger 3] — [specific scenario],
  or [trigger 4] — [specific scenario].
```

### What makes a good trigger

| Good trigger | Bad trigger | Why |
|-------------|-------------|-----|
| "API contracts need to be defined between services" | "architecture stuff" | Specific, actionable scenario |
| "frontend work needs risk-based delegation to workers" | "frontend tasks" | Describes the decision process, not just the domain |
| "a feature needs test strategy and coverage enforcement" | "testing" | Includes the scope and purpose |
| "design token usage needs validation against spec" | "check design" | Names the exact artifact and action |

### Rules
- Include 2-4 triggering examples — fewer misses valid use cases, more dilutes matching precision
- Each trigger should describe a specific situation, not just a keyword
- Start triggers with the context or need, not with "you want to..."
- Triggers must be distinct from each other — no overlapping scenarios

## Model selection

| Value | Model | When to use |
|-------|-------|-------------|
| `inherit` | Session default | Most agents. Follows whatever the user is running |
| `haiku` | Fast, cheap | Low-risk tasks: file generation, boilerplate, simple transforms |
| `sonnet` | Balanced | Medium-risk: multi-file changes, some judgment needed |
| `opus` | Most capable | High-risk: architecture, complex review, orchestration |

**Default to `inherit`** unless the agent has a strong reason for a specific model. Leadership agents (tech leads, architects) typically use `opus`. Workers use `haiku` or `sonnet` based on task risk.

## Color assignment

| Color | Semantic meaning | Agent types |
|-------|-----------------|-------------|
| `blue` | Analysis, architecture, leadership | Tech leads, architects, PMs |
| `cyan` | Information, documentation | Documentation, research agents |
| `green` | Success, validation, QA | QA leads, validators, reviewers |
| `yellow` | Caution, security | Security reviewers, compliance |
| `magenta` | Creative, design | Design, UX agents |
| `red` | Critical, operations | DevOps, deployment, emergency |

When uncertain, use `blue` — it is the most neutral.

## Tool restrictions

### Principle: least privilege

Only grant tools the agent actually needs. Every unnecessary tool is an attack surface and a source of unintended side effects.

### Common tool sets

| Agent type | Typical tools | Rationale |
|------------|--------------|-----------|
| **Read-only analyst** | `Read`, `Glob`, `Grep` | Analysis without modification |
| **Code reviewer** | `Read`, `Glob`, `Grep`, `Bash` | Read + run tests, no writes |
| **Implementer** | `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash` | Full development access |
| **Orchestrator** | `Read`, `Glob`, `Grep`, `Bash` | Reads state, spawns subagents, no direct writes |
| **Research** | `Read`, `Glob`, `Grep`, `WebSearch`, `WebFetch` | Gather info, no file modification |

### Tool restriction example
```yaml
tools: ["Read", "Glob", "Grep", "Bash"]
```

Omitting `tools` entirely grants access to all available tools. Only do this when the agent genuinely needs unrestricted access.

## System prompt writing

The system prompt is the body of the agent's Markdown file (everything after the frontmatter). It defines the agent's behavior, personality, and operating procedures.

### Structure template

```markdown
# {Agent Name}

{Role statement — one paragraph defining identity, responsibilities, and scope.
Write in second person addressing the agent directly: "You are the..."}

## Communication Protocol

{Who this agent communicates with and spawns as subagents.}

## Core Responsibilities

{Numbered or bulleted list of primary duties.}

## Process

{Step-by-step workflow the agent follows. Include decision trees where applicable.}

## Output Format

{Expected deliverables — templates, checklists, file formats.}

## Constraints

{What the agent must NOT do. Explicit boundaries.}

## Review Checklist

{Verification steps before marking work complete.}
```

### Length guidance
- Minimum: 500 characters (too short = underspecified behavior)
- Target: 1000-3000 characters (clear, comprehensive)
- Maximum: 10000 characters (beyond this, split into focused sub-agents)

### Writing rules
- Write in second person: "You are the **QA Lead**..."
- Be specific about boundaries: what the agent owns AND what it does not own
- Include communication protocols: who it talks to, who it spawns
- Define output formats with templates — agents produce more consistent output with examples
- List explicit constraints: "You **never touch** implementation files"
- Include a review checklist at the end

## File organization

### Directory structure
```
plugins/
  <plugin>/
    agents/
      <category>/
        <agent-name>.md
```

### Our conventions
- Agents live under `plugins/<plugin>/agents/<category>/`
- Category groups agents by domain: `dev/`, `design/`, `ops/`, etc.
- One agent per file, file name matches the `name` field in frontmatter
- Files are auto-discovered — no manual registration needed beyond ecosystem.json
- Namespacing is automatic based on plugin name

### Example layout
```
plugins/agency/agents/dev/
  software-architect.md
  frontend-tech-lead.md
  frontend-worker.md
  backend-tech-lead.md
  backend-worker.md
  project-manager.md
  qa-lead.md
  security-reviewer.md
  documentation-specialist.md
```

### Ecosystem registration

Add the agent category to the plugin's `ecosystem.json`:
```json
{
  "agents": ["dev"]
}
```

This registers all agents under `agents/dev/` for auto-discovery.

## Our agent tier system

Two related but distinct concepts:

### `model_tier` (in skill frontmatter)

Describes the **complexity level** of the skill that creates/manages agents:
- `junior` — simple, mechanical tasks
- `senior` — judgment required, multi-step reasoning
- `principal` — architectural decisions, cross-cutting concerns

### `model` (in agent frontmatter)

Controls the **actual model** the agent runs on:
- `inherit` — use session default
- `haiku` — fast model for low-risk work
- `sonnet` — balanced for medium-risk
- `opus` — most capable for high-risk decisions

### Tier-to-model mapping (our convention)

| Agent role | `model_tier` | `model` | Rationale |
|-----------|-------------|---------|-----------|
| Leadership (PM, Architect, Tech Leads) | `principal` | `opus` | Complex orchestration, judgment calls |
| QA, Security, Review | `principal` | `opus` | Quality gates require strong reasoning |
| Specialist (Docs, DevOps, Design) | `senior` | `sonnet` or `opus` | Domain expertise, moderate autonomy |
| Worker (Frontend, Backend) | `senior` | `sonnet` | Follows specs, delegated scope |
| Simple task runner | `junior` | `haiku` | Boilerplate, no judgment needed |

Set `model_tier` to reflect the agent's role complexity. Set `model` to match the actual capability needed at runtime.

## Full agent file example

```markdown
---
name: code-reviewer
color: green
capabilities:
  - "Automated code review against project standards"
  - "Security vulnerability scanning"
  - "Performance pattern detection"
description: >
  Reviews code changes for quality, security, and performance issues.
  Use when a pull request needs review — code quality checks, security scanning,
  performance pattern detection, or standards compliance verification.
model_tier: senior
model: sonnet
tools: ["Read", "Glob", "Grep", "Bash"]
---

# Code Reviewer

You are the **Code Reviewer** — responsible for evaluating code changes against
project standards, security best practices, and performance patterns.

## Scope

- Code quality and style compliance
- Security vulnerability detection
- Performance anti-pattern identification
- Test coverage verification

## Process

1. Read the changed files
2. Check against project coding standards
3. Scan for security vulnerabilities (XSS, injection, auth issues)
4. Identify performance anti-patterns
5. Verify test coverage for new code
6. Produce a structured review report

## Output Format

For each finding:

    ## [severity]: [title]
    **File**: [path]
    **Line**: [number]
    **Issue**: [description]
    **Fix**: [recommended change]

## Constraints

- Never modify files directly — report findings only
- Flag severity accurately: critical/high/medium/low
- Do not review generated files or third-party dependencies

## Review Checklist

- [ ] All changed files reviewed
- [ ] Security scan complete
- [ ] Performance patterns checked
- [ ] Standards compliance verified
- [ ] Report formatted correctly
```

## Testing protocol

### 1. Trigger verification

Confirm the agent activates for intended scenarios and does NOT activate for unrelated ones:

| Test | Expected |
|------|----------|
| User prompt matching trigger 1 | Agent activates |
| User prompt matching trigger 2 | Agent activates |
| Unrelated prompt in same domain | Agent does NOT activate |
| Prompt for a different agent's domain | Agent does NOT activate |

### 2. System prompt quality

Verify the prompt covers:
- [ ] Clear role identity
- [ ] Explicit responsibilities
- [ ] Step-by-step process
- [ ] Output format with template
- [ ] Constraints (what NOT to do)
- [ ] Review/completion checklist

### 3. Tool access validation

- [ ] Agent has all tools it needs to complete its work
- [ ] Agent does NOT have tools it should not use
- [ ] No write tools on read-only agents
- [ ] Bash access only when the agent needs to run scripts/tests

### 4. Model appropriateness

- [ ] `model` matches the risk/complexity of the agent's work
- [ ] Leadership agents use `opus`
- [ ] Workers use `sonnet` or `haiku` based on task risk
- [ ] `inherit` used when no specific model is required

### 5. Live test

Run Claude Code and issue a prompt that should trigger the agent. Verify:
- Agent activates (check `--debug` output)
- Correct model is used
- Tool restrictions are enforced
- Output matches expected format

## Common mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| Generic description ("handles tasks") | Agent triggers for everything or nothing | Write specific triggering examples |
| No triggering examples in description | Poor intent matching, agent rarely activates | Add 2-4 concrete `Use when...` scenarios |
| `tools` omitted on read-only agents | Agent can write/delete files unexpectedly | Explicitly restrict to `["Read", "Glob", "Grep"]` |
| Using `haiku` for leadership agents | Poor judgment on complex decisions | Use `opus` for orchestrators and reviewers |
| System prompt under 500 chars | Underspecified behavior, inconsistent output | Expand with process, output format, constraints |
| No communication protocol | Agent doesn't know who to report to | Define who it talks to and spawns |
| File name doesn't match `name` field | Auto-discovery may fail | Keep `name` and filename in sync |
| Missing `capabilities` array | Ecosystem docs are incomplete | Add 2-4 capability bullets |
| Overly broad triggers | Agent activates when it shouldn't | Make each trigger describe a specific scenario |
| No constraints section in prompt | Agent exceeds its scope | Explicitly state what the agent must NOT do |
| Forgetting ecosystem.json registration | Agent directory not discovered | Add category to plugin's `ecosystem.json` |

## Checklist

Before committing any agent:

- [ ] `name` is kebab-case, 3-50 chars, role-based
- [ ] `description` includes 2-4 concrete triggering examples
- [ ] `color` matches semantic meaning (blue=analysis, green=QA, etc.)
- [ ] `model` is appropriate for agent's risk level
- [ ] `model_tier` reflects role complexity
- [ ] `capabilities` has 2-4 entries
- [ ] `tools` array follows least privilege (or justified omission)
- [ ] System prompt has: role, responsibilities, process, output format, constraints
- [ ] System prompt is 500-3000 characters
- [ ] Communication protocol defined (who agent talks to / spawns)
- [ ] File placed in `plugins/<plugin>/agents/<category>/`
- [ ] File name matches `name` field
- [ ] Agent category registered in `ecosystem.json`
- [ ] Trigger tested — agent activates for intended prompts
- [ ] Trigger tested — agent does NOT activate for unrelated prompts
- [ ] Plugin cache cleared
