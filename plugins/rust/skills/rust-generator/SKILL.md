---
name: rust-generator
description: "Generate idiomatic Rust code, tests, or design Rust architecture — structs, traits, modules, error types, test strategies, and full features. This skill should be used proactively. Use when: 'write Rust code', 'implement in Rust', 'refactor to idiomatic Rust', 'create a Rust struct', 'add a module', 'design this in Rust', 'Rust architecture for', 'what Rust pattern should I use', 'how would I design this in Rust', 'write tests for', 'test this', 'add tests', 'TDD for', 'test design for', 'generate tests', 'unit test for', 'what should I test', 'test plan for'."
argument-hint: "<feature, task, or code to generate>"
allowed-tools: "Read, Glob, Grep, Edit, Write, Bash, Skill, WebSearch, WebFetch"
model: opus
effort: max
---

## Modes

- **Design** ("how should I structure", "what pattern", "architecture for"): read code, apply guidelines, output traits/types/patterns/trade-offs. No code changes.
- **Generate** ("write", "implement", "refactor", "add", "fix"): read code, apply guidelines, generate with Edit/Write.
- **Test** ("write tests", "TDD", "unit test for", "integration test"): read code + testing guidelines, generate test modules/fixtures/assertions with Edit/Write.
  - Prefer integration tests when feature has observable external behavior (public API, HTTP, CLI, file I/O, DB)
  - Unit tests only for isolated logic hard to exercise end-to-end
  - Every test asserts meaningful behavior — skip language-semantics tests (e.g. `Clone` derives) or third-party-crate validation
  - No redundant tests covering same path under same conditions

## Principles — Simplest Correct Solution

Solve today's problem. Not tomorrow's.

- **YAGNI** — Not needed now → not built now. No speculative generics, no premature trait hierarchies.
- **KISS** — Concrete struct > generic. Function > trait. `Vec` > custom collection. Escalate complexity only when simple version fails.
- **Work → right → fast** — That order. Refactor when patterns emerge. Optimize when profiling proves need.
- **DRY at 3** — Two similar blocks fine. Extract at three.
- **Minimal surface** — Start `pub(crate)`. Widen only when consumer exists.
- **No gold-plating** — No extra error variants "just in case." No builder for ≤2-field structs. No custom iterators when `.iter().map()` works. No `macro_rules!` when function suffices. No proc macros when `macro_rules!` suffices.

## Worthiness Gate

Before applying any rule below: does it produce real benefit here, or just compliance?

**Skip the rule** if ANY apply:

