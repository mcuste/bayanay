# PLAN-RFC-004: Multi-Tenancy Foundation

**RFC**: RFC-004 — Multi-Tenancy Foundation: Data Model, RLS, Auth, and Context Propagation
**Status**: Ready
**Created**: 2026-04-19
**Last Updated**: 2026-04-19

## File Structure Map

| File | Action | Responsibility |
|---|---|---|
| `shared/tenancy/__init__.py` | Create | Public package API: re-exports `TenantId`, `Tenant`, `TenantPlan`, `TenantStatus`, `tenant_context`, `admin_context`, `register_tenant_hooks`, `TenantMiddleware`, `TenantAwareTask` |
| `shared/tenancy/models.py` | Create | `TenantId` NewType, `TenantPlan`/`TenantStatus` StrEnum, `Tenant` SQLAlchemy 2.0 ORM model on `shared.tenants` |
| `shared/tenancy/context.py` | Create | `_current_tenant_id` ContextVar, `tenant_context()` and `admin_context()` context managers |
| `shared/tenancy/hooks.py` | Create | `register_tenant_hooks(engine)` — SQLAlchemy `checkout` event listener calling `set_config('app.current_tenant', ...)` |
| `shared/tenancy/middleware.py` | Create | Django `TenantMiddleware` — extracts `tenant_id` from JWT claim `https://yourapp.com/tenant_id`, wraps request in `tenant_context()` |
| `shared/tenancy/celery_integration.py` | Create | `TenantAwareTask(Task)` — injects `x_tenant_id` header at `apply_async`, restores ContextVar in `__call__` |
| `billing_svc/db.py` | Modify | Add `register_tenant_hooks(engine)` call after engine creation |
| `notif_svc/db.py` | Modify | Add `register_tenant_hooks(engine)` call after engine creation |
| `user_svc/db.py` | Modify | Add `register_tenant_hooks(engine)` call after engine creation |
| `billing_svc/celery.py` | Modify | Add `app.Task = TenantAwareTask` after Celery app creation |
| `notif_svc/celery.py` | Modify | Add `app.Task = TenantAwareTask` after Celery app creation |
| `user_svc/celery.py` | Modify | Add `app.Task = TenantAwareTask` after Celery app creation |
| `shared_events/envelope.py` | Modify | Add required `tenant_id: uuid.UUID` field to `EventEnvelope`; add `build_envelope()` helper that reads ContextVar |
| `src/middleware/tenant.ts` | Create | `tenantStorage` AsyncLocalStorage, `tenantMiddleware()` — extracts claim, 403 on missing, runs `next` in storage context |
| `src/db/tenant-client.ts` | Create | `withTenantConnection<T>()` — checks out pool connection, calls `SET LOCAL app.current_tenant`, passes to callback |
| `db/roles.sql` | Create | DDL: `CREATE ROLE app_user` (RLS enforced) and `CREATE ROLE app_admin BYPASSRLS` (migration runner only) |
| `billing_svc/migrations/0002_add_tenant_id.py` | Create | Alembic: provision default tenant, add `tenant_id` to `billing_subscriptions` + `invoices`, FK, index, RLS policy |
| `notif_svc/migrations/0002_add_tenant_id.py` | Create | Alembic: same pattern for `notification_logs` + `notification_templates` |
| `user_svc/migrations/0002_add_tenant_id.py` | Create | Alembic: same pattern for `users` + `projects` + `teams` |
| `auth0/actions/inject-tenant-id.js` | Create | Auth0 post-login Action: fetch tenant by `auth0_org_id`, inject `tenant_id` claim on id + access tokens |
| `src/app.ts` | Modify | Mount `tenantMiddleware` after JWT middleware, before route handlers |
| `.eslintrc.js` (or equivalent) | Modify | Add `no-restricted-syntax` rule disallowing `pool.query(...)` calls |

---

## Phase 1 — Core

### M1: Create `shared/tenancy/models.py` with Tenant data model

Create `shared/tenancy/models.py`:

