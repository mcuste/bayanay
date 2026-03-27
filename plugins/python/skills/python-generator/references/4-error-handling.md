# §4 — Error Handling

## When to Use

- Designing error hierarchy for a module/package — one base exception, typed subclasses
- Multiple concurrent tasks failing — `ExceptionGroup` + `except*` (3.11+)
- Adding operational context to propagating errors — `e.add_note()` (3.11+)
- Caller needs to distinguish failure modes — typed exception subclasses with structured data

## How It Works

**Hierarchy:** One base exception per package/application. Subclasses carry structured data (not just message strings). Subclass from the most specific stdlib exception when it fits.

**ExceptionGroup (3.11+):** Bundles multiple concurrent exceptions. `except*` selectively catches subsets — multiple `except*` clauses can match different subgroups (they are not mutually exclusive). Unmatched exceptions propagate in a new `ExceptionGroup`.

**Exception notes (3.11+):** `e.add_note()` adds context without creating wrapper exceptions. Useful for operational context (request ID, batch info).

**Cause chain:** Always use `raise NewError(...) from original_error` to preserve the original cause. Never bare `raise` a new exception that discards the original.

## Code Snippet

```python
# Module-level exception hierarchy
class AppError(Exception):
    """Base for all application errors."""

class ValidationError(AppError):
    def __init__(self, errors: dict[str, str]) -> None:
        self.errors = errors
        super().__init__(f"Validation failed: {errors}")

class NotFoundError(AppError):
    def __init__(self, entity: str, id: object) -> None:
        self.entity = entity
        self.id = id
        super().__init__(f"{entity} {id} not found")

class ExternalServiceError(AppError):
    pass

# ExceptionGroup and except* (3.11+)
import asyncio

async def main() -> None:
    try:
        async with asyncio.TaskGroup() as tg:
            tg.create_task(fetch_users())     # raises ValueError
            tg.create_task(fetch_orders())    # raises ConnectionError
            tg.create_task(fetch_products())  # succeeds
    except* ValueError as eg:
        for exc in eg.exceptions:
            logger.warning(f"Validation error: {exc}")
    except* ConnectionError as eg:
        for exc in eg.exceptions:
            logger.error(f"Connection failed: {exc}")
    # Both except* clauses can run — not mutually exclusive

# Exception notes (3.11+)
try:
    process_batch(items)
except ValidationError as e:
    e.add_note(f"Occurred while processing batch {batch_id}")
    e.add_note(f"Items in batch: {len(items)}")
    raise  # notes visible in traceback

# Cause chain — always preserve the original
try:
    result = parse_config(data)
except json.JSONDecodeError as e:
    raise ConfigError("Invalid config format") from e
```

## Notes

- `except*` clauses are not mutually exclusive — multiple can match different subgroups
- `except*` cannot be mixed with regular `except` in the same `try` block
- Log when handling errors, not when propagating — avoids duplicate log entries
- Carry structured data in exceptions, not just message strings
- Use `raise ... from err` to preserve cause chains — always
