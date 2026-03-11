---
name: c4-architecture
description: >
  Generate C4 model architecture documentation with Mermaid diagrams at four
  levels: system context, container, component, and deployment. Use when
  documenting how systems interact at different abstraction levels, creating
  stakeholder-appropriate architecture views, or mapping deployment topology.
  For general-purpose diagrams (flowcharts, sequence, ERD, class), use
  mermaid-diagrams instead.
user_invocable: true
interactive: true
depends_on: []
triggers:
  - "architecture diagram"
  - "C4 diagram"
  - "system context"
  - "container diagram"
  - "document architecture"
reads: []
writes:
  - "docs/architecture/*.md"
checkpoint:
  type: data_validation
  required_checks:
    - name: "diagrams_render"
      verify: "All Mermaid C4 diagrams use valid syntax (C4Context, C4Container, C4Component, C4Deployment, C4Dynamic)"
      fail_action: "Fix Mermaid syntax errors"
    - name: "level_appropriate"
      verify: "Diagram levels match the stated audience"
      fail_action: "Adjust diagram level to match audience needs"
  on_fail: "Fix diagram issues and re-verify"
  on_pass: "Architecture documentation complete"
model_tier: senior
_source:
  origin: "agent-toolkit-main/skills/c4-architecture"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Adapted for kronen. Split heavy syntax reference to references/c4-syntax.md. Added frontmatter per kronen conventions."
---

# c4-architecture

Generate architecture documentation using the C4 model with Mermaid diagrams. The C4 model (Context, Containers, Components, Code) provides four hierarchical levels of abstraction for communicating software architecture to different audiences.

## Workflow

1. **Understand scope** -- system, users, external dependencies
2. **Analyze codebase** -- project structure, configs, entry points
3. **Select levels** -- appropriate for the audience (see table)
4. **Generate diagrams** -- valid Mermaid C4 syntax
5. **Document** -- write to `docs/architecture/` with narrative

## Level selection

| Level | Diagram type | Audience | Shows |
|-------|-------------|----------|-------|
| 1 | System Context | Everyone | System + users + external systems |
| 2 | Container | Dev team + ops | Applications, databases, APIs within the system |
| 3 | Component | Developers | Internal modules/services within a container |
| 4 | Deployment | Ops + infra | Infrastructure nodes and container placement |
| -- | Dynamic | Anyone | Request flows through the system over time |

Context + Container (levels 1-2) are sufficient for most teams. Only go deeper when the audience needs it.

## References

- Quick start example, output conventions, best practices: `references/process.md`
- Full Mermaid C4 syntax: `references/c4-syntax.md`
