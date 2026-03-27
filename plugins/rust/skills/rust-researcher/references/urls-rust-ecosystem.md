# Rust Ecosystem URLs

## Official Rust

- **The Rust Reference**: `https://doc.rust-lang.org/reference/`
- **Rust API Guidelines**: `https://rust-lang.github.io/api-guidelines/`
- **Rustdoc Book**: `https://doc.rust-lang.org/rustdoc/`
- **Rust Edition Guide**: `https://doc.rust-lang.org/edition-guide/`
- **Rust Compiler Error Index**: `https://doc.rust-lang.org/error_codes/`
- **Rust Unsafe Code Guidelines**: `https://rust-lang.github.io/unsafe-code-guidelines/`
- **Rust Performance Book**: `https://nnethercote.github.io/perf-book/`
- **Rust Design Patterns**: `https://rust-unofficial.github.io/patterns/`
- **Rust Nomicon** (advanced/unsafe): `https://doc.rust-lang.org/nomicon/`
- **Cargo Book**: `https://doc.rust-lang.org/cargo/`

## Crate Documentation

- **docs.rs** (any crate): `https://docs.rs/{crate_name}/latest/`
- **crates.io** (metadata, versions, features): `https://crates.io/crates/{crate_name}`
- **lib.rs** (alternative docs + categories): `https://lib.rs/crates/{crate_name}`

## Major Ecosystem Crates

### Async & Concurrency

- **tokio** (async runtime): `https://docs.rs/tokio/latest/tokio/` | guide: `https://tokio.rs/tokio/tutorial`
- **tokio-util** (codecs, framing): `https://docs.rs/tokio-util/latest/tokio_util/`
- **futures** (async combinators): `https://docs.rs/futures/latest/futures/`
- **rayon** (parallelism): `https://docs.rs/rayon/latest/rayon/`
- **crossbeam** (concurrency primitives): `https://docs.rs/crossbeam/latest/crossbeam/`
- **flume** (sync+async MPMC channel): `https://docs.rs/flume/latest/flume/`
- **parking_lot** (fast mutex/rwlock): `https://docs.rs/parking_lot/latest/parking_lot/`
- **dashmap** (concurrent hashmap): `https://docs.rs/dashmap/latest/dashmap/`
- **arc-swap** (read-heavy shared state): `https://docs.rs/arc-swap/latest/arc_swap/`

### Serialization & Data

- **serde** (serialization): `https://docs.rs/serde/latest/serde/` | guide: `https://serde.rs/`
- **bytes** (byte buffers): `https://docs.rs/bytes/latest/bytes/`
- **phf** (compile-time perfect hash map): `https://docs.rs/phf/latest/phf/`
- **smallvec** (small-buffer optimization): `https://docs.rs/smallvec/latest/smallvec/`
- **arrayvec** (stack-allocated vec): `https://docs.rs/arrayvec/latest/arrayvec/`
- **compact_str** (small string optimization): `https://docs.rs/compact_str/latest/compact_str/`
- **bumpalo** (arena allocator): `https://docs.rs/bumpalo/latest/bumpalo/`
- **slotmap** (generational arena): `https://docs.rs/slotmap/latest/slotmap/`
- **lasso** (string interning): `https://docs.rs/lasso/latest/lasso/`
- **rustc-hash** (fast hasher): `https://docs.rs/rustc-hash/latest/rustc_hash/`

### Error Handling

- **anyhow** (application errors): `https://docs.rs/anyhow/latest/anyhow/`
- **thiserror** (error derive): `https://docs.rs/thiserror/latest/thiserror/`
- **snafu** (workspace-scale errors): `https://docs.rs/snafu/latest/snafu/`

### Web & Networking

- **axum** (web framework): `https://docs.rs/axum/latest/axum/`
- **tower** (service middleware): `https://docs.rs/tower/latest/tower/`
- **tower-http** (HTTP middleware): `https://docs.rs/tower-http/latest/tower_http/`
- **reqwest** (HTTP client): `https://docs.rs/reqwest/latest/reqwest/`
- **hyper** (low-level HTTP): `https://docs.rs/hyper/latest/hyper/`
- **tonic** (gRPC): `https://docs.rs/tonic/latest/tonic/`
- **prost** (protobuf): `https://docs.rs/prost/latest/prost/`

### Database

- **sqlx** (async SQL): `https://docs.rs/sqlx/latest/sqlx/`
- **diesel** (ORM): `https://docs.rs/diesel/latest/diesel/` | guide: `https://diesel.rs/guides/`
- **sea-orm** (async ORM): `https://docs.rs/sea-orm/latest/sea_orm/` | guide: `https://www.sea-ql.org/SeaORM/docs/`

### CLI

- **clap** (CLI parsing): `https://docs.rs/clap/latest/clap/` | guide: `https://docs.rs/clap/latest/clap/_derive/_tutorial/index.html`
- **indicatif** (progress bars): `https://docs.rs/indicatif/latest/indicatif/`
- **dialoguer** (interactive prompts): `https://docs.rs/dialoguer/latest/dialoguer/`
- **console** (terminal styling): `https://docs.rs/console/latest/console/`

### Observability

- **tracing** (diagnostics): `https://docs.rs/tracing/latest/tracing/`
- **tracing-subscriber** (subscriber setup): `https://docs.rs/tracing-subscriber/latest/tracing_subscriber/`
- **tracing-opentelemetry** (OTel bridge): `https://docs.rs/tracing-opentelemetry/latest/tracing_opentelemetry/`

### Testing

- **criterion** (benchmarking): `https://docs.rs/criterion/latest/criterion/`
- **proptest** (property testing): `https://docs.rs/proptest/latest/proptest/`
- **mockall** (mocking): `https://docs.rs/mockall/latest/mockall/`
- **insta** (snapshot testing): `https://docs.rs/insta/latest/insta/`
- **assert_cmd** (CLI testing): `https://docs.rs/assert_cmd/latest/assert_cmd/`

### FFI

- **bindgen** (C binding generator): `https://docs.rs/bindgen/latest/bindgen/`
- **cxx** (C++ interop): `https://docs.rs/cxx/latest/cxx/` | guide: `https://cxx.rs/`

### Builder & Derive

- **bon** (typestate builder): `https://docs.rs/bon/latest/bon/`
- **trait-variant** (async trait variants): `https://docs.rs/trait-variant/latest/trait_variant/`

### Game

- **bevy** (game engine): `https://docs.rs/bevy/latest/bevy/` | guide: `https://bevyengine.org/learn/`

## Community & Discussion

- **Rust Users Forum**: `https://users.rust-lang.org/`
- **Rust Internals Forum**: `https://internals.rust-lang.org/`
- **This Week in Rust**: `https://this-week-in-rust.org/`
- **Rust Blog**: `https://blog.rust-lang.org/`
- **Rust RFCs**: `https://rust-lang.github.io/rfcs/`
