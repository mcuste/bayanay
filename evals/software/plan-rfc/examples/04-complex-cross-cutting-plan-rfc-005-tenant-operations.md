# PLAN-RFC-005: Tenant Operations

**RFC**: RFC-005 — Tenant Operations: Configuration, Feature Flags, Job Scoping, and Usage Billing
**Status**: Ready
**Created**: 2026-04-19
**Last Updated**: 2026-04-19

## Open Question Resolutions

RFC-005 has four open questions. Three are must-resolve before implementation begins:

1. **Q1 — Usage metering granularity**: Plan uses per-call `billing.usage.recorded` events. Each service emits one event per API call. Batching at middleware level is deferred until RabbitMQ throughput becomes a measured concern.
2. **Q2 — Stripe subscription model**: Plan assumes flat-rate subscription + metered overages. Each Stripe Subscription has a metered `SubscriptionItem` per metric (identified by `metadata.metric`). `_get_subscription_item()` in Phase 2 uses `stripe.Subscription.list` to find the matching item.
3. **Q3 — Cache invalidation**: Application-level invalidation — the writer calls `invalidate_feature_flag_cache()` explicitly. Trigger-based invalidation deferred to a future RFC.
4. **Q4 — Bull wildcard queue subscription**: Redis SCAN polling every 30 seconds. `ActiveQueueRegistry` in `src/workers/queue-registry.ts` scans for `bull:tenant:*:{jobType}:*` keys and creates Queue instances for any new queue names found.

---

## File Structure Map

| File | Action | Responsibility |
|---|---|---|
| `shared/tenancy/flags.py` | Create | `GLOBAL_FEATURE_DEFAULTS: dict[str, bool]` — 4 flag key defaults |
| `shared/tenancy/config.py` | Create | `TenantConfig`, `TenantFeatureFlag` ORM models; `is_feature_enabled()`, `get_config()` DB functions; `get_feature_flag_cached()`, `invalidate_feature_flag_cache()` Redis wrappers |
| `shared/tenancy/context.py` | Modify | Add `get_current_tenant_id()` helper if absent — raises `RuntimeError` when ContextVar is `None` |
| `shared_events/payloads.py` | Modify | Add `TenantCreatedPayload` and `UsageRecordedPayload` frozen dataclasses |
| `billing_svc/models.py` | Modify | Add `stripe_customer_id: Mapped[str \| None]` to `Tenant`; add `UsageRecord` ORM model |
| `billing_svc/events/handlers.py` | Create | `handle_tenant_created()` Stripe Customer provisioning; `handle_usage_recorded()` UsageRecord insert |
| `billing_svc/consumers.py` | Create | Kombu `ConsumerMixin` wiring `handle_tenant_created` to `tenant.created` and `handle_usage_recorded` to `billing.usage.recorded` |
| `billing_svc/tasks/usage_reporter.py` | Create | `submit_usage_to_stripe()` Celery beat task; `_submit_for_tenant()` per-tenant aggregation + Stripe submission |
| `billing_svc/celery.py` | Modify | Add `submit_usage_to_stripe` to `CELERY_BEAT_SCHEDULE` with daily midnight cron |
| `shared/migrations/0003_add_tenant_config_tables.py` | Create | Alembic: `tenant_configs` and `tenant_feature_flags` tables in `shared` schema |
| `billing_svc/migrations/0003_add_usage_records.py` | Create | Alembic: `stripe_customer_id` on `shared.tenants`; `usage_records` table in `billing_svc` schema with RLS |
| `src/jobs/tenant-queue.ts` | Create | `getQueue(jobType)` factory with tenant-prefixed names; `enqueueJob(jobType, payload)` with `tenant_id` injection |
| `src/workers/tenant-worker.ts` | Create | `processTenantJob(processor)` HOF — reads `job.data.tenant_id`, sets AsyncLocalStorage before delegating |
| `src/workers/queue-registry.ts` | Create | `ActiveQueueRegistry` — scans Redis every 30s for `bull:tenant:*:{jobType}:*` keys; creates Queue instances and registers processor |

---

## Phase 1 — Core

### M1: Create `shared/tenancy/flags.py` with `GLOBAL_FEATURE_DEFAULTS`

Create `shared/tenancy/flags.py`:

```python
# shared/tenancy/flags.py

GLOBAL_FEATURE_DEFAULTS: dict[str, bool] = {
    "sso_enabled": False,
    "advanced_analytics": False,
    "api_rate_limit_override": False,
    "data_export": True,
}
```

No other logic in this file. Imported by `shared/tenancy/config.py` as the fallback for flag evaluation when no per-tenant override exists.

**Acceptance Criteria**

