# Crates: Advanced Error Handling

## Error Type Placement

- **ALWAYS** define error types in the module whose functions return them
- **ALWAYS** extract to flat `error.rs` when crate has one public Error type re-exported from `lib.rs` and ≤4 modules feeding into it; max 150 lines
- **ALWAYS** use `mod/error.rs` sibling when producing module becomes a directory (e.g., `gcp/error.rs` next to `gcp/mod.rs`)
- **ALWAYS** let orchestrating module define combined error wrapping others via `#[from]` (e.g., `iap.rs` calls gcp + oauth → `iap.rs` owns combined Error)
- **ALWAYS** fall back to flat `error.rs` at crate root when multiple modules need combining but no single orchestrator exists
- **NEVER** create `error/` directory at any level
- **NEVER** define error types in modules whose functions don't return them
- **NEVER** mix unrelated error variants in one enum

## Error Strategy Selection

- **ALWAYS** use `thiserror` when any caller (including tests) discriminates on failure mode — match arms, conditional retry, variant-specific user messages
- **ALWAYS** use `anyhow`/`eyre` when all callers treat failures uniformly — log, report, propagate without branching on variant
- **NEVER** use `anyhow` in public APIs of published crates or cross-team boundaries — callers can't downcast reliably across semver
- **PREFER** hybrid in workspace crates: `thiserror` for variants callers actually match on, `anyhow::Context` for the rest
- **ALWAYS** justify each error variant with a caller that discriminates on it — unmatched variants are dead weight; collapse or replace with `.context()`; exception: `#[non_exhaustive]` enums where future discrimination is planned
- **ALWAYS** define `pub type Result<T> = std::result::Result<T, crate::Error>` for single primary error type
- **ALWAYS** prefer `#[from]` for direct 1:1 source wrapping; manual `From` when conversion adds context
- **NEVER** create catch-all `Other(String)`/`Internal(String)` variants — use `anyhow` for catch-all; exception: app-level error enums wrapping 5+ heterogeneous source types where callers only propagate (not match)
- **ALWAYS** prefer `inspect_err` over `map_err` for side-effect-only closures (logging)

## snafu

- **NEVER** use `snafu` for single-crate projects — `thiserror` suffices
- **ALWAYS** use `snafu` only when context chaining across crate boundaries justifies compile cost

## miette

- **ALWAYS** use `miette` for CLI/compiler error reporting with source snippets
- **NEVER** use `miette` for library errors — keep at application edge
