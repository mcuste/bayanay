## Published Crate Rules

Rules for crates published to crates.io or consumed as dependencies by other teams. Applies when `Cargo.toml` has `version` + `license`/`description` and does NOT have `publish = false`.

### Extensibility

- **ALWAYS** add `#[non_exhaustive]` only to public enums that may gain variants
- **ALWAYS** use sealed traits for public traits requiring closed set of implementors

### Features

- **ALWAYS** keep features strictly additive
- **NEVER** change type fields or trait impls under `#[cfg(feature)]` — use `Option<T>`
- **ALWAYS** declare every feature referenced in `#[cfg(feature)]` in `Cargo.toml`
- **NEVER** put heavy optional deps in `default` features

### Type Design

- **NEVER** derive `Copy` on public types unless permanently small and stack-only

### Error Handling

- **ALWAYS** re-export inner errors in thin wrapper crates

### Naming & Conversions

- **NEVER** implement `Borrow<T>` unless `Hash`/`Eq`/`Ord` semantics match between borrowed and owned
