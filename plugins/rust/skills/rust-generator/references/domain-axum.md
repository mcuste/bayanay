## Domain: Axum

- **ALWAYS** use `State<T>` over `Extension<T>` for app-wide DI; `Extension` for per-request middleware data
- **ALWAYS** move request-side cross-cutting into `FromRequestParts`; response-side into Tower middleware
- **ALWAYS** consolidate error mapping into single `AppError` implementing `IntoResponse`
- **ALWAYS** order handler extractors: infallible/cheap first, fallible last
- **NEVER** use `dyn Service` when generics suffice
