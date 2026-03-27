# §5 — Structural Pattern Matching

## When to Use

- Complex conditional dispatch — nested `if/elif` chains that inspect type, shape, and value
- Destructuring data structures (dataclasses, dicts, lists, tuples)
- JSON/API response parsing with varying shapes
- Replacing verbose `isinstance` chains for 3+ types

## How It Works

`match/case` (PEP 634, Python 3.10+) provides destructuring dispatch. Pattern types: literal, capture, class, sequence, mapping, OR, guard, walrus.

**When NOT to use:** Simple value dispatch → dict lookup is faster. Type check for 1-2 types → `isinstance()`. Match is not exhaustive by default (pyright can warn with `type` unions).

## Code Snippet

```python
from dataclasses import dataclass

@dataclass
class Click:
    x: int
    y: int

@dataclass
class KeyPress:
    key: str
    modifiers: list[str]

@dataclass
class Quit:
    pass

type Event = Click | KeyPress | Quit

def handle_event(event: Event) -> str:
    match event:
        case Click(x, y) if x < 0 or y < 0:
            return "Out of bounds click"
        case Click(x=x, y=y):
            return f"Clicked at ({x}, {y})"
        case KeyPress(key="q", modifiers=["ctrl"]):
            return "Quit shortcut"
        case KeyPress(key=k):
            return f"Key: {k}"
        case Quit():
            return "Goodbye"

# JSON / API response parsing
def parse_api_response(data: dict) -> Result:
    match data:
        case {"status": "ok", "data": {"users": [*users]}}:
            return Success(users=[User(**u) for u in users])
        case {"status": "error", "code": code, "message": msg}:
            return Failure(code=code, message=msg)
        case {"status": "ok", "data": None}:
            return Success(users=[])
        case _:
            raise ValueError(f"Unexpected response shape: {data!r}")

# Simple value dispatch — dict lookup is better
actions = {"start": start_handler, "stop": stop_handler}
actions[cmd]()  # faster and more Pythonic than match for this
```

## Notes

- `case x:` (bare name) always matches and binds — it's a capture, not a comparison
- Dict matching ignores extra keys — `case {"type": "error"}:` matches `{"type": "error", "extra": 1}`
- Sequence matching: `case [first, *rest]:` destructures lists/tuples
- Guard: `case x if x > 0:` adds a condition after the structural match
- `case str() as s:` — type check + bind (walrus pattern)
- pyright can check exhaustiveness when using `type` union aliases