- `from shared.tenancy.flags import GLOBAL_FEATURE_DEFAULTS` succeeds with no error.
- `GLOBAL_FEATURE_DEFAULTS["sso_enabled"] is False` and `GLOBAL_FEATURE_DEFAULTS["data_export"] is True`.
- `GLOBAL_FEATURE_DEFAULTS` contains exactly 4 keys: `"sso_enabled"`, `"advanced_analytics"`, `"api_rate_limit_override"`, `"data_export"`.

---

### M2: Create `shared/tenancy/config.py` with `TenantConfig` and `TenantFeatureFlag` ORM models

Create `shared/tenancy/config.py` with model definitions only — no service functions yet:

```python
# shared/tenancy/config.py
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from shared.db import Base  # use project-wide DeclarativeBase; if absent, define inline


class TenantConfig(Base):
    __tablename__ = "tenant_configs"
    __table_args__ = {"schema": "shared"}

    tenant_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("shared.tenants.id"), primary_key=True
    )
    key: Mapped[str] = mapped_column(String(128), primary_key=True)
    value: Mapped[str] = mapped_column(Text, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class TenantFeatureFlag(Base):
    __tablename__ = "tenant_feature_flags"
    __table_args__ = {"schema": "shared"}

    tenant_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("shared.tenants.id"), primary_key=True
    )
    flag_key: Mapped[str] = mapped_column(String(128), primary_key=True)
    enabled: Mapped[bool] = mapped_column(Boolean, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
```

If the project does not have a shared `Base` in `shared/db.py`, define `class Base(DeclarativeBase): pass` inline in this file. The models are accessed by the config service using `admin_context()` or explicit `WHERE tenant_id = ?` — they are NOT subject to RFC-004 RLS policies.

**Acceptance Criteria**

- `from shared.tenancy.config import TenantConfig, TenantFeatureFlag` succeeds with no import error.
- `TenantConfig.__tablename__ == "tenant_configs"` and `TenantConfig.__table_args__ == {"schema": "shared"}`.
- `TenantFeatureFlag.__tablename__ == "tenant_feature_flags"` and `TenantFeatureFlag.__table_args__ == {"schema": "shared"}`.

---

### M3: Add `get_current_tenant_id()` helper to `shared/tenancy/context.py`

In `shared/tenancy/context.py` (created in RFC-004), add `get_current_tenant_id()` if it does not already exist:

```python
def get_current_tenant_id() -> uuid.UUID:
    tenant_id = _current_tenant_id.get()
    if tenant_id is None:
        raise RuntimeError(
            "Called outside tenant context — wrap caller in tenant_context()"
        )
    return tenant_id
```

Position: after `admin_context()`. Add to `__all__` in `shared/tenancy/__init__.py` as well. If `get_current_tenant_id()` already exists in `context.py`, skip this milestone.

**Acceptance Criteria**

- Inside `with tenant_context(some_uuid)`, `get_current_tenant_id()` returns `some_uuid`.
- Outside any `tenant_context`, `get_current_tenant_id()` raises `RuntimeError` with message containing `"outside tenant context"`.
- `from shared.tenancy import get_current_tenant_id` succeeds with no error.

---

### M4: Add `is_feature_enabled()` to `shared/tenancy/config.py`

In `shared/tenancy/config.py`, add imports and `is_feature_enabled()` after the model definitions:

```python
from sqlalchemy.orm import Session

from shared.tenancy.context import get_current_tenant_id
from shared.tenancy.flags import GLOBAL_FEATURE_DEFAULTS


def is_feature_enabled(session: Session, flag_key: str) -> bool:
    tenant_id = get_current_tenant_id()
    row = session.get(TenantFeatureFlag, (tenant_id, flag_key))
    if row is not None:
        return row.enabled
    return GLOBAL_FEATURE_DEFAULTS.get(flag_key, False)
```

No Redis in Phase 1 — direct DB lookup on every call. The Redis-cached variant is added in Phase 2.

**Acceptance Criteria**

- When called inside `tenant_context(tenant_uuid)` with a `TenantFeatureFlag(tenant_id=tenant_uuid, flag_key="sso_enabled", enabled=True)` row present, returns `True`.
- When called inside `tenant_context(tenant_uuid)` with no matching row in `tenant_feature_flags`, returns `GLOBAL_FEATURE_DEFAULTS.get(flag_key, False)`.
- When called outside any `tenant_context`, raises `RuntimeError` (propagates from `get_current_tenant_id()`).

---

### M5: Add `get_config()` to `shared/tenancy/config.py`

In `shared/tenancy/config.py`, add `get_config()` after `is_feature_enabled()`:

```python
def get_config(session: Session, key: str) -> str | None:
    tenant_id = get_current_tenant_id()
    row = session.get(TenantConfig, (tenant_id, key))
    return row.value if row is not None else None
```

