# C4 Mermaid Syntax Reference

Complete syntax reference for C4 architecture diagrams in Mermaid.

## Diagram types

Five diagram types are available:

```
C4Context      -- Level 1: System Context
C4Container    -- Level 2: Container
C4Component    -- Level 3: Component
C4Deployment   -- Level 4: Deployment
C4Dynamic      -- Dynamic: sequenced interactions
```

---

## Element syntax

### People

```
Person(alias, "Label", "Description")
Person_Ext(alias, "Label", "Description")
```

### Systems

```
System(alias, "Label", "Description")
System_Ext(alias, "Label", "Description")
System_Db(alias, "Label", "Description")
System_Db_Ext(alias, "Label", "Description")
System_Queue(alias, "Label", "Description")
System_Queue_Ext(alias, "Label", "Description")
```

### Containers

```
Container(alias, "Label", "Technology", "Description")
Container_Ext(alias, "Label", "Technology", "Description")
ContainerDb(alias, "Label", "Technology", "Description")
ContainerDb_Ext(alias, "Label", "Technology", "Description")
ContainerQueue(alias, "Label", "Technology", "Description")
ContainerQueue_Ext(alias, "Label", "Technology", "Description")
```

### Components

```
Component(alias, "Label", "Technology", "Description")
Component_Ext(alias, "Label", "Technology", "Description")
ComponentDb(alias, "Label", "Technology", "Description")
ComponentQueue(alias, "Label", "Technology", "Description")
```

---

## Boundary syntax

Boundaries group elements visually. They can be nested.

```
Boundary(alias, "Label") {
    <elements>
}

Enterprise_Boundary(alias, "Label") {
    <elements>
}

System_Boundary(alias, "Label") {
    <elements>
}

Container_Boundary(alias, "Label") {
    <elements>
}
```

### Deployment boundaries

```
Deployment_Node(alias, "Label", "Technology", "Description") {
    <elements or nested nodes>
}

Deployment_Node_R(alias, "Label", "Technology", "Description", $instances) {
    <elements>
}
```

The `_R` variant accepts an instance count.

---

## Relationship syntax

### Basic relationships

```
Rel(from, to, "Label")
Rel(from, to, "Label", "Technology")
Rel(from, to, "Label", "Technology", "Description")
```

### Directional relationships

```
Rel_D(from, to, "Label")      -- Down
Rel_U(from, to, "Label")      -- Up
Rel_L(from, to, "Label")      -- Left
Rel_R(from, to, "Label")      -- Right
```

Long form aliases also work: `Rel_Down`, `Rel_Up`, `Rel_Left`, `Rel_Right`.

### Bidirectional

```
BiRel(from, to, "Label")
BiRel(from, to, "Label", "Technology")
```

### Indexed relationships (Dynamic diagrams)

In `C4Dynamic` diagrams, relationships are automatically numbered in order of appearance. Use `Rel` as normal -- Mermaid adds the sequence index.

---

## Styling and layout

### Update element style

```
UpdateElementStyle(alias, $bgColor="color", $fontColor="color", $borderColor="color")
```

### Update relationship style

```
UpdateRelStyle(from, to, $textColor="color", $lineColor="color", $offsetX="n", $offsetY="n")
```

### Layout direction

```
UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")
```

- `$c4ShapeInRow` -- max elements per row inside a boundary
- `$c4BoundaryInRow` -- max boundaries per row

---

## Example: System Context (Level 1)

```mermaid
C4Context
    title System Context — E-Commerce Platform

    Person(customer, "Customer", "Browses and purchases products")
    Person(admin, "Admin", "Manages inventory and orders")

    System(ecommerce, "E-Commerce Platform", "Handles product catalog, orders, and payments")

    System_Ext(payment, "Payment Gateway", "Processes credit card payments")
    System_Ext(shipping, "Shipping Provider", "Handles package delivery")
    System_Ext(email, "Email Service", "Sends transactional emails")

    Rel(customer, ecommerce, "Browses, orders", "HTTPS")
    Rel(admin, ecommerce, "Manages", "HTTPS")
    Rel(ecommerce, payment, "Processes payments", "HTTPS/API")
    Rel(ecommerce, shipping, "Creates shipments", "HTTPS/API")
    Rel(ecommerce, email, "Sends notifications", "SMTP")
```

## Example: Container (Level 2)

```mermaid
C4Container
    title Container — E-Commerce Platform

    Person(customer, "Customer", "Browses and purchases")

    System_Boundary(ecommerce, "E-Commerce Platform") {
        Container(spa, "SPA", "React", "Product browsing and checkout UI")
        Container(api, "API Gateway", "Node.js/Express", "Routes requests, auth")
        Container(catalog, "Catalog Service", "Python/FastAPI", "Product search and listings")
        Container(orders, "Order Service", "Go", "Order processing and fulfillment")
        ContainerDb(db, "Database", "PostgreSQL", "Products, orders, users")
        ContainerQueue(queue, "Message Queue", "RabbitMQ", "Async order events")
    }

    System_Ext(payment, "Payment Gateway", "Stripe")

    Rel(customer, spa, "Uses", "HTTPS")
    Rel(spa, api, "API calls", "HTTPS/JSON")
    Rel(api, catalog, "Queries", "gRPC")
    Rel(api, orders, "Submits orders", "gRPC")
    Rel(orders, queue, "Publishes events", "AMQP")
    Rel(catalog, db, "Reads", "SQL")
    Rel(orders, db, "Reads/Writes", "SQL")
    Rel(orders, payment, "Charges", "HTTPS/API")
```

