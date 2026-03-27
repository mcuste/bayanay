# Performance & Allocation

Apply after profiling/benchmarking identifies hot path or bottleneck. Do not apply speculatively.

## Allocation

- [perf-with-capacity] ALWAYS pre-allocate with `with_capacity` when collection size is known
- [perf-extend] ALWAYS prefer `extend`/`extend_from_slice` over loop + `push`
- [perf-no-context-hot] NEVER use `.context()` in hot paths — use bare `?`
- [perf-box-slice] ALWAYS prefer `Box<[T]>` over `Vec<T>` for fixed-size heap data; `Box<str>` over `String` for immutable heap strings

## Data Layout

- [perf-aos-default] ALWAYS start with AoS — switch to SoA only when profiling shows cache misses accessing <half fields
- [perf-repr-transparent] ALWAYS add `#[repr(transparent)]` to `NonZero*`/`NonNull` newtypes

## Dispatch & Monomorphization

- [perf-generic-hot] ALWAYS prefer generics for hot paths in leaf functions — `dyn Trait` at 5+ cascading bounds, for heterogeneous collections, or to reduce monomorphization bloat in large binaries
- [perf-extract-non-generic] ALWAYS extract non-generic inner functions from generic wrappers in library crates
- [perf-no-enum-hot-branch] NEVER use enum state machines in hot paths where profiling shows branch prediction suffering

## Shared State

- [perf-no-arc-mutex-clone] NEVER wrap data in `Arc<Mutex<T>>` when `T` is `Clone` and cheap to clone — just clone

## Lifetimes

- [perf-no-multi-lifetime] NEVER add multiple lifetime params to public functions without profiling confirming zero-copy benefit

## Arena Allocation

- [perf-bumpalo] ALWAYS use `bumpalo` for short-lived per-request allocations

## Stack-Optimized Collections

- [perf-arrayvec] ALWAYS use `ArrayVec<T, N>` for fixed compile-time-bounded collections
- [perf-smallvec] ALWAYS use `SmallVec<[T; N]>` for usually-small occasionally-large collections

## String Interning

- [perf-string-intern] ALWAYS use `lasso`/`string_interner` for repeated strings

## Compile-Time Maps

- [perf-phf] ALWAYS use `phf` over `lazy_static! { HashMap }` for fixed key sets ~50+ entries
- [perf-no-phf-small] NEVER use `phf` for ≤10 entries, tight dep budgets, or composite key types