No caching in Phase 1. Returns `None` when no override exists for the key — callers must handle `None` as "use application default".

**Acceptance Criteria**

- When called inside `tenant_context(tenant_uuid)` with a `TenantConfig(tenant_id=tenant_uuid, key="max_users", value="100")` row present, returns `"100"`.
- When called inside `tenant_context(tenant_uuid)` with no matching row, returns `None`.
- When called outside any `tenant_context`, raises `RuntimeError`.

---

### M6: Create `shared/migrations/0003_add_tenant_config_tables.py`

Create `shared/migrations/0003_add_tenant_config_tables.py` as an Alembic migration. Set `depends_on` to the most recent revision in `shared/migrations/`.

```python
import sqlalchemy as sa
from alembic import op


def upgrade() -> None:
    op.create_table(
        "tenant_configs",
        sa.Column("tenant_id", sa.UUID(as_uuid=True), sa.ForeignKey("shared.tenants.id"), primary_key=True),
        sa.Column("key", sa.String(128), primary_key=True),
        sa.Column("value", sa.Text, nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
        schema="shared",
    )
    op.create_table(
        "tenant_feature_flags",
        sa.Column("tenant_id", sa.UUID(as_uuid=True), sa.ForeignKey("shared.tenants.id"), primary_key=True),
        sa.Column("flag_key", sa.String(128), primary_key=True),
        sa.Column("enabled", sa.Boolean, nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
        schema="shared",
    )


def downgrade() -> None:
    op.drop_table("tenant_feature_flags", schema="shared")
    op.drop_table("tenant_configs", schema="shared")
```

These tables are NOT subject to RFC-004 RLS — do NOT add `ENABLE ROW LEVEL SECURITY` or RLS policies. They live in `shared` schema and are queried by the config service with explicit `WHERE tenant_id = ?` clauses.

**Acceptance Criteria**

- `alembic upgrade head` (as `app_admin`) creates both `shared.tenant_configs` and `shared.tenant_feature_flags`.
- `shared.tenant_configs` has composite primary key `(tenant_id, key)` with FK to `shared.tenants.id`.
- `shared.tenant_feature_flags` has composite primary key `(tenant_id, flag_key)` with FK to `shared.tenants.id`.
- `alembic downgrade -1` drops both tables cleanly.

---

### M7: Add `TenantCreatedPayload` and `UsageRecordedPayload` to `shared_events/payloads.py`

In `shared_events/payloads.py`, append two new frozen dataclasses after the last existing payload class. Add `from datetime import datetime` to imports if absent:

```python
@dataclass(frozen=True)
class TenantCreatedPayload:
    tenant_id: str   # UUID as string — mirrors EventEnvelope.tenant_id for consumers inspecting payload only
    slug: str
    name: str


@dataclass(frozen=True)
class UsageRecordedPayload:
    metric: str          # e.g. "api_calls", "seats", "storage_gb"
    quantity: int
    occurred_at: datetime
```

`UsageRecordedPayload` omits `tenant_id` — the tenant is carried by `EventEnvelope.tenant_id`.

**Acceptance Criteria**

- `from shared_events.payloads import TenantCreatedPayload, UsageRecordedPayload` succeeds with no error.
- `TenantCreatedPayload(tenant_id="x", slug="acme", name="Acme")` constructs without error; `payload.slug = "y"` raises `FrozenInstanceError`.
- `UsageRecordedPayload(metric="api_calls", quantity=100, occurred_at=datetime.utcnow())` constructs without error.

---

### M8: Add `stripe_customer_id` column to `Tenant` in `billing_svc/models.py`

In `billing_svc/models.py`, locate the `Tenant` ORM model (added in RFC-004). Add one column after `auth0_org_id`:

```python
stripe_customer_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
```

`String(64)` accommodates the Stripe customer ID format (`cus_` + up to 58 chars). Nullable because existing tenants do not have a Stripe Customer until `handle_tenant_created` runs.

**Acceptance Criteria**

- `from billing_svc.models import Tenant` succeeds with no error.
- `Tenant.stripe_customer_id.property.columns[0].nullable is True`.
- `python -c "import billing_svc.models"` exits 0.

---

### M9: Add `UsageRecord` ORM model to `billing_svc/models.py`

In `billing_svc/models.py`, add `UsageRecord` after the `Tenant` class. Add `BigInteger` to the existing `sqlalchemy` import:

```python
class UsageRecord(Base):
    __tablename__ = "usage_records"
    __table_args__ = {"schema": "billing_svc"}

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tenant_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("shared.tenants.id"), nullable=False, index=True
    )
    metric: Mapped[str] = mapped_column(String(64), nullable=False)
    quantity: Mapped[int] = mapped_column(BigInteger, nullable=False)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    reported_to_stripe: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
```

