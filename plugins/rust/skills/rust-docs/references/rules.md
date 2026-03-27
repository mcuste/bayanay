# Documentation Rules

## Rustdoc (`///`, `//!`)

### Required — All Crates

- [doc-safety] `unsafe fn` → add `# Safety` section listing every caller invariant
- [doc-unsafe-block] `unsafe {}` → add `// SAFETY:` comment explaining why invariants hold

### Required — Published Crates Only

- [doc-errors] Public `fn() -> Result` → add `# Errors` describing each variant
- [doc-panics] Public fn that can panic → add `# Panics` with condition
- [doc-crate-root] `lib.rs` → add `//!` crate doc: purpose, key types, usage
- [doc-all-pub] Every `pub` item → doc comment, minimum summary line

### Required — Application Crates (when applicable)

- [doc-errors-app] `# Errors` only when error conditions non-obvious
- [doc-panics-app] `# Panics` only when panic conditions non-obvious from signature
- [doc-crate-root-app] `//!` crate doc only when purpose unclear from name + structure

### Format

- [doc-summary-fragment] Summary = imperative fragment, no subject — "Returns the connection" not "This function returns the connection"
- [doc-summary-single] Summary = one sentence — details go in extended description
- [doc-link-types] Use intra-doc links for types — `` [`Option`] ``, `` [`Config::new`] ``
- [doc-examples-public] Public non-trivial fns → add `# Examples` (compile-tested via `cargo test`)

### Noise — Delete or Rewrite

- [doc-no-echo-fn] Don't restate fn name — "Validates the input" on `fn validate_input` = noise
- [doc-no-echo-field] Don't restate field name + type — "The user's ID" on `id: UserId` = noise
- [doc-no-echo-variant] Don't restate variant name — "North direction" on `North` = noise
- [doc-no-echo-impl] No doc on trait impl blocks — rustdoc shows this already
- [doc-no-echo-getter] Don't write "Returns the X" on `fn x(&self) -> &X` — add real info or delete
- [doc-no-echo-new] Don't write "Creates a new X" on `fn new()` alone — describe initialized state, bindings, or deferred work
- [doc-no-echo-module] Don't restate module name — "Authentication module" in `auth.rs` = noise
- [doc-no-private-examples] No `# Examples` on private/`pub(crate)` fns — won't compile-test or render

## Dev Notes (`//`)

### Required

- [note-workaround] Workarounds → comment with issue link — `// WORKAROUND: upstream bug foo/bar#123`
- [note-unsafe-block] `unsafe` blocks → `// SAFETY:` comment, even when obvious
- [note-todo] TODO/FIXME → include issue number or context — bare `// TODO` not actionable

### Appropriate

- [note-why-not-what] Comments explain WHY, not WHAT — code shows what
- [note-invariant] Comment non-obvious invariants — why `unwrap()` safe, why ordering matters
- [note-perf] Comment perf choices that look wrong — "Vec not HashMap because N < 16"
- [note-magic] Comment magic numbers, regex, bitwise ops — `// Mask lower 4 bits: packet type field`

### Noise — Delete

- [note-no-narration] Don't narrate next line — "// Send the request" before `client.send()`
- [note-no-section-headers] Don't use comments as section headers — "// Initialization", "// Processing"
- [note-no-commented-code] Don't leave commented-out code — git has history
- [note-no-stdlib-explain] Don't explain stdlib/well-known APIs — "// Convert to string" before `.to_string()`
- [note-no-stale-risk] Don't write comments that rot — "// Check if temperature exceeds 100" when constant is `OVERHEAT_THRESHOLD`