## Example: Component (Level 3)

```mermaid
C4Component
    title Component — Order Service

    Container_Boundary(orders, "Order Service") {
        Component(controller, "Order Controller", "Go", "Handles gRPC requests")
        Component(service, "Order Logic", "Go", "Business rules and validation")
        Component(repo, "Order Repository", "Go", "Data access layer")
        Component(publisher, "Event Publisher", "Go", "Publishes order events")
    }

    ContainerDb_Ext(db, "Database", "PostgreSQL", "Order data")
    ContainerQueue_Ext(queue, "Message Queue", "RabbitMQ", "Order events")
    Container_Ext(api, "API Gateway", "Node.js", "Incoming requests")

    Rel(api, controller, "gRPC calls")
    Rel(controller, service, "Delegates")
    Rel(service, repo, "Persists")
    Rel(service, publisher, "Publishes")
    Rel(repo, db, "SQL")
    Rel(publisher, queue, "AMQP")
```

## Example: Dynamic diagram

```mermaid
C4Dynamic
    title Checkout Flow

    ContainerDb(db, "Database", "PostgreSQL")
    Container(spa, "SPA", "React")
    Container(api, "API Gateway", "Node.js")
    Container(orders, "Order Service", "Go")
    Container_Ext(payment, "Payment Gateway", "Stripe")

    Rel(spa, api, "POST /checkout", "HTTPS")
    Rel(api, orders, "CreateOrder", "gRPC")
    Rel(orders, payment, "Charge card", "HTTPS")
    Rel(payment, orders, "Confirmation", "HTTPS")
    Rel(orders, db, "Save order", "SQL")
    Rel(orders, api, "Order confirmed", "gRPC")
    Rel(api, spa, "200 OK + order ID", "HTTPS")
```

## Example: Deployment (Level 4)

```mermaid
C4Deployment
    title Deployment — Production

    Deployment_Node(cdn, "CDN", "CloudFront") {
        Container(spa, "SPA", "React", "Static bundle")
    }

    Deployment_Node(aws, "AWS", "us-east-1") {
        Deployment_Node(ecs, "ECS Cluster", "Fargate") {
            Deployment_Node(api_task, "API Task", "2 instances") {
                Container(api, "API Gateway", "Node.js")
            }
            Deployment_Node(order_task, "Order Task", "3 instances") {
                Container(orders, "Order Service", "Go")
            }
        }
        Deployment_Node(rds, "RDS", "Multi-AZ") {
            ContainerDb(db, "Database", "PostgreSQL 15")
        }
        Deployment_Node(mq, "AmazonMQ", "RabbitMQ") {
            ContainerQueue(queue, "Message Queue", "RabbitMQ")
        }
    }

    Rel(spa, api, "HTTPS")
    Rel(api, orders, "gRPC")
    Rel(orders, db, "SQL")
    Rel(orders, queue, "AMQP")
```

---

## Microservices guidelines

### Single team ownership

When one team owns the full system, a single Container diagram usually suffices. Show all services, databases, and queues in one boundary. Zoom into Component level only for the most complex service.

### Multi-team ownership

When multiple teams own different services:
- Create one System Context showing the full landscape
- Create one Container diagram per team's domain boundary
- Use `_Ext` variants for services owned by other teams
- Each team maintains their own Component diagrams

### Event-driven architectures

- Show message queues/brokers as `ContainerQueue` elements
- Use Dynamic diagrams to show event flows (pub/sub sequences)
- Label relationships with event names, not just protocols
- Consider separate Dynamic diagrams for each major event flow

---

## Common mistakes and anti-patterns

### Wrong level of detail

- Showing classes/functions in a Container diagram (too detailed)
- Showing infrastructure in a System Context diagram (wrong audience)
- Mixing abstraction levels in a single diagram

### Missing context

- Omitting external systems that the software depends on
- Not showing users/personas who interact with the system
- Leaving relationships unlabeled (no protocol or purpose)

### Diagram overload

- Cramming 20+ elements into a single diagram -- split into multiple
- Showing every microservice in a Context diagram -- aggregate into one System box
- Including deployment details in Component diagrams

### Syntax pitfalls

- Using `Container` in a `C4Context` diagram (wrong level -- use `System`)
- Forgetting quotes around labels with special characters
- Using `Rel` without specifying `from` and `to` aliases that exist in the diagram
- Nesting boundaries deeper than 2 levels (renders poorly in most tools)

### Staleness

- Architecture diagrams that aren't updated when the system changes
- Keep diagrams in version control alongside the code they describe
- Prefer fewer, accurate diagrams over comprehensive but stale ones
