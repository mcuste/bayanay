# Crate: bon

- **ALWAYS** use `::new()` for types with ≤3 required fields; `bon` builder for more
- **ALWAYS** use `bon` for public API builders with >3 required fields
- **NEVER** use `bon` when builder must be `dyn`-compatible or serializable
- **ALWAYS** make builder `build()` consume `self` unless callers need multiple builds from same builder
