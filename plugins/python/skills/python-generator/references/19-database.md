# §19 — SQLAlchemy 2.0 Database Access

## When to Use

- Database access with type-safe queries and modern Python type hints
- Async database operations with `asyncpg` or `aiosqlite`
- ORM-based model definitions with `Mapped` types
- Repository pattern implementations for hexagonal architecture

## How It Works

SQLAlchemy 2.0 provides:
- `Mapped[T]` + `mapped_column()` — type-checked column definitions
- `select()` — composable, type-safe queries (replaces `session.query()`)
- `async_sessionmaker` + `AsyncSession` — first-class async support
- `expire_on_commit=False` — critical for async to avoid lazy-load exceptions

## Code Snippet

```python
from sqlalchemy import ForeignKey, String, select, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from datetime import datetime
from decimal import Decimal

# Model definition (2.0 style)
class Base(DeclarativeBase):
    pass

class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    email: Mapped[str] = mapped_column(String(255), unique=True)
    is_active: Mapped[bool] = mapped_column(default=True)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)

    orders: Mapped[list["Order"]] = relationship(back_populates="user", lazy="selectin")

class Order(Base):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    total: Mapped[Decimal] = mapped_column()
    status: Mapped[str] = mapped_column(String(20), default="pending")

    user: Mapped["User"] = relationship(back_populates="orders")

# Async engine and session
engine = create_async_engine(
    "postgresql+asyncpg://user:pass@localhost/db",
    pool_size=20,
    max_overflow=10,
)
async_session_factory = async_sessionmaker(engine, expire_on_commit=False)

# Type-safe queries (2.0 style)
async def get_active_users(session: AsyncSession) -> list[User]:
    stmt = select(User).where(User.is_active == True).order_by(User.name)
    result = await session.execute(stmt)
    return list(result.scalars().all())

async def get_user_order_totals(session: AsyncSession) -> list[tuple[str, Decimal]]:
    stmt = (
        select(User.name, func.sum(Order.total).label("total"))
        .join(Order)
        .where(User.is_active == True)
        .group_by(User.name)
        .having(func.sum(Order.total) > 100)
    )
    result = await session.execute(stmt)
    return list(result.all())

# Repository using async session
class SQLAlchemyUserRepo:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get(self, user_id: int) -> User | None:
        return await self._session.get(User, user_id)

    async def save(self, user: User) -> None:
        self._session.add(user)
        await self._session.flush()
```

## Notes

- Use `select()` not `session.query()` — 1.x style is deprecated
- `Mapped[T]` annotations — mypy/pyright understand the column types
- `expire_on_commit=False` is critical for async — prevents lazy-load exceptions
- Explicit `selectin` / `joinedload` — no implicit lazy loading (N+1 prevention)
- `flush()` gets generated IDs without committing the transaction
