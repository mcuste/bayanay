# §3 — Data Modeling (Dataclasses, Attrs, Pydantic)

## When to Use

- Modeling data-holding objects — avoid hand-written `__init__`, `__repr__`, `__eq__`
- **Internal domain objects:** `@dataclass(frozen=True, slots=True)` — zero dependencies
- **Internal with validation:** `attrs` — mature, fast validator ecosystem
- **External boundaries (HTTP, config):** Pydantic v2 — serialization, schema generation, runtime validation

## How It Works

| Feature               | `dataclass` (stdlib)  | `attrs`                | `Pydantic v2`                     |
|-----------------------|-----------------------|------------------------|------------------------------------|
| Validation            | None built-in         | `@field_validator`     | Full, schema-based                 |
| Performance           | Fast (no overhead)    | Fast                   | Fast (Rust core in v2)             |
| Immutability          | `frozen=True`         | `frozen=True`          | `frozen=True` (model_config)       |
| Serialization         | None                  | `attrs.asdict()`       | `.model_dump()`, `.model_dump_json()` |
| Runtime type coercion | No                    | Optional               | Yes, by default                    |
| JSON Schema           | No                    | No                     | Yes, automatic                     |
| Slots                 | `slots=True` (3.10+)  | `slots=True` (default) | Always slots                       |

## Code Snippet

```python
from dataclasses import dataclass, field

# Dataclass — the stdlib standard
@dataclass(frozen=True, slots=True)
class Point:
    x: float
    y: float

@dataclass(slots=True)
class Config:
    host: str
    port: int = 8080
    tags: list[str] = field(default_factory=list)

    def __post_init__(self) -> None:
        if self.port < 0 or self.port > 65535:
            raise ValueError(f"Invalid port: {self.port}")

# Pydantic v2 — boundary layer
from pydantic import BaseModel, ConfigDict, field_validator

class CreateUserRequest(BaseModel):
    model_config = ConfigDict(frozen=True, strict=True)

    name: str
    email: str
    age: int

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        if "@" not in v:
            raise ValueError("Invalid email format")
        return v.lower()

# Attrs — middle ground
import attrs

@attrs.define
class Measurement:
    value: float = attrs.field(validator=attrs.validators.gt(0))
    unit: str = attrs.field(validator=attrs.validators.in_(["m", "km", "mi"]))
    timestamp: float = attrs.Factory(time.time)
```

## Notes

- **Always use `slots=True`** (3.10+): reduces memory ~30%, prevents accidental attribute assignment
- **Always use `frozen=True`** for value objects — immutability by default, mutable only when justified
- Pydantic at boundaries, dataclasses internally — avoid coupling domain to serialization library
- Use `field(default_factory=list)` for mutable defaults — never `tags: list[str] = []`
- `@attrs.define` uses `slots=True` by default and generates `__init__`, `__repr__`, `__eq__`
