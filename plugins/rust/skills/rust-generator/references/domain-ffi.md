## Domain: FFI

- **ALWAYS** separate `*-sys` raw bindings from safe wrapper for published libs; `mod ffi` for internal
- **ALWAYS** wrap C resource handles in RAII `Drop` struct; exception: C library owns lifecycle
- **ALWAYS** wrap Rust callbacks to C in `catch_unwind`; not needed with `panic = "abort"` or `no_std`
- **ALWAYS** add `#[repr(transparent)]` to newtypes crossing FFI boundaries
- **ALWAYS** add `#[repr(C)]` to types used in shared memory, memory-mapped I/O, or persisted binary formats
