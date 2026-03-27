# §6 — Context Managers and Resource Management

## When to Use

- Resources (files, connections, locks, transactions) must be released even on exception
- Async resources (HTTP clients, DB sessions, Redis connections)
- Dynamic/variable number of resources to manage
- Application-scoped resource lifecycle (startup/shutdown)

## How It Works

Context managers (`with` statement) tie resource lifetime to a lexical scope. Three approaches:

- **`@contextmanager`** / **`@asynccontextmanager`**: Generator-based — simplest for most cases
- **Class-based** (`__enter__`/`__exit__`): When the context manager needs state accessed after `with` exits
- **`ExitStack`** / **`AsyncExitStack`**: For dynamic/variable number of resources

`__exit__` returning `True` suppresses exceptions — almost never what you want.

## Code Snippet

```python
from contextlib import contextmanager, asynccontextmanager, ExitStack, AsyncExitStack
from typing import AsyncIterator, Iterator

# Generator-based — simplest
@contextmanager
def db_transaction(conn: Connection) -> Iterator[Transaction]:
    tx = conn.begin()
    try:
        yield tx
        tx.commit()
    except Exception:
        tx.rollback()
        raise

# Async version
@asynccontextmanager
async def managed_client(base_url: str) -> AsyncIterator[httpx.AsyncClient]:
    async with httpx.AsyncClient(base_url=base_url) as client:
        yield client

# Class-based — when you need state after with exits
class Timer:
    def __enter__(self) -> "Timer":
        self.start = time.perf_counter()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> bool:
        self.elapsed = time.perf_counter() - self.start
        return False  # don't suppress exceptions

# ExitStack — dynamic number of resources
def process_files(paths: list[str]) -> list[str]:
    with ExitStack() as stack:
        files = [stack.enter_context(open(p)) for p in paths]
        return [f.read() for f in files]

# AsyncExitStack — async dynamic resources
async def managed_connections(urls: list[str]) -> list[Client]:
    async with AsyncExitStack() as stack:
        return [
            await stack.enter_async_context(connect(url))
            for url in urls
        ]
```

## Notes

- Prefer `@contextmanager` / `@asynccontextmanager` for most cases — less boilerplate than class-based
- `ExitStack` for variable number of resources — all cleaned up on exit
- `__exit__` returning `True` suppresses exceptions — almost never what you want; return `False`
- For application lifecycle (connection pools, caches), use FastAPI's lifespan context manager
