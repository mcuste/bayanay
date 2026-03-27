## Advanced Code Patterns

- **ALWAYS** prefer `Iterator::partition` over two `filter` + `collect` passes
- **ALWAYS** prefer `HashMap::from([(k, v), ...])` over `new()` + repeated `insert()` for small fixed maps
- **ALWAYS** prefer explicit field initialization over `..Default::default()` for owned types
- **ALWAYS** prefer `std::mem::take`/`replace` over clone-and-reassign when moving out of `&mut T`
- **ALWAYS** prefer `std::array::from_fn` over manual array initialization
- **ALWAYS** prefer `std::iter::successors`/`from_fn` over `loop` + `push` for sequence generation
- **ALWAYS** prefer `retain`/`retain_mut` over filter-collect-reassign for in-place filtering
- **ALWAYS** prefer `Iterator::chain` over collect into intermediate `Vec` then iterate
- **ALWAYS** prefer `Iterator::zip` over manual index-based parallel iteration
- **ALWAYS** prefer `collect::<Result<Vec<_>, _>>()` over manual loop with `?` for simple map-and-collect fallible iteration
- **ALWAYS** escalate code generation: functions → generics → `macro_rules!` → proc-macros

## Advanced Naming & Conversions

- **ALWAYS** use `_unchecked` suffix for methods skipping validation; pair with `unsafe` when skipping causes UB
- **ALWAYS** prefer `Cow<'a, str>` when function usually returns borrowed but occasionally allocates; avoid in hot paths or structs where lifetime cascades
- **ALWAYS** add explicit lifetimes in zero-copy APIs with multiple input references

## Advanced Error Handling

- **ALWAYS** return consumed values in error types for non-`Clone` types with recoverable failure
- **NEVER** return consumed values when type is `Clone`, operation not retryable, or value partially consumed
- **ALWAYS** allow `Unknown(u16)` variants at protocol boundaries for unrecognized wire values + `#[non_exhaustive]`

## Advanced Type Design

- **ALWAYS** implement `Debug` manually for types with sensitive data — redact secrets
- **NEVER** derive `Clone` on types owning unique OS resources — use fallible `try_clone()`
- **NEVER** panic inside `Drop` — double-panic during unwind aborts process
- **ALWAYS** add `where Self: Sized` on individual methods that prevent object safety when trait should support `dyn`
- **ALWAYS** mark `unsafe trait` when implementations must uphold invariants compiler cannot check
