# C4 Level 3 — Component: {Container Name}

| Level     | Status | Author | Created      | Last Updated |
|-----------|--------|--------|--------------|--------------|
| Component | Draft  | {name} | {YYYY-MM-DD} | {YYYY-MM-DD} |

## Component Diagram

```mermaid
C4Component
    title Component Diagram — {Container Name}

    Container_Boundary(container, "Container Name") {
        Component(router, "Router", "axum::Router", "Route dispatch and middleware")
        Component(handlers, "Handlers", "Rust module", "Request/response logic")
        Component(service, "Domain Service", "Rust module", "Core business logic")
        Component(repo, "Repository", "Rust trait impl", "Data access abstraction")
    }

    ContainerDb(db, "Database", "PostgreSQL")
    ContainerQueue(queue, "Message Queue", "NATS JetStream")

    Rel(router, handlers, "Dispatches to")
    Rel(handlers, service, "Calls")
    Rel(service, repo, "Uses")
    Rel(repo, db, "Queries", "SQL")
    Rel(service, queue, "Publishes events", "NATS protocol")
```

## Legend

- **`Component(...)`** — Module, class group, or service layer (with technology label)
- **`ContainerDb(...)`** — External data store
- **`ContainerQueue(...)`** — External message queue

## Notes

- **Responsibilities**: What each component does and its boundaries
- **Key interfaces**: Traits, module visibility, and abstraction boundaries
- **Design decisions**: Why components are structured this way

## References

- Related PRDs, RFCs, ADRs
