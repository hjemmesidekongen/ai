# Agent Teams — Process Detail

## Team Sizing Guide

| Task Complexity | Team Size | Composition |
|----------------|-----------|-------------|
| Simple review | 2-3 | Parallel reviewers, no lead needed |
| Single feature | 3 | 1 lead + 2 implementers |
| Full-stack feature | 4 | 1 lead + frontend + backend + test |
| Large migration | 4-5 | 1 lead + 2-3 implementers + 1 reviewer |
| Comprehensive audit | 4-6 | Parallel specialists, coordinator consolidates |

## Agent Type Selection

| Role | Model Tier | Tools | When |
|------|-----------|-------|------|
| Lead/Coordinator | inherit (Opus) | All | Decomposition, integration, review |
| Implementer | senior (Sonnet) | Read, Write, Edit, Bash, Glob, Grep | Code writing, file changes |
| Reviewer | senior (Sonnet) | Read, Glob, Grep | Read-only analysis |
| Researcher | junior (Haiku) | Read, Glob, Grep, WebSearch | Information gathering |

## Communication Patterns

### Message Types
- **Direct message**: Default. One agent to one other agent. Use for specific requests.
- **Broadcast**: All team members. Use ONLY for critical blockers affecting everyone.
- **Shutdown request**: Graceful termination when work is complete or blocked.

### Rules
- Never broadcast routine updates — wastes context across all agents
- Lead handles coordination; implementers communicate through lead, not each other
- When blocked: message the lead, not the blocking agent directly

## Display Modes (Agent Teams API)

| Mode | Requirement | Best For |
|------|------------|----------|
| tmux | tmux installed | Terminal users, see all agents simultaneously |
| iTerm2 | iTerm2 on macOS | Native tabs per agent |
| in-process | None | Programmatic use, no visual |

## File Ownership Enforcement

### Pre-Implementation Setup

Before dispatching parallel agents:

1. **Decompose** the task into streams (use `file-ownership` skill)
2. **Assign** each file to exactly one stream
3. **Define** interface contracts at boundaries
4. **Verify** no file appears in multiple streams

### During Execution

- Each agent receives its file list in the dispatch prompt
- Agents must NOT write to files outside their ownership
- If an agent needs a change in another's file: request through the lead
- Shared read-only files (configs, types) are fine — only writes conflict

### Post-Execution Integration

1. Lead verifies all agents completed
2. Run integration tests across all streams
3. Resolve any interface mismatches
4. Commit as a single logical unit (or per-stream commits)

## Integration with Plan-Engine

When plan-engine uses parallel dispatch:

```yaml
# In state.yml, tasks within a wave can run in parallel
wave-2:
  tasks: [t3, t4, t5]
  # t3, t4, t5 have non-overlapping file ownership
  # plan-engine dispatches them as parallel Agent calls
```

Future: `--teams` flag to switch from sequential Agent dispatch to native Agent Teams API when stable.

## Preset Team Details

### Review Team
```
Agent 1: Security review (OWASP, injection, auth)
Agent 2: Performance review (complexity, memory, queries)
Agent 3: Architecture review (coupling, boundaries, patterns)
→ Coordinator consolidates, deduplicates, ranks by severity
```

### Debug Team
```
Agent 1: Hypothesis A investigation
Agent 2: Hypothesis B investigation
Agent 3: Hypothesis C investigation
→ Coordinator compares evidence, determines root cause
```

### Feature Team
```
Lead: Decomposes feature, defines interfaces, reviews
Agent 1: Implements stream A (files a1, a2, a3)
Agent 2: Implements stream B (files b1, b2, b3)
→ Lead integrates, runs cross-stream tests
```

## When NOT to Use Teams

- Single-file changes — overhead exceeds benefit
- Sequential dependencies — can't parallelize a chain
- Exploratory work — don't know what files are involved yet
- Context window pressure — each agent consumes its own context budget
