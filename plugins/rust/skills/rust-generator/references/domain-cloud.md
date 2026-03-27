## Domain: Cloud / K8s

- **ALWAYS** use `CancellationToken` + `TaskTracker` for graceful shutdown with background tasks
- **ALWAYS** implement separate `/healthz` (liveness) and `/readyz` (readiness) probes
- **ALWAYS** return 503 from readiness probe on shutdown signal
- **ALWAYS** parse config at startup into `serde::Deserialize` structs; `arc-swap` for hot-reload
