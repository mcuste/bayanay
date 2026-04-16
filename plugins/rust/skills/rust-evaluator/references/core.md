# Core Rust Rules

Always loaded. Applies to all Rust code.

## Architecture

- [core-borrow-friction] ALWAYS treat borrow checker friction as architecture signal — restructure rather than fight
- [core-no-oop] NEVER translate OOP hierarchies directly into Rust — traits for behavior, enums for state, ownership for relationships

## Code Patterns

- [core-iter-chain] ALWAYS prefer iterator chains over imperative loops for filter/map/collect
- [core-iter-no-branch] NEVER use iterator chains for multi-branch control flow (break with value, continue with side-effect, nested match) — use `for` loop; `try_fold`/`try_collect` for `Result`-based early exit
- [core-combinators] ALWAYS prefer `Option`/`Result` combinators (`and_then`, `zip`, `filter`, `unwrap_or_else`) over nested `match`/`if let` for linear transforms
- [core-tuple-destructure] ALWAYS prefer tuple destructuring `|(key, value)|` over `.0`/`.1` in closures

## Naming & Conversions

- [core-derive-order] ALWAYS order derives: `Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord`; derive only what needed
- [core-no-get-prefix] NEVER add `get_` prefix to infallible field accessors — bare name; `_mut` for mutable; `get` for fallible/keyed returning `Option`
- [core-bool-prefix] ALWAYS use `is_`/`has_` for bool-returning methods
- [core-path-methods] ALWAYS use `Path` methods (`join`, `with_extension`) over string concat for file paths
- [core-enum-over-string] NEVER use `String` for fixed value sets — use enums with `Display`/`FromStr`
- [core-named-returns] ALWAYS return named structs over tuples when returning 3+ values

## Error Handling — General

- [core-err-log-or-propagate] NEVER log and propagate same error — choose one
- [core-err-log-at-handler] NEVER log errors at propagation sites (`?`) — log only where handled
- [core-err-semantic-variants] ALWAYS group error variants by failure semantics (`NotFound`, `InvalidInput`), not by source module
- [core-err-scope] ALWAYS scope error types to API surfaces — don't return 15-variant enum when 3 reachable
- [core-err-display-format] ALWAYS start error display messages lowercase without trailing punctuation

## Error Handling — Application

- [core-err-anyhow-app] ALWAYS use `anyhow`/`eyre` for app-level errors reported to humans
- [core-err-context] ALWAYS add `.context()` when propagating across abstraction boundaries
- [core-err-typed-vs-opaque] ALWAYS prefer typed enums when caller behavior changes per failure mode; opaque errors when all failures get same treatment
- [core-err-context-static] ALWAYS prefer `.context("msg")?` over `.ok_or_else(|| anyhow!("msg"))?` for static messages — works on both `Result` and `Option`
- [core-err-with-context] ALWAYS prefer `.with_context(|| format!(...))` for dynamic messages — lazy allocation
- [core-err-no-context-format] NEVER use `.context(format!(...))` — eagerly allocates on success path; use `.with_context(|| format!(...))` instead

## Type Design

- [core-enum-vs-trait] ALWAYS prefer enums for fixed variant sets — traits when new types expected over time
- [core-display-vs-debug] ALWAYS implement `Display` for user-facing, `Debug` for developer diagnostics
- [core-no-single-impl-trait] NEVER extract trait from type with only one impl; exception: DI across crates, plugin contracts, FFI
- [core-no-mock-trait] NEVER extract traits solely for mocking; exception: external APIs you don't control
- [core-no-default-bug] NEVER implement `Default` on types where "empty" is a bug

## Project Structure

- [core-visibility] ALWAYS default to private; `pub(crate)` for internal sharing; `pub` only for external API
- [core-file-order] ALWAYS order file items: `use` → `mod` → constants → types → traits → `impl` → functions
- [core-no-mod-rs] NEVER use `mod.rs` for new modules — use `domain.rs` alongside `domain/`; follow existing convention if codebase uses `mod.rs`
- [core-thin-main] ALWAYS keep `main.rs` thin — parse args, load config, wire deps, delegate to `lib.rs`; exception: <200 line tools
- [core-dep-direction] ALWAYS enforce one-directional deps: `domain ← application ← infrastructure ← api`
- [core-reexport] ALWAYS use `pub use` re-exports to flatten import paths for consumers

## Testing — General

- [core-test-concrete-first] ALWAYS start concrete — extract traits when second impl arrives (test doubles count)
- [core-test-callsite-di] ALWAYS prefer call-site DI over constructor-stored `Arc<Config>`; exception: 5+ call levels
- [core-test-aaa] ALWAYS follow AAA with one action per test
- [core-test-naming] ALWAYS name SUT `sut`; name tests as scenarios (`returns_error_on_expired_token`)
- [core-test-no-reimplement] NEVER reimplement production logic in test assertions
- [core-test-no-prod-code] NEVER add production code only for testing

## Testing — Unit Tests

- [core-test-output-based] ALWAYS prefer output-based > state-based > interaction-based tests
- [core-test-no-mocks] NEVER use mocks in unit tests — use real or fake collaborators
- [core-test-func-core] ALWAYS prefer functional core/imperative shell > hand-written fakes > integration with real deps
- [core-test-cfg-mod] ALWAYS place implementation-detail tests in `#[cfg(test)] mod tests`
