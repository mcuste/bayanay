# §12 — Concurrency Models

## When to Use

- **asyncio**: I/O-bound, many connections (web servers, API clients, DB access)
- **threading**: I/O-bound, simple scripts with few concurrent operations
- **multiprocessing / ProcessPoolExecutor**: CPU-bound, parallelizable work
- **asyncio + ProcessPoolExecutor**: CPU-bound work within an async application
- **Free-threaded Python (3.13+)**: True thread parallelism, experimental

## How It Works

| Workload                    | Tool                                      | Why                                              |
|-----------------------------|-------------------------------------------|--------------------------------------------------|
| I/O-bound, many connections | `asyncio`                                 | Single thread, thousands of concurrent I/O ops   |
| I/O-bound, simple scripts   | `threading`                               | Simpler than async for few concurrent operations |
| CPU-bound, parallelizable   | `multiprocessing` / `ProcessPoolExecutor` | Bypasses GIL with separate processes             |
| CPU-bound + I/O             | `asyncio` + `ProcessPoolExecutor`         | Async for I/O, process pool for CPU              |
| CPU-bound, shared memory    | Free-threaded Python (3.13+)              | True parallelism without process overhead        |

## Code Snippet

```python
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor
import asyncio

# Sync-to-async bridge — blocking code in async context
async def read_file_async(path: str) -> str:
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(None, Path(path).read_text)

# ThreadPoolExecutor for I/O-bound batch operations
def download_all(urls: list[str]) -> list[bytes]:
    with ThreadPoolExecutor(max_workers=10) as pool:
        return list(pool.map(download, urls))

# ProcessPoolExecutor for CPU-bound work in async
async def compute_heavy(data: list[float]) -> float:
    loop = asyncio.get_running_loop()
    with ProcessPoolExecutor() as pool:
        return await loop.run_in_executor(pool, heavy_computation, data)

# Free-threaded Python (3.13t) — true parallelism
from threading import Thread

def compute_chunk(data: list[float]) -> float:
    return sum(math.sin(x) * math.cos(x) for x in data)

# With 3.13t, these run in parallel on multiple cores
threads = [Thread(target=compute_chunk, args=(chunk,)) for chunk in chunks]
for t in threads: t.start()
for t in threads: t.join()
```

## Notes

- GIL prevents true thread parallelism for CPU-bound work (except 3.13t free-threaded build)
- `run_in_executor(None, fn)` uses the default ThreadPoolExecutor — good for blocking I/O in async
- Free-threaded Python (3.13t): ~5-10% single-threaded slowdown, not yet default, most major packages support it
- `multiprocessing` remains more battle-tested for CPU parallelism than free-threaded mode
- Never run CPU-bound work directly in async tasks — it blocks the event loop
