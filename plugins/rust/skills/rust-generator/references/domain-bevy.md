## Domain: Bevy / ECS

- **ALWAYS** encapsulate features as `Plugin`s
- **NEVER** add `.before()`/`.after()` ordering without data or logical dependency
- **ALWAYS** use `Commands` (deferred) for spawn/despawn/insert; exception: exclusive systems for bulk ops
- **ALWAYS** use typed events for cross-system communication; `Changed<T>` for same-frame guarantees
