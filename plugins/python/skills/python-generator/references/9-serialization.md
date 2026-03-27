# §9 — Serialization Architecture

## When to Use

- API boundary serialization (HTTP request/response) — Pydantic v2 as default
- Configuration loading — Pydantic v2 with `BaseSettings`
- High-throughput message processing (measured bottleneck) — msgspec
- Wire format differs from domain type — separate wire types + conversion at boundary

## How It Works

**Pydantic v2** (Rust-powered core): Standard for web APIs and config. Full validation, JSON Schema generation, `model_validate()` from dicts/ORM objects, `model_dump_json()` for fast serialization.

**msgspec**: 10-75x faster than Pydantic v2 for encode/decode. `msgspec.Struct` with `frozen=True`. Supports JSON, MessagePack, TOML, YAML. Use when serialization is a measured bottleneck.

**Principle:** Use Pydantic at system boundaries, plain dataclasses internally. Don't couple domain objects to a serialization library.

## Code Snippet

```python
# Pydantic v2 — standard for API boundaries
from pydantic import BaseModel, ConfigDict, computed_field
from datetime import datetime

class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    email: str
    created_at: datetime

    @computed_field
    @property
    def display_name(self) -> str:
        return f"{self.name} <{self.email}>"

user = UserResponse.model_validate({"id": 1, "name": "Alice", ...})  # from dict
user = UserResponse.model_validate(db_user)  # from ORM object
json_bytes = user.model_dump_json()  # fast serialization
schema = UserResponse.model_json_schema()  # JSON Schema

# msgspec — high-performance alternative
import msgspec

class User(msgspec.Struct, frozen=True):
    id: int
    name: str
    email: str

data = msgspec.json.encode(User(1, "Alice", "alice@example.com"))
user = msgspec.json.decode(data, type=User)
msgspec.msgpack.encode(user)  # also MessagePack, TOML, YAML
```

## Notes

- Pydantic v2 is the default choice — huge ecosystem (FastAPI, SQLAlchemy integration)
- msgspec only when serialization performance is a measured bottleneck
- `from_attributes=True` (ConfigDict) enables construction from ORM objects
- `model_dump_json()` is faster than `json.dumps(model.model_dump())` — uses Rust core
- Separate API models (Pydantic) from domain models (dataclasses) — convert at boundary