```python
import uuid
from datetime import datetime
from enum import StrEnum
from typing import NewType

from sqlalchemy import DateTime, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

TenantId = NewType("TenantId", uuid.UUID)


class Base(DeclarativeBase):
    pass


class TenantPlan(StrEnum):
    STARTER = "starter"
    BUSINESS = "business"
    ENTERPRISE = "enterprise"


class TenantStatus(StrEnum):
    ACTIVE = "active"
    SUSPENDED = "suspended"
    CANCELLED = "cancelled"


class Tenant(Base):
    __tablename__ = "tenants"
    __table_args__ = {"schema": "shared"}

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    slug: Mapped[str] = mapped_column(String(63), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    plan: Mapped[TenantPlan] = mapped_column(String(20), nullable=False, default=TenantPlan.STARTER)
    status: Mapped[TenantStatus] = mapped_column(String(20), nullable=False, default=TenantStatus.ACTIVE)
    auth0_org_id: Mapped[str | None] = mapped_column(String(64), unique=True, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
```

`Base` is defined inline in this file. If other service models import a different `DeclarativeBase`, each service's engine must be configured separately — `Tenant` is not mapped on service engines; it exists only for type reference and the `shared.tenants` table DDL.

**Acceptance Criteria**

- `from shared.tenancy.models import Tenant, TenantPlan, TenantStatus, TenantId` succeeds with no import error.
- `Tenant.__tablename__ == "tenants"` and `Tenant.__table_args__ == {"schema": "shared"}`.
- `TenantPlan.STARTER == "starter"` — StrEnum inherits `str`, comparison holds.

---

### M2: Create `shared/tenancy/context.py` with ContextVar and context managers

Create `shared/tenancy/context.py`:

```python
import uuid
from contextlib import contextmanager
from contextvars import ContextVar
from typing import Generator

_current_tenant_id: ContextVar[uuid.UUID | None] = ContextVar("current_tenant_id", default=None)


@contextmanager
def tenant_context(tenant_id: uuid.UUID) -> Generator[None, None, None]:
    token = _current_tenant_id.set(tenant_id)
    try:
        yield
    finally:
        _current_tenant_id.reset(token)


@contextmanager
def admin_context() -> Generator[None, None, None]:
    token = _current_tenant_id.set(None)
    try:
        yield
    finally:
        _current_tenant_id.reset(token)
```

`ContextVar` is used (not `threading.local`) for coroutine-safe isolation in both threaded WSGI and async ASGI deployments.

**Acceptance Criteria**

- Inside `with tenant_context(some_uuid)`, `_current_tenant_id.get()` returns `some_uuid`.
- After exiting `tenant_context`, `_current_tenant_id.get()` returns the value that was set before entering (not `some_uuid`).
- Inside `with admin_context()`, `_current_tenant_id.get()` returns `None`, even when called inside an outer `tenant_context`.

---

### M3: Create `shared/tenancy/hooks.py` with SQLAlchemy checkout hook

Create `shared/tenancy/hooks.py`:

```python
from sqlalchemy import Engine, event

from .context import _current_tenant_id


def register_tenant_hooks(engine: Engine) -> None:
    @event.listens_for(engine, "checkout")
    def _set_tenant(dbapi_conn, conn_record, conn_proxy):
        tenant_id = _current_tenant_id.get()
        cursor = dbapi_conn.cursor()
        cursor.execute(
            "SELECT set_config('app.current_tenant', %s, TRUE)",
            (str(tenant_id) if tenant_id is not None else "",),
        )
        cursor.close()
```

`set_config(..., TRUE)` is equivalent to `SET LOCAL` — resets at transaction end. PgBouncer transaction-mode safe: context never persists across transaction boundaries. `checkout` fires on every pool checkout (correct hook); `connect` fires only on pool init (wrong); `before_cursor_execute` fires per-statement (too heavy).

**Acceptance Criteria**

- After `register_tenant_hooks(engine)`, `event.contains(engine, "checkout", ...)` returns `True` (a listener is registered).
- When `_current_tenant_id` holds a UUID and a connection is checked out, `set_config` executes with the UUID's string representation (e.g., `"3f2504e0-4f89-11d3-9a0c-0305e82c3301"`).
- When `_current_tenant_id` holds `None`, `set_config` executes with `""` (empty string, not the string `"None"`).

---

### M4: Create `shared/tenancy/middleware.py` with Django TenantMiddleware

Create `shared/tenancy/middleware.py`:

