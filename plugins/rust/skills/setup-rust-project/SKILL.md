---
name: setup-rust-project
description: "Set up a Rust project — Clippy lints, cargo-deny, cargo-machete, release profile, and allocator. Use when: 'new Rust project', 'set up Rust tooling', 'configure clippy', 'initialize Rust workspace', 'set up cargo-deny', 'configure Rust linting'."
argument-hint: "<project or workspace path>"
disable-model-invocation: true
---

Set up Rust project tooling. Use `AskUserQuestion` to gather info step by step. Generate config by reading and adapting preset files in `references/` (relative to this skill file).

## Reference Files

- `references/clippy-lints.toml` — Clippy lints preset for Cargo.toml
- `references/clippy.toml` — Clippy config: thresholds + test relaxations
- `references/deny.toml` — Cargo Deny: license, advisory, dependency policy
- `references/machete.toml` — Cargo Machete: false-positive ignore list

## Step 1: Project Info

`AskUserQuestion` with 3 questions:

**Q1** — "What are you configuring?", header: "Scope", multiSelect: false

- "Single crate project" — config in `[lints.*]` in `Cargo.toml`
- "Specific crate in workspace" — config in that crate's `Cargo.toml`; `[lints] workspace = true` if inheriting
- "Whole workspace" — config in root `Cargo.toml` under `[workspace.lints.*]`; all members need `[lints] workspace = true`

**Q2** — "Any special targets or constraints?", header: "Special targets", multiSelect: true

- "Binary / CLI tool" — allow print macros (stdout/stderr intentional)
- "Embedded / no_std"
- "WASM (browser or WASI)"
- "Proc macro crate"
- "Bevy / ECS game engine"
- "FFI / C interop"

**Q3** — "Which tools do you want to set up?", header: "Tools", multiSelect: true

- "Clippy — lint configuration in Cargo.toml + clippy.toml (Recommended)"
- "Cargo Deny — license, advisory, and dependency policy via deny.toml (Recommended)"
- "Cargo Machete — unused dependency detection ignore list (Recommended)"

Skip deselected tools. Wait for answers before proceeding.

## Step 2: Project-Specific Adjustments

Present **only relevant** adjustments. Combine into single `AskUserQuestion` with multiSelect: true. Pre-select recommended with "(Recommended)" suffix.

### Binary / CLI tool

- "Allow print macros — stdout/stderr intentional for CLIs (Recommended)" — remove `print_stdout`, `print_stderr` from clippy preset

### Embedded / no_std or WASM

- "Add no_std lints (Recommended)" — add `std_instead_of_core = "warn"`, `std_instead_of_alloc = "warn"`, `alloc_instead_of_core = "warn"`
- "Remove print macro lints (Recommended)" — remove `print_stdout`, `print_stderr`
- "Allow `missing_const_for_fn` — limited in no_std (Recommended)" — set to `"allow"`

### Proc macro crate

- "Relax noisy lints for proc macros (Recommended)" — allow `too_many_lines`, `cognitive_complexity`, `wildcard_imports`, `similar_names`

### Bevy / ECS game engine

- "Allow `needless_pass_by_value` — Bevy system params (`Res<T>`, `Query<T>`, etc.) must be owned (Recommended)" — set `needless_pass_by_value = "allow"`
- "Allow `too_many_arguments` — Bevy systems take one param per ECS resource/query (Recommended)" — set `too_many_arguments = "allow"`

### FFI / C interop

- "Allow unsafe code — required for FFI (Recommended)" — remove `unsafe_code = "forbid"` from `[lints.rust]`; add `undocumented_unsafe_blocks = "warn"`, `multiple_unsafe_ops_per_block = "warn"`, `missing_safety_doc = "warn"`, `ptr_as_ptr = "warn"`

### Publishing to crates.io

Infer from `[package]` metadata. If publishing: add `multiple_crate_versions = "warn"`, `wildcard_dependencies = "deny"` to clippy section.

### General adjustments (always ask in second call)

`AskUserQuestion`:

**Q1** — "Do you use `anyhow` or similar error-handling crate?", header: "Error handling", multiSelect: false

- "Yes — prefer `.context()?` over `.expect()`" — keep `expect_used = "deny"`
- "No" — downgrade `expect_used` to `"warn"`

**Q2** — "Does this project use `unsafe` code?", header: "Unsafe", multiSelect: false (skip if FFI selected)

- "Yes" — remove `unsafe_code = "forbid"`; add `undocumented_unsafe_blocks = "warn"`, `multiple_unsafe_ops_per_block = "warn"`
- "No" — keep `unsafe_code = "forbid"`

## Step 3: Generate & Apply

### Build config

1. Read reference preset files (listed above)
2. Apply Step 2 adjustments
3. Adapt TOML headers by scope:
   - **Single crate:** `[lints.rust]`, `[lints.clippy]`, `[package.metadata.cargo-machete]`
   - **Workspace:** `[workspace.lints.rust]`, `[workspace.lints.clippy]`, `[workspace.metadata.cargo-machete]` (reference files use workspace format)

### Review

Show all generated configs (selected tools only):

1. Clippy lints — `[lints.rust]` + `[lints.clippy]` for `Cargo.toml`
2. `clippy.toml` — thresholds + test relaxations
3. `deny.toml` — full cargo-deny config
4. Machete — `[*.metadata.cargo-machete]` for `Cargo.toml`

`AskUserQuestion` — "What would you like to do?", header: "Apply", multiSelect: false

- "Apply all — write configs"
- "Make adjustments first" — ask what to change, regenerate, re-prompt
- "Just show me — I'll apply myself"

### If "Apply all"

1. Update `Cargo.toml` with clippy lint sections + machete config
2. Write `clippy.toml` to project root
3. Write `deny.toml` to project root
4. If workspace: ensure each member has `[lints] workspace = true`
5. Run `cargo clippy` to show violations
6. `AskUserQuestion` — "Clippy found violations. What would you like to do?", header: "Violations", multiSelect: false
   - "Address them now"
   - "Leave as warnings for now" — continue to Step 4

## Step 4: Release Profile & Allocator

Check if `[profile.release]` exists. If missing/incomplete, suggest:

```toml
[profile.release]
lto = "fat"
codegen-units = 1
opt-level = 3
```

For binary targets (`Cargo.toml` or `src/main.rs`), also suggest:

- `panic = "abort"` — if no unwinding needed (no panic recovery, no FFI catching panics)
- `strip = true` — if debug symbols unneeded in release
- **Global allocator** (skip embedded/WASM) — for allocation-heavy multi-threaded binaries, suggest `jemalloc` via `tikv-jemallocator` or `mimalloc`. Default system allocator fine for single-threaded/low-allocation.

`AskUserQuestion` — "Would you like to apply these optimizations?", header: "Release optimizations", multiSelect: true

- "Add release profile settings"
- "Add global allocator" (binary crates only, skip embedded/WASM)
- "Skip — I'll handle these myself"
