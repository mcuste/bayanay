# PLAN-RFC-004: Migrate users.created_at to TIMESTAMPTZ with ISO 8601 API Serialization

**RFC**: RFC-004
**Status**: Ready
**Created**: 2026-04-19
**Last Updated**: 2026-04-19

## Pre-flight: Open Questions (Must Resolve Before Implementation)

Three open questions in RFC-004 are marked **must resolve**. Do not begin M1 until all three are answered.

| # | Question | Blocks | Resolution needed by |
|---|---|---|---|
| OQ-1 | Is `users.created_at` constrained `NOT NULL`? | Confirming migration safety (DDL is identical either way, but test data setup differs) | Before M1 |
| OQ-2 | Approximate row count of `users` table? | Determines whether `AccessExclusiveLock` requires a maintenance window or `pg_repack` | Before running M1 in production |
| OQ-3 | Current v1 serialization format of `created_at`? | Consumer migration guide (Phase 3 only — does not block code) | Before M7 |

One question is deferred and does not block implementation:

| # | Question | Assumption baked into plan |
|---|---|---|
| OQ-4 | Sub-second precision in v2 responses? | Second precision only — `%Y-%m-%dT%H:%M:%SZ` (per RFC code example). Revisit in Phase 3 if changed. |

---

## File Structure Map

| File | Action | Responsibility |
|---|---|---|
| `user_svc/migrations/versions/xxxx_created_at_timestamptz.py` | Create | Alembic migration: `TIMESTAMP` → `TIMESTAMPTZ` via raw DDL with `AT TIME ZONE 'UTC'` cast; `upgrade()` and `downgrade()` |
| `user_svc/domain/models.py` | Modify | `DateTime` → `DateTime(timezone=True)`, `datetime.utcnow` → `lambda: datetime.now(timezone.utc)` on the `User.created_at` column |
| `user_svc/api/v2/__init__.py` | Create | Empty package init — must exist before `user_svc/api/v2/users.py` is importable |
| `user_svc/api/v2/users.py` | Create | `UserProfileV2` Pydantic model with `@field_serializer("created_at")`; `APIRouter` with three v2 route handlers mirroring `/v1/` |
| `user_svc/api/v1/users.py` | Modify | Add `Deprecation` and `Sunset` response headers to three affected route handlers |
| *(app router/factory — path from codebase)* | Modify | `include_router(v2_users.router, prefix="/v2")` — locate the file that registers the v1 router and add v2 alongside |

---

## Phase 1 — Core

### M1: Create Alembic migration `xxxx_created_at_timestamptz.py`

Highest-risk step — front-loaded. Alembic's `op.alter_column()` does not support the `USING` clause; raw DDL is required. Resolve OQ-1 and OQ-2 before running in production.

Create `user_svc/migrations/versions/xxxx_created_at_timestamptz.py`:

```python
"""Migrate users.created_at from TIMESTAMP to TIMESTAMPTZ

Revision ID: xxxx
Revises: <prior_revision>
Create Date: 2026-04-19
"""
from alembic import op


def upgrade() -> None:
    op.execute(
        "ALTER TABLE users "
        "ALTER COLUMN created_at TYPE TIMESTAMPTZ "
        "USING created_at AT TIME ZONE 'UTC'"
    )


def downgrade() -> None:
    op.execute(
        "ALTER TABLE users "
        "ALTER COLUMN created_at TYPE TIMESTAMP "
        "USING created_at AT TIME ZONE 'UTC'"
    )
```

The `AT TIME ZONE 'UTC'` cast attaches UTC metadata without shifting clock values. The downgrade strips timezone info; safe because all values were written as UTC. Replace `<prior_revision>` with the actual preceding revision ID from `alembic history`.

Do not add `NOT NULL` constraints or defaults here — this migration changes only the column type.

**Acceptance Criteria**

- `alembic upgrade head` applies without error on a local database with the pre-migration schema (naive `TIMESTAMP` column).
- After upgrade, `SELECT pg_typeof(created_at) FROM users LIMIT 1` returns `timestamp with time zone`.
- `alembic downgrade -1` reverts the column to `timestamp without time zone` without data loss.

---

### M2: Update `User.created_at` column definition in `user_svc/domain/models.py`

In `user_svc/domain/models.py`, locate the `User` model's `created_at` field. Replace the existing declaration with:

```python
# Before
created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

# After
from datetime import datetime, timezone

created_at: Mapped[datetime] = mapped_column(
    DateTime(timezone=True),
    default=lambda: datetime.now(timezone.utc),
)
```

`datetime.utcnow` is deprecated since Python 3.12 and rejected by `asyncpg` when writing to `TIMESTAMPTZ` columns. Do not change any other column on this model. Do not change any other model file.

**Acceptance Criteria**

- `User.created_at.property.columns[0].type` is a `DateTime` instance with `timezone=True`.
- The `default` callable returns a timezone-aware `datetime` with `tzinfo=timezone.utc`.
- `datetime.utcnow` does not appear anywhere in `user_svc/domain/models.py`.
- `from datetime import timezone` is present in the file's imports.

---

### M3: Create `user_svc/api/v2/__init__.py` and `UserProfileV2` Pydantic model in `user_svc/api/v2/users.py`

Create `user_svc/api/v2/__init__.py` — empty file.

Create `user_svc/api/v2/users.py` with the `UserProfileV2` Pydantic model only. No route handlers in this milestone.

Copy all field declarations from the v1 response model (e.g. `UserProfile` in `user_svc/api/v1/users.py`) into `UserProfileV2`. Add `@field_serializer("created_at")` for ISO 8601 output. Do not add any field that v1 does not have. Do not add serializers for any field other than `created_at`:

```python
from datetime import datetime, timezone

from pydantic import BaseModel, ConfigDict, field_serializer


class UserProfileV2(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    # ... all other fields from the v1 response model ...
    created_at: datetime

    @field_serializer("created_at")
    def serialize_created_at(self, value: datetime) -> str:
        if value.tzinfo is None:
            # Guard for naive datetimes (pre-migration data or test fixtures)
            value = value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
```

**Acceptance Criteria**

- `UserProfileV2(id=1, email="a@b.com", created_at=datetime(2026, 4, 19, 12, 34, 56, tzinfo=timezone.utc)).model_dump()["created_at"]` returns `"2026-04-19T12:34:56Z"`.
- `UserProfileV2` contains exactly the same fields as the v1 response model — no additions, no removals.
- `@field_serializer` is applied only to `"created_at"`.

---

### M4: Add three v2 route handlers to `user_svc/api/v2/users.py`

In `user_svc/api/v2/users.py`, add an `APIRouter` and three route handler functions. Mirror each of the three v1 route handlers from `user_svc/api/v1/users.py` exactly — copy function body, dependencies, path parameters — changing only the response model from the v1 model to `UserProfileV2`:

```python
from fastapi import APIRouter, Depends
# ... same DB/dependency imports as v1 ...

router = APIRouter(tags=["users-v2"])


# Repeat the same pattern for each of the three v1 handlers:
@router.get("/users/{user_id}", response_model=UserProfileV2)
async def get_user_v2(user_id: int, ...):
    # identical to v1 handler body
    ...
```

Do not change any service call, query, business logic, or path parameter relative to the v1 handler. The only permitted difference is `response_model=UserProfileV2` in the decorator and the import of `UserProfileV2` instead of the v1 model.

**Acceptance Criteria**

- `user_svc/api/v2/users.py` exports a `router: APIRouter` object.
- `router.routes` contains exactly three entries, one per v1 endpoint mirrored.
- Each route's `response_model` is `UserProfileV2`.
- No business logic (service calls, queries, conditionals) differs from the corresponding v1 handler.

---

### M5: Register the v2 router in the application

Locate the file that calls `app.include_router` (or equivalent) for the v1 users router — typically `user_svc/main.py` or `user_svc/api/router.py`. Import the v2 router and register it with the `/v2` prefix alongside the existing v1 registration:

```python
from user_svc.api.v2 import users as users_v2

app.include_router(users_v2.router, prefix="/v2")
```

Do not remove, reorder, or modify the existing v1 router registration.

**Acceptance Criteria**

- `GET /v2/users/{user_id}` returns HTTP 200 with `created_at` as an ISO 8601 string (e.g., `"2026-04-19T12:34:56Z"`).
- `GET /v1/users/{user_id}` still returns HTTP 200 with the original `created_at` format (byte-for-byte unchanged).
- The application starts without import errors.

---

## Phase 2 — Details

### M6: Add `Deprecation` and `Sunset` response headers to three v1 endpoints in `user_svc/api/v1/users.py`

Per ADR-001's 6-month sunset policy, the sunset date is **2026-10-19** (6 months from RFC-004's acceptance date of 2026-04-19).

In `user_svc/api/v1/users.py`, add a `Response` parameter to each of the three affected route handlers (if absent) and set both headers before returning:

```python
from fastapi import Response

@router.get("/users/{user_id}", response_model=UserProfile)
async def get_user(user_id: int, response: Response, ...):
    response.headers["Deprecation"] = "true"
    response.headers["Sunset"] = "Sun, 19 Oct 2026 00:00:00 GMT"
    # existing handler body unchanged
    ...
```

Apply to all three handlers. The `Response` parameter is injected by FastAPI and does not appear in the OpenAPI schema. Do not alter any other part of the handler.

**Acceptance Criteria**

- `GET /v1/users/{user_id}` response includes `Deprecation: true` header.
- `GET /v1/users/{user_id}` response includes `Sunset: Sun, 19 Oct 2026 00:00:00 GMT` header.
- All three v1 user profile endpoints return both headers on every response.
- v1 response body is byte-for-byte identical to pre-change responses (no field added, removed, or reordered).

---

## Phase 3 — Polish

### M7: Add deprecation notice module docstring to `user_svc/api/v1/users.py`

At the top of `user_svc/api/v1/users.py`, add a module-level docstring documenting the deprecation, sunset date, the migration path, and the format change. Fill in the v1 format entry once OQ-3 is resolved:

```python
"""
Deprecated (RFC-004, accepted 2026-04-19). Sunset: 2026-10-19.
Migrate consumers to /v2/users/* endpoints.

created_at format:
  v1: <fill in once OQ-3 resolved — e.g. "2026-04-19 12:34:56" or epoch int>
  v2: ISO 8601 UTC — "2026-04-19T12:34:56Z"
"""
```

**Acceptance Criteria**

- `user_svc/api/v1/users.py` opens with a module docstring (first non-blank, non-comment line is `"""`).
- The docstring contains `RFC-004`, `2026-10-19`, and both `v1:` and `v2:` format examples.
- The v1 format entry is filled in with the actual format confirmed by OQ-3 resolution before this milestone is marked done.

---

## RFC Goal Coverage

| RFC Goal | Milestone(s) |
|---|---|
| Migrate `users.created_at` from `TIMESTAMP` to `TIMESTAMPTZ`, interpreting existing values as UTC | M1, M2 |
| Introduce `/v2/` user profile endpoints serializing `created_at` as ISO 8601 | M3, M4, M5 |
| Deprecate three `/v1/` user profile endpoints per ADR-001's 6-month sunset policy | M6 |
| Leave all `/v1/` response shapes byte-for-byte identical | M6 (verified by AC: body unchanged) |

---

## Change Log

- 2026-04-19: Initial plan — 7 milestones across 3 phases