```python
import uuid

from .context import tenant_context

TENANT_CLAIM = "https://yourapp.com/tenant_id"


class TenantMiddleware:
    def __init__(self, get_response):
        self._get_response = get_response

    def __call__(self, request):
        tenant_id = self._extract(request)
        if tenant_id is None:
            return self._get_response(request)
        with tenant_context(tenant_id):
            return self._get_response(request)

    def _extract(self, request) -> uuid.UUID | None:
        auth = getattr(request, "auth", None)
        if not auth:
            return None
        raw = auth.get(TENANT_CLAIM)
        if not raw:
            return None
        try:
            return uuid.UUID(raw)
        except (ValueError, AttributeError):
            return None
```

Middleware order requirement: `JWTAuthMiddleware` (which sets `request.auth`) must appear before `TenantMiddleware` in `MIDDLEWARE` settings.

**Acceptance Criteria**

- When `request.auth == {"https://yourapp.com/tenant_id": str(some_uuid)}`, `_extract()` returns `uuid.UUID(str(some_uuid))`.
- When `request.auth` is absent or the claim key is missing, `_extract()` returns `None` and `get_response` is called without entering `tenant_context`.
- When the claim value is not a valid UUID string (e.g., `"not-a-uuid"`), `_extract()` returns `None` — no exception propagates to the caller.

---

### M5: Create `shared/tenancy/celery_integration.py` with TenantAwareTask

Create `shared/tenancy/celery_integration.py`:

```python
import uuid

from celery import Task

from .context import _current_tenant_id


class TenantAwareTask(Task):
    def apply_async(self, args=None, kwargs=None, **options):
        tenant_id = _current_tenant_id.get()
        headers = options.setdefault("headers", {})
        if tenant_id is not None:
            headers["x_tenant_id"] = str(tenant_id)
        return super().apply_async(args, kwargs, **options)

    def __call__(self, *args, **kwargs):
        raw = self.request.get("x_tenant_id")
        if raw:
            token = _current_tenant_id.set(uuid.UUID(raw))
            try:
                return super().__call__(*args, **kwargs)
            finally:
                _current_tenant_id.reset(token)
        return super().__call__(*args, **kwargs)
```

**Acceptance Criteria**

- When `_current_tenant_id` holds a UUID and `apply_async` is called, task `options["headers"]` contains `{"x_tenant_id": str(that_uuid)}`.
- When `_current_tenant_id` holds `None` and `apply_async` is called, `options["headers"]` does not contain `"x_tenant_id"`.
- When `__call__` executes with `self.request["x_tenant_id"] = str(some_uuid)`, `_current_tenant_id.get()` returns `some_uuid` during task body execution and is reset to its previous value after the task completes (including on exception).

---

### M6: Create `shared/tenancy/__init__.py` with public exports

Create `shared/tenancy/__init__.py`:

```python
from .celery_integration import TenantAwareTask
from .context import admin_context, tenant_context
from .hooks import register_tenant_hooks
from .middleware import TenantMiddleware
from .models import Tenant, TenantId, TenantPlan, TenantStatus

__all__ = [
    "Tenant",
    "TenantAwareTask",
    "TenantId",
    "TenantMiddleware",
    "TenantPlan",
    "TenantStatus",
    "admin_context",
    "register_tenant_hooks",
    "tenant_context",
]
```

No other logic in this file.

**Acceptance Criteria**

- `from shared.tenancy import Tenant, TenantId, TenantPlan, TenantStatus, tenant_context, admin_context, register_tenant_hooks, TenantMiddleware, TenantAwareTask` succeeds with no import error.
- `shared.tenancy.TenantMiddleware is shared.tenancy.middleware.TenantMiddleware` — same object, not a re-wrapped copy.

---

### M7: Wire `register_tenant_hooks` into `billing_svc/db.py`

In `billing_svc/db.py`, add the import at module level and call `register_tenant_hooks(engine)` immediately after `engine = create_engine(settings.DATABASE_URL)`:

```python
from shared.tenancy.hooks import register_tenant_hooks

engine = create_engine(settings.DATABASE_URL)
register_tenant_hooks(engine)       # ← add this line
```

Call must appear before any `Session`, `sessionmaker`, or `scoped_session` setup that uses `engine`.

**Acceptance Criteria**

- `billing_svc/db.py` imports `register_tenant_hooks` from `shared.tenancy.hooks`.
- The call `register_tenant_hooks(engine)` appears in the file after `engine = create_engine(...)`.
- `python -c "import billing_svc.db"` (with `shared.tenancy` on `PYTHONPATH`) exits 0.

---

### M8: Wire `register_tenant_hooks` into `notif_svc/db.py`

