# Observability

- [obs-tracing-async] ALWAYS use `tracing` over `log` for async applications
- [obs-structured-fields] ALWAYS use structured fields (`info!(user_id = %id, "processed")`) over string interpolation
- [obs-no-error-expected] NEVER log at `error` level for expected/recoverable conditions — use `warn` or `info`
- [obs-instrument-skip] ALWAYS use selective `skip`/`skip_all` in `#[instrument]` for sensitive, large, or non-`Debug` params
- [obs-display-vs-debug] ALWAYS use `%` for user-meaningful values, `?` for diagnostic values in tracing fields
- [obs-span-boundaries] ALWAYS create spans at operation boundaries (request, transaction), not per-function
- [obs-log-trust-boundary] ALWAYS log at trust boundaries before redacting for external response
