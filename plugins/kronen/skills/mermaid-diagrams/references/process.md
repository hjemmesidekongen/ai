# Mermaid Diagrams — Process Detail

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
