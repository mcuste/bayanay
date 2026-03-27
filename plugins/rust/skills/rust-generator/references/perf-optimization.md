
# Performance Optimization

Apply these rules **after profiling/benchmarking** identifies the relevant hot path or bottleneck. Do not apply speculatively.

## Allocation

- **ALWAYS** pre-allocate with `with_capacity` when collection size is known
- **ALWAYS** prefer `extend`/`extend_from_slice` over loop + `push`
- **NEVER** use `.context()` in hot paths — use bare `?`
- **ALWAYS** prefer `Box<[T]>` over `Vec<T>` for fixed-size heap data; `Box<str>` over `String` for immutable heap strings

## Data Layout

- **ALWAYS** start with AoS — switch to SoA only when profiling shows cache misses accessing <half fields
- **ALWAYS** add `#[repr(transparent)]` to `NonZero*`/`NonNull` newtypes

## Dispatch & Monomorphization

- **ALWAYS** prefer generics for hot paths in leaf functions — `dyn Trait` at 5+ cascading bounds, for heterogeneous collections, or to reduce monomorphization bloat in large binaries
- **ALWAYS** extract non-generic inner functions from generic wrappers in library crates
- **NEVER** use enum state machines in hot paths where profiling shows branch prediction suffering

## Shared State

- **NEVER** wrap data in `Arc<Mutex<T>>` when `T` is `Clone` and cheap to clone — just clone

## Lifetimes

- **NEVER** add multiple lifetime params to public functions without profiling confirming zero-copy benefit
