# API Design

## Closure Bounds

- [api-least-closure] ALWAYS use least restrictive closure bound: `Fn` → `FnMut` → `FnOnce`
- [api-impl-fn] ALWAYS prefer `impl Fn(T) -> R` over `Box<dyn Fn(T) -> R>` unless closure must be stored

## Slice Patterns

- [api-slice-pattern] ALWAYS prefer slice patterns (`[first, rest @ ..]`) over index access for known-length slices

## Iterator & Collection Params

- [api-into-iterator] ALWAYS prefer `impl IntoIterator<Item = T>` over `&[T]` for params that only iterate
- [api-asref-path] ALWAYS prefer `impl AsRef<Path>` over `&Path` for read-only params

## Naming Conventions

- [api-try-prefix] ALWAYS use `try_` prefix for fallible variants of panicking methods
- [api-tryfrom] ALWAYS prefer `TryFrom<T>` over `fn new(T) -> Result` for fallible constructors

## Parsing

- [api-fromstr] ALWAYS implement `FromStr` for types parsed from human-readable text

## Trait Design

- [api-assoc-type] ALWAYS prefer associated types when determined by implementor — generic params when multiple impls per type valid
- [api-no-deref-delegate] NEVER implement `Deref`/`DerefMut` for field delegation — reserved for smart pointer types

## Display & Equality

- [api-no-display-debug] NEVER implement `Display` by delegating to `Debug`
- [api-entity-eq] ALWAYS implement `PartialEq`/`Eq` manually for entity types where identity (ID) determines equality
- [api-ext-trait] ALWAYS prefer extension traits over standalone functions for adding methods to foreign types

## Error Type Scoping

- [api-no-result-shadow] NEVER shadow `std::result::Result` in modules using multiple error types
