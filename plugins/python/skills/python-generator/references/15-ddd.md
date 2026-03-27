# §15 — Domain-Driven Design in Python

## When to Use

- Complex business domains with non-trivial invariants
- Business logic scattered across service functions with anemic data containers
- Domain concepts like "an order can only be cancelled if it's pending" live in controllers, not domain model
- Need domain events for cross-aggregate communication

## How It Works

| DDD Concept    | Python Implementation                                               |
|----------------|---------------------------------------------------------------------|
| Value Object   | `@dataclass(frozen=True)` — immutable, equality by value            |
| Entity         | `@dataclass` with `id` field — equality by identity                 |
| Aggregate      | Entity that controls access to a cluster of objects                 |
| Repository     | `Protocol` — persistence abstraction                                |
| Domain Event   | `@dataclass(frozen=True)` — immutable fact that something happened  |
| Domain Service | Function or class with logic that doesn't belong to a single entity |

## Code Snippet

```python
from dataclasses import dataclass, field
from decimal import Decimal
from datetime import datetime
from typing import Protocol, Self

# Value Object — immutable, compared by value
@dataclass(frozen=True)
class Money:
    amount: Decimal
    currency: str

# Entity — compared by identity
@dataclass
class Customer:
    id: CustomerId
    name: str
    email: str
    address: Address

    def __eq__(self, other: object) -> bool:
        return isinstance(other, Customer) and self.id == other.id

    def __hash__(self) -> int:
        return hash(self.id)

# Domain Event
@dataclass(frozen=True)
class OrderSubmitted:
    order_id: OrderId
    total: Money
    occurred_at: datetime = field(default_factory=datetime.utcnow)

# Aggregate Root — enforces invariants
@dataclass
class Order:
    id: OrderId
    customer_id: CustomerId
    _items: list[OrderItem] = field(default_factory=list)
    _events: list[DomainEvent] = field(default_factory=list, repr=False)
    status: OrderStatus = OrderStatus.DRAFT

    def add_item(self, product: Product, quantity: int) -> None:
        if self.status != OrderStatus.DRAFT:
            raise DomainError("Can only add items to draft orders")
        if quantity <= 0:
            raise DomainError("Quantity must be positive")
        self._items.append(OrderItem(product_id=product.id, quantity=quantity, price=product.price))

    def submit(self) -> None:
        if not self._items:
            raise DomainError("Cannot submit empty order")
        self.status = OrderStatus.SUBMITTED
        self._events.append(OrderSubmitted(order_id=self.id, total=self.total))

    def collect_events(self) -> list[DomainEvent]:
        events, self._events = self._events, []
        return events

# Unit of Work — coordinate repository + events within a transaction
class UnitOfWork(Protocol):
    orders: OrderRepository
    async def __aenter__(self) -> Self: ...
    async def __aexit__(self, *args) -> None: ...
    async def commit(self) -> None: ...

# Application service — orchestrates domain
class OrderApplicationService:
    def __init__(self, uow_factory: Callable[[], UnitOfWork], events: EventBus) -> None:
        self._uow_factory = uow_factory
        self._events = events

    async def submit_order(self, order_id: OrderId) -> None:
        async with self._uow_factory() as uow:
            order = await uow.orders.get(order_id)
            order.submit()
            await uow.orders.save(order)
            await uow.commit()
            for event in order.collect_events():
                await self._events.publish(event)
```

## Notes

- Aggregates own their invariants — external code cannot bypass validation
- Value objects are `frozen=True` dataclasses — equality by value, immutable
- Entities compare by identity (`id`), not by field values
- Domain events: collect in the aggregate, publish after commit
- Unit of Work: coordinate repository operations within a single transaction
- Don't over-apply DDD to simple CRUD — it's for complex business domains
