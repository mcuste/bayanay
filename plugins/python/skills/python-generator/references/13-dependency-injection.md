# §13 — Dependency Injection

## When to Use

- Hard-coded dependencies make code untestable — `UserService` directly constructs `PostgresRepo`
- Need to swap implementations (real DB vs in-memory for tests)
- Wiring dependencies at application startup

## How It Works

**Constructor injection** is the default — no magic, no framework, fully type-checked. Pass Protocol-typed dependencies via `__init__`, wire in a composition root at startup.

**FastAPI `Depends`**: Use within FastAPI — auto-resolves dependency graph, per-request caching, generator cleanup, overridable in tests.

**Composition root**: One place at startup that knows about all concrete implementations. The only module that imports infrastructure.

## Code Snippet

```python
from typing import Protocol

# Protocols define what the domain needs
class UserRepository(Protocol):
    async def get(self, user_id: int) -> User | None: ...
    async def save(self, user: User) -> None: ...

class EmailSender(Protocol):
    async def send(self, to: str, subject: str, body: str) -> None: ...

# Service depends on Protocols, not concrete implementations
class UserService:
    def __init__(self, repo: UserRepository, email: EmailSender) -> None:
        self._repo = repo
        self._email = email

    async def register(self, name: str, email: str) -> User:
        user = User(name=name, email=email)
        await self._repo.save(user)
        await self._email.send(email, "Welcome!", f"Hi {name}")
        return user

# Production wiring
service = UserService(repo=PostgresUserRepo(pool), email=SMTPSender(config))
# Test wiring
service = UserService(repo=InMemoryUserRepo(), email=FakeEmailSender())

# FastAPI Depends — framework-level DI
from fastapi import Depends
from typing import Annotated

async def get_db() -> AsyncIterator[AsyncSession]:
    async with async_session_factory() as session:
        yield session

async def get_user_repo(db: Annotated[AsyncSession, Depends(get_db)]) -> UserRepository:
    return SQLAlchemyUserRepo(db)

@app.get("/users/{user_id}")
async def get_user(
    user_id: int,
    repo: Annotated[UserRepository, Depends(get_user_repo)],
) -> UserResponse:
    user = await repo.get(user_id)
    if user is None:
        raise HTTPException(404)
    return UserResponse.model_validate(user)

# Composition root — wire everything at startup
def create_app() -> FastAPI:
    pool = create_connection_pool(settings.database_url)
    user_repo = PostgresUserRepo(pool)
    user_service = UserService(repo=user_repo, cache=RedisCache(redis))
    app = FastAPI(lifespan=lifespan(pool))
    app.include_router(create_user_router(user_service))
    return app
```

## Notes

- Constructor injection is sufficient for most Python applications — no DI framework needed
- FastAPI `Depends()` is well-designed — use it within FastAPI, don't build your own
- `dependency-injector` library for complex projects with container-based DI and scopes
- Avoid service locator pattern (global registry) — it hides dependencies
- `app.dependency_overrides[get_db] = mock_db` for FastAPI test overrides
