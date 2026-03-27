# §2 — Protocols (Structural Typing)

## When to Use

- Function parameter needs "anything with `.read()`" — without requiring inheritance from a specific base class
- Decoupling domain logic from infrastructure — define what the domain needs as a Protocol, let adapters satisfy it
- Third-party types that already have the right methods — Protocol matches them without modification
- Generic repository/service pattern — `Protocol[T_co]` with covariant type parameter

## How It Works

`Protocol` (PEP 544, Python 3.8+) enables *structural subtyping* — "if it has the right methods, it qualifies." No registration or inheritance required. This is Python's equivalent of Go interfaces.

**Protocol vs ABC:** Default to Protocol for function parameters. Use ABC only when you need shared default implementation (template method pattern) or mandatory registration.

**`@runtime_checkable`:** Adds `isinstance` support but only checks method *existence*, not signatures — don't rely on it for validation.

**Protocol composition:** Combine protocols via multiple inheritance of Protocol subclasses.

## Code Snippet

```python
from typing import Protocol, runtime_checkable, TypeVar

# Simple protocol
class Readable(Protocol):
    def read(self, n: int = -1) -> bytes: ...

class Closeable(Protocol):
    def close(self) -> None: ...

# Protocol composition
class ReadableAndCloseable(Readable, Closeable, Protocol): ...

def process(source: Readable) -> bytes:
    return source.read()
# Works with ANY object that has .read(n) -> bytes — no inheritance needed

# Generic protocol
T_co = TypeVar("T_co", covariant=True)

class Repository(Protocol[T_co]):
    def get(self, id: int) -> T_co | None: ...
    def list(self, limit: int = 100) -> list[T_co]: ...

# Any class with matching methods satisfies Repository[User]
class SQLUserRepo:
    def get(self, id: int) -> User | None: ...
    def list(self, limit: int = 100) -> list[User]: ...

def get_active_users(repo: Repository[User]) -> list[User]:
    return [u for u in repo.list() if u.is_active]

# runtime_checkable — limited, checks method existence only
@runtime_checkable
class Serializable(Protocol):
    def to_json(self) -> str: ...

isinstance(obj, Serializable)  # True if obj has .to_json method
```

## Notes

- Protocol has no runtime overhead (static analysis only) — `@runtime_checkable` adds minimal `isinstance` cost
- Protocol methods with default implementations are allowed — the implementor still only needs matching signatures
- Prefer Protocol for function parameters; ABC when shared implementation is needed
- Don't extract a Protocol for a single implementation — wait for a second real one
- `@runtime_checkable` only checks method *existence*, not argument types or return types
