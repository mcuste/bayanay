# §1 — Type-Driven Design

## When to Use

- Function signatures use bare `str`, `int`, `dict` for domain concepts — callers don't know what shape the data is
- Validation logic is scattered throughout the codebase instead of enforced once at the boundary
- A primitive represents a distinct domain concept (`UserId` vs `OrderId`) and should not be mixed
- Building a method chain API that returns `self` — need the return type to work correctly with subclasses

## How It Works

Use the modern type system (PEP 484+) as an *architectural tool*, not just documentation. Type hints enable static analysis (mypy/pyright), IDE support, and runtime validation (via Pydantic). The goal is to make invalid states harder to construct.

**Parse, don't validate:** Validate at system boundaries (HTTP, config, CLI) using Pydantic. Internally, types carry proof of validity — no re-validation needed.

**NewType:** Zero-cost static wrapper. `NewType("UserId", int)` creates a callable that returns `int` at runtime but is a distinct type for static analysis. Cannot use `isinstance` — for runtime enforcement, use a dataclass or Pydantic model wrapper instead.

**Self type (3.11+, PEP 673):** Annotate methods returning `self` so subclasses inherit the correct return type.

**Type parameter syntax (3.12+, PEP 695):** `type Vector[T] = list[T]` replaces `TypeAlias + TypeVar` boilerplate. `def first[T](items: list[T]) -> T` replaces explicit `TypeVar()` for generic functions.

## Code Snippet

```python
from typing import NewType, Self
from pydantic import BaseModel, EmailStr, field_validator

# NewType — lightweight semantic wrapper (static only, zero runtime cost)
UserId = NewType("UserId", int)
OrderId = NewType("OrderId", int)

def get_user(user_id: UserId) -> User: ...

uid = UserId(42)
oid = OrderId(42)
get_user(oid)  # mypy error: expected UserId, got OrderId
get_user(uid)  # ok

# Parse, don't validate — Pydantic at the boundary
class EmailAddress(BaseModel, frozen=True):
    value: EmailStr

class UserRegistration(BaseModel):
    email: EmailAddress
    username: str
    age: int

    @field_validator("age")
    @classmethod
    def validate_age(cls, v: int) -> int:
        if v < 13:
            raise ValueError("Must be at least 13")
        return v

# Parse once at boundary:
registration = UserRegistration.model_validate(request_body)
# Internally — type proves validity:
send_welcome_email(registration.email)  # EmailAddress, not str

# Self type (3.11+) — return type follows subclass
class Builder:
    def with_name(self, name: str) -> Self:
        self.name = name
        return self

# Type parameter syntax (3.12+) — replaces TypeVar boilerplate
type Vector[T] = list[T]
type Matrix[T: (int, float)] = list[Vector[T]]

def first[T](items: list[T]) -> T:
    return items[0]

# Built-in generics and union syntax (3.10+)
def process(items: list[str | int], *, limit: int = 100) -> dict[str, int]: ...
```

## Notes

- `NewType` is invisible at runtime (`isinstance` check not possible) — for runtime enforcement use Pydantic models or `@dataclass` wrappers
- Use `X | Y` union syntax (3.10+) instead of `Union[X, Y]`
- Use built-in `list[T]`, `dict[K, V]` (3.9+) instead of `typing.List`, `typing.Dict`
- `type` alias syntax (3.12+) is preferred over `TypeAlias` when targeting 3.12+
