---
name: rust-evaluator
description: "Evaluate Rust code for idiomatic patterns, correctness, architecture, performance, and test quality — coupling, concurrency, error handling, domain design, allocation, hot paths, test doubles, and assertions. This skill should be used proactively. Use when: 'review Rust code', 'check if this Rust is idiomatic', 'evaluate Rust patterns', 'audit Rust architecture', 'code review', 'is this good Rust', 'review these Rust files', 'optimize this Rust code', 'review performance', 'check for perf issues', 'performance audit', 'make this faster', 'why is this slow', 'review these tests', 'check test quality', 'evaluate test patterns', 'audit test design', 'are these tests good', 'review test code'."
argument-hint: "<file paths or description of code to evaluate>"
allowed-tools: "Read, Glob, Grep, TodoWrite"
model: sonnet
effort: max
---

# Rust Evaluator

No improvisation. No invented rules.

## Process

1. SCAN & LOAD — read target files, `Cargo.toml`, `references/core.md`, then signal-matched reference files
2. EVALUATE — check every line against ONLY loaded rules

For each potential violation:

1. Identify exact rule (quote the ALWAYS/NEVER text)
2. Verify violation is real — check context, check if exception applies
3. If rule has exception clause, verify exception does NOT apply before reporting
4. Apply worthiness filter (below) — drop if not worth fixing

### Worthiness filter

Before reporting any violation, STOP and answer: "If someone fixes this, what concretely improves?" If you cannot name a specific, concrete improvement in 10 words, drop it.

**Drop** the violation if ANY apply:

- **No consumer** — no callers benefit from the precision (e.g., per-method error types when all callers just `?`-propagate, catch-all string variants when 5+ source types exist and callers never match).
- **Rule breaks down** — the rule's intent doesn't hold at this edge case (e.g., "lowercase error messages" for acronyms like HTTP, JSON).
- **Cost dwarfs value** — disproportionate refactoring for marginal gain (e.g., typestate for a 3-field builder that can't be misused, typed error variants for a CLI tool's internal errors).
- **Already mitigated** — surrounding code handles the risk differently.

**Keep** the violation if ANY apply:

- **Low-cost alternative exists** — a better approach is available or trivial to adopt (e.g., `InMemoryCache` exists in test-doubles crate but tests hand-roll a mock).
- **Downstream breakage** — skipping causes bugs, panics, or incorrect behavior in callers.
- **Compounds over time** — pattern will be copy-pasted; catching it now prevents spread.

When in doubt, drop. Only report violations someone should actually fix. Zero violations is a valid and expected outcome — do NOT search harder just to find something to report.

## Rules

### Violation tiers (descending priority)

1. **correctness** — wrong behavior, UB, data race, logic error
2. **safety** — unsafe misuse, missing safety invariants
3. **architecture** — structural violations (layering, coupling, module design)
4. **performance** — allocation, dispatch, hot-path violations (only when perf topic detected)
5. **style** — naming, ordering, derive ordering, idiomatic patterns

### Root-cause filter

- Higher tier explains lower → drop lower
- B is consequence of A → report only A, list all locations
- Same rule violated in N places → ONE entry, list all locations

### Do NOT report

- Rules not in loaded files
- Simplicity/YAGNI/KISS heuristics — only codified ALWAYS/NEVER rules
- Code patterns with no matching rule
- Speculation about what "might" be better
- Things merely "unusual" but not rule violations
- Style preferences not backed by specific rule

## Output

Max 5 violations, ranked by tier priority (highest first).

Format: `- file:line — [rule-id] description`

- Violations only. No suggestions, positives, questions, prose.
- No tables. No intros. No summaries.
- Clean files → omit. Entirely clean → `All clean — no violations found.`
- Every violation MUST cite `[rule-id]` from loaded reference files.
- Unsure if violation → NOT violation. Do not report.

## Reference files

Read every target file and `Cargo.toml` if available. ALWAYS read `references/core.md`. Then read ONLY reference files whose signals appear in code:

- `references/error-handling.md` — `thiserror`, `anyhow`, `eyre`, `snafu`, `miette`, custom `Error` enum, `impl From<`, `.context(`
- `references/serde.md` — `serde`, `Serialize`, `Deserialize`, `#[serde(`
- `references/concurrency.md` — `async fn`, `.await`, `tokio::`, `futures::`, `select!`, `JoinSet`, `CancellationToken`, `Semaphore`, `FuturesUnordered`, `dashmap`, `flume`, `parking_lot`
- `references/testing.md` — `#[test]`, `#[cfg(test)]`, `#[tokio::test]`, `assert`, `mock`, `rstest`, `proptest`, `insta`, `testcontainers`, `wiremock`
- `references/api-design.md` — `pub fn`, `pub trait`, `pub struct`, closure params (`Fn`, `FnMut`, `FnOnce`), `IntoIterator`, `AsRef`, `FromStr`
- `references/architecture.md` — module structure, `pub(crate)`, workspace layout, `mod`, `pub use`, newtypes, typestate
- `references/performance.md` — `with_capacity`, `Box<[T]>`, `#[repr(`, `Arc<Mutex<`, `bumpalo`, `ArrayVec`, `SmallVec`, `lasso`, `phf`, `lazy_static`
- `references/observability.md` — `tracing`, `log`, `#[instrument]`, `info!`, `warn!`, `error!`, `debug!`
- `references/unsafe.md` — `unsafe fn`, `unsafe impl`, `unsafe {`, `unsafe trait`
- `references/crates.md` — `bon`, `#[builder]`, `rayon`, `par_iter`
- `references/published-crate.md` — `Cargo.toml` has `version` + `license`/`description`, no `publish = false`
- `references/advanced-patterns.md` — `mem::take`, `mem::replace`, `Cow<`, `partition`, `retain`, `from_fn`, `chain`, `zip`
- `references/domains.md` — `axum::`, `clap`, `slotmap`, `bytes::Bytes`, `extern "C"`, `wasm_bindgen`, `no_std`, `bevy::`, `CancellationToken` + `TaskTracker`

Read reference files relative to this skill's directory. Use Glob to locate if path doesn't resolve.
