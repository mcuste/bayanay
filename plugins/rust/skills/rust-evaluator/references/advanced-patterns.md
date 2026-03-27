# Advanced Code Patterns

## Code Patterns

- [adv-partition] ALWAYS prefer `Iterator::partition` over two `filter` + `collect` passes
- [adv-hashmap-from] ALWAYS prefer `HashMap::from([(k, v), ...])` over `new()` + repeated `insert()` for small fixed maps
- [adv-explicit-fields] ALWAYS prefer explicit field initialization over `..Default::default()` for owned types
- [adv-mem-take] ALWAYS prefer `std::mem::take`/`replace` over clone-and-reassign when moving out of `&mut T`
- [adv-array-from-fn] ALWAYS prefer `std::array::from_fn` over manual array initialization
- [adv-successors] ALWAYS prefer `std::iter::successors`/`from_fn` over `loop` + `push` for sequence generation
- [adv-retain] ALWAYS prefer `retain`/`retain_mut` over filter-collect-reassign for in-place filtering
- [adv-chain] ALWAYS prefer `Iterator::chain` over collect into intermediate `Vec` then iterate
- [adv-zip] ALWAYS prefer `Iterator::zip` over manual index-based parallel iteration
- [adv-collect-result] ALWAYS prefer `collect::<Result<Vec<_>, _>>()` over manual loop with `?` for simple map-and-collect fallible iteration
- [adv-codegen-escalate] ALWAYS escalate code generation: functions → generics → `macro_rules!` → proc-macros

## Naming & Conversions

- [adv-unchecked-suffix] ALWAYS use `_unchecked` suffix for methods skipping validation; pair with `unsafe` when skipping causes UB
- [adv-cow] ALWAYS prefer `Cow<'a, str>` when function usually returns borrowed but occasionally allocates; avoid in hot paths or structs where lifetime cascades
- [adv-explicit-lifetimes] ALWAYS add explicit lifetimes in zero-copy APIs with multiple input references

## Error Handling

- [adv-consumed-in-error] ALWAYS return consumed values in error types for non-`Clone` types with recoverable failure
- [adv-no-consumed-clone] NEVER return consumed values when type is `Clone`, operation not retryable, or value partially consumed
- [adv-unknown-variant] ALWAYS allow `Unknown(u16)` variants at protocol boundaries for unrecognized wire values + `#[non_exhaustive]`

## Type Design

- [adv-debug-redact] ALWAYS implement `Debug` manually for types with sensitive data — redact secrets
- [adv-no-clone-os] NEVER derive `Clone` on types owning unique OS resources — use fallible `try_clone()`
- [adv-no-panic-drop] NEVER panic inside `Drop` — double-panic during unwind aborts process
- [adv-sized-object-safety] ALWAYS add `where Self: Sized` on individual methods that prevent object safety when trait should support `dyn`
- [adv-unsafe-trait] ALWAYS mark `unsafe trait` when implementations must uphold invariants compiler cannot check
