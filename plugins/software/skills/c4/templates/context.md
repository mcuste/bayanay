# C4 Level 1 — System Context: {System Name}

| Level   | Status | Author | Created      | Last Updated |
|---------|--------|--------|--------------|--------------|
| Context | Draft  | {name} | {YYYY-MM-DD} | {YYYY-MM-DD} |

## System Context

```mermaid
C4Context
    title System Context — {System Name}

    Person(user, "User Role", "Who they are and what they need")

    System(system, "System Name", "One-line purpose of the system")

    System_Ext(ext_1, "External System", "What it provides")
    System_Ext(ext_2, "Another External", "What it provides")

    Rel(user, system, "Uses")
    Rel(system, ext_1, "Sends data to")
    Rel(system, ext_2, "Authenticates via")
```

## Legend

- **`Person(...)`** — Human actor or user role
- **`System(...)`** — The system being documented
- **`System_Ext(...)`** — External system outside the boundary

## Notes

- **Users/Actors**: Who interacts with this system, their role, and their goal
- **External dependencies**: What systems does this depend on? What happens if they're unavailable?
- **Trust boundaries**: Where do trust levels change (e.g., public internet → internal network)?

## References

- Related PRDs, RFCs, ADRs
