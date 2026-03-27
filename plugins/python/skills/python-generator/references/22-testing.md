# §22 — Testing Patterns

## When to Use

- Testing pure domain logic — unit tests with plain asserts, no mocking
- Testing async code — `pytest-asyncio` with `asyncio_mode = "auto"`
- Testing with external services — `testcontainers` for Docker-based fixtures
- Testing FastAPI endpoints — `httpx.AsyncClient`
- Testing invariants over arbitrary input — `hypothesis` property-based testing
- Testing complex structured output — snapshot tests (syrupy, inline-snapshot)

## How It Works

**What to test:**
- Pure domain logic, few deps → unit test heavily
- Trivial (getters, simple delegation) → don't test
- Controller/handler with many deps → integration test
- Complex with many deps → refactor first

**Test doubles:** Prefer hand-written fakes (e.g., `InMemoryRepo`) over `unittest.mock` — they catch interface drift. Use mocks only for external services you don't control.

## Code Snippet

```python
import pytest
from unittest.mock import AsyncMock

# Fixtures — composable test setup
@pytest.fixture
def user_repo() -> InMemoryUserRepo:
    return InMemoryUserRepo()

@pytest.fixture
def user_service(user_repo: InMemoryUserRepo) -> UserService:
    return UserService(repo=user_repo, email=FakeEmailSender())

# Parametrize — multiple cases without repetition
@pytest.mark.parametrize("age,expected_error", [
    (12, "Must be at least 13"),
    (0, "Must be at least 13"),
    (13, None),
    (100, None),
])
def test_user_age_validation(age: int, expected_error: str | None) -> None:
    if expected_error:
        with pytest.raises(ValidationError, match=expected_error):
            User(name="Test", email="t@t.com", age=age)
    else:
        user = User(name="Test", email="t@t.com", age=age)
        assert user.age == age

# Async testing (with asyncio_mode = "auto" — no decorator needed)
async def test_fetch_user(user_service: UserService) -> None:
    user = await user_service.create("Alice", "alice@example.com")
    fetched = await user_service.get(user.id)
    assert fetched is not None
    assert fetched.name == "Alice"

# Testing ExceptionGroup
import asyncio

async def test_concurrent_failures() -> None:
    with pytest.raises(ExceptionGroup) as exc_info:
        async with asyncio.TaskGroup() as tg:
            tg.create_task(failing_task())
            tg.create_task(another_failing_task())
    assert len(exc_info.value.exceptions) == 2

# Property-based testing with hypothesis
from hypothesis import given, strategies as st

@given(st.lists(st.integers()))
def test_sort_is_idempotent(xs: list[int]) -> None:
    assert sorted(sorted(xs)) == sorted(xs)

emails = st.from_regex(r"[a-z]{3,10}@[a-z]{3,8}\.(com|org|net)", fullmatch=True)
ages = st.integers(min_value=13, max_value=120)

@given(name=st.text(min_size=1, max_size=100), email=emails, age=ages)
def test_user_creation_roundtrip(name: str, email: str, age: int) -> None:
    user = User(name=name, email=email, age=age)
    data = user.model_dump()
    restored = User.model_validate(data)
    assert restored == user
```

## Notes

- Set `asyncio_mode = "auto"` in `pyproject.toml` — async tests work without decorators
- Fakes over mocks: `InMemoryUserRepo` catches interface drift; `AsyncMock` does not
- Organize: `tests/unit/` (fast, no I/O), `tests/integration/` (DB, external services), `tests/e2e/`
- `conftest.py` at appropriate directory level for shared fixtures
- `testcontainers` for Docker-based integration fixtures (Postgres, Redis, etc.)
- Follow AAA: Arrange / Act / Assert — one assertion focus per test
