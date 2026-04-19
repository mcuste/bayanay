# PLAN-RFC-004: Scoped asyncpg Layer for Analytics Pipeline

**RFC**: RFC-004
**Status**: Ready
**Created**: 2026-04-19
**Last Updated**: 2026-04-19

## File Structure Map

| File | Action | Responsibility |
|---|---|---|
| `src/analytics/_types.py` | Create | `UserId = NewType('UserId', int)`, `PeriodStart = NewType('PeriodStart', datetime)` — param safety aliases |
| `src/analytics/models.py` | Create | `@dataclass(frozen=True, slots=True)` result types: `RevenueByPeriodRow`, `CohortRetentionRow` |
| `src/analytics/pool.py` | Create | asyncpg pool singleton: `create_pool()`, `get_pool()`, `close_pool()` |
| `src/analytics/queries/revenue_by_period.sql` | Create | Revenue aggregation query — `$1` (start_date timestamptz), `$2` (end_date timestamptz) |
| `src/analytics/queries/cohort_retention.sql` | Create | Cohort retention query — `$1` (cohort_start timestamptz), `$2` (periods int) |
| `src/analytics/repository.py` | Create | `AnalyticsRepository` — `get_revenue_by_period()`, `get_cohort_retention()` |
| `src/analytics/views.py` | Modify | Convert all analytics view functions from `def` to `async def`; replace ORM calls with `AnalyticsRepository` |
| `src/analytics/apps.py` | Modify | `AnalyticsConfig.ready()` — pool init via `run_until_complete(create_pool(...))` + `atexit` shutdown |
| `.importlinter` | Create | `ForbidModuleImportContract` — asyncpg imports blocked outside `src/analytics/` |
| `.github/workflows/ci.yml` | Modify | Add `lint-imports` step |
| `src/analytics/README.md` | Create | ASGI deployment requirement, split-deploy pattern, pool lifecycle, scope boundary |
| `docs/adr/ADR-003-*.md` | Modify | Amendment: asyncpg permitted in `src/analytics/` for read-only aggregates only |

---

## Phase 1 — Core

### M1: Create `src/analytics/_types.py` with `UserId` and `PeriodStart` NewType aliases

Create `src/analytics/_types.py`:

```python
from __future__ import annotations
from datetime import datetime
from typing import NewType

UserId = NewType("UserId", int)
PeriodStart = NewType("PeriodStart", datetime)
```

`models.py` and `repository.py` both import these — define before those files exist.

**Acceptance Criteria**

- `UserId(42)` returns `42`; `isinstance(UserId(42), int) == True`.
- `PeriodStart(datetime.now())` does not raise.
- No `asyncpg` import exists in this file.

---

### M2: Create `src/analytics/models.py` with frozen dataclass result types

Create `src/analytics/models.py`:

```python
from __future__ import annotations
from dataclasses import dataclass
from decimal import Decimal
from src.analytics._types import PeriodStart

@dataclass(frozen=True, slots=True)
class RevenueByPeriodRow:
    period: PeriodStart
    revenue: Decimal
    order_count: int

@dataclass(frozen=True, slots=True)
class CohortRetentionRow:
    cohort_start: PeriodStart
    period_offset: int
    retained_users: int
    cohort_size: int
```

No logic — type definitions only. `repository.py` maps `asyncpg.Record` to these at the boundary.

**Acceptance Criteria**

- `RevenueByPeriodRow(period=PeriodStart(datetime.now()), revenue=Decimal("100.00"), order_count=5)` instantiates without error.
- Assigning `row.revenue = Decimal("200.00")` raises `FrozenInstanceError`.
- `CohortRetentionRow` has exactly 4 fields: `cohort_start`, `period_offset`, `retained_users`, `cohort_size`.

---

### M3: Create `src/analytics/pool.py` with asyncpg pool singleton

Create `src/analytics/pool.py`:

```python
from __future__ import annotations
import asyncpg

_pool: asyncpg.Pool | None = None

async def create_pool(dsn: str) -> None:
    global _pool
    _pool = await asyncpg.create_pool(dsn, min_size=5, max_size=20)

def get_pool() -> asyncpg.Pool:
    if _pool is None:
        raise RuntimeError("asyncpg pool not initialised — call create_pool() first")
    return _pool

async def close_pool() -> None:
    global _pool
    if _pool is not None:
        await _pool.close()
        _pool = None
```

Happy path only — `command_timeout` and `max_inactive_connection_lifetime` added in Phase 2.

**Acceptance Criteria**

- Before `create_pool()` is called, `get_pool()` raises `RuntimeError`.
- After `await create_pool(dsn)`, `get_pool()` returns an `asyncpg.Pool` instance.
- After `await close_pool()`, `get_pool()` raises `RuntimeError` again.