**Acceptance Criteria**

- `from billing_svc.models import UsageRecord` succeeds with no error.
- `UsageRecord.__tablename__ == "usage_records"` and `UsageRecord.__table_args__ == {"schema": "billing_svc"}`.
- `UsageRecord` has a `reported_to_stripe` mapped column with `default=False`.
- `python -c "import billing_svc.models"` exits 0.

---

### M10: Create `billing_svc/migrations/0003_add_usage_records.py`

Create `billing_svc/migrations/0003_add_usage_records.py`. Set `depends_on` to the most recent revision in `billing_svc/migrations/` (e.g., `0002_add_tenant_id`).

```python
import sqlalchemy as sa
from alembic import op


def upgrade() -> None:
    # Add stripe_customer_id to shared.tenants
    op.add_column(
        "tenants",
        sa.Column("stripe_customer_id", sa.String(64), nullable=True),
        schema="shared",
    )

    # Create usage_records with RLS (same pattern as RFC-004)
    op.create_table(
        "usage_records",
        sa.Column("id", sa.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "tenant_id",
            sa.UUID(as_uuid=True),
            sa.ForeignKey("shared.tenants.id"),
            nullable=False,
        ),
        sa.Column("metric", sa.String(64), nullable=False),
        sa.Column("quantity", sa.BigInteger, nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "reported_to_stripe", sa.Boolean, nullable=False, server_default="false"
        ),
        schema="billing_svc",
    )
    op.create_index(
        "ix_usage_records_tenant_id", "usage_records", ["tenant_id"], schema="billing_svc"
    )
    op.create_index(
        "ix_usage_records_reported",
        "usage_records",
        ["reported_to_stripe"],
        schema="billing_svc",
    )
    op.execute(sa.text("ALTER TABLE billing_svc.usage_records ENABLE ROW LEVEL SECURITY"))
    op.execute(sa.text("ALTER TABLE billing_svc.usage_records FORCE ROW LEVEL SECURITY"))
    op.execute(sa.text(
        "CREATE POLICY tenant_isolation ON billing_svc.usage_records "
        "USING (NULLIF(current_setting('app.current_tenant', TRUE), '')::uuid = tenant_id)"
    ))


def downgrade() -> None:
    op.execute(sa.text("DROP POLICY IF EXISTS tenant_isolation ON billing_svc.usage_records"))
    op.execute(sa.text("ALTER TABLE billing_svc.usage_records DISABLE ROW LEVEL SECURITY"))
    op.drop_index("ix_usage_records_reported", table_name="usage_records", schema="billing_svc")
    op.drop_index("ix_usage_records_tenant_id", table_name="usage_records", schema="billing_svc")
    op.drop_table("usage_records", schema="billing_svc")
    op.drop_column("tenants", "stripe_customer_id", schema="shared")
```

**Acceptance Criteria**

- `alembic upgrade head` (as `app_admin`) creates `billing_svc.usage_records` and adds `stripe_customer_id` to `shared.tenants`.
- `billing_svc.usage_records` has indexes on `tenant_id` and `reported_to_stripe`.
- `SELECT * FROM billing_svc.usage_records` as `app_user` with no `app.current_tenant` GUC returns 0 rows (RLS active).
- `alembic downgrade -1` reverses all changes cleanly.

---

### M11: Create `billing_svc/events/handlers.py` with `handle_tenant_created()`

Create `billing_svc/events/handlers.py`:

```python
# billing_svc/events/handlers.py
import stripe
from sqlalchemy.orm import Session

from billing_svc.models import Tenant
from shared_events.envelope import EventEnvelope


async def handle_tenant_created(envelope: EventEnvelope, session: Session) -> None:
    tenant = session.get(Tenant, envelope.tenant_id)
    if tenant is None:
        return
    customer = stripe.Customer.create(
        name=tenant.name,
        metadata={
            "tenant_id": str(envelope.tenant_id),
            "tenant_slug": tenant.slug,
        },
    )
    tenant.stripe_customer_id = customer.id
    session.commit()
```

`stripe.api_key` is set in the application bootstrap via environment variable (`STRIPE_API_KEY`). `session.get(Tenant, envelope.tenant_id)` works because `billing_svc` maps `Tenant` from RFC-004.

**Acceptance Criteria**

- Given a `Tenant` row with `stripe_customer_id=None`, `handle_tenant_created` calls `stripe.Customer.create` with `name=tenant.name` and `metadata["tenant_id"]=str(tenant_id)`, then sets `tenant.stripe_customer_id = customer.id` and commits.
- Given an envelope with a `tenant_id` not found in `shared.tenants`, the function returns without calling `stripe.Customer.create` or raising.
- `from billing_svc.events.handlers import handle_tenant_created` succeeds with no import error.

