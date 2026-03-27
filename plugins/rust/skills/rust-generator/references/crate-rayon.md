# Crate: rayon

- **NEVER** call `rayon::join`/`par_iter` inside tokio task directly — use `spawn_blocking` or `rayon::spawn` + `oneshot`
- **NEVER** use `par_iter()` without profiling — justified at ~10k+ elements for cheap ops