In `notif_svc/db.py`, add the import at module level and call `register_tenant_hooks(engine)` immediately after `engine = create_engine(settings.DATABASE_URL)`:

```python
from shared.tenancy.hooks import register_tenant_hooks

engine = create_engine(settings.DATABASE_URL)
register_tenant_hooks(engine)       # ← add this line
```

Call must appear before any `Session`, `sessionmaker`, or `scoped_session` setup that uses `engine`.

**Acceptance Criteria**

- `notif_svc/db.py` imports `register_tenant_hooks` from `shared.tenancy.hooks`.
- The call `register_tenant_hooks(engine)` appears in the file after `engine = create_engine(...)`.
- `python -c "import notif_svc.db"` (with `shared.tenancy` on `PYTHONPATH`) exits 0.

---

### M9: Wire `register_tenant_hooks` into `user_svc/db.py`

In `user_svc/db.py`, add the import at module level and call `register_tenant_hooks(engine)` immediately after `engine = create_engine(settings.DATABASE_URL)`:

```python
from shared.tenancy.hooks import register_tenant_hooks

engine = create_engine(settings.DATABASE_URL)
register_tenant_hooks(engine)       # ← add this line
```

Call must appear before any `Session`, `sessionmaker`, or `scoped_session` setup that uses `engine`.

**Acceptance Criteria**

- `user_svc/db.py` imports `register_tenant_hooks` from `shared.tenancy.hooks`.
- The call `register_tenant_hooks(engine)` appears in the file after `engine = create_engine(...)`.
- `python -c "import user_svc.db"` (with `shared.tenancy` on `PYTHONPATH`) exits 0.

---

### M10: Set `app.Task = TenantAwareTask` in `billing_svc/celery.py`

In `billing_svc/celery.py`, add the import at module level and assign `app.Task` immediately after `app = Celery("billing_svc")`:

```python
from shared.tenancy.celery_integration import TenantAwareTask

app = Celery("billing_svc")
app.Task = TenantAwareTask          # ← add this line
```

Assignment must appear before any `@app.task` decorators are evaluated. Import at module level with other imports.

**Acceptance Criteria**

- `billing_svc/celery.py` contains `app.Task = TenantAwareTask` before any `@app.task` decorator.
- Any `@app.task`-decorated function in `billing_svc` (without an explicit `base=` argument) has `TenantAwareTask` in its MRO.
- `python -c "import billing_svc.celery"` exits 0.

---

### M11: Set `app.Task = TenantAwareTask` in `notif_svc/celery.py`

In `notif_svc/celery.py`, add the import at module level and assign `app.Task` immediately after `app = Celery("notif_svc")`:

```python
from shared.tenancy.celery_integration import TenantAwareTask

app = Celery("notif_svc")
app.Task = TenantAwareTask          # ← add this line
```

Assignment must appear before any `@app.task` decorators are evaluated.

**Acceptance Criteria**

- `notif_svc/celery.py` contains `app.Task = TenantAwareTask` before any `@app.task` decorator.
- Any `@app.task`-decorated function in `notif_svc` (without explicit `base=`) has `TenantAwareTask` in its MRO.
- `python -c "import notif_svc.celery"` exits 0.

---

### M12: Set `app.Task = TenantAwareTask` in `user_svc/celery.py`

In `user_svc/celery.py`, add the import at module level and assign `app.Task` immediately after `app = Celery("user_svc")`:

```python
from shared.tenancy.celery_integration import TenantAwareTask

app = Celery("user_svc")
app.Task = TenantAwareTask          # ← add this line
```

Assignment must appear before any `@app.task` decorators are evaluated.

**Acceptance Criteria**

- `user_svc/celery.py` contains `app.Task = TenantAwareTask` before any `@app.task` decorator.
- Any `@app.task`-decorated function in `user_svc` (without explicit `base=`) has `TenantAwareTask` in its MRO.
- `python -c "import user_svc.celery"` exits 0.

---

### M13: Add `tenant_id` field to `EventEnvelope` and add `build_envelope()` helper

In `shared_events/envelope.py`, modify `EventEnvelope` to add `tenant_id: uuid.UUID` as a required field (no default), positioned after `payload` and before `event_id` (which has a default). Add `build_envelope()` helper:

```python
# shared_events/envelope.py
import uuid
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any

from shared.tenancy.context import _current_tenant_id


@dataclass(frozen=True, slots=True)
class EventEnvelope:
    event_type: str
    payload: dict[str, Any]
    tenant_id: uuid.UUID                           # new — required, no default
    event_id: uuid.UUID = field(default_factory=uuid.uuid4)
    occurred_at: datetime = field(default_factory=datetime.utcnow)
    correlation_id: uuid.UUID | None = None


def build_envelope(event_type: str, payload: dict[str, Any]) -> EventEnvelope:
    tenant_id = _current_tenant_id.get()
    if tenant_id is None:
        raise RuntimeError(
            f"build_envelope called outside tenant context for event_type={event_type!r}"
        )
    return EventEnvelope(event_type=event_type, payload=payload, tenant_id=tenant_id)
```

This is a **breaking change**: all existing callers of `EventEnvelope(...)` that do not pass `tenant_id` will raise `TypeError`. Update all callers to use `build_envelope()` or pass `tenant_id` explicitly.

**Acceptance Criteria**

- `EventEnvelope(event_type="x", payload={}, tenant_id=some_uuid)` constructs without error.
- `EventEnvelope(event_type="x", payload={})` raises `TypeError: missing required argument 'tenant_id'`.
- Calling `build_envelope("x", {})` outside any `tenant_context` raises `RuntimeError` with message containing `"outside tenant context"`.
- Calling `build_envelope("x", {})` inside `with tenant_context(some_uuid)` returns `EventEnvelope` with `tenant_id == some_uuid`.

---

### M14: Create `src/middleware/tenant.ts`

Create `src/middleware/tenant.ts`:

```typescript
import { AsyncLocalStorage } from 'async_hooks';
import { NextFunction, Request, Response } from 'express';

export const tenantStorage = new AsyncLocalStorage<{ tenantId: string }>();

const TENANT_CLAIM = 'https://yourapp.com/tenant_id';

export function tenantMiddleware(req: Request, res: Response, next: NextFunction): void {
  const tenantId = (req as any).auth?.[TENANT_CLAIM] as string | undefined;
  if (!tenantId) {
    res.status(403).json({ error: 'Missing tenant context' });
    return;
  }
  tenantStorage.run({ tenantId }, next);
}
```

`req.auth` is set by the JWT auth middleware that must run before this one. Cast to `any` if the JWT middleware does not augment the Express `Request` type — a follow-up PR can add the type augmentation.

**Acceptance Criteria**

- When `req.auth` contains `{ "https://yourapp.com/tenant_id": "abc-123" }`, `next()` is called and `tenantStorage.getStore()` returns `{ tenantId: "abc-123" }` inside the next handler.
- When the claim is absent or empty, response status is `403` and body is `{ "error": "Missing tenant context" }`, and `next()` is not called.
- `tsc --noEmit` passes on this file with no type errors.

---

### M15: Create `src/db/tenant-client.ts`

Create `src/db/tenant-client.ts`:

```typescript
import { PoolClient } from 'pg';
import { tenantStorage } from '../middleware/tenant';
import { pool } from './pool';

export async function withTenantConnection<T>(
  callback: (client: PoolClient) => Promise<T>
): Promise<T> {
  const store = tenantStorage.getStore();
  const client = await pool.connect();
  try {
    await client.query("SELECT set_config('app.current_tenant', $1, TRUE)", [
      store?.tenantId ?? '',
    ]);
    return await callback(client);
  } finally {
    client.release();
  }
}
```

`pool` must be the existing `pg.Pool` instance exported from `./pool`. `set_config(..., TRUE)` is `SET LOCAL` — resets at transaction end, PgBouncer transaction-mode safe.

**Acceptance Criteria**

- When `tenantStorage` store is `{ tenantId: "abc" }`, `withTenantConnection` executes `SELECT set_config('app.current_tenant', 'abc', TRUE)` before invoking `callback`.
- When `tenantStorage.getStore()` returns `undefined`, `set_config` is called with `''` (empty string).
- `client.release()` is called in the `finally` block even when `callback` throws.

---

## Phase 2 — Details

### M16: Create `db/roles.sql` with PostgreSQL role DDL

Create `db/roles.sql`:

```sql
-- Run once against the database before any service connection or Alembic migration.
-- app_user: used by all service DATABASE_URL connection strings. RLS is enforced.
-- app_admin: used by ALEMBIC_DATABASE_URL and admin CLI scripts only. No application
-- code path connects as app_admin.

CREATE ROLE app_user;
CREATE ROLE app_admin BYPASSRLS;
```

