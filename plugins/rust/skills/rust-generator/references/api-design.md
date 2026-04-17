## Closure Bounds

- **ALWAYS** use least restrictive closure bound: `Fn` → `FnMut` → `FnOnce`
- **ALWAYS** prefer `impl Fn(T) -> R` over `Box<dyn Fn(T) -> R>` unless closure must be stored
- **NEVER** `&impl Fn` — `Fn` auto-impl'd for `&F`, use `impl Fn` directly

## Slice Patterns

- **ALWAYS** prefer slice patterns (`[first, rest @ ..]`) over index access for known-length slices

## Iterator & Collection Params

- **ALWAYS** prefer `impl IntoIterator<Item = T>` over `&[T]` for params that only iterate
- **ALWAYS** prefer `impl AsRef<Path>` over `&Path` for read-only params
- **NEVER** `impl AsRef<T>`/`impl Borrow<T>` when body immediately clones to owned — take owned type or `impl Into<Owned>`

## Naming Conventions

- **ALWAYS** use `try_` prefix for fallible variants of panicking methods
- **ALWAYS** prefer `TryFrom<T>` over `fn new(T) -> Result` for fallible constructors

## Parsing

- **ALWAYS** implement `FromStr` for types parsed from human-readable text

## Trait Design

- **ALWAYS** prefer associated types when determined by implementor — generic params when multiple impls per type valid
- **NEVER** implement `Deref`/`DerefMut` for field delegation — reserved for smart pointer types

## Display & Equality

- **NEVER** implement `Display` by delegating to `Debug`
- **ALWAYS** implement `PartialEq`/`Eq` manually for entity types where identity (ID) determines equality
- **ALWAYS** prefer extension traits over standalone functions for adding methods to foreign types

## Error Type Scoping

- **NEVER** shadow `std::result::Result` in modules using multiple error types
