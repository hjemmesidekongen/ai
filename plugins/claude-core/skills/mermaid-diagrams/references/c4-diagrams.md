# C4 Model Diagrams

Hierarchical software architecture visualization at four levels of abstraction.

## C4 Levels

1. **System Context** — system + users + external systems (stakeholder audience)
2. **Container** — applications, databases, services within the system (architect audience)
3. **Component** — internal structure of containers (developer audience)
4. **Code** — class diagrams for implementation detail (use `classDiagram`)

## C4 Context Diagram

```mermaid
C4Context
    title System Context for Banking System

    Person(customer, "Customer", "A banking customer")
    System(banking, "Banking System", "Manages accounts")
    System_Ext(email, "Email System", "Sends emails")

    Rel(customer, banking, "Uses")
    Rel(banking, email, "Sends emails via")
```

**Elements:**
- `Person(id, "Name", "Description")` / `Person_Ext()`
- `System(id, "Name", "Description")` / `System_Ext()`
- `SystemDb()` / `SystemDb_Ext()` — database systems
- `SystemQueue()` / `SystemQueue_Ext()` — message queues
- `Rel(from, to, "Label", "Technology")` / `BiRel()`

## C4 Container Diagram

```mermaid
C4Container
    title Container Diagram for Banking System

    Person(customer, "Customer")

    Container_Boundary(banking, "Banking System") {
        Container(web, "Web App", "React", "Delivers UI")
        Container(api, "API", "Node.js", "Banking API")
        ContainerDb(db, "Database", "PostgreSQL", "Account data")
    }

    Rel(customer, web, "Uses", "HTTPS")
    Rel(web, api, "Calls", "HTTPS/JSON")
    Rel(api, db, "Reads/writes", "SQL/TCP")
```

**Elements:**
- `Container(id, "Name", "Technology", "Description")` / `Container_Ext()`
- `ContainerDb()` — database containers
- `ContainerQueue()` — message queue containers
- `Container_Boundary(id, "Label") { ... }` — grouping

## C4 Component Diagram

```mermaid
C4Component
    title Component Diagram for API

    Container_Boundary(api, "API Application") {
        Component(controller, "Controller", "Express", "Handles HTTP")
        Component(service, "Business Logic", "Service", "Core logic")
        Component(repo, "Data Access", "Repository", "DB operations")
    }

    Rel(controller, service, "Uses")
    Rel(service, repo, "Uses")
```

## Styling

```
UpdateRelStyle(from, to, $offsetX="-50", $offsetY="-30")
```

## Architecture Patterns

**Monolithic:** Single `Container` + `ContainerDb` + `ContainerDb` (cache)
**Three-tier:** Presentation → Business → Data boundaries
**Microservices:** Multiple containers per boundary, `ContainerQueue` for async
**Event-driven:** Services publish/consume via `ContainerQueue`

## Tips

1. Use appropriate level for your audience
2. One system per Context, one container per Component
3. Show key relationships — don't clutter
4. Consistent naming across all levels
5. Include technology details at Container/Component level
6. Use `*_Ext` variants for external systems
7. Start with Context, drill down as needed