This file is applied manually or via a bootstrap step in the deployment runbook — not via Alembic (roles are cluster-scoped, not database-scoped).

**Acceptance Criteria**

- `db/roles.sql` contains `CREATE ROLE app_user` without the `BYPASSRLS` attribute.
- `db/roles.sql` contains `CREATE ROLE app_admin BYPASSRLS`.
- File contains a comment identifying which role is used for application connections vs. migration runner connections.

---

### M17: Create `billing_svc/migrations/0002_add_tenant_id.py`

Create `billing_svc/migrations/0002_add_tenant_id.py` as an Alembic migration. `depends_on` the previous migration revision (e.g., `0001_initial`).

`upgrade()` — apply identical 9-step pattern for each table. For `billing_subscriptions` (schema `billing_svc`):

1. `op.execute(sa.text("INSERT INTO shared.tenants (id, slug, name, plan, status, created_at) VALUES ('00000000-0000-0000-0000-000000000001', 'default', 'Default Tenant', 'enterprise', 'active', now()) ON CONFLICT DO NOTHING"))`
2. `op.add_column("billing_subscriptions", sa.Column("tenant_id", UUID(as_uuid=True), nullable=True), schema="billing_svc")`
3. `op.execute(sa.text("UPDATE billing_svc.billing_subscriptions SET tenant_id = '00000000-0000-0000-0000-000000000001' WHERE tenant_id IS NULL"))`
4. `op.alter_column("billing_subscriptions", "tenant_id", nullable=False, schema="billing_svc")`
5. `op.create_foreign_key("fk_billing_subscriptions_tenant_id", "billing_subscriptions", "tenants", ["tenant_id"], ["id"], source_schema="billing_svc", referent_schema="shared")`
6. `op.create_index("ix_billing_subscriptions_tenant_id", "billing_subscriptions", ["tenant_id"], schema="billing_svc")`
7. `op.execute(sa.text("ALTER TABLE billing_svc.billing_subscriptions ENABLE ROW LEVEL SECURITY"))`
8. `op.execute(sa.text("ALTER TABLE billing_svc.billing_subscriptions FORCE ROW LEVEL SECURITY"))`
9. `op.execute(sa.text("CREATE POLICY tenant_isolation ON billing_svc.billing_subscriptions USING (NULLIF(current_setting('app.current_tenant', TRUE), '')::uuid = tenant_id)"))`

Repeat steps 2–9 for table `invoices` (schema `billing_svc`), FK name `fk_invoices_tenant_id`, index name `ix_invoices_tenant_id`.

Step 1 (INSERT default tenant) runs once at the top of `upgrade()` — not repeated per table.

`downgrade()`: for each table (`billing_subscriptions`, `invoices`) in reverse order: `DROP POLICY tenant_isolation`, `ALTER TABLE ... DISABLE ROW LEVEL SECURITY`, `op.drop_index(...)`, `op.drop_constraint(...)`, `op.drop_column("tenant_id", ...)`.

Migration runner connects as `app_admin` (BYPASSRLS) via `ALEMBIC_DATABASE_URL`.

**Acceptance Criteria**

- `alembic upgrade head` (as `app_admin`) completes without error on a schema with existing rows in `billing_subscriptions` and `invoices`.
- After upgrade, `billing_svc.billing_subscriptions.tenant_id` is `NOT NULL` with a FK referencing `shared.tenants.id`.
- After upgrade, `SELECT * FROM billing_svc.billing_subscriptions` as `app_user` with no `app.current_tenant` GUC set returns 0 rows (RLS blocks all access).
- `alembic downgrade -1` reverses all schema changes and RLS policies cleanly.

---

### M18: Create `notif_svc/migrations/0002_add_tenant_id.py`

Create `notif_svc/migrations/0002_add_tenant_id.py` as an Alembic migration. `depends_on` the previous revision in `notif_svc/migrations/`.

`upgrade()`:

1. `op.execute(sa.text("INSERT INTO shared.tenants (id, slug, name, plan, status, created_at) VALUES ('00000000-0000-0000-0000-000000000001', 'default', 'Default Tenant', 'enterprise', 'active', now()) ON CONFLICT DO NOTHING"))`
2. Apply 8-step pattern (steps 2–9 from M17) for table `notification_logs` (schema `notif_svc`), FK name `fk_notification_logs_tenant_id`, index name `ix_notification_logs_tenant_id`.
3. Apply 8-step pattern for table `notification_templates` (schema `notif_svc`), FK name `fk_notification_templates_tenant_id`, index name `ix_notification_templates_tenant_id`.

