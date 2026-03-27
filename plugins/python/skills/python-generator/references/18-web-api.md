# §18 — Web APIs (FastAPI)

## When to Use

- Building production web APIs with automatic validation, serialization, and documentation
- Need type-driven request validation and OpenAPI docs
- Dependency injection for database sessions, services, auth
- Lifespan management for connection pools, caches

## How It Works

FastAPI provides routing, Pydantic-based validation, `Depends` DI, automatic OpenAPI docs, middleware, exception handlers, and lifespan management.

**Key patterns:**
- **Lifespan** context manager for startup/shutdown (replaces `@app.on_event`)
- **Router-based organization** with `APIRouter` for modular routes
- **Pydantic models** for request/response with `from_attributes=True`
- **`Annotated[T, Depends(fn)]`** for type-safe dependency injection
- **Exception handlers** mapping domain errors to HTTP responses

## Code Snippet

```python
from contextlib import asynccontextmanager
from typing import Annotated, AsyncIterator
from fastapi import FastAPI, APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, ConfigDict, EmailStr

# Lifespan — startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    pool = await asyncpg.create_pool(settings.database_url)
    redis = await aioredis.from_url(settings.redis_url)
    app.state.pool = pool
    app.state.redis = redis
    yield
    await pool.close()
    await redis.close()

app = FastAPI(title="My API", lifespan=lifespan)

# Request/Response models
class CreateUserRequest(BaseModel):
    name: str
    email: EmailStr
    role: Literal["admin", "user"] = "user"

class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    email: str
    created_at: datetime

# Router with dependencies
router = APIRouter()

@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_user(
    body: CreateUserRequest,
    service: Annotated[UserService, Depends(get_user_service)],
) -> UserResponse:
    user = await service.create(body.name, body.email, body.role)
    return UserResponse.model_validate(user)

app.include_router(router, prefix="/users", tags=["users"])

# Exception handlers
from fastapi import Request
from fastapi.responses import JSONResponse

@app.exception_handler(NotFoundError)
async def not_found_handler(request: Request, exc: NotFoundError) -> JSONResponse:
    return JSONResponse(status_code=404, content={"error": "not_found", "detail": str(exc)})

@app.exception_handler(DomainError)
async def domain_error_handler(request: Request, exc: DomainError) -> JSONResponse:
    return JSONResponse(status_code=422, content={"error": "domain_error", "detail": str(exc)})

# Pure ASGI middleware (prefer over BaseHTTPMiddleware for performance)
class RequestIdMiddleware:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] == "http":
            scope.setdefault("state", {})["request_id"] = str(uuid.uuid4())
        await self.app(scope, receive, send)
```

## Notes

- `Annotated[T, Depends(fn)]` is the modern DI syntax (not positional `Depends()`)
- Generator dependencies (`yield`) — cleanup runs after response is sent
- `app.dependency_overrides[get_db] = mock_db` for test overrides
- Prefer pure ASGI middleware over `BaseHTTPMiddleware` for performance
- `from_attributes=True` enables constructing Pydantic models from ORM objects
- Use `lifespan` context manager, not deprecated `@app.on_event("startup")`
