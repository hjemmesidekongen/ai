---
name: mermaid-diagrams
description: |
  Create software diagrams using Mermaid syntax. Use when generating class diagrams,
  sequence diagrams, flowcharts, ERDs, state diagrams, git graphs, or gantt charts.
  For C4 architecture diagrams specifically, use c4-architecture instead.
user_invocable: true
interactive: true
depends_on: []
reads: []
writes:
  - "docs/**/*.md"
triggers:
  - diagram
  - visualize
  - mermaid
  - flowchart
  - sequence diagram
  - class diagram
  - ERD
  - state diagram
  - gantt chart
  - git graph
checkpoint:
  type: data_validation
  required_checks:
    - name: "diagram_renders"
      verify: "Mermaid diagram uses valid syntax for the declared diagram type"
      fail_action: "Fix syntax errors using the appropriate reference file"
  on_fail: "Fix diagram syntax and re-verify"
  on_pass: "Diagram generated with valid Mermaid syntax"
model_tier: junior
_source:
  origin: original
  ported_date: "2026-03-09"
  iteration: 1
  changes: ["initial creation"]
---

# Mermaid Diagramming

Generate professional diagrams from text definitions. Mermaid renders in GitHub, GitLab, VS Code, Notion, and Obsidian natively.

## Diagram Type Selection

| Need | Diagram Type | Reference |
|------|-------------|-----------|
| Domain modeling, OOP design | Class diagram | [class-diagrams.md](references/class-diagrams.md) |
| API flows, auth sequences, interactions | Sequence diagram | [sequence-diagrams.md](references/sequence-diagrams.md) |
| Processes, algorithms, user journeys | Flowchart | [flowcharts.md](references/flowcharts.md) |
| Database schemas, table relationships | ERD | [erd-diagrams.md](references/erd-diagrams.md) |
| System architecture (multi-level) | C4 diagram | [c4-diagrams.md](references/c4-diagrams.md) |
| Cloud infra, CI/CD, deployments | Architecture diagram | [architecture-diagrams.md](references/architecture-diagrams.md) |
| Themes, styling, layout, export | Advanced features | [advanced-features.md](references/advanced-features.md) |

## Core Syntax

All diagrams follow: diagram type declaration, then definition content.

```mermaid
diagramType
  definition content
```

Use `%%` for comments. First line declares type (`classDiagram`, `sequenceDiagram`, `flowchart`, `erDiagram`, `C4Context`, `C4Container`, `C4Component`, `architecture-beta`).

Quick examples and configuration: `references/process.md`

## Principles

1. Start simple — add details incrementally
2. One concept per diagram — split large systems into focused views
3. Use meaningful labels — make diagrams self-documenting
4. Store `.mmd` files alongside code for version control
5. Load the relevant reference file for full syntax before generating complex diagrams