---

### M12: Add `handle_usage_recorded()` to `billing_svc/events/handlers.py`

In `billing_svc/events/handlers.py`, add imports and `handle_usage_recorded()`:

```python
import uuid

from billing_svc.models import UsageRecord
from shared_events.payloads import UsageRecordedPayload


async def handle_usage_recorded(envelope: EventEnvelope, session: Session) -> None:
    payload = UsageRecordedPayload(**envelope.payload)
    record = UsageRecord(
        id=uuid.uuid4(),
        tenant_id=envelope.tenant_id,
        metric=payload.metric,
        quantity=payload.quantity,
        occurred_at=payload.occurred_at,
        reported_to_stripe=False,
    )
    session.add(record)
    session.commit()
```

**Acceptance Criteria**

- Given an `EventEnvelope` with `event_type="billing.usage.recorded"` and `payload={"metric": "api_calls", "quantity": 5, "occurred_at": "..."}`, `handle_usage_recorded` inserts one `UsageRecord` row with `reported_to_stripe=False`.
- The inserted row's `tenant_id` equals `envelope.tenant_id`.
- `from billing_svc.events.handlers import handle_usage_recorded` succeeds with no import error.

---

### M13: Create `billing_svc/tasks/usage_reporter.py` with `submit_usage_to_stripe()` skeleton

Create `billing_svc/tasks/usage_reporter.py`. Phase 1 implements the task skeleton: tenant enumeration + usage record aggregation. The Stripe API submission is added in Phase 2 (M20).

```python
# billing_svc/tasks/usage_reporter.py
from sqlalchemy import select

from billing_svc.celery import app
from billing_svc.db import Session
from billing_svc.models import Tenant, TenantStatus, UsageRecord
from shared.tenancy.context import admin_context, tenant_context


@app.task
def submit_usage_to_stripe() -> None:
    with admin_context():
        session = Session()
        tenants = session.scalars(
            select(Tenant).where(
                Tenant.status == TenantStatus.ACTIVE,
                Tenant.stripe_customer_id.isnot(None),
            )
        ).all()
        session.close()

    for tenant in tenants:
        with tenant_context(tenant.id):
            _submit_for_tenant(tenant)


def _submit_for_tenant(tenant: Tenant) -> None:
    session = Session()
    try:
        records = session.scalars(
            select(UsageRecord).where(
                UsageRecord.tenant_id == tenant.id,
                UsageRecord.reported_to_stripe.is_(False),
            )
        ).all()

        by_metric: dict[str, int] = {}
        for record in records:
            by_metric[record.metric] = by_metric.get(record.metric, 0) + record.quantity

        # Stripe submission and mark-as-reported added in Phase 2 (M20)
        _ = by_metric
    finally:
        session.close()
```

**Acceptance Criteria**

- `from billing_svc.tasks.usage_reporter import submit_usage_to_stripe` succeeds with no import error.
- `submit_usage_to_stripe` is a registered Celery task (`submit_usage_to_stripe.name` is not `None`).
- `_submit_for_tenant` queries `UsageRecord` rows scoped to `tenant.id` where `reported_to_stripe=False` — no rows from other tenants are returned (RLS enforced inside `tenant_context`).

---

### M14: Create `src/jobs/tenant-queue.ts` with `getQueue()` and `enqueueJob()`

Create `src/jobs/tenant-queue.ts`:

```typescript
// src/jobs/tenant-queue.ts
import Queue from 'bull';
import { tenantStorage } from '../middleware/tenant';
import { redisConfig } from '../config/redis';

const queues = new Map<string, Queue.Queue>();

function getQueue(jobType: string): Queue.Queue {
  const store = tenantStorage.getStore();
  if (!store) throw new Error('getQueue called outside tenant context');
  const queueName = `tenant:${store.tenantId}:${jobType}`;
  if (!queues.has(queueName)) {
    queues.set(queueName, new Queue(queueName, { redis: redisConfig }));
  }
  return queues.get(queueName)!;
}

export function enqueueJob(jobType: string, payload: object): Promise<Queue.Job> {
  const store = tenantStorage.getStore();
  if (!store) throw new Error('enqueueJob called outside tenant context');
  return getQueue(jobType).add({ ...payload, tenant_id: store.tenantId });
}
```

`tenantStorage` is the `AsyncLocalStorage` exported by `src/middleware/tenant.ts` (RFC-004). `redisConfig` is the existing Redis connection config used elsewhere in the project — import from `../config/redis` or the equivalent path.

**Acceptance Criteria**

