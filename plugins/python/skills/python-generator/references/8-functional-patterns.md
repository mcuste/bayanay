# §8 — Functional Programming Patterns

## When to Use

- Data transformation pipelines — comprehensions over `map`/`filter`
- Lazy iteration over large datasets — generators and `itertools`
- Memoization for expensive pure functions — `@cache`, `@lru_cache`
- Partial application for dependency injection or callback wiring — `functools.partial`
- Chunked/batched processing — `itertools.batched` (3.12+)

## How It Works

Python supports a pragmatic subset of FP — not pure, but effective for data transformation.

- **Comprehensions** over `map`/`filter` — Guido's recommendation, more readable
- **Generators** over lists when you only iterate once — lazy, memory-efficient
- **`itertools`** for lazy iterator combinators — `chain`, `islice`, `groupby`, `batched`
- **`functools`** for higher-order functions — `partial`, `cache`, `lru_cache`, `reduce`

## Code Snippet

```python
from functools import reduce, partial, cache, lru_cache
from itertools import chain, islice, groupby, batched

# Comprehensions — the Pythonic transform
active_emails = [u.email for u in users if u.is_active]
all_tags = [tag for post in posts for tag in post.tags]  # flatten
name_by_id = {u.id: u.name for u in users}  # dict
unique_domains = {email.split("@")[1] for email in emails}  # set
total = sum(order.amount for order in orders if order.status == "completed")  # generator

# functools — higher-order functions
send = partial(send_email, sender="noreply@example.com")  # fix some args

@cache  # unbounded memoization (3.9+)
def fibonacci(n: int) -> int:
    return n if n < 2 else fibonacci(n - 1) + fibonacci(n - 2)

@lru_cache(maxsize=256)  # bounded memoization
def get_user(user_id: int) -> User: ...

# itertools — lazy iterator combinators
all_items = chain(local_items, remote_items)  # concatenate lazily

for batch in batched(items, 100):  # 3.12+ — process in chunks
    process_batch(batch)

for status, group in groupby(sorted(orders, key=lambda o: o.status), key=lambda o: o.status):
    print(f"{status}: {sum(1 for _ in group)} orders")

first_10 = list(islice(huge_generator(), 10))  # take N without materializing
```

## Notes

- `sum(x for x in ...)` not `sum([x for x in ...])` — generator avoids materializing
- `itertools.batched` (3.12+) replaces `[items[i:i+n] for i in range(0, len(items), n)]`
- `groupby` requires data sorted by key — it groups consecutive elements only
- `@cache` is unbounded — use `@lru_cache(maxsize=N)` for bounded memoization
- Avoid deep nesting in comprehensions — extract named functions for readability