`downgrade()`: for each table (`notification_logs`, `notification_templates`): drop policy, disable RLS, drop index, drop FK, drop column — in reverse order.

**Acceptance Criteria**

- `alembic upgrade head` (as `app_admin`) completes without error on a schema with existing rows in `notification_logs` and `notification_templates`.
- After upgrade, both `notif_svc.notification_logs.tenant_id` and `notif_svc.notification_templates.tenant_id` are `NOT NULL` with FK to `shared.tenants.id`.
- After upgrade, `SELECT * FROM notif_svc.notification_logs` as `app_user` with no GUC set returns 0 rows.
- `alembic downgrade -1` reverses all changes cleanly.

---

### M19: Create `user_svc/migrations/0002_add_tenant_id.py`

Create `user_svc/migrations/0002_add_tenant_id.py` as an Alembic migration. `depends_on` the previous revision in `user_svc/migrations/`.

`upgrade()`:

1. `op.execute(sa.text("INSERT INTO shared.tenants (id, slug, name, plan, status, created_at) VALUES ('00000000-0000-0000-0000-000000000001', 'default', 'Default Tenant', 'enterprise', 'active', now()) ON CONFLICT DO NOTHING"))`
2. Apply 8-step pattern (steps 2–9 from M17) for table `users` (schema `user_svc`), FK name `fk_users_tenant_id`, index name `ix_users_tenant_id`.
3. Apply 8-step pattern for table `projects` (schema `user_svc`), FK name `fk_projects_tenant_id`, index name `ix_projects_tenant_id`.
4. Apply 8-step pattern for table `teams` (schema `user_svc`), FK name `fk_teams_tenant_id`, index name `ix_teams_tenant_id`.

`downgrade()`: for each table (`users`, `projects`, `teams`): drop policy, disable RLS, drop index, drop FK, drop column — in reverse order.

**Acceptance Criteria**

- `alembic upgrade head` (as `app_admin`) completes without error on a schema with existing rows in `users`, `projects`, `teams`.
- After upgrade, `user_svc.users.tenant_id`, `user_svc.projects.tenant_id`, and `user_svc.teams.tenant_id` are all `NOT NULL` with FK to `shared.tenants.id`.
- After upgrade, `SELECT * FROM user_svc.users` as `app_user` with no GUC set returns 0 rows.
- `alembic downgrade -1` reverses all changes cleanly.

---

### M20: Create `auth0/actions/inject-tenant-id.js`

Create `auth0/actions/inject-tenant-id.js` (versioned in repo; deployed to Auth0 via `auth0 deploy` CLI or dashboard):

```javascript
/**
 * Auth0 Post-Login Action: inject-tenant-id
 *
 * Trigger: Post Login
 * Required secrets: TENANTS_API_URL — internal URL of the tenants lookup API
 *
 * Injects tenant_id as a custom claim on both the ID token and access token.
 * Claim namespace must match TENANT_CLAIM in:
 *   - shared/tenancy/middleware.py (Python services)
 *   - src/middleware/tenant.ts (Node.js API server)
 *
 * Users not in an Auth0 Organization (e.g., internal tooling logins) receive
 * no tenant claim and are treated as unauthenticated on protected routes.
 */

const TENANT_CLAIM = 'https://yourapp.com/tenant_id';

async function fetchTenantByAuth0OrgId(orgId) {
  const url = `${event.secrets.TENANTS_API_URL}/internal/tenants?auth0_org_id=${encodeURIComponent(orgId)}`;
  const response = await fetch(url, {
    headers: { 'Authorization': `Bearer ${event.secrets.INTERNAL_API_KEY}` },
  });
  if (!response.ok) return null;
  return response.json();
}

exports.onExecutePostLogin = async (event, api) => {
  const orgId = event.organization?.id;
  if (!orgId) return;

  const tenant = await fetchTenantByAuth0OrgId(orgId);
  if (tenant) {
    api.idToken.setCustomClaim(TENANT_CLAIM, tenant.id);
    api.accessToken.setCustomClaim(TENANT_CLAIM, tenant.id);
  }
};
```

