# Crate-Specific Rules

## bon

- [bon-new-small] ALWAYS use `::new()` for types with ≤3 required fields; `bon` builder for more
- [bon-pub-api] ALWAYS use `bon` for public API builders with >3 required fields
- [bon-no-dyn] NEVER use `bon` when builder must be `dyn`-compatible or serializable
- [bon-consume-self] ALWAYS make builder `build()` consume `self` unless callers need multiple builds from same builder

## rayon

- [rayon-no-tokio] NEVER call `rayon::join`/`par_iter` inside tokio task directly — use `spawn_blocking` or `rayon::spawn` + `oneshot`
- [rayon-profile-first] NEVER use `par_iter()` without profiling — justified at ~10k+ elements for cheap ops
