# §23 — ASGI

## When to Use

- Deploying async Python web applications (FastAPI, Starlette, Django 4+)
- Need WebSocket support, background tasks, or streaming responses
- Application lifecycle management (connection pools, caches at startup/shutdown)
- Writing custom middleware at the ASGI protocol level

## How It Works

ASGI (Asynchronous Server Gateway Interface) is the async successor to WSGI. It connects async frameworks to async servers (Uvicorn, Hypercorn).

**Lifespan protocol:** Manages application startup/shutdown — initialize connection pools, caches; clean up on shutdown.

**ASGI app signature:** `async def app(scope: dict, receive: Callable, send: Callable) -> None`

## Code Snippet

```python
from contextlib import asynccontextmanager
from typing import AsyncIterator
from fastapi import FastAPI

# Lifespan — application startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    # Startup
    app.state.db_pool = await create_pool()
    app.state.http_client = httpx.AsyncClient()
    yield  # Application runs here
    # Shutdown
    await app.state.http_client.aclose()
    await app.state.db_pool.close()

app = FastAPI(lifespan=lifespan)

# Raw ASGI app (for understanding the protocol)
async def raw_app(scope: dict, receive, send) -> None:
    if scope["type"] == "http":
        body = b""
        while True:
            message = await receive()
            body += message.get("body", b"")
            if not message.get("more_body"):
                break

        await send({
            "type": "http.response.start",
            "status": 200,
            "headers": [(b"content-type", b"application/json")],
        })
        await send({
            "type": "http.response.body",
            "body": json.dumps({"received": len(body)}).encode(),
        })
```

```bash
# Production deployment
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4

# With uv
uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

## Notes

- Use `lifespan` context manager, not deprecated `@app.on_event("startup")`
- Uvicorn is the standard ASGI server — `--workers N` for multi-process deployment
- ASGI supports HTTP, WebSocket, and lifespan scope types
- Pure ASGI middleware is faster than Starlette's `BaseHTTPMiddleware`
- Hypercorn is an alternative ASGI server with HTTP/2 and Trio support
