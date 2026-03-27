# Rust Plugin

Code generation, evaluation, linting, and research for Rust — with guideline-based quality loops.

## Setup

Run `/setup-rust-project` in your project to configure clippy, cargo-deny, cargo-machete, and an optimized release profile.

---

## Skills

### `/rust-implement`

Implements Rust code using a full TDD loop: designs tests first, evaluates them, generates the implementation, then audits it against the guidelines. Use this for any non-trivial feature or module.

### `/rust-evaluate`

Audits an entire Rust repository for idiomatic patterns, architecture issues, test quality, and design problems. Runs `rust-evaluator` and `rust-test-evaluator` across every crate. Use this for code reviews or before a release.

### `/rust-lint`

Runs the full linting suite: `cargo fmt`, `clippy`, `nextest`, `cargo-deny`, and `cargo-machete`. Use this before committing or as a CI check.

### `/rust-researcher`

Researches the Rust ecosystem via the web — crates, frameworks, cloud platforms, databases, tooling. Returns structured findings with links. Use this when evaluating dependencies or looking up idiomatic approaches.

### `/setup-rust-project`

Scaffolds linting and tooling configuration in your project. Sets up `clippy.toml`, `deny.toml`, `.cargo/config.toml` with a fast release profile, and `cargo-machete` ignore rules.

---

## How guidelines work

Guidelines are layered by context so the right rules apply at the right time.

### Tier A — Activity scoped

Loaded by `rust-generator` when the task matches. Stored in `skills/rust-generator/references/`:

| File                   | What it covers                                |
|------------------------|-----------------------------------------------|
| `type-design.md`       | Type design, API surface, builders, lifetimes |
| `error-handling.md`    | Error types, thiserror/anyhow, context        |
| `concurrency.md`       | Async, mutexes, actors, channels, pinning     |
| `testing.md`           | Testability, test selection, tools            |
| `performance.md`       | Hot paths, data structures, optimization      |
| `project-structure.md` | Modules, workspaces, architecture patterns    |
| `unsafe.md`            | Unsafe code safety                            |

### Tier B — Domain scoped

Loaded automatically when matching dependencies are found in `Cargo.toml`:

| File                 | Triggered by                              |
|----------------------|-------------------------------------------|
| `domain-cli.md`      | `clap`, `argh`, `lexopt`                  |
| `domain-axum.md`     | `axum`, `tower`                           |
| `domain-cloud.md`    | `kube`, `tokio-util` + k8s patterns       |
| `domain-ffi.md`      | `*-sys` crates, `extern "C"`             |
| `domain-embedded.md` | `embassy`, `rtic`, `thumbv*` target       |
| `domain-gamedev.md`  | `bevy`                                    |
| `domain-systems.md`  | `slotmap`, `bytes`, `glommio`             |
| `domain-wasm.md`     | `wasm-bindgen`, `wasm32-*` target         |