---

### M4: Create `src/analytics/queries/revenue_by_period.sql`

Create directory `src/analytics/queries/` and file `revenue_by_period.sql`:

```sql
SELECT
    date_trunc('day', created_at)    AS period,
    SUM(amount_cents)::numeric / 100 AS revenue,
    COUNT(*)                         AS order_count
FROM orders
WHERE created_at >= $1
  AND created_at <  $2
GROUP BY 1
ORDER BY 1;
```

`$1` = `start_date` (timestamptz), `$2` = `end_date` (timestamptz). One statement per file; no string formatting or concatenation anywhere in the file.

**Acceptance Criteria**

- File contains exactly one SQL statement.
- `$1` and `$2` are the only parameter placeholders — no `%s`, `?`, or format-string markers present.
- Columns aliased as `period`, `revenue`, `order_count` — matching `RevenueByPeriodRow` field names.

---

### M5: Create `src/analytics/repository.py` with `AnalyticsRepository` and `get_revenue_by_period()`

Create `src/analytics/repository.py`:

```python
from __future__ import annotations
from pathlib import Path
import asyncpg
from src.analytics._types import PeriodStart
from src.analytics.models import RevenueByPeriodRow

_QUERIES_DIR = Path(__file__).parent / "queries"
_REVENUE_BY_PERIOD_SQL = (_QUERIES_DIR / "revenue_by_period.sql").read_text()

class AnalyticsRepository:
    def __init__(self, pool: asyncpg.Pool) -> None:
        self._pool = pool

    async def get_revenue_by_period(
        self, start: PeriodStart, end: PeriodStart
    ) -> list[RevenueByPeriodRow]:
        rows = await self._pool.fetch(_REVENUE_BY_PERIOD_SQL, start, end)
        return [
            RevenueByPeriodRow(
                period=PeriodStart(row["period"]),
                revenue=row["revenue"],
                order_count=row["order_count"],
            )
            for row in rows
        ]
```

SQL is loaded at module import time (module-level constant). No `get_cohort_retention()` yet (Phase 2).

**Acceptance Criteria**

- `_REVENUE_BY_PERIOD_SQL` is a module-level constant — `.read_text()` is NOT inside the method.
- `await repo.get_revenue_by_period(start, end)` returns `list[RevenueByPeriodRow]` (may be empty).
- No raw `asyncpg.Record` is returned — every element in the list is a `RevenueByPeriodRow`.
- Importing `repository.py` when `queries/revenue_by_period.sql` is missing raises `FileNotFoundError` at import time.

---

### M6: Wire pool init and shutdown into `src/analytics/apps.py`

In `src/analytics/apps.py`, update (or create) `AnalyticsConfig`:

```python
import asyncio
import atexit
from django.apps import AppConfig

class AnalyticsConfig(AppConfig):
    name = "src.analytics"
    default_auto_field = "django.db.models.BigAutoField"

    def ready(self) -> None:
        from django.conf import settings
        from src.analytics.pool import create_pool, close_pool

        loop = asyncio.get_event_loop()
        loop.run_until_complete(create_pool(settings.ANALYTICS_DB_DSN))
        atexit.register(lambda: loop.run_until_complete(close_pool()))
```

Add `ANALYTICS_DB_DSN = env("ANALYTICS_DB_DSN")` to `settings.py` if absent (asyncpg DSN format: `postgresql://user:pass@host/db`).

**Acceptance Criteria**

- After Django startup, `get_pool()` returns an `asyncpg.Pool` without raising.
- `ANALYTICS_DB_DSN` missing from settings raises at startup (during `ready()`), not at first request.
- `atexit` shutdown lambda is registered — inspectable via `atexit._atexit` in tests.

---

### M7: Update `src/analytics/views.py` — convert `revenue_dashboard` to `async def`

In `src/analytics/views.py`, update `revenue_dashboard`:

```python
from datetime import datetime
from django.http import HttpRequest, JsonResponse
from src.analytics._types import PeriodStart
from src.analytics.pool import get_pool
from src.analytics.repository import AnalyticsRepository

async def revenue_dashboard(request: HttpRequest) -> JsonResponse:
    start = PeriodStart(datetime.fromisoformat(request.GET["start"]))
    end   = PeriodStart(datetime.fromisoformat(request.GET["end"]))
    repo  = AnalyticsRepository(get_pool())
    rows  = await repo.get_revenue_by_period(start, end)
    return JsonResponse({"data": [{"period": r.period.isoformat(), "revenue": str(r.revenue), "order_count": r.order_count} for r in rows]})
```