- **No consumer** — no callers benefit from the precision (e.g., per-method error types when all callers just `?`-propagate).
- **Rule breaks down** — the rule's intent doesn't hold at this edge case (e.g., "lowercase error messages" for acronyms like HTTP, JSON).
- **Cost dwarfs value** — disproportionate machinery for marginal gain (e.g., typestate for a 3-field builder that can't be misused).
- **Already mitigated** — surrounding code handles the risk differently.

**Apply the rule** if ANY apply:

- **Low-cost alternative exists** — a better approach is available or trivial to adopt.
- **Downstream breakage** — skipping causes bugs, panics, or incorrect behavior in callers.
- **Compounds over time** — pattern will be copy-pasted; getting it right now prevents spread.

Default: simpler path wins.

## Rules

### Architecture

- **ALWAYS** treat borrow checker friction as architecture signal — restructure rather than fight
- **NEVER** translate OOP hierarchies directly into Rust — traits for behavior, enums for state, ownership for relationships

### Code Patterns

- **ALWAYS** prefer iterator chains over imperative loops for filter/map/collect — except when chain requires per-element allocation (`vec![]` in `flat_map`) that a loop avoids
- **NEVER** use iterator chains for multi-branch control flow (break with value, continue with side-effect, nested match) — use `for` loop; `try_fold`/`try_collect` for `Result`-based early exit
- **ALWAYS** prefer `Option`/`Result` combinators (`and_then`, `zip`, `filter`, `unwrap_or_else`) over nested `match`/`if let` for linear transforms
- **ALWAYS** prefer tuple destructuring `|(key, value)|` over `.0`/`.1` in closures

### Naming & Conversions

- **ALWAYS** order derives: `Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord`; derive only what needed
- **NEVER** add `get_` prefix to infallible field accessors — bare name; `_mut` for mutable; `get` for fallible/keyed returning `Option`
- **ALWAYS** use `is_`/`has_` for bool-returning methods
- **ALWAYS** use `Path` methods (`join`, `with_extension`) over string concat for file paths
- **NEVER** use `String` for fixed value sets — use enums with `Display`/`FromStr`
- **ALWAYS** return named structs over tuples when returning 3+ values

### Error Handling

#### General

- **NEVER** expose implementation-detail errors in public APIs — wrap in domain-specific variants
- **NEVER** log and propagate same error — choose one
- **NEVER** log errors at propagation sites (`?`) — log only where handled
- **ALWAYS** group error variants by failure semantics (`NotFound`, `InvalidInput`), not by source module
- **ALWAYS** scope error types to API surfaces — don't return 15-variant enum when 3 reachable
- **ALWAYS** start error display messages lowercase without trailing punctuation

#### Strategy Selection (axis: does the caller discriminate?)

- **ALWAYS** prefer typed enums (`thiserror`) when caller behavior changes per failure mode — even in binaries
- **ALWAYS** prefer opaque errors (`anyhow`/`eyre`) when all failures get same treatment — even in internal workspace crates
- **NEVER** use `anyhow` in public APIs of published crates — callers can't downcast across semver
- **ALWAYS** add `.context()` when propagating across abstraction boundaries
- **ALWAYS** justify each enum variant: if no caller matches on it, collapse or use `.context()` instead
- **ALWAYS** prefer `.context("msg")?` over `.ok_or_else(|| anyhow!("msg"))?` for static messages — works on both `Result` and `Option`
- **ALWAYS** prefer `.with_context(|| format!(...))` for dynamic messages — lazy allocation
- **NEVER** use `.context(format!(...))` — eagerly allocates on success path; use `.with_context(|| format!(...))` instead

### Type Design

- **ALWAYS** prefer enums for fixed variant sets — traits when new types expected over time
- **ALWAYS** implement `Display` for user-facing, `Debug` for developer diagnostics
- **NEVER** extract trait from type with only one impl; exception: DI across crates, plugin contracts, FFI
- **NEVER** extract traits solely for mocking; exception: external APIs you don't control
- **NEVER** implement `Default` on types where "empty" is a bug

### Project Structure

- **ALWAYS** default to private; `pub(crate)` for internal sharing; `pub` only for external API
- **ALWAYS** order file items: `use` → `mod` → constants → types → traits → `impl` → functions
- **NEVER** use `mod.rs` for new modules — use `domain.rs` alongside `domain/`; follow existing convention if codebase uses `mod.rs`
- **ALWAYS** keep `main.rs` thin — parse args, load config, wire deps, delegate to `lib.rs`; exception: <200 line tools
- **ALWAYS** enforce one-directional deps: `domain ← application ← infrastructure ← api`
- **ALWAYS** use `pub use` re-exports to flatten import paths for consumers

### Testing

#### General

- **ALWAYS** start concrete — extract traits when second impl arrives (test doubles count)
- **ALWAYS** prefer call-site DI over constructor-stored `Arc<Config>`; exception: 5+ call levels
- **ALWAYS** follow AAA with one action per test
- **ALWAYS** name SUT `sut`; name tests as scenarios (`returns_error_on_expired_token`)
- **NEVER** reimplement production logic in test assertions
- **NEVER** add production code only for testing

#### Unit Tests

- **ALWAYS** prefer output-based > state-based > interaction-based tests
- **NEVER** use mocks in unit tests — use real or fake collaborators
- **ALWAYS** prefer functional core/imperative shell > hand-written fakes > integration with real deps
- **ALWAYS** place implementation-detail tests in `#[cfg(test)] mod tests`

## Reference Materials

Read when topic relevant to current task. Files relative to this skill's directory.

- thiserror, inspect_err, #[from], library errors -> references/error-handling.md
- snafu, miette, multi-crate errors, CLI error reporting -> references/error-handling.md
- error type placement, error.rs, orchestrator errors -> references/error-handling.md
- serde, Serialize, Deserialize, #[serde(...)], rename_all -> references/crate-serde.md
- newtype, typestate, state machine, architecture selection -> references/architecture-design.md
- hexagonal, CQRS, dispatch, dyn Trait -> references/architecture-design.md
- workspace, crate layout, layering, Cargo.toml ordering -> references/architecture-design.md
- lifetimes, HRTB, const generics, const fn, OnceLock -> references/architecture-design.md
- DI, prelude, src/bin, tests/common -> references/architecture-design.md
- tokio, async, await, spawn, Send, Sync -> references/concurrency-async.md
- Mutex, RwLock, channel, oneshot, watch, select! -> references/concurrency-async.md
- TDD strategy, when to unit test, when to integration test -> references/testing.md
- rstest, proptest, insta, expect-test, cargo-fuzz -> references/testing.md
- integration tests, API contract tests, tests/ -> references/testing.md
- mockall, wiremock, mock unmanaged deps -> references/testing.md
- testcontainers, service emulator, gRPC testing, testing tiers -> references/testing.md
- track_caller, should_panic, Sans-IO, assert_matches -> references/testing.md
- repository testing, tempfile, async test, sleep test -> references/testing.md
- closure bounds, Fn/FnMut/FnOnce, IntoIterator -> references/api-design.md
- AsRef<Path>, FromStr, slice patterns -> references/api-design.md
- associated types, Deref, extension traits -> references/api-design.md
- Display vs Debug delegation, PartialEq entity -> references/api-design.md
- Result shadow, try_ prefix, TryFrom -> references/api-design.md
- tracing, log, #[instrument], structured logging, spans -> references/observability.md
- mem::take, mem::replace, Cow, array::from_fn -> references/advanced-patterns.md
- retain, retain_mut, chain, zip, collect Result -> references/advanced-patterns.md
- partition, HashMap::from, Default::default -> references/advanced-patterns.md
- Debug redact sensitive, consumed values in errors -> references/advanced-patterns.md
- object safety, Self: Sized, macro_rules -> references/advanced-patterns.md
- Unknown(u16) protocol, Clone OS resources, Drop panic -> references/advanced-patterns.md
- performance, hot path, profiling, allocation -> references/perf-optimization.md
- with_capacity, extend, extend_from_slice, monomorphization -> references/perf-optimization.md
- AoS, SoA, Box<[T]>, repr(transparent), branch prediction -> references/perf-optimization.md
- axum, web server, handler, extractor, IntoResponse -> references/domain-axum.md
- Tower middleware, AppError -> references/domain-axum.md
- CLI, clap, command-line, subcommand -> references/domain-cli.md
- bon, builder pattern, builder API, >3 required fields -> references/crate-bon.md
- cancellation safety, JoinSet, FuturesUnordered -> references/concurrency-advanced.md
- Semaphore, actor pattern -> references/concurrency-advanced.md
- unsafe, unsafe block, unsafe impl, SAFETY comment -> references/unsafe.md
- published crate, crates.io, #[non_exhaustive], sealed trait, feature flags -> references/published-crate.md
- rayon, par_iter, parallel iteration, rayon::join -> references/crate-rayon.md
- dashmap, flume, parking_lot, concurrent map -> references/crate-concurrency.md
- cloud, kubernetes, k8s, graceful shutdown -> references/domain-cloud.md
- CancellationToken, TaskTracker -> references/domain-cloud.md
- systems programming, generational index, slotmap, bytes -> references/domain-systems.md
- FFI, C interop, bindgen, sys crate, extern -> references/domain-ffi.md
- RAII, catch_unwind -> references/domain-ffi.md
- bumpalo, ArrayVec, SmallVec -> references/crate-alloc.md
- lasso, string_interner, phf -> references/crate-alloc.md
- WASM, WebAssembly, wasm-pack, Leptos, Dioxus, Yew -> references/domain-wasm.md
- embedded, no_std, PAC, HAL, BSP, RTIC, Embassy -> references/domain-embedded.md
- Bevy, ECS, Plugin, Commands, EventWriter, EventReader -> references/domain-bevy.md

## Workflow

**NEVER** run cargo commands directly. Use `/rust-lint` for all checking, formatting, testing.

After generating/modifying code: run `/rust-lint`, fix all issues before finishing.

Use `/rust-researcher` for ecosystem research.
