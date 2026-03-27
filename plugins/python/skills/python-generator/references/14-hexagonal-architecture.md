# §14 — Hexagonal Architecture (Ports & Adapters)

## When to Use

- Infrastructure (DB, HTTP, filesystem) bleeding into domain logic
- Need to test domain logic without spinning up real infrastructure
- Need to swap implementations (in-memory for tests, real DB for production)
- Team project, long-lived codebase

## How It Works

Three layers:

1. **Domain / Application Core**: Pure business logic, dataclasses, no infrastructure imports
2. **Ports (interfaces)**: Protocol definitions — what the domain needs
3. **Adapters (outer)**: Implementations — infrastructure connecting to ports

**Dependency rule:** Source code dependencies point *inward*. Domain imports nothing from adapters. Adapters import from domain/ports. Enforced by convention or `import-linter`.

```
src/
├── domain/              # Core — no external dependencies
│   ├── models.py        # Entities, value objects (dataclasses)
│   └── services.py      # Business logic
├── ports/               # Interfaces — Protocol definitions
│   ├── repositories.py  # UserRepository, OrderRepository
│   └── notifications.py # EmailSender, PushNotifier
├── adapters/            # Implementations — infrastructure
│   ├── postgres.py      # PostgresUserRepo implements UserRepository
│   ├── smtp.py          # SMTPSender implements EmailSender
│   └── api/             # FastAPI routes (driving adapter)
│       └── users.py
└── composition.py       # Wires everything together
```

## Code Snippet

```python
from dataclasses import dataclass
from typing import Protocol
from decimal import Decimal
from functools import reduce

# domain/models.py — pure Python, no imports from adapters
@dataclass(frozen=True)
class Money:
    amount: Decimal
    currency: str

    def __add__(self, other: "Money") -> "Money":
        if self.currency != other.currency:
            raise ValueError(f"Cannot add {self.currency} and {other.currency}")
        return Money(self.amount + other.amount, self.currency)

@dataclass
class Order:
    id: int
    items: list[OrderItem]
    status: OrderStatus

    @property
    def total(self) -> Money:
        return reduce(lambda a, b: a + b, (item.subtotal for item in self.items))

    def cancel(self) -> None:
        if self.status != OrderStatus.PENDING:
            raise DomainError(f"Cannot cancel order in {self.status} state")
        self.status = OrderStatus.CANCELLED

# ports/repositories.py — Protocol definitions
class OrderRepository(Protocol):
    async def get(self, order_id: int) -> Order | None: ...
    async def save(self, order: Order) -> None: ...

# domain/services.py — depends only on ports
class OrderService:
    def __init__(self, orders: OrderRepository, notifications: NotificationSender) -> None:
        self._orders = orders
        self._notifications = notifications

    async def cancel_order(self, order_id: int) -> None:
        order = await self._orders.get(order_id)
        if order is None:
            raise NotFoundError("Order", order_id)
        order.cancel()
        await self._orders.save(order)
        await self._notifications.send(f"Order {order_id} cancelled")

# adapters/postgres.py — implements the port
class PostgresOrderRepo:
    def __init__(self, pool: asyncpg.Pool) -> None:
        self._pool = pool

    async def get(self, order_id: int) -> Order | None:
        row = await self._pool.fetchrow("SELECT * FROM orders WHERE id = $1", order_id)
        return Order(**row) if row else None

    async def save(self, order: Order) -> None:
        await self._pool.execute(
            "UPDATE orders SET status = $1 WHERE id = $2",
            order.status.value, order.id,
        )
```

## Notes

- Significant upfront structure for small projects — not worth it for scripts or single-module apps
- Protocol-based ports add indirection — "jump to definition" is less useful
- Testing is dramatically easier — domain logic tested with in-memory fakes, no infrastructure
- Use `import-linter` to enforce the dependency rule at CI time
- Trade-off: complexity vs testability — worth it for team/long-lived projects