- When called inside `tenantStorage.run({ tenantId: "abc" }, ...)`, `enqueueJob("reports", {})` adds a job to a Bull queue named `"tenant:abc:reports"` with `job.data.tenant_id === "abc"`.
- Calling `enqueueJob("reports", {})` with `tenantStorage.getStore()` returning `undefined` throws `Error` with message `"enqueueJob called outside tenant context"`.
- `tsc --noEmit` passes on this file with no type errors.

---

### M15: Create `src/workers/tenant-worker.ts` with `processTenantJob()`

Create `src/workers/tenant-worker.ts`:

```typescript
// src/workers/tenant-worker.ts
import { Job } from 'bull';
import { tenantStorage } from '../middleware/tenant';

export function processTenantJob(
  processor: (job: Job) => Promise<void>
): (job: Job) => Promise<void> {
  return async (job: Job): Promise<void> => {
    const tenantId = job.data.tenant_id as string | undefined;
    if (!tenantId) {
      throw new Error(`Job ${job.id} missing tenant_id in job.data`);
    }
    await tenantStorage.run({ tenantId }, () => processor(job));
  };
}
```

Usage: `queue.process(processTenantJob(myHandler))`. The wrapper sets AsyncLocalStorage before calling the handler so that `withTenantConnection()` (RFC-004) picks up the correct tenant for RLS.

**Acceptance Criteria**

- When `job.data.tenant_id === "abc"`, the returned function calls `processor(job)` with `tenantStorage.getStore()?.tenantId === "abc"` inside `processor`.
- When `job.data.tenant_id` is absent, the returned function throws `Error` with message containing `"missing tenant_id"`.
- After `processor` completes (success or throw), `tenantStorage.getStore()` returns whatever value was set before the call (AsyncLocalStorage scope is restored).
- `tsc --noEmit` passes on this file with no type errors.

---

## Phase 2 — Details

### M16: Add Redis-cached `get_feature_flag_cached()` to `shared/tenancy/config.py`

In `shared/tenancy/config.py`, add import `from redis import Redis` at the top and the cached variant after `is_feature_enabled()`:

```python
_FLAG_CACHE_TTL = 60  # seconds


def get_feature_flag_cached(redis_client: Redis, session: Session, flag_key: str) -> bool:
    tenant_id = get_current_tenant_id()
    cache_key = f"tenant:{tenant_id}:flag:{flag_key}"
    cached = redis_client.get(cache_key)
    if cached is not None:
        return cached == b"1"
    result = is_feature_enabled(session, flag_key)
    redis_client.set(cache_key, b"1" if result else b"0", ex=_FLAG_CACHE_TTL)
    return result
```

Cache stores `b"1"` (enabled) or `b"0"` (disabled). TTL 60 seconds. Cache miss falls through to `is_feature_enabled()`. Cache-aside — no write-through.

**Acceptance Criteria**

- On first call with an empty Redis, `get_feature_flag_cached` queries the DB via `is_feature_enabled()` and writes the result to `tenant:{uuid}:flag:{key}` with 60s TTL.
- On second call within TTL, `get_feature_flag_cached` returns the cached value without issuing any SQL (no `session` calls).
- `redis_client.get(f"tenant:{tenant_id}:flag:sso_enabled")` returns `b"1"` when enabled, `b"0"` when disabled.

---

### M17: Add `invalidate_feature_flag_cache()` to `shared/tenancy/config.py`

In `shared/tenancy/config.py`, add `invalidate_feature_flag_cache()` after `get_feature_flag_cached()`:

```python
def invalidate_feature_flag_cache(
    redis_client: Redis, tenant_id: uuid.UUID, flag_key: str
) -> None:
    cache_key = f"tenant:{tenant_id}:flag:{flag_key}"
    redis_client.delete(cache_key)
```

Takes explicit `tenant_id` (not ContextVar) to support callers writing flags in `admin_context()`. Must be called by any code path that writes a row to `tenant_feature_flags`.

**Acceptance Criteria**

- After `invalidate_feature_flag_cache(redis_client, tenant_uuid, "sso_enabled")`, `redis_client.get(f"tenant:{tenant_uuid}:flag:sso_enabled")` returns `None`.
- Calling on a key not present in Redis does not raise an error.
- `from shared.tenancy.config import invalidate_feature_flag_cache` succeeds with no import error.

---

### M18: Create `src/workers/queue-registry.ts` with `ActiveQueueRegistry`

Create `src/workers/queue-registry.ts` to resolve RFC-005 Q4 (Bull wildcard subscription). Strategy: Redis SCAN every 30 seconds.

