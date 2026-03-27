# Crates: Allocation & Data Structures

## Arena Allocation

- **ALWAYS** use `bumpalo` for short-lived per-request allocations

## Stack-Optimized Collections

- **ALWAYS** use `ArrayVec<T, N>` for fixed compile-time-bounded collections
- **ALWAYS** use `SmallVec<[T; N]>` for usually-small occasionally-large collections

## String Interning

- **ALWAYS** use `lasso`/`string_interner` for repeated strings

## Compile-Time Maps

- **ALWAYS** use `phf` over `lazy_static! { HashMap }` for fixed key sets ~50+ entries
- **NEVER** use `phf` for ≤10 entries, tight dep budgets, or composite key types
