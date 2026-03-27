# Architecture & Design

## Newtypes

- [arch-newtype-boundary] ALWAYS parse external input into validated newtypes at system boundaries if value crosses >1 function boundary
- [arch-no-newtype-generic] NEVER force newtypes in generic pipelines — trait bounds are the abstraction
- [arch-no-newtype-single] NEVER newtype if value crosses only one function boundary; exception: safety-critical argument transposition
- [arch-newtype-pub-api] ALWAYS newtype public API parameters even if used once internally

## Enum State Machines vs Typestate

- [arch-enum-sm-default] ALWAYS prefer enum state machines by default
- [arch-typestate-safety] ALWAYS prefer typestate for safety-critical protocols where wrong transition is a vulnerability
- [arch-no-typestate-large] NEVER use typestate for >7 states or heterogeneous storage needs
- [arch-typestate-builder] ALWAYS consider typestate for builders with required fields

## Compile-Time Computation

- [arch-const-fn] ALWAYS prefer `const fn` + `const` over `lazy_static!`/`OnceLock` for compile-time computable values
- [arch-no-const-runtime] NEVER shoehorn runtime values (env vars, config) into `const` — use `OnceLock`
- [arch-no-fight-const] NEVER fight `const fn` limitations — use `OnceLock` when unsupported ops needed

## Representation & Layout

- [arch-const-generic] ALWAYS use const generics for fixed dimensions known at compile time
- [arch-no-const-generic-runtime] NEVER use const generics for runtime-sized or heterogeneous-collection scenarios

## Dispatch

- [arch-dyn-threshold] ALWAYS prefer `dyn Trait` at 5+ cascading bounds, for heterogeneous collections, or to reduce monomorphization bloat in large binaries
- [arch-impl-iterator] ALWAYS prefer `-> impl Iterator<Item = T>` over `-> Vec<T>` when caller only iterates
- [arch-vec-when-len] ALWAYS return `Vec<T>` when callers need `.len()` before iterating or iterator would borrow local state

## Lifetimes

- [arch-hrtb] ALWAYS use `for<'a>` HRTB when closure must accept borrows of any lifetime
- [arch-concrete-lifetime] ALWAYS prefer concrete lifetime over HRTB for single known lifetime
- [arch-owned-pub-boundary] ALWAYS prefer returning owned data at public API boundaries when lifetime would propagate into caller structs

## Architecture Selection

- [arch-no-hex-crud] NEVER apply hexagonal for CRUD under ~5k lines — unless team consistency requires it
- [arch-no-cqrs-default] NEVER adopt CQRS/event sourcing as default — only for audit trails, temporal queries, separate read/write scaling
- [arch-hex-3-deps] ALWAYS use hexagonal when 3+ infrastructure deps need independent testing

## Hexagonal

- [arch-hex-generic-ports] ALWAYS use generics for ports — switch to `dyn Trait` when generic params reach 4-5
- [arch-hex-port-domain] NEVER define port traits in infrastructure — ports belong in domain
- [arch-hex-colocate] ALWAYS co-locate port trait with domain types it operates on; exception: cross-cutting ports in `domain::ports`

## DI

- [arch-callsite-di] ALWAYS prefer call-site injection over stored deps; store in `self` only for per-instance state or 5+ call level threading

## Workspace

- [arch-flat-crates] ALWAYS use flat `crates/` layout for 10k-1M line workspaces
- [arch-no-tiny-crate] NEVER create crate under ~500 lines with one dependent — use `pub(crate)` module; exception: `#[no_std]` shared with embedded
- [arch-no-premature-crate] NEVER extract module into own crate unless it has own error types + public API, is shared across binaries, or measurably hurts compile times
- [arch-workspace-deps] ALWAYS use `[workspace.dependencies]` for shared dependency versions
- [arch-workspace-lints] ALWAYS use `[workspace.lints]` for shared lint configuration
- [arch-hub-crate-watch] ALWAYS watch for dependency hub crates bottlenecking incremental compilation

## Functional Core, Imperative Shell

- [arch-fcis-async] ALWAYS extract decision logic out of async fns into pure `fn(data) -> enum/tuple` — keeps I/O and decisions separate
- [arch-fcis-trait-smell] ALWAYS extract pure fn before reaching for trait-based mocks — traits belong in I/O shell integration tests, not branch-logic tests
- [arch-fcis-not-io-pipe] NEVER apply FCIS to pure I/O pipelines (no branching) — no decisions means nothing to extract

## Layering

- [arch-domain-no-io] ALWAYS keep domain layer free of runtime I/O — derive macros acceptable
- [arch-no-layers-small] NEVER introduce full four-layer structure for projects under ~5k lines

## Project Structure Details

- [arch-cargo-toml-order] ALWAYS order `Cargo.toml`: `[package]` → `[features]` → `[dependencies]` → `[dev-dependencies]` → `[build-dependencies]` → `[lints]`, alpha-sorted within each
- [arch-test-helpers] ALWAYS place integration test helpers in `tests/common/mod.rs`
- [arch-minimal-prelude] ALWAYS keep `pub mod prelude` minimal (core types, traits, `Result` alias)
- [arch-bins-dir] ALWAYS place multiple binaries in `src/bin/`; shared logic in `lib.rs`
