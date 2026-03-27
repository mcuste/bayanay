# Published Crate Rules

Applies when `Cargo.toml` has `version` + `license`/`description` and does NOT have `publish = false`.

## Extensibility

- [pub-non-exhaustive] ALWAYS add `#[non_exhaustive]` only to public enums that may gain variants
- [pub-sealed-trait] ALWAYS use sealed traits for public traits requiring closed set of implementors

## Features

- [pub-additive-features] ALWAYS keep features strictly additive
- [pub-no-cfg-type-change] NEVER change type fields or trait impls under `#[cfg(feature)]` — use `Option<T>`
- [pub-declare-features] ALWAYS declare every feature referenced in `#[cfg(feature)]` in `Cargo.toml`
- [pub-no-heavy-default] NEVER put heavy optional deps in `default` features

## Type Design

- [pub-no-copy] NEVER derive `Copy` on public types unless permanently small and stack-only

## Error Handling

- [pub-err-no-leak] NEVER expose implementation-detail errors in public APIs — wrap in domain-specific variants
- [pub-reexport-errors] ALWAYS re-export inner errors in thin wrapper crates

## Naming & Conversions

- [pub-borrow-semantics] NEVER implement `Borrow<T>` unless `Hash`/`Eq`/`Ord` semantics match between borrowed and owned