```typescript
// src/workers/queue-registry.ts
import Queue, { Job } from 'bull';
import { createClient } from 'redis';
import { redisConfig } from '../config/redis';

type JobProcessor = (job: Job) => Promise<void>;

export class ActiveQueueRegistry {
  private readonly queues = new Map<string, Queue.Queue>();
  private intervalId: NodeJS.Timeout | null = null;

  constructor(
    private readonly jobTypes: string[],
    private readonly processor: JobProcessor,
    private readonly pollIntervalMs = 30_000,
  ) {}

  start(): void {
    void this._refresh();
    this.intervalId = setInterval(() => void this._refresh(), this.pollIntervalMs);
  }

  stop(): void {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
  }

  private async _refresh(): Promise<void> {
    const redis = createClient(redisConfig as Parameters<typeof createClient>[0]);
    await redis.connect();
    try {
      for (const jobType of this.jobTypes) {
        const pattern = `bull:tenant:*:${jobType}:*`;
        for await (const key of redis.scanIterator({ MATCH: pattern, COUNT: 100 })) {
          const queueName = this._extractQueueName(key);
          if (queueName && !this.queues.has(queueName)) {
            const queue = new Queue(queueName, { redis: redisConfig });
            queue.process(this.processor);
            this.queues.set(queueName, queue);
          }
        }
      }
    } finally {
      await redis.disconnect();
    }
  }

  private _extractQueueName(bullKey: string): string | null {
    // Bull stores queue metadata as "bull:{queueName}:{suffix}"
    // Queue names have the form "tenant:{tenantId}:{jobType}"
    const match = bullKey.match(/^bull:(tenant:[^:]+:[^:]+):/);
    return match?.[1] ?? null;
  }
}
```

Usage in the worker entry point:

```typescript
const registry = new ActiveQueueRegistry(
  ['reports', 'exports'],
  processTenantJob(myHandler),
);
registry.start();
```

**Acceptance Criteria**

- On `start()`, `_refresh()` is invoked immediately and then every `pollIntervalMs` milliseconds.
- When Redis contains a key matching `bull:tenant:abc:reports:*`, `_refresh()` creates a Bull queue named `"tenant:abc:reports"` and registers `processor` on it.
- For a queue name already in `this.queues`, `_refresh()` does not create a duplicate Queue instance or re-register the processor.
- `stop()` cancels the interval so no further `_refresh()` calls are scheduled.
- `tsc --noEmit` passes on this file with no type errors.

---

### M19: Create `billing_svc/consumers.py` wiring RabbitMQ handlers

Create `billing_svc/consumers.py` using Kombu (already a Celery transitive dependency):

```python
# billing_svc/consumers.py
import asyncio
import json

from kombu import Connection, Exchange, Queue
from kombu.mixins import ConsumerMixin
from sqlalchemy.orm import Session

from billing_svc.db import Session as DbSession
from billing_svc.events.handlers import handle_tenant_created, handle_usage_recorded
from shared_events.envelope import EventEnvelope

EVENTS_EXCHANGE = Exchange("events", type="topic", durable=True)

TENANT_CREATED_QUEUE = Queue(
    "billing_svc.tenant_created",
    exchange=EVENTS_EXCHANGE,
    routing_key="tenant.created",
    durable=True,
)
USAGE_RECORDED_QUEUE = Queue(
    "billing_svc.usage_recorded",
    exchange=EVENTS_EXCHANGE,
    routing_key="billing.usage.recorded",
    durable=True,
)

_HANDLERS = {
    "tenant.created": handle_tenant_created,
    "billing.usage.recorded": handle_usage_recorded,
}


class BillingConsumer(ConsumerMixin):
    def __init__(self, connection: Connection) -> None:
        self.connection = connection

    def get_consumers(self, Consumer, channel):
        return [
            Consumer(
                queues=[TENANT_CREATED_QUEUE, USAGE_RECORDED_QUEUE],
                callbacks=[self._on_message],
                accept=["json"],
            )
        ]

    def _on_message(self, body, message) -> None:
        raw = json.loads(body) if isinstance(body, str) else body
        envelope = EventEnvelope(**raw)
        handler = _HANDLERS.get(envelope.event_type)
        if handler:
            session: Session = DbSession()
            try:
                asyncio.run(handler(envelope, session))
            finally:
                session.close()
        message.ack()
```

**Acceptance Criteria**

- `BillingConsumer.get_consumers()` declares exactly `TENANT_CREATED_QUEUE` and `USAGE_RECORDED_QUEUE`.
- A message with `event_type="tenant.created"` dispatches to `handle_tenant_created`.
- A message with `event_type="billing.usage.recorded"` dispatches to `handle_usage_recorded`.
- `message.ack()` is called after the handler returns, including when `handler` is `None` (unknown event types are acknowledged and dropped).

---

### M20: Add Stripe submission to `_submit_for_tenant()` in `billing_svc/tasks/usage_reporter.py`

In `billing_svc/tasks/usage_reporter.py`, replace the Phase 1 stub body of `_submit_for_tenant()` with the full implementation. Add `import stripe` at the top.

