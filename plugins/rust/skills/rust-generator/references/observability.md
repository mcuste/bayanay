## Logging & Observability

- **ALWAYS** use `tracing` over `log` for async applications
- **ALWAYS** use structured fields (`info!(user_id = %id, "processed")`) over string interpolation
- **NEVER** log at `error` level for expected/recoverable conditions — use `warn` or `info`
- **ALWAYS** use selective `skip`/`skip_all` in `#[instrument]` for sensitive, large, or non-`Debug` params
- **ALWAYS** use `%` for user-meaningful values, `?` for diagnostic values in tracing fields
- **ALWAYS** create spans at operation boundaries (request, transaction), not per-function
- **ALWAYS** log at trust boundaries before redacting for external response
