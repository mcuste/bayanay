# §10 — Async Python Core Model

## When to Use

- I/O-bound services (web servers, API clients, database access) that spend most time waiting
- Need to multiplex thousands of concurrent I/O operations on a single thread
- Sequential `await` calls that could run concurrently — `asyncio.gather()` or `TaskGroup`

## How It Works

`async`/`await` (PEP 492) provides cooperative multitasking. A single thread multiplexes I/O operations via an event loop.

**Key mental model:** `await` is a *yield point*. The current coroutine suspends, the event loop runs another ready coroutine. A coroutine that doesn't `await` blocks the entire loop.

**Sequential vs concurrent:**
- Sequential: `a = await f(); b = await g()` — total time = sum
- Concurrent: `a, b = await asyncio.gather(f(), g())` — total time = max
- Structured: `TaskGroup` (3.11+) — concurrent with proper error handling

## Code Snippet

```python
import asyncio
import httpx

async def fetch_data(url: str) -> bytes:
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        return response.content

async def main() -> None:
    # Sequential — total time = sum of all waits
    a = await fetch_data("https://api1.example.com")
    b = await fetch_data("https://api2.example.com")

    # Concurrent — total time = max wait
    a, b = await asyncio.gather(
        fetch_data("https://api1.example.com"),
        fetch_data("https://api2.example.com"),
    )

    # Structured concurrency (3.11+) — preferred
    async with asyncio.TaskGroup() as tg:
        task_a = tg.create_task(fetch_data("https://api1.example.com"))
        task_b = tg.create_task(fetch_data("https://api2.example.com"))
    a, b = task_a.result(), task_b.result()

# Blocking call in async context
async def read_file_async(path: str) -> str:
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(None, Path(path).read_text)
```

## Notes

- `await` is a yield point — a coroutine that doesn't `await` blocks the entire loop
- Use `TaskGroup` (3.11+) over `asyncio.gather()` — proper cancellation and error handling
- CPU-bound work in async code → `loop.run_in_executor(None, fn)` for threads or `ProcessPoolExecutor` for processes
- `asyncio.Lock` for shared mutable state across async tasks — or restructure to avoid shared state
- Never call `asyncio.run()` inside an already-running event loop
