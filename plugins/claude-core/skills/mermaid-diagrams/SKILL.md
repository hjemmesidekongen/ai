---
name: mermaid-diagrams
description: |
  Create software diagrams using Mermaid syntax. Use when generating class diagrams,
  sequence diagrams, flowcharts, ERDs, C4 architecture diagrams, state diagrams,
  git graphs, or gantt charts. Triggers: "diagram", "visualize", "model", "map out",
  "show the flow", architecture documentation, database design, code structure.
triggers:
  - diagram
  - visualize
  - mermaid
  - flowchart
  - sequence diagram
  - class diagram
  - ERD
  - C4
  - architecture diagram
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

## Quick Examples

**Flowchart:** `flowchart TD` → `A --> B`, node shapes: `[rect]`, `{diamond}`, `([rounded])`, `[(db)]`
**Sequence:** `sequenceDiagram` → `A->>B: Message`, `alt`/`opt`/`par`/`loop` blocks
**Class:** `classDiagram` → `A *-- B`, relationships: `--`, `*--`, `o--`, `<|--`, `<..`
**ERD:** `erDiagram` → `A ||--o{ B : label`, cardinality: `||`, `|o`, `}{`, `}o`
**C4:** `C4Context`/`C4Container`/`C4Component` → `Person()`, `System()`, `Container()`, `Rel()`

## Configuration

```mermaid
---
config:
  theme: base
  themeVariables:
    primaryColor: "#ff6b6b"
---
```

Themes: `default`, `forest`, `dark`, `neutral`, `base`. Looks: `classic`, `handDrawn`. Layouts: `dagre` (default), `elk` (complex diagrams).

## Principles

1. Start simple — add details incrementally
2. One concept per diagram — split large systems into focused views
3. Use meaningful labels — make diagrams self-documenting
4. Store `.mmd` files alongside code for version control
5. Load the relevant reference file for full syntax before generating complex diagrams
