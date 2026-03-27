# §16 — Functional Core, Imperative Shell

## When to Use

- Business logic tangled with I/O — testing requires databases, email servers, HTTP clients
- Want to test domain logic with plain asserts, no mocking
- Separating "what to do" (pure computation) from "how to do it" (I/O)

## How It Works

Separate the application into:

- **Functional core:** Pure functions that take data in, return data out. No I/O, no mutation of external state. Easy to test with plain asserts.
- **Imperative shell:** Thin layer that performs I/O (database, HTTP, filesystem) and feeds data to the functional core.

This is complementary to hexagonal architecture, not a replacement. The "shell" is the adapter layer; the "core" is the domain.

## Code Snippet

```python
from dataclasses import dataclass
from datetime import datetime, timedelta

@dataclass(frozen=True)
class ExpirationNotice:
    user_id: int
    email: str
    expired_at: datetime
    days_overdue: int

@dataclass(frozen=True)
class EmailMessage:
    to: str
    subject: str
    body: str

# Functional core — pure, testable, no I/O
def find_expired_subscriptions(
    users: list[User],
    now: datetime,
    grace_period: timedelta = timedelta(days=7),
) -> list[ExpirationNotice]:
    cutoff = now - grace_period
    return [
        ExpirationNotice(
            user_id=user.id,
            email=user.email,
            expired_at=user.subscription_end,
            days_overdue=(now - user.subscription_end).days,
        )
        for user in users
        if user.subscription_end < cutoff and not user.is_exempt
    ]

def format_notification(notice: ExpirationNotice) -> EmailMessage:
    return EmailMessage(
        to=notice.email,
        subject="Your subscription has expired",
        body=f"Your subscription expired {notice.days_overdue} days ago.",
    )

# Imperative shell — thin I/O orchestration
async def process_expired_subscriptions(
    db: Database, mailer: EmailSender, now: datetime,
) -> int:
    users = await db.get_all_users()                  # I/O
    notices = find_expired_subscriptions(users, now)   # Pure
    emails = [format_notification(n) for n in notices] # Pure
    for email in emails:
        await mailer.send(email)                       # I/O
    return len(emails)

# Tests — no mocking needed for the core logic
def test_expired_subscriptions():
    users = [
        User(id=1, email="a@b.com", subscription_end=datetime(2024, 1, 1), is_exempt=False),
        User(id=2, email="c@d.com", subscription_end=datetime(2099, 1, 1), is_exempt=False),
    ]
    result = find_expired_subscriptions(users, datetime(2024, 6, 1))
    assert len(result) == 1
    assert result[0].user_id == 1
```

## Notes

- Pure functions are trivially testable — no mocking, no fixtures, just data in → data out
- The shell should be thin — just I/O orchestration calling into the core
- Works well with hexagonal architecture — the shell is the adapter layer
- Inject `now: datetime` as a parameter rather than calling `datetime.utcnow()` inside pure functions — makes testing deterministic