Remove the existing SQLAlchemy ORM query for this view. Response JSON keys are unchanged.

**Acceptance Criteria**

- `revenue_dashboard` is declared `async def`, not `def`.
- The view calls `await AnalyticsRepository(get_pool()).get_revenue_by_period(start, end)`.
- No `Model.objects` or SQLAlchemy ORM call remains in the body of this view.
- Response `Content-Type` is `application/json`.

---

## Phase 2 — Details

### M8: Create `src/analytics/queries/cohort_retention.sql`

Create `src/analytics/queries/cohort_retention.sql`:

```sql
SELECT
    date_trunc('month', first_order_at)                      AS cohort_start,
    EXTRACT(month FROM age(created_at, first_order_at))::int AS period_offset,
    COUNT(DISTINCT o.user_id)                                AS retained_users,
    c.cohort_size
FROM orders o
JOIN (
    SELECT user_id,
           MIN(created_at) AS first_order_at,
           COUNT(*)        AS cohort_size
    FROM   orders
    WHERE  created_at >= $1
    GROUP  BY user_id
) c USING (user_id)
WHERE o.created_at >= $1
  AND EXTRACT(month FROM age(o.created_at, c.first_order_at)) < $2
GROUP  BY 1, 2, c.cohort_size
ORDER  BY 1, 2;
```

`$1` = `cohort_start` (timestamptz), `$2` = `periods` (int). Positional placeholders only.

**Acceptance Criteria**

- File contains exactly one SQL statement.
- `$1` and `$2` are the only placeholder formats in the file.
- Columns aliased as `cohort_start`, `period_offset`, `retained_users`, `cohort_size` — matching `CohortRetentionRow` field names exactly.

---

### M9: Add `get_cohort_retention()` to `src/analytics/repository.py`

In `src/analytics/repository.py`, add at module level after `_REVENUE_BY_PERIOD_SQL`:

```python
from src.analytics.models import CohortRetentionRow
_COHORT_RETENTION_SQL = (_QUERIES_DIR / "cohort_retention.sql").read_text()
```

Add to `AnalyticsRepository`:

```python
async def get_cohort_retention(
    self, cohort_start: PeriodStart, periods: int
) -> list[CohortRetentionRow]:
    rows = await self._pool.fetch(_COHORT_RETENTION_SQL, cohort_start, periods)
    return [
        CohortRetentionRow(
            cohort_start=PeriodStart(row["cohort_start"]),
            period_offset=row["period_offset"],
            retained_users=row["retained_users"],
            cohort_size=row["cohort_size"],
        )
        for row in rows
    ]
```

**Acceptance Criteria**

- `_COHORT_RETENTION_SQL` is a module-level constant — loaded at import, not inside the method.
- `await repo.get_cohort_retention(cohort_start, 6)` returns `list[CohortRetentionRow]`.
- No raw `asyncpg.Record` escapes the repository — every element is a `CohortRetentionRow`.

---

### M10: Convert all remaining analytics views to `async def` in `src/analytics/views.py`

For each remaining `def` view in `src/analytics/views.py` that still uses SQLAlchemy ORM (all except `revenue_dashboard` converted in M7):

- Change `def view_name(request)` → `async def view_name(request: HttpRequest)`.
- Replace ORM aggregate or `raw()` call with `await AnalyticsRepository(get_pool()).get_<matching_method>(...)`.
- Response JSON shape (keys, HTTP status) must be identical to the pre-migration response.
- No `sync_to_async` wrappers — native `async def` only (ASGI hard requirement per RFC-004).

**Acceptance Criteria**

- Every view function in `src/analytics/views.py` is declared `async def`.
- No `Model.objects.*` or SQLAlchemy ORM call remains anywhere in `src/analytics/views.py`.
- No `sync_to_async` import or call remains in `src/analytics/views.py`.

---

### M11: Harden pool configuration in `src/analytics/pool.py`

In `src/analytics/pool.py`, update `create_pool()`:

```python
async def create_pool(dsn: str) -> None:
    global _pool
    _pool = await asyncpg.create_pool(
        dsn,
        min_size=5,
        max_size=20,
        command_timeout=30,                    # hard cap per query; surfaces slow plans fast
        max_inactive_connection_lifetime=300,  # recycle idle connections before PgBouncer closes them
    )
```

No other changes to `pool.py`.

**Acceptance Criteria**

- `create_pool()` passes `command_timeout=30` to `asyncpg.create_pool()`.
- `create_pool()` passes `max_inactive_connection_lifetime=300` to `asyncpg.create_pool()`.
- `min_size=5` and `max_size=20` remain unchanged.

