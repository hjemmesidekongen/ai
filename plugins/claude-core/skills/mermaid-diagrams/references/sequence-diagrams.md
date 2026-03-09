# Sequence Diagrams

Show interactions between participants over time. Ideal for API flows, auth sequences, and component interactions.

## Participants

```mermaid
sequenceDiagram
    actor User
    participant Frontend
    participant API
    participant Database
```

- `participant` — system components (services, classes, databases)
- `actor` — external entities (users, external systems)

## Message Types

| Syntax | Type |
|--------|------|
| `->>` | Solid arrow (synchronous request) |
| `-->>` | Dotted arrow (response/return) |
| `-)` | Open arrow (async message) |
| `--)` | Dotted open arrow (async response) |
| `-x` | Cross (delete/failure) |

## Activations

Show active processing with `+` (activate) and `-` (deactivate):

```mermaid
sequenceDiagram
    Client->>+Server: Request
    Server->>+Database: Query
    Database-->>-Server: Data
    Server-->>-Client: Response
```

## Control Flow Blocks

**Alt/Else (conditional):**
```mermaid
sequenceDiagram
    alt Valid credentials
        API-->>User: 200 OK
    else Invalid credentials
        API-->>User: 401 Unauthorized
    end
```

**Opt (optional):**
```mermaid
sequenceDiagram
    opt Payment successful
        API->>EmailService: Send confirmation
    end
```

**Par (parallel):**
```mermaid
sequenceDiagram
    par Send email
        Service->>EmailService: Confirmation
    and Update inventory
        Service->>InventoryService: Reduce stock
    end
```

**Loop:**
```mermaid
sequenceDiagram
    loop For each item
        Server->>Database: Process item
    end
```

**Break (early exit):**
```mermaid
sequenceDiagram
    break Input invalid
        API-->>User: 400 Bad Request
    end
```

## Notes

```mermaid
sequenceDiagram
    Note over API: Validates JWT token
    Note over Frontend,API: HTTPS encrypted
    Note right of System: Logs to database
```

## Autonumber

```mermaid
sequenceDiagram
    autonumber
    User->>Frontend: Login
    Frontend->>API: Authenticate
```

## Links

```mermaid
sequenceDiagram
    participant A as Service A
    link A: Dashboard @ https://dashboard.example.com
```

## Tips

1. Order participants logically: User → Frontend → Backend → Database
2. Use activations to show processing duration
3. Group related logic with alt/opt/par
4. Use autonumber for complex flows
5. Show error paths with alt/else
6. One scenario per diagram — keep focused
