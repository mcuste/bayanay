# §11 — Structured Concurrency (TaskGroup)

## When to Use

- Running multiple concurrent async operations that should be treated as a unit
- Need automatic cancellation of sibling tasks when one fails
- Replacing `asyncio.gather()` with proper error handling
- Fan-out with bounded concurrency (TaskGroup + Semaphore)
- Need timeout on a group of concurrent operations

## How It Works

`TaskGroup` (PEP 654, Python 3.11+) implements *structured concurrency*:

1. **No orphan tasks** — all tasks complete (or are cancelled) before `async with` exits
2. **Automatic cancellation** — if one task fails, all siblings are cancelled
3. **All errors surface** — failures collected into `ExceptionGroup`
4. **Clean shutdown** — waits for cancelled tasks to finish cleanup

| Feature        | `TaskGroup` (3.11+)              | `asyncio.gather()`                   |
|----------------|----------------------------------|--------------------------------------|
| On first failure | Cancels all siblings            | Continues (or mixed results)         |
| Error reporting  | `ExceptionGroup` with ALL failures | First exception only              |
| Orphan tasks     | Impossible                      | Easy to create                       |
| Use case         | **Default choice**              | Legacy, `return_exceptions=True`     |

## Code Snippet

```python
import asyncio

# Basic structured concurrency
async def fetch_all_data() -> tuple[Users, Orders, Products]:
    async with asyncio.TaskGroup() as tg:
        users_task = tg.create_task(fetch_users())
        orders_task = tg.create_task(fetch_orders())
        products_task = tg.create_task(fetch_products())
    # Only reached if ALL tasks succeed
    return users_task.result(), orders_task.result(), products_task.result()

# Fan-out with bounded concurrency
async def process_urls(urls: list[str], max_concurrent: int = 10) -> list[Response]:
    semaphore = asyncio.Semaphore(max_concurrent)
    results: list[Response] = []

    async def bounded_fetch(url: str) -> None:
        async with semaphore:
            result = await fetch(url)
            results.append(result)

    async with asyncio.TaskGroup() as tg:
        for url in urls:
            tg.create_task(bounded_fetch(url))
    return results

# Timeout with TaskGroup
async def with_timeout() -> Data:
    async with asyncio.timeout(30):  # 3.11+
        async with asyncio.TaskGroup() as tg:
            tg.create_task(slow_operation())

# Error handling with except*
async def resilient_fetch() -> None:
    try:
        async with asyncio.TaskGroup() as tg:
            tg.create_task(fetch_users())
            tg.create_task(fetch_orders())
    except* ValueError as eg:
        for exc in eg.exceptions:
            logger.warning(f"Validation: {exc}")
    except* ConnectionError as eg:
        for exc in eg.exceptions:
            logger.error(f"Connection: {exc}")
```

## Notes

- `TaskGroup` is the default for concurrent async operations — use `gather()` only for backward compat
- `asyncio.timeout()` (3.11+) is preferred over `asyncio.wait_for()` for timeouts
- Fan-out with `Semaphore` prevents overwhelming external services
- Dropped `create_task()` handles (without TaskGroup) detach the task — exceptions are lost until GC
- `except*` clauses are not mutually exclusive — multiple can match different subgroups