---

### M12: Create `.importlinter` with `ForbidModuleImportContract`

Create `.importlinter` in the project root:

```ini
[importlinter]
root_packages =
    src

[importlinter:contract:no-asyncpg-outside-analytics]
name = asyncpg is forbidden outside src.analytics
type = forbidden
source_modules =
    src
forbidden_modules =
    asyncpg
ignore_imports =
    src.analytics -> asyncpg
    src.analytics.pool -> asyncpg
    src.analytics.repository -> asyncpg
```

`ignore_imports` exempts the three `src/analytics/` files that legitimately use asyncpg. All other modules under `src/` are checked.

**Acceptance Criteria**

- `lint-imports` exits 0 on a clean codebase with no asyncpg imports outside `src/analytics/`.
- Adding `import asyncpg` to any file outside `src/analytics/` causes `lint-imports` to exit non-zero.
- `src/analytics/pool.py` importing `asyncpg` does NOT cause a lint failure.

---

### M13: Add `lint-imports` step to CI

In `.github/workflows/ci.yml`, add after the existing lint steps:

```yaml
- name: Enforce asyncpg scope boundary
  run: |
    pip install import-linter
    lint-imports
```

**Acceptance Criteria**

- CI workflow file contains a step that runs `lint-imports`.
- The step runs after dependency installation.
- A PR introducing `import asyncpg` outside `src/analytics/` causes this step to fail and blocks merge.

---

## Phase 3 — Polish

### M14: Create `src/analytics/README.md` with ASGI deployment documentation

Create `src/analytics/README.md` containing:

- **ASGI requirement section**: analytics views are `async def` and require Daphne or Uvicorn; deploying under WSGI raises `SynchronousOnlyOperation`.
- **Split deployment option**: nginx example routing `/analytics/` to the ASGI upstream while WSGI serves remaining routes.
- **Pool lifecycle section**: pool is initialized in `AnalyticsConfig.ready()` and closed on process exit via `atexit`; do not call `get_pool()` before the app registry is loaded.
- **Scope boundary section**: `asyncpg` is forbidden outside `src/analytics/` — enforced by `import-linter` via `.importlinter` in CI.

**Acceptance Criteria**

- `src/analytics/README.md` exists and contains the words "ASGI", "WSGI", "Daphne", and "Uvicorn".
- The README includes the nginx `proxy_pass` split-deployment snippet.
- The README mentions `import-linter` and `.importlinter` for scope enforcement.

---

### M15: Amend ADR-003 to add scoped asyncpg exception

In `docs/adr/ADR-003-*.md`, add an **Amendment** section after the existing decision record:

```markdown
## Amendment — 2026-04-19 (RFC-004)

**Scoped exception:** `asyncpg` is permitted in `src/analytics/` for read-only aggregate queries only.

All other database access continues to use SQLAlchemy ORM. This exception covers the ~8–10 analytics pipeline queries in `src/analytics/` that exhibited 25–40x ORM overhead (P95 ≈ 4 s against a <500 ms target; raw SQL executes in ~2 ms, ORM hydration takes 50–80 ms per query).

**Constraints on this exception:**
- `asyncpg` imports outside `src/analytics/` are blocked by `import-linter` CI contract (`.importlinter`).
- All queries must use asyncpg positional placeholders (`$1, $2`) — no string formatting or concatenation.
- Repository methods must map `asyncpg.Record` results to `@dataclass(frozen=True, slots=True)` types before returning — raw Records must not escape the `AnalyticsRepository` boundary.
- Read-only queries only — no write transactions through the asyncpg pool.

See RFC-004 for benchmark data and rejected alternatives (SQLAlchemy Core, full asyncpg migration).
```

**Acceptance Criteria**

- ADR-003 contains an Amendment section dated 2026-04-19.
- Amendment text references RFC-004.
- Amendment lists all four constraints: import-linter enforcement, positional placeholders, frozen dataclass mapping, read-only restriction.
- Existing ADR-003 decision text is unchanged — only the Amendment section is appended.

---

## RFC Goal Coverage

| RFC Goal | Milestone(s) |
|---|---|
| Analytics P95 latency < 500ms via asyncpg | M3–M7, M9–M11 |
| asyncpg scoped to `src/analytics/` only (~8–10 queries) | M4–M5, M8–M9, M12–M13 |
| Amend ADR-003 with scoped exception | M15 |
| SQL injection protection — positional placeholders only | M4, M8 (SQL files), M5, M9 (repository mapping) |
| Scope enforcement via linter rule | M12–M13 |

---

## Change Log

- 2026-04-19: Initial plan — 15 milestones across 3 phases