Required Auth0 Action secrets: `TENANTS_API_URL`, `INTERNAL_API_KEY`.

**Acceptance Criteria**

- When `event.organization.id` is `null` or `undefined`, the function returns without calling `api.idToken.setCustomClaim` or `api.accessToken.setCustomClaim`.
- When `event.organization.id` is a known `auth0_org_id`, both `api.idToken.setCustomClaim` and `api.accessToken.setCustomClaim` are called with `'https://yourapp.com/tenant_id'` and the corresponding tenant UUID string.
- When `fetchTenantByAuth0OrgId` returns `null` (unknown org or API error), no claim is set.

---

### M21: Mount `tenantMiddleware` in Express app entry point

In `src/app.ts` (or the main Express app file), import `tenantMiddleware` and mount it after the JWT auth middleware and before any route handlers that require tenant context:

```typescript
import { tenantMiddleware } from './middleware/tenant';

// existing:
app.use(jwtMiddleware);
// add:
app.use(tenantMiddleware);
// existing:
app.use('/api', apiRouter);
```

Public routes (health checks, auth callbacks) that must remain accessible without tenant context must be registered before `tenantMiddleware`, or `tenantMiddleware` must be scoped to `/api` only.

**Acceptance Criteria**

- A `GET /api/...` request without a JWT org claim returns `403` with `{ "error": "Missing tenant context" }`.
- A `GET /api/...` request with a valid JWT containing `https://yourapp.com/tenant_id` claim reaches the route handler and `tenantStorage.getStore()` is non-null inside that handler.
- A health check route registered before `tenantMiddleware` (e.g., `GET /health`) continues to return `200` without a JWT.

---

### M22: Add ESLint rule disallowing direct `pool.query` calls

In the ESLint config (`.eslintrc.js`, `.eslintrc.cjs`, or `eslint.config.js` at repo root or `src/`), add a `no-restricted-syntax` entry:

```javascript
{
  selector: "CallExpression[callee.object.name='pool'][callee.property.name='query']",
  message: "Use withTenantConnection() instead of pool.query() — direct pool.query() bypasses tenant context and RLS."
}
```

Add this entry to the existing `no-restricted-syntax` array (create the rule if absent). Apply to all `*.ts` files under `src/`.

**Acceptance Criteria**

- Running `eslint src/` on a file containing `pool.query(sql, params)` reports an ESLint error citing the message about `withTenantConnection()`.
- Running `eslint src/` on a file containing `withTenantConnection(callback)` reports no error for that expression.
- Existing `eslint src/` output (number of errors/warnings) is unchanged on files that contain neither pattern.

---

## Phase 3 — Polish

### M23: Update C4 container diagram for tenant context propagation

Locate the C4 container diagram (glob `docs/c4/*.md` or `docs/architecture/*.md`). Update each service container's description and relationship labels to reflect RFC-004:

- **Auth0 container description**: append "Issues JWT with `tenant_id` custom claim via post-login Action"
- **Express API Server**: append "Extracts `tenant_id` from JWT via `TenantMiddleware`; propagates via AsyncLocalStorage"
- **Django services** (`billing_svc`, `notif_svc`, `user_svc`): append "Extracts `tenant_id` from EventEnvelope or JWT via `TenantMiddleware`; propagates via ContextVar"
- **Celery Workers**: append "Extracts `tenant_id` from task header `x_tenant_id` via `TenantAwareTask`"
- **PostgreSQL container description**: append "RLS enforced on all tenant-scoped tables via `app.current_tenant` GUC"
- **`Rel()` labels** for service→DB connections: append `"tenant_id set via SET LOCAL app.current_tenant"`
- **`Rel()` label** for API→RabbitMQ: append `"EventEnvelope carries tenant_id"`
- **`Rel()` label** for API→Bull: append `"job payload carries tenant_id"`

Add Change Log entry: `2026-04-19: Updated to reflect RFC-004 tenant context propagation across all services`.

Do not add new containers — RFC-004 introduces no new infrastructure components.

**Acceptance Criteria**

- The C4 diagram file renders without syntax errors.
- Every service-to-database `Rel()` label references tenant context or RLS.
- The `shared.tenants` table (or the tenant identity concept) is mentioned in the diagram as the source of truth for tenant identity.

---

## Change Log

- 2026-04-19: Initial plan created from RFC-004