```python
def _submit_for_tenant(tenant: Tenant) -> None:
    session = Session()
    try:
        records = session.scalars(
            select(UsageRecord).where(
                UsageRecord.tenant_id == tenant.id,
                UsageRecord.reported_to_stripe.is_(False),
            )
        ).all()
        if not records:
            return

        by_metric: dict[str, int] = {}
        for record in records:
            by_metric[record.metric] = by_metric.get(record.metric, 0) + record.quantity

        for metric, total in by_metric.items():
            item_id = _get_subscription_item(tenant.stripe_customer_id, metric)
            if item_id is None:
                continue  # tenant has no subscription item for this metric — skip
            stripe.UsageRecord.create(
                subscription_item=item_id,
                quantity=total,
                action="increment",
            )

        for record in records:
            record.reported_to_stripe = True
        session.commit()
    finally:
        session.close()


def _get_subscription_item(customer_id: str, metric: str) -> str | None:
    """Return the Stripe SubscriptionItem ID for this customer + metric.

    Resolves Q2: flat-rate + usage overages model. Each metered subscription item
    carries metadata.metric identifying which usage metric it tracks.
    """
    subscriptions = stripe.Subscription.list(customer=customer_id, status="active", limit=1)
    if not subscriptions.data:
        return None
    for item in subscriptions.data[0]["items"]["data"]:
        if item.get("metadata", {}).get("metric") == metric:
            return item["id"]
    return None
```

**Acceptance Criteria**

- Given a tenant with an active Stripe Subscription containing a SubscriptionItem with `metadata.metric="api_calls"`, `_submit_for_tenant` calls `stripe.UsageRecord.create` with the correct `subscription_item` and `quantity` equal to the sum of all unreported records for that metric.
- After a successful Stripe call, all processed `UsageRecord` rows have `reported_to_stripe=True` committed.
- When `_get_subscription_item` returns `None` (no matching subscription item), `stripe.UsageRecord.create` is not called for that metric and existing records remain `reported_to_stripe=False`.

---

### M21: Register `submit_usage_to_stripe` in Celery beat schedule in `billing_svc/celery.py`

In `billing_svc/celery.py`, add import and beat schedule entry. Add `from celery.schedules import crontab` to imports:

```python
from celery.schedules import crontab
from billing_svc.tasks.usage_reporter import submit_usage_to_stripe  # noqa: F401

app.conf.beat_schedule = {
    **getattr(app.conf, "beat_schedule", {}),
    "submit-usage-to-stripe-daily": {
        "task": "billing_svc.tasks.usage_reporter.submit_usage_to_stripe",
        "schedule": crontab(hour=0, minute=0),  # daily at midnight UTC
    },
}
```

The `noqa: F401` comment silences the "imported but unused" linter warning — the import is needed to register the task with Celery's task registry.

**Acceptance Criteria**

- `billing_svc.celery.app.conf.beat_schedule` contains the key `"submit-usage-to-stripe-daily"`.
- The `"task"` value is `"billing_svc.tasks.usage_reporter.submit_usage_to_stripe"`.
- The `"schedule"` value is a `crontab(hour=0, minute=0)` instance.
- `python -c "import billing_svc.celery"` exits 0.

---

## Phase 3 — Polish

### M22: Update C4 container diagram for RFC-005 changes

Locate the C4 container diagram (glob `docs/c4/*.md` or `docs/architecture/c4*.md`). Apply these targeted updates — no new containers:

**Container description updates:**

- **Redis**: append `"; tenant feature flag and config cache (TTL 60s, key: tenant:{id}:flag:{key})"`
- **billing_svc**: append `"; provisions Stripe Customer on tenant.created; aggregates billing.usage.recorded events into usage_records; submits Stripe Usage Records via daily Celery beat task"`
- **RabbitMQ**: add `tenant.created` and `billing.usage.recorded` to the list of routed event types

**Rel() label updates:**

- Service → Redis: add `"feature flag cache read (TTL 60s)"`
- API Server → RabbitMQ: add `"tenant.created on tenant provisioning"`
- Any service → RabbitMQ: add `"billing.usage.recorded per metered API call"`
- billing_svc → Stripe: add `"Customer.create (tenant.created); UsageRecord.create (daily beat)"`

Add Change Log entry: `2026-04-19: Updated for RFC-005 — tenant config cache, usage metering, Stripe Customer management`.

**Acceptance Criteria**

- The C4 diagram file renders without Mermaid syntax errors.
- Redis container description references `"60s"` and `"flag"`.
- billing_svc container description references both `"Stripe Customer"` and `"usage"`.
- At least one `Rel()` label references `billing.usage.recorded`.

---

## Change Log

- 2026-04-19: Initial plan created from RFC-005
