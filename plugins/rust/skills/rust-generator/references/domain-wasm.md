## Domain: WASM

- **ALWAYS** set `lto = true`, `codegen-units = 1`, `opt-level = "s"` for WASM; `opt-level = 3` for compute-heavy
- **ALWAYS** add `console_error_panic_hook` in browser WASM; not needed for WASI
- **ALWAYS** prefer Leptos (SSR/perf), Dioxus (multi-platform), Yew (Elm-style)
- **NEVER** assume multithreading in browser WASM
- **ALWAYS** use `wasm-opt` post-processing
