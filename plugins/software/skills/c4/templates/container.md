# C4 Level 2 — Container: {System Name}

| Level     | Status | Author | Created      | Last Updated |
|-----------|--------|--------|--------------|--------------|
| Container | Draft  | {name} | {YYYY-MM-DD} | {YYYY-MM-DD} |

## Container Diagram

```mermaid
C4Container
    title Container Diagram — {System Name}

    Person(user, "User Role", "Who they are")

    System_Boundary(boundary, "System Name") {
        Container(api, "API Service", "Rust/Axum", "Handles HTTP requests and routing")
        ContainerDb(db, "Database", "PostgreSQL 16", "Stores domain data")
        Container(worker, "Background Worker", "Rust/Tokio", "Processes async jobs")
        ContainerQueue(queue, "Message Queue", "NATS JetStream", "Async event delivery")
    }

    System_Ext(ext, "External System", "What it provides")

    Rel(user, api, "Uses", "HTTPS")
    Rel(api, db, "Reads/writes", "SQL/TCP")
    Rel(api, queue, "Publishes events", "NATS protocol")
    Rel(worker, queue, "Subscribes to events", "NATS protocol")
    Rel(worker, db, "Reads/writes", "SQL/TCP")
    Rel(api, ext, "Calls", "HTTPS")
```

## Legend

- **`Container(...)`** — Application or service (with technology label)
- **`ContainerDb(...)`** — Data store
- **`ContainerQueue(...)`** — Message queue or event bus
- **`System_Ext(...)`** — External system outside the boundary

## Notes

- **Technology choices**: Why each container uses its specific technology
- **Communication**: How containers talk to each other (sync HTTP, async messaging, shared DB)
- **Data ownership**: Which container owns which data

## References

- Related PRDs, RFCs, ADRs
