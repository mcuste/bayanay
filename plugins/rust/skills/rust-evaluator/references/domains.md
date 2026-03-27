# Domain-Specific Rules

## Axum

- [axum-state] ALWAYS use `State<T>` over `Extension<T>` for app-wide DI; `Extension` for per-request middleware data
- [axum-from-request] ALWAYS move request-side cross-cutting into `FromRequestParts`; response-side into Tower middleware
- [axum-app-error] ALWAYS consolidate error mapping into single `AppError` implementing `IntoResponse`
- [axum-extractor-order] ALWAYS order handler extractors: infallible/cheap first, fallible last
- [axum-no-dyn-service] NEVER use `dyn Service` when generics suffice

## CLI

- [cli-clap-derive] ALWAYS use clap derive over builder; `argh`/`lexopt` for size-constrained
- [cli-ctx-struct] ALWAYS normalize config sources into single `Ctx` struct; skip for ≤3-flag single-command CLIs
- [cli-subcommand-mod] ALWAYS put each subcommand in own module with `run(args, ctx) -> Result<()>`
- [cli-stderr-stdout] ALWAYS write diagnostics/progress to stderr, data to stdout

## Cloud / K8s

- [cloud-cancel-tracker] ALWAYS use `CancellationToken` + `TaskTracker` for graceful shutdown with background tasks
- [cloud-health-probes] ALWAYS implement separate `/healthz` (liveness) and `/readyz` (readiness) probes
- [cloud-503-shutdown] ALWAYS return 503 from readiness probe on shutdown signal
- [cloud-config-startup] ALWAYS parse config at startup into `serde::Deserialize` structs; `arc-swap` for hot-reload

## Systems

- [sys-generational-index] ALWAYS prefer generational indices (`slotmap`) over `Rc<RefCell<T>>` for cyclic structures; `Box<Node>` for small heterogeneous trees
- [sys-bytes] ALWAYS use `bytes::Bytes`/`BytesMut` for multi-stage network pipelines; `Vec<u8>` for simple request/response
- [sys-no-thread-per-core] NEVER use thread-per-core runtimes unless profiling proves cross-thread sync is bottleneck

## FFI

- [ffi-sys-split] ALWAYS separate `*-sys` raw bindings from safe wrapper for published libs; `mod ffi` for internal
- [ffi-raii-drop] ALWAYS wrap C resource handles in RAII `Drop` struct; exception: C library owns lifecycle
- [ffi-catch-unwind] ALWAYS wrap Rust callbacks to C in `catch_unwind`; not needed with `panic = "abort"` or `no_std`
- [ffi-repr-transparent] ALWAYS add `#[repr(transparent)]` to newtypes crossing FFI boundaries
- [ffi-repr-c] ALWAYS add `#[repr(C)]` to types used in shared memory, memory-mapped I/O, or persisted binary formats

## WASM

- [wasm-opt-profile] ALWAYS set `lto = true`, `codegen-units = 1`, `opt-level = "s"` for WASM; `opt-level = 3` for compute-heavy
- [wasm-panic-hook] ALWAYS add `console_error_panic_hook` in browser WASM; not needed for WASI
- [wasm-framework] ALWAYS prefer Leptos (SSR/perf), Dioxus (multi-platform), Yew (Elm-style)
- [wasm-no-threads] NEVER assume multithreading in browser WASM
- [wasm-post-opt] ALWAYS use `wasm-opt` post-processing

## Embedded

- [embed-layering] ALWAYS follow PAC → HAL → BSP layering; direct register access only when HAL lacks feature or ISR needs it
- [embed-typestate] ALWAYS use typestate for peripheral config; `DynPin` when mode changes at runtime
- [embed-concurrency] ALWAYS choose concurrency by latency: RTIC (hard real-time) → Embassy (cooperative async) → RTOS (porting threaded code)
- [embed-no-embassy-rt] NEVER use Embassy for sub-ms deadline guarantees
- [embed-no-alloc-assume] NEVER assume `alloc` in `no_std` — set up `#[global_allocator]` explicitly

## Bevy / ECS

- [bevy-plugin] ALWAYS encapsulate features as `Plugin`s
- [bevy-no-ordering] NEVER add `.before()`/`.after()` ordering without data or logical dependency
- [bevy-commands] ALWAYS use `Commands` (deferred) for spawn/despawn/insert; exception: exclusive systems for bulk ops
- [bevy-typed-events] ALWAYS use typed events for cross-system communication; `Changed<T>` for same-frame guarantees
