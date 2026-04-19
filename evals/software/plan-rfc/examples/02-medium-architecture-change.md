# PLAN-RFC-005: Strangler Fig Extraction — Billing, Notifications, User Management

**RFC**: RFC-005
**Status**: Ready
**Created**: 2026-04-19
**Last Updated**: 2026-04-19

## File Structure Map

| File | Action | Responsibility |
|---|---|---|
| `shared_events/__init__.py` | Create | Re-exports `EventEnvelope`, `InvoiceCreatedPayload`, `PlanChangedPayload` |
| `shared_events/envelope.py` | Create | `EventEnvelope` Pydantic model — 9 fields (event_id, event_type, aggregate_id, aggregate_type, service_origin, occurred_at, schema_version, correlation_id, payload) |
| `shared_events/payloads.py` | Create | `InvoiceCreatedPayload` and `PlanChangedPayload` Pydantic models |
| `billing/events/__init__.py` | Create | Empty package init |
| `billing/events/outbox.py` | Create | `OutboxEntry` Django model — UUID PK, event_type, exchange, routing_key, payload JSON, created_at, published_at nullable, failed_at nullable, attempt_count |
| `billing/events/publishers.py` | Create | `EventPublisher` Protocol + `OutboxPublisher` writing to `OutboxEntry` within caller's transaction |
| `billing/events/relay.py` | Create | `drain_outbox` Celery task — drains unpublished `OutboxEntry` rows to RabbitMQ via kombu |
| `billing/events/consumers.py` | Create | `process_plan_changed` Celery task — consumes `user_management.plan.changed` |
| `billing/events/handlers.py` | Create | `handle_plan_changed(payload: PlanChangedPayload) -> None` — pure orchestration, no Celery |
| `billing/events/idempotency.py` | Create | `ProcessedEvent` Django model — event_id UUID PK, processed_at |
| `billing/events/schemas.py` | Create | `build_invoice_created_envelope()`, `parse_plan_changed_envelope()` |
| `billing/adapters/notification_adapter.py` | Create | `NotificationDispatcher` Protocol + `SynchronousDispatcher`, `EventBasedDispatcher`, `DualWriteDispatcher` — deleted post-cut-over |
| `billing/_state.py` | Create | Module-level singleton: `notification_dispatcher: Any = None` |
| `billing/apps.py` | Modify | Wire `NOTIFICATION_DISPATCH_MODE` dispatcher in `BillingConfig.ready()` |
| `billing/settings.py` | Modify | Add `NOTIFICATION_DISPATCH_MODE = "sync"` |
| `billing/celery.py` | Create | Celery app — relay beat (5 s), `billing.plan.changed` consumer queue |
| `billing_svc/manage.py` | Create | Django management entry point — `DJANGO_SETTINGS_MODULE=billing_svc.settings` |
| `billing_svc/settings.py` | Create | Django settings — `INSTALLED_APPS: ["billing"]`, DB schema billing, `CELERY_BROKER_URL` from env |
| `billing_svc/wsgi.py` | Create | WSGI entry point |
| `billing_svc/urls.py` | Create | Minimal URLconf — health endpoint only |
| `notifications/events/__init__.py` | Create | Empty package init |
| `notifications/events/idempotency.py` | Create | `ProcessedEvent` Django model for notifications — event_id UUID PK, processed_at |
| `notifications/events/handlers.py` | Create | `handle_invoice_created(payload: InvoiceCreatedPayload) -> None` — pure, no Celery |
| `notifications/events/consumers.py` | Create | `process_invoice_created` Celery task — idempotency check + handler call in one `atomic()` |
| `notifications/events/schemas.py` | Create | `parse_invoice_created_envelope(raw: dict) -> tuple[EventEnvelope, InvoiceCreatedPayload]` |
| `notifications/celery.py` | Create | Celery app — explicit `notif.invoice.created` queue bound to `billing.invoice.created` routing key |
| `notif_svc/manage.py` | Create | Django management entry point — `DJANGO_SETTINGS_MODULE=notif_svc.settings` |
| `notif_svc/settings.py` | Create | Django settings — `INSTALLED_APPS: ["notifications"]`, DB schema notif, `CELERY_BROKER_URL` from env |
| `notif_svc/wsgi.py` | Create | WSGI entry point |
| `notif_svc/urls.py` | Create | Minimal URLconf — health endpoint only |
| `user_management/events/__init__.py` | Create | Empty package init |
| `user_management/events/outbox.py` | Create | `OutboxEntry` Django model — same structure as billing, `db_table = "user_management_outbox_entry"` |
| `user_management/events/publishers.py` | Create | `EventPublisher` Protocol + `OutboxPublisher` writing to `user_management.OutboxEntry` |
| `user_management/events/relay.py` | Create | `drain_outbox` Celery task for user_management outbox |
| `user_management/events/schemas.py` | Create | `build_plan_changed_envelope()` |
| `user_management/events/idempotency.py` | Create | `ProcessedEvent` Django model for user_management (structural completeness; no consumers in this service) |
| `user_management/adapters/billing_adapter.py` | Create | `PlanRecalculationAdapter` Protocol + `SynchronousAdapter`, `EventBasedAdapter`, `DualWriteAdapter` — deleted post-cut-over |
| `user_management/_state.py` | Create | Module-level singleton: `plan_recalc_adapter: Any = None` |
| `user_management/apps.py` | Modify | Wire `PLAN_RECALC_DISPATCH_MODE` adapter in `UserManagementConfig.ready()` |
| `user_management/settings.py` | Modify | Add `PLAN_RECALC_DISPATCH_MODE = "sync"` |
| `user_management/celery.py` | Create | Celery app — relay beat (5 s), no consumer queues |
| `user_svc/manage.py` | Create | Django management entry point — `DJANGO_SETTINGS_MODULE=user_svc.settings` |
| `user_svc/settings.py` | Create | Django settings — `INSTALLED_APPS: ["user_management"]`, DB schema users, `CELERY_BROKER_URL` from env |
| `user_svc/wsgi.py` | Create | WSGI entry point |
| `user_svc/urls.py` | Create | Minimal URLconf — health endpoint only |

Django migrations (auto-generated via `makemigrations`):

| File | Action | Responsibility |
|---|---|---|
| `billing/migrations/NNNN_add_outbox_entry.py` | Create | `OutboxEntry` table |
| `billing/migrations/NNNN_add_processed_event.py` | Create | `ProcessedEvent` table |
| `notifications/migrations/NNNN_add_processed_event.py` | Create | `ProcessedEvent` table |
| `user_management/migrations/NNNN_add_outbox_entry.py` | Create | `OutboxEntry` table |

---

## Phase 1 — Core

### M1: Create `shared_events/` package with `EventEnvelope` Pydantic model

Create `shared_events/envelope.py`:

```python
from __future__ import annotations
from datetime import datetime
from typing import Any
from uuid import UUID
from pydantic import BaseModel

class EventEnvelope(BaseModel):
    event_id: UUID
    event_type: str
    aggregate_id: str
    aggregate_type: str
    service_origin: str
    occurred_at: datetime
    schema_version: int
    correlation_id: UUID | None = None
    payload: dict[str, Any]
```

Create `shared_events/__init__.py` with one line: `from shared_events.envelope import EventEnvelope`.

**Acceptance Criteria**

- `EventEnvelope(event_id=uuid4(), event_type="x", aggregate_id="1", aggregate_type="Y", service_origin="svc", occurred_at=datetime.now(UTC), schema_version=1, payload={})` instantiates without error.
- Omitting `event_type` raises `pydantic.ValidationError`.
- `correlation_id` defaults to `None` when not supplied.

---

### M2: Add `InvoiceCreatedPayload` to `shared_events/payloads.py`

Create `shared_events/payloads.py`:

```python
from uuid import UUID
from pydantic import BaseModel

class InvoiceCreatedPayload(BaseModel):
    invoice_id: UUID
    user_id: UUID
    amount_cents: int
    currency: str
```

Add to `shared_events/__init__.py`: `from shared_events.payloads import InvoiceCreatedPayload`.

**Acceptance Criteria**

- `InvoiceCreatedPayload(invoice_id=uuid4(), user_id=uuid4(), amount_cents=1000, currency="USD")` instantiates without error.
- Omitting `invoice_id` raises `ValidationError`.

---

### M3: Add `PlanChangedPayload` to `shared_events/payloads.py`

In `shared_events/payloads.py`, add after `InvoiceCreatedPayload`:

```python
class PlanChangedPayload(BaseModel):
    user_id: UUID
    old_plan: str
    new_plan: str
```

Add to `shared_events/__init__.py`: `from shared_events.payloads import PlanChangedPayload`.

**Acceptance Criteria**

- `PlanChangedPayload(user_id=uuid4(), old_plan="starter", new_plan="pro")` instantiates without error.
- Omitting `new_plan` raises `ValidationError`.

---

### M4: Create `billing/events/outbox.py` with `OutboxEntry` Django model

Create `billing/events/__init__.py` (empty). Create `billing/events/outbox.py`:

```python
import uuid
from django.db import models

class OutboxEntry(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    event_type = models.CharField(max_length=255)
    exchange = models.CharField(max_length=255)
    routing_key = models.CharField(max_length=255)
    payload = models.JSONField()
    created_at = models.DateTimeField(auto_now_add=True)
    published_at = models.DateTimeField(null=True, blank=True)
    failed_at = models.DateTimeField(null=True, blank=True)
    attempt_count = models.IntegerField(default=0)

    class Meta:
        db_table = "billing_outbox_entry"
```

**Acceptance Criteria**

- `OutboxEntry` has 9 fields: id, event_type, exchange, routing_key, payload, created_at, published_at, failed_at, attempt_count.
- `published_at` and `failed_at` are nullable (`null=True`).
- `attempt_count` defaults to `0`.

---

### M5: Generate Django migration for `billing.OutboxEntry`

Run `python billing_svc/manage.py makemigrations billing --name add_outbox_entry`. Do not manually edit the generated file.

**Acceptance Criteria**

- `billing/migrations/NNNN_add_outbox_entry.py` exists.
- `python billing_svc/manage.py migrate --run-syncdb` applies the migration without error and creates the `billing_outbox_entry` table.

---

### M6: Create `billing/events/publishers.py` with `EventPublisher` Protocol and `OutboxPublisher`

Create `billing/events/publishers.py`:

```python
from typing import Protocol
from shared_events.envelope import EventEnvelope
from billing.events.outbox import OutboxEntry

class EventPublisher(Protocol):
    def publish(self, envelope: EventEnvelope, exchange: str, routing_key: str) -> None: ...

class OutboxPublisher:
    def publish(self, envelope: EventEnvelope, exchange: str, routing_key: str) -> None:
        OutboxEntry.objects.create(
            event_type=envelope.event_type,
            exchange=exchange,
            routing_key=routing_key,
            payload=envelope.model_dump(mode="json"),
        )
```

`OutboxPublisher.publish()` must be called inside the same DB transaction as the business state change — this file does not open or manage transactions.

**Acceptance Criteria**

- `OutboxPublisher().publish(envelope, "domain.events", "billing.invoice.created")` creates one `OutboxEntry` row with `published_at=None`.
- The saved `payload` JSON equals `envelope.model_dump(mode="json")`.
- No `kombu`, `pika`, or AMQP import exists in this file.

---

### M7: Create `billing/events/schemas.py` with `build_invoice_created_envelope()`

Create `billing/events/schemas.py`:

```python
import uuid
from datetime import datetime, timezone
from shared_events.envelope import EventEnvelope
from shared_events.payloads import InvoiceCreatedPayload

def build_invoice_created_envelope(
    payload: InvoiceCreatedPayload,
    correlation_id: uuid.UUID | None = None,
) -> EventEnvelope:
    return EventEnvelope(
        event_id=uuid.uuid4(),
        event_type="billing.invoice.created",
        aggregate_id=str(payload.invoice_id),
        aggregate_type="Invoice",
        service_origin="billing",
        occurred_at=datetime.now(tz=timezone.utc),
        schema_version=1,
        correlation_id=correlation_id,
        payload=payload.model_dump(mode="json"),
    )
```

**Acceptance Criteria**

- Returns `EventEnvelope` with `event_type="billing.invoice.created"` and `schema_version=1`.
- `aggregate_id == str(payload.invoice_id)`.
- Two consecutive calls return envelopes with different `event_id` values.

---

### M8: Create `billing/events/relay.py` with `drain_outbox` Celery task (happy path only)

Create `billing/events/relay.py`:

```python
from celery import shared_task
from django.conf import settings
from django.utils import timezone
import kombu

@shared_task(name="billing.events.drain_outbox")
def drain_outbox() -> None:
    from billing.events.outbox import OutboxEntry
    unpublished = OutboxEntry.objects.filter(
        published_at__isnull=True
    ).order_by("created_at")[:100]
    for entry in unpublished:
        with kombu.Connection(settings.CELERY_BROKER_URL) as conn:
            exchange = kombu.Exchange(entry.exchange, type="topic", durable=True)
            producer = conn.Producer(serializer="json")
            producer.publish(
                entry.payload,
                exchange=exchange,
                routing_key=entry.routing_key,
                declare=[exchange],
            )
        entry.published_at = timezone.now()
        entry.save(update_fields=["published_at"])
```

No `SELECT FOR UPDATE SKIP LOCKED` yet (Phase 2). No error handling yet (Phase 2). Beat schedule is registered in `billing/celery.py` (M22), not here.

**Acceptance Criteria**

- Given one `OutboxEntry` with `published_at=None`, calling `drain_outbox()` sets `published_at` to a non-null timestamp.
- Entries with non-null `published_at` are not processed.
- Task name is `"billing.events.drain_outbox"`.

---

### M9: Create `NotificationDispatcher` Protocol in `billing/adapters/notification_adapter.py`

Create `billing/adapters/__init__.py` (empty, if absent). Create `billing/adapters/notification_adapter.py`:

```python
from typing import Protocol
from uuid import UUID

class NotificationDispatcher(Protocol):
    def send_receipt(self, invoice_id: UUID, user_id: UUID) -> None: ...
```

No implementations yet — those are M10–M12.

**Acceptance Criteria**

- `NotificationDispatcher` is a `typing.Protocol` subclass.
- It declares exactly one method: `send_receipt(self, invoice_id: UUID, user_id: UUID) -> None`.
- A class with a matching `send_receipt` signature satisfies the Protocol structurally (no explicit inheritance required).

---

### M10: Add `SynchronousDispatcher` to `billing/adapters/notification_adapter.py`

In `billing/adapters/notification_adapter.py`, append after `NotificationDispatcher`:

```python
from notifications.services import send_receipt as _send_receipt

class SynchronousDispatcher:
    def send_receipt(self, invoice_id: UUID, user_id: UUID) -> None:
        _send_receipt(invoice_id=invoice_id, user_id=user_id)
```

`_send_receipt` is the existing synchronous in-process function in `notifications/services.py`. Do not change `notifications/services.py` in this milestone.

**Acceptance Criteria**

- `SynchronousDispatcher().send_receipt(invoice_id, user_id)` calls `notifications.services.send_receipt` with identical arguments.
- `SynchronousDispatcher` structurally satisfies `NotificationDispatcher`.

---

### M11: Add `EventBasedDispatcher` to `billing/adapters/notification_adapter.py`

In `billing/adapters/notification_adapter.py`, append after `SynchronousDispatcher`:

```python
from billing.events.publishers import OutboxPublisher
from billing.events.schemas import build_invoice_created_envelope
from shared_events.payloads import InvoiceCreatedPayload

class EventBasedDispatcher:
    def __init__(self, publisher: OutboxPublisher | None = None) -> None:
        self._publisher = publisher or OutboxPublisher()

    def send_receipt(self, invoice_id: UUID, user_id: UUID) -> None:
        from billing.models import Invoice  # avoid circular import at module load
        invoice = Invoice.objects.get(id=invoice_id)
        payload = InvoiceCreatedPayload(
            invoice_id=invoice_id,
            user_id=user_id,
            amount_cents=invoice.amount_cents,
            currency=invoice.currency,
        )
        envelope = build_invoice_created_envelope(payload)
        self._publisher.publish(
            envelope,
            exchange="domain.events",
            routing_key="billing.invoice.created",
        )
```

**Acceptance Criteria**

- `EventBasedDispatcher().send_receipt(invoice_id, user_id)` creates one `OutboxEntry` with `routing_key="billing.invoice.created"` and `published_at=None`.
- Does not call `notifications.services.send_receipt`.
- `EventBasedDispatcher` structurally satisfies `NotificationDispatcher`.

---

### M12: Add `DualWriteDispatcher` to `billing/adapters/notification_adapter.py`

In `billing/adapters/notification_adapter.py`, append after `EventBasedDispatcher`:

```python
import logging

_log = logging.getLogger(__name__)

class DualWriteDispatcher:
    def __init__(
        self,
        sync: SynchronousDispatcher | None = None,
        event: EventBasedDispatcher | None = None,
    ) -> None:
        self._sync = sync or SynchronousDispatcher()
        self._event = event or EventBasedDispatcher()

    def send_receipt(self, invoice_id: UUID, user_id: UUID) -> None:
        self._sync.send_receipt(invoice_id=invoice_id, user_id=user_id)
        try:
            self._event.send_receipt(invoice_id=invoice_id, user_id=user_id)
        except Exception:
            _log.exception(
                "DualWriteDispatcher: event path failed invoice_id=%s user_id=%s",
                invoice_id,
                user_id,
            )
```

Sync call is NOT wrapped — its exceptions propagate. Event call IS wrapped — its exceptions are logged but swallowed. Sync call is authoritative during dual-write phase.

**Acceptance Criteria**

- When sync call raises, `DualWriteDispatcher.send_receipt` re-raises (sync is authoritative).
- When sync call succeeds and event call raises, `DualWriteDispatcher.send_receipt` logs the exception and returns without raising.
- `DualWriteDispatcher` structurally satisfies `NotificationDispatcher`.

---

### M13: Create `billing/_state.py` and wire `NOTIFICATION_DISPATCH_MODE` in `billing/apps.py`

Create `billing/_state.py`:

```python
from typing import Any
notification_dispatcher: Any = None
```

In `billing/settings.py`, add:

```python
NOTIFICATION_DISPATCH_MODE = "sync"  # values: "sync" | "dual" | "event"
```

In `billing/apps.py`, inside `BillingConfig.ready()`, add:

```python
from django.conf import settings as django_settings
from billing.adapters.notification_adapter import (
    SynchronousDispatcher,
    DualWriteDispatcher,
    EventBasedDispatcher,
)
import billing._state as _state

_MODE_MAP = {
    "sync": SynchronousDispatcher,
    "dual": DualWriteDispatcher,
    "event": EventBasedDispatcher,
}
mode = getattr(django_settings, "NOTIFICATION_DISPATCH_MODE", "sync")
cls = _MODE_MAP.get(mode)
if cls is None:
    raise ValueError(f"Unknown NOTIFICATION_DISPATCH_MODE: {mode!r}")
_state.notification_dispatcher = cls()
```

Callers in the billing service layer replace `notifications.send_receipt(...)` with `billing._state.notification_dispatcher.send_receipt(...)`.

**Acceptance Criteria**

- With `NOTIFICATION_DISPATCH_MODE = "sync"` in settings, `billing._state.notification_dispatcher` is a `SynchronousDispatcher` instance after `AppConfig.ready()` runs.
- With `NOTIFICATION_DISPATCH_MODE = "event"`, it is an `EventBasedDispatcher` instance.
- With `NOTIFICATION_DISPATCH_MODE = "unsupported"`, `ready()` raises `ValueError`.

---

### M14: Scaffold `notif_svc/` standalone Django project

Create these four files:

**`notif_svc/manage.py`** — standard Django manage.py:

```python
#!/usr/bin/env python
import os, sys
def main():
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "notif_svc.settings")
    from django.core.management import execute_from_command_line
    execute_from_command_line(sys.argv)
if __name__ == "__main__":
    main()
```

**`notif_svc/settings.py`** — minimal Django settings:

```python
import os
SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]
DEBUG = False
INSTALLED_APPS = ["django.contrib.contenttypes", "django.contrib.auth", "notifications"]
DATABASES = {"default": {"ENGINE": "django.db.backends.postgresql", "NAME": os.environ["DB_NAME"], "USER": os.environ["DB_USER"], "PASSWORD": os.environ["DB_PASSWORD"], "HOST": os.environ.get("DB_HOST", "localhost"), "PORT": os.environ.get("DB_PORT", "5432"), "OPTIONS": {"options": "-c search_path=notif"}}}
CELERY_BROKER_URL = os.environ.get("RABBITMQ_URL", "amqp://guest:guest@localhost/")
```

**`notif_svc/wsgi.py`** — standard WSGI:

```python
import os
from django.core.wsgi import get_wsgi_application
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "notif_svc.settings")
application = get_wsgi_application()
```

**`notif_svc/urls.py`** — minimal URLconf:

```python
from django.urls import path
from django.http import HttpResponse
urlpatterns = [path("health/", lambda r: HttpResponse("ok"))]
```

**Acceptance Criteria**

- `python notif_svc/manage.py check` passes (no Django system check errors) when required env vars are set.
- `INSTALLED_APPS` contains `"notifications"`.
- `CELERY_BROKER_URL` reads from `os.environ.get("RABBITMQ_URL")`.

---

### M15: Create `notifications/events/idempotency.py` with `ProcessedEvent` Django model

Create `notifications/events/__init__.py` (empty). Create `notifications/events/idempotency.py`:

```python
from django.db import models

class ProcessedEvent(models.Model):
    event_id = models.UUIDField(primary_key=True)
    processed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "notifications_processed_event"
```

**Acceptance Criteria**

- `ProcessedEvent.objects.create(event_id=uuid4())` inserts a row.
- Inserting the same `event_id` twice raises `django.db.utils.IntegrityError` (duplicate PK).
- `processed_at` is set automatically; callers do not supply it.

---

### M16: Generate Django migration for `notifications.ProcessedEvent`

Run `python notif_svc/manage.py makemigrations notifications --name add_processed_event`. Do not manually edit the generated file.

**Acceptance Criteria**

- `notifications/migrations/NNNN_add_processed_event.py` exists.
- `python notif_svc/manage.py migrate` applies without error and creates `notifications_processed_event` with UUID primary key.

---

### M17: Create `notifications/events/handlers.py` with `handle_invoice_created()`

Create `notifications/events/handlers.py`:

```python
from shared_events.payloads import InvoiceCreatedPayload

def handle_invoice_created(payload: InvoiceCreatedPayload) -> None:
    from notifications.services import send_receipt_email
    send_receipt_email(
        invoice_id=payload.invoice_id,
        user_id=payload.user_id,
        amount_cents=payload.amount_cents,
        currency=payload.currency,
    )
```

No Celery imports. No transaction management. No idempotency. Those are in `consumers.py`. This function is testable without Celery running.

**Acceptance Criteria**

- `handle_invoice_created(payload)` calls `notifications.services.send_receipt_email` with all four keyword arguments: `invoice_id`, `user_id`, `amount_cents`, `currency`.
- No `celery` import exists in `notifications/events/handlers.py`.
- Given a mock `send_receipt_email`, calling `handle_invoice_created` invokes the mock exactly once.

---

### M18: Create `notifications/events/consumers.py` with `process_invoice_created` Celery task

Create `notifications/events/consumers.py`:

```python
from celery import shared_task
from django.db import IntegrityError, transaction
from notifications.events.handlers import handle_invoice_created
from notifications.events.idempotency import ProcessedEvent
from shared_events.envelope import EventEnvelope
from shared_events.payloads import InvoiceCreatedPayload

@shared_task(name="notifications.events.process_invoice_created")
def process_invoice_created(raw_envelope: dict) -> None:
    envelope = EventEnvelope(**raw_envelope)
    payload = InvoiceCreatedPayload(**envelope.payload)
    with transaction.atomic():
        try:
            ProcessedEvent.objects.create(event_id=envelope.event_id)
        except IntegrityError:
            return  # already processed — idempotent skip
        handle_invoice_created(payload)
```

No `acks_late` yet (Phase 2). No `ValidationError` handling yet (Phase 2).

**Acceptance Criteria**

- Given a valid `raw_envelope` dict, `process_invoice_created(raw_envelope)` creates one `ProcessedEvent` row and calls `handle_invoice_created` once.
- Calling `process_invoice_created` a second time with the same `event_id` returns without calling `handle_invoice_created`.
- The `ProcessedEvent.create` and `handle_invoice_created` execute inside the same `atomic()` block.

---

### M19: Create `notifications/events/schemas.py` with `parse_invoice_created_envelope()`

Create `notifications/events/schemas.py`:

```python
from shared_events.envelope import EventEnvelope
from shared_events.payloads import InvoiceCreatedPayload

def parse_invoice_created_envelope(raw: dict) -> tuple[EventEnvelope, InvoiceCreatedPayload]:
    envelope = EventEnvelope(**raw)
    payload = InvoiceCreatedPayload(**envelope.payload)
    return envelope, payload
```

No `try/except` in this file — `ValidationError` handling is added in Phase 2.

**Acceptance Criteria**

- `parse_invoice_created_envelope(valid_dict)` returns `(EventEnvelope, InvoiceCreatedPayload)`.
- `envelope.event_type == "billing.invoice.created"` for a correctly formed input.
- No `try`/`except` blocks exist in this file.

---

### M20: Create `notifications/celery.py` with Celery app and queue declaration

Create `notifications/celery.py`:

```python
import os
from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "notif_svc.settings")

app = Celery("notifications")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks(["notifications.events"])

app.conf.task_queues = [
    {
        "name": "notif.invoice.created",
        "exchange": "domain.events",
        "exchange_type": "topic",
        "routing_key": "billing.invoice.created",
    }
]
app.conf.task_routes = {
    "notifications.events.process_invoice_created": {"queue": "notif.invoice.created"},
}
```

No `x-dead-letter-exchange` yet (Phase 2).

**Acceptance Criteria**

- `app.conf.task_queues` contains exactly one entry with `routing_key="billing.invoice.created"`.
- `app.conf.task_routes["notifications.events.process_invoice_created"]["queue"] == "notif.invoice.created"`.
- `app.autodiscover_tasks(["notifications.events"])` is present so `process_invoice_created` registers on worker startup.

---

### M21: Scaffold `billing_svc/` standalone Django project

Create these four files using the same pattern as `notif_svc/` (M14), substituting:

- `DJANGO_SETTINGS_MODULE=billing_svc.settings`
- `INSTALLED_APPS = ["django.contrib.contenttypes", "django.contrib.auth", "billing"]`
- `DB OPTIONS: search_path=billing`
- Health endpoint at `/health/`

**`billing_svc/manage.py`**, **`billing_svc/wsgi.py`**, **`billing_svc/urls.py`** — same boilerplate as `notif_svc/` equivalents with substituted settings module.

**`billing_svc/settings.py`**:

```python
import os
SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]
DEBUG = False
INSTALLED_APPS = ["django.contrib.contenttypes", "django.contrib.auth", "billing"]
DATABASES = {"default": {"ENGINE": "django.db.backends.postgresql", "NAME": os.environ["DB_NAME"], "USER": os.environ["DB_USER"], "PASSWORD": os.environ["DB_PASSWORD"], "HOST": os.environ.get("DB_HOST", "localhost"), "PORT": os.environ.get("DB_PORT", "5432"), "OPTIONS": {"options": "-c search_path=billing"}}}
CELERY_BROKER_URL = os.environ.get("RABBITMQ_URL", "amqp://guest:guest@localhost/")
```

**Acceptance Criteria**

- `python billing_svc/manage.py check` passes when required env vars are set.
- `INSTALLED_APPS` contains `"billing"`.
- DB `search_path` is set to `billing`.

---

### M22: Create `billing/celery.py` with Celery app, relay beat, and consumer queue

Create `billing/celery.py`:

```python
import os
from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "billing_svc.settings")

app = Celery("billing")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks(["billing.events"])

app.conf.task_queues = [
    {
        "name": "billing.plan.changed",
        "exchange": "domain.events",
        "exchange_type": "topic",
        "routing_key": "user_management.plan.changed",
    }
]
app.conf.task_routes = {
    "billing.events.process_plan_changed": {"queue": "billing.plan.changed"},
}
app.conf.beat_schedule = {
    "billing-drain-outbox": {
        "task": "billing.events.drain_outbox",
        "schedule": 5.0,
    }
}
```

No `x-dead-letter-exchange` yet (Phase 2).

**Acceptance Criteria**

- `app.conf.beat_schedule["billing-drain-outbox"]["schedule"] == 5.0`.
- `app.conf.task_queues` has one entry with `routing_key="user_management.plan.changed"`.
- `app.conf.task_routes["billing.events.process_plan_changed"]["queue"] == "billing.plan.changed"`.

---

### M23: Create `PlanRecalculationAdapter` Protocol in `user_management/adapters/billing_adapter.py`

Create `user_management/adapters/__init__.py` (empty, if absent). Create `user_management/adapters/billing_adapter.py`:

```python
from typing import Protocol
from uuid import UUID

class PlanRecalculationAdapter(Protocol):
    def recalculate(self, user_id: UUID, old_plan: str, new_plan: str) -> None: ...
```

**Acceptance Criteria**

- `PlanRecalculationAdapter` is a `typing.Protocol`.
- It declares exactly one method: `recalculate(self, user_id: UUID, old_plan: str, new_plan: str) -> None`.

---

### M24: Add `SynchronousAdapter` to `user_management/adapters/billing_adapter.py`

In `user_management/adapters/billing_adapter.py`, append after `PlanRecalculationAdapter`:

```python
from billing.services import recalculate_plan as _recalculate_plan

class SynchronousAdapter:
    def recalculate(self, user_id: UUID, old_plan: str, new_plan: str) -> None:
        _recalculate_plan(user_id=user_id, old_plan=old_plan, new_plan=new_plan)
```

**Acceptance Criteria**

- `SynchronousAdapter().recalculate(user_id, "starter", "pro")` calls `billing.services.recalculate_plan` with the same three keyword arguments.
- `SynchronousAdapter` structurally satisfies `PlanRecalculationAdapter`.

---

### M25: Create `user_management/events/outbox.py` with `OutboxEntry` Django model

Create `user_management/events/__init__.py` (empty). Create `user_management/events/outbox.py`:

```python
import uuid
from django.db import models

class OutboxEntry(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    event_type = models.CharField(max_length=255)
    exchange = models.CharField(max_length=255)
    routing_key = models.CharField(max_length=255)
    payload = models.JSONField()
    created_at = models.DateTimeField(auto_now_add=True)
    published_at = models.DateTimeField(null=True, blank=True)
    failed_at = models.DateTimeField(null=True, blank=True)
    attempt_count = models.IntegerField(default=0)

    class Meta:
        db_table = "user_management_outbox_entry"
```

**Acceptance Criteria**

- Same 9-field structure as `billing.OutboxEntry`.
- `db_table = "user_management_outbox_entry"` (distinct from billing's table).
- `published_at` and `failed_at` nullable; `attempt_count` defaults to 0.

---

### M26: Generate Django migration for `user_management.OutboxEntry`

Run `python user_svc/manage.py makemigrations user_management --name add_outbox_entry`. Do not manually edit.

**Acceptance Criteria**

- `user_management/migrations/NNNN_add_outbox_entry.py` exists.
- Migration applies without error and creates `user_management_outbox_entry` table.

---

### M27: Create `user_management/events/publishers.py` with `OutboxPublisher`

Create `user_management/events/publishers.py`:

```python
from typing import Protocol
from shared_events.envelope import EventEnvelope
from user_management.events.outbox import OutboxEntry

class EventPublisher(Protocol):
    def publish(self, envelope: EventEnvelope, exchange: str, routing_key: str) -> None: ...

class OutboxPublisher:
    def publish(self, envelope: EventEnvelope, exchange: str, routing_key: str) -> None:
        OutboxEntry.objects.create(
            event_type=envelope.event_type,
            exchange=exchange,
            routing_key=routing_key,
            payload=envelope.model_dump(mode="json"),
        )
```

**Acceptance Criteria**

- `OutboxPublisher().publish(envelope, "domain.events", "user_management.plan.changed")` creates one `user_management.OutboxEntry` row with `published_at=None`.
- No AMQP import in this file.

---

### M28: Create `user_management/events/schemas.py` with `build_plan_changed_envelope()`

Create `user_management/events/schemas.py`:

```python
import uuid
from datetime import datetime, timezone
from shared_events.envelope import EventEnvelope
from shared_events.payloads import PlanChangedPayload

def build_plan_changed_envelope(
    payload: PlanChangedPayload,
    correlation_id: uuid.UUID | None = None,
) -> EventEnvelope:
    return EventEnvelope(
        event_id=uuid.uuid4(),
        event_type="user_management.plan.changed",
        aggregate_id=str(payload.user_id),
        aggregate_type="User",
        service_origin="user_management",
        occurred_at=datetime.now(tz=timezone.utc),
        schema_version=1,
        correlation_id=correlation_id,
        payload=payload.model_dump(mode="json"),
    )
```

**Acceptance Criteria**

- Returns `EventEnvelope` with `event_type="user_management.plan.changed"` and `service_origin="user_management"`.
- `aggregate_id == str(payload.user_id)`.
- Two calls return envelopes with different `event_id` values.

---

### M29: Create `user_management/events/relay.py` with `drain_outbox` Celery task (happy path only)

Create `user_management/events/relay.py`:

```python
from celery import shared_task
from django.conf import settings
from django.utils import timezone
import kombu

@shared_task(name="user_management.events.drain_outbox")
def drain_outbox() -> None:
    from user_management.events.outbox import OutboxEntry
    unpublished = OutboxEntry.objects.filter(
        published_at__isnull=True
    ).order_by("created_at")[:100]
    for entry in unpublished:
        with kombu.Connection(settings.CELERY_BROKER_URL) as conn:
            exchange = kombu.Exchange(entry.exchange, type="topic", durable=True)
            producer = conn.Producer(serializer="json")
            producer.publish(
                entry.payload,
                exchange=exchange,
                routing_key=entry.routing_key,
                declare=[exchange],
            )
        entry.published_at = timezone.now()
        entry.save(update_fields=["published_at"])
```

No `SELECT FOR UPDATE SKIP LOCKED` yet (Phase 2). No error handling yet (Phase 2).

**Acceptance Criteria**

- Given one `user_management.OutboxEntry` with `published_at=None`, `drain_outbox()` sets `published_at` to a non-null timestamp.
- Entries with non-null `published_at` are skipped.
- Task name is `"user_management.events.drain_outbox"`.

---

### M30: Add `EventBasedAdapter` to `user_management/adapters/billing_adapter.py`

In `user_management/adapters/billing_adapter.py`, append after `SynchronousAdapter`:

```python
from user_management.events.publishers import OutboxPublisher
from user_management.events.schemas import build_plan_changed_envelope
from shared_events.payloads import PlanChangedPayload

class EventBasedAdapter:
    def __init__(self, publisher: OutboxPublisher | None = None) -> None:
        self._publisher = publisher or OutboxPublisher()

    def recalculate(self, user_id: UUID, old_plan: str, new_plan: str) -> None:
        payload = PlanChangedPayload(user_id=user_id, old_plan=old_plan, new_plan=new_plan)
        envelope = build_plan_changed_envelope(payload)
        self._publisher.publish(
            envelope,
            exchange="domain.events",
            routing_key="user_management.plan.changed",
        )
```

**Acceptance Criteria**

- `EventBasedAdapter().recalculate(user_id, "starter", "pro")` creates one `user_management.OutboxEntry` with `routing_key="user_management.plan.changed"`.
- Does not call `billing.services.recalculate_plan`.
- `EventBasedAdapter` structurally satisfies `PlanRecalculationAdapter`.

---

### M31: Add `DualWriteAdapter` to `user_management/adapters/billing_adapter.py`

In `user_management/adapters/billing_adapter.py`, append after `EventBasedAdapter`:

```python
import logging

_log = logging.getLogger(__name__)

class DualWriteAdapter:
    def __init__(
        self,
        sync: SynchronousAdapter | None = None,
        event: EventBasedAdapter | None = None,
    ) -> None:
        self._sync = sync or SynchronousAdapter()
        self._event = event or EventBasedAdapter()

    def recalculate(self, user_id: UUID, old_plan: str, new_plan: str) -> None:
        self._sync.recalculate(user_id=user_id, old_plan=old_plan, new_plan=new_plan)
        try:
            self._event.recalculate(user_id=user_id, old_plan=old_plan, new_plan=new_plan)
        except Exception:
            _log.exception(
                "DualWriteAdapter: event path failed user_id=%s old_plan=%s new_plan=%s",
                user_id,
                old_plan,
                new_plan,
            )
```

Sync call is not wrapped — its exceptions propagate. Event call exceptions are logged and swallowed.

**Acceptance Criteria**

- When sync call raises, `DualWriteAdapter.recalculate` re-raises.
- When sync call succeeds and event call raises, logs the exception and returns without raising.
- `DualWriteAdapter` structurally satisfies `PlanRecalculationAdapter`.

---

### M32: Create `user_management/_state.py` and wire `PLAN_RECALC_DISPATCH_MODE` in `user_management/apps.py`

Create `user_management/_state.py`:

```python
from typing import Any
plan_recalc_adapter: Any = None
```

In `user_management/settings.py`, add:

```python
PLAN_RECALC_DISPATCH_MODE = "sync"  # values: "sync" | "dual" | "event"
```

In `user_management/apps.py`, inside `UserManagementConfig.ready()`, add:

```python
from django.conf import settings as django_settings
from user_management.adapters.billing_adapter import (
    SynchronousAdapter,
    DualWriteAdapter,
    EventBasedAdapter,
)
import user_management._state as _state

_MODE_MAP = {
    "sync": SynchronousAdapter,
    "dual": DualWriteAdapter,
    "event": EventBasedAdapter,
}
mode = getattr(django_settings, "PLAN_RECALC_DISPATCH_MODE", "sync")
cls = _MODE_MAP.get(mode)
if cls is None:
    raise ValueError(f"Unknown PLAN_RECALC_DISPATCH_MODE: {mode!r}")
_state.plan_recalc_adapter = cls()
```

Callers in user_management service layer replace `billing.recalculate_plan(...)` with `user_management._state.plan_recalc_adapter.recalculate(...)`.

**Acceptance Criteria**

- With `PLAN_RECALC_DISPATCH_MODE = "sync"`, `user_management._state.plan_recalc_adapter` is a `SynchronousAdapter` after startup.
- With `PLAN_RECALC_DISPATCH_MODE = "event"`, it is an `EventBasedAdapter`.
- With `PLAN_RECALC_DISPATCH_MODE = "bad_value"`, `ready()` raises `ValueError`.

---

### M33: Scaffold `user_svc/` standalone Django project

Create these four files using the same pattern as `notif_svc/` (M14), substituting:

- `DJANGO_SETTINGS_MODULE=user_svc.settings`
- `INSTALLED_APPS = ["django.contrib.contenttypes", "django.contrib.auth", "user_management"]`
- `DB OPTIONS: search_path=users`

**`user_svc/settings.py`**:

```python
import os
SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]
DEBUG = False
INSTALLED_APPS = ["django.contrib.contenttypes", "django.contrib.auth", "user_management"]
DATABASES = {"default": {"ENGINE": "django.db.backends.postgresql", "NAME": os.environ["DB_NAME"], "USER": os.environ["DB_USER"], "PASSWORD": os.environ["DB_PASSWORD"], "HOST": os.environ.get("DB_HOST", "localhost"), "PORT": os.environ.get("DB_PORT", "5432"), "OPTIONS": {"options": "-c search_path=users"}}}
CELERY_BROKER_URL = os.environ.get("RABBITMQ_URL", "amqp://guest:guest@localhost/")
```

**Acceptance Criteria**

- `python user_svc/manage.py check` passes when required env vars are set.
- `INSTALLED_APPS` contains `"user_management"`.
- DB `search_path` is `users`.

---

### M34: Create `user_management/celery.py` with Celery app and relay beat schedule

Create `user_management/celery.py`:

```python
import os
from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "user_svc.settings")

app = Celery("user_management")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks(["user_management.events"])

app.conf.beat_schedule = {
    "user-management-drain-outbox": {
        "task": "user_management.events.drain_outbox",
        "schedule": 5.0,
    }
}
```

No consumer queue declarations — user_management publishes plan.changed but consumes no events.

**Acceptance Criteria**

- `app.conf.beat_schedule["user-management-drain-outbox"]["schedule"] == 5.0`.
- `app.conf.task_queues` is absent or empty (no inbound event queues for user_management).

---

### M35: Create `billing/events/idempotency.py` with `ProcessedEvent` Django model

Create `billing/events/idempotency.py`:

```python
from django.db import models

class ProcessedEvent(models.Model):
    event_id = models.UUIDField(primary_key=True)
    processed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "billing_processed_event"
```

**Acceptance Criteria**

- `ProcessedEvent.objects.create(event_id=uuid4())` inserts a row.
- Duplicate `event_id` raises `IntegrityError`.
- `db_table = "billing_processed_event"` (distinct from notifications' table).

---

### M36: Generate Django migration for `billing.ProcessedEvent`

Run `python billing_svc/manage.py makemigrations billing --name add_processed_event`. Do not manually edit.

**Acceptance Criteria**

- `billing/migrations/NNNN_add_processed_event.py` exists.
- Applies alongside the `add_outbox_entry` migration without conflict.

---

### M37: Create `billing/events/handlers.py` with `handle_plan_changed()`

Create `billing/events/handlers.py`:

```python
from shared_events.payloads import PlanChangedPayload

def handle_plan_changed(payload: PlanChangedPayload) -> None:
    from billing.services import recalculate_plan
    recalculate_plan(
        user_id=payload.user_id,
        old_plan=payload.old_plan,
        new_plan=payload.new_plan,
    )
```

No Celery imports. No idempotency logic. Pure orchestration.

**Acceptance Criteria**

- `handle_plan_changed(PlanChangedPayload(...))` calls `billing.services.recalculate_plan` with `user_id`, `old_plan`, `new_plan`.
- No `celery` import exists in this file.

---

### M38: Create `billing/events/consumers.py` with `process_plan_changed` Celery task

Create `billing/events/consumers.py`:

```python
from celery import shared_task
from django.db import IntegrityError, transaction
from billing.events.handlers import handle_plan_changed
from billing.events.idempotency import ProcessedEvent
from shared_events.envelope import EventEnvelope
from shared_events.payloads import PlanChangedPayload

@shared_task(name="billing.events.process_plan_changed")
def process_plan_changed(raw_envelope: dict) -> None:
    envelope = EventEnvelope(**raw_envelope)
    payload = PlanChangedPayload(**envelope.payload)
    with transaction.atomic():
        try:
            ProcessedEvent.objects.create(event_id=envelope.event_id)
        except IntegrityError:
            return  # already processed
        handle_plan_changed(payload)
```

No `acks_late` yet (Phase 2). No `ValidationError` handling yet (Phase 2).

**Acceptance Criteria**

- Given a valid `raw_envelope` dict, `process_plan_changed(raw_envelope)` calls `handle_plan_changed` and creates a `ProcessedEvent` row.
- Second call with same `event_id` skips the handler.
- `ProcessedEvent.create` and `handle_plan_changed` execute inside the same `atomic()` block.

---

### M39: Add `parse_plan_changed_envelope()` to `billing/events/schemas.py`

In `billing/events/schemas.py`, add after `build_invoice_created_envelope()`:

```python
from shared_events.payloads import PlanChangedPayload

def parse_plan_changed_envelope(raw: dict) -> tuple[EventEnvelope, PlanChangedPayload]:
    envelope = EventEnvelope(**raw)
    payload = PlanChangedPayload(**envelope.payload)
    return envelope, payload
```

Also add the required import at the top of the file: `from shared_events.envelope import EventEnvelope`.

**Acceptance Criteria**

- `parse_plan_changed_envelope(valid_dict)` returns `(EventEnvelope, PlanChangedPayload)`.
- `envelope.event_type == "user_management.plan.changed"` for a correctly formed input.
- No `try`/`except` blocks in this function.

---

### M40: Create `user_management/events/idempotency.py` with `ProcessedEvent` Django model

Create `user_management/events/idempotency.py`:

```python
from django.db import models

class ProcessedEvent(models.Model):
    event_id = models.UUIDField(primary_key=True)
    processed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "user_management_processed_event"
```

User_management consumes no events in this RFC; this model is present per the standard module structure and is available for future use without schema migration.

**Acceptance Criteria**

- `db_table = "user_management_processed_event"`.
- `ProcessedEvent.objects.create(event_id=uuid4())` inserts a row without error.
- Duplicate `event_id` raises `IntegrityError`.

---

## Phase 2 — Details

### M41: Add `SELECT FOR UPDATE SKIP LOCKED` to `billing/events/relay.py`

In `billing/events/relay.py`, wrap the query in `transaction.atomic()` and add `select_for_update(skip_locked=True)` to prevent double-processing when multiple relay workers run concurrently:

```python
from django.db import transaction

@shared_task(name="billing.events.drain_outbox")
def drain_outbox() -> None:
    from billing.events.outbox import OutboxEntry
    with transaction.atomic():
        unpublished = (
            OutboxEntry.objects
            .select_for_update(skip_locked=True)
            .filter(published_at__isnull=True)
            .order_by("created_at")[:100]
        )
        for entry in unpublished:
            # ... same publish logic ...
```

Replace the existing `unpublished = OutboxEntry.objects.filter(...)` line with the `select_for_update(skip_locked=True)` form wrapped in `transaction.atomic()`. Keep the rest of the task body identical.

**Acceptance Criteria**

- The query uses `select_for_update(skip_locked=True)`.
- The query and all `entry.save()` calls execute within a single `transaction.atomic()` block.
- Two concurrent relay worker invocations do not process the same `OutboxEntry` row (no duplicate publishes).

---

### M42: Add retry and `failed_at` tracking to `billing/events/relay.py`

In `billing/events/relay.py`, wrap the per-entry publish block in a `try/except` to increment `attempt_count`, set `failed_at`, and log on failure. Replace the bare publish-and-save block:

```python
import logging
_log = logging.getLogger(__name__)

# inside the for loop, replace bare publish block with:
try:
    with kombu.Connection(settings.CELERY_BROKER_URL) as conn:
        exchange = kombu.Exchange(entry.exchange, type="topic", durable=True)
        producer = conn.Producer(serializer="json")
        producer.publish(
            entry.payload,
            exchange=exchange,
            routing_key=entry.routing_key,
            declare=[exchange],
        )
    entry.published_at = timezone.now()
    entry.save(update_fields=["published_at"])
except Exception:
    entry.attempt_count = models.F("attempt_count") + 1
    entry.failed_at = timezone.now()
    entry.save(update_fields=["attempt_count", "failed_at"])
    _log.exception("billing relay: failed to publish outbox entry %s", entry.id)
```

Import `from django.db import models` for the `F()` expression.

**Acceptance Criteria**

- When AMQP publish raises, `attempt_count` is incremented by 1 and `failed_at` is set to a non-null timestamp.
- A failed entry is NOT marked `published_at` — it remains eligible for retry on the next beat cycle.
- Failure of one entry does not abort processing of subsequent entries in the same batch.

---

### M43: Add `SELECT FOR UPDATE SKIP LOCKED` and retry to `user_management/events/relay.py`

In `user_management/events/relay.py`, apply the same changes as M41 and M42: wrap query in `transaction.atomic()` + `select_for_update(skip_locked=True)`, and add `try/except` with `attempt_count` increment and `failed_at` on failure.

The implementation is identical to the updated `billing/events/relay.py` except it imports `from user_management.events.outbox import OutboxEntry` and uses task name `"user_management.events.drain_outbox"`.

**Acceptance Criteria**

- `user_management.OutboxEntry` rows are processed with `select_for_update(skip_locked=True)` inside `atomic()`.
- Failed publish increments `attempt_count` and sets `failed_at`.
- Failure of one entry does not abort subsequent entries.

---

### M44: Set `acks_late=True` on `process_invoice_created` in `notifications/events/consumers.py`

In `notifications/events/consumers.py`, update the task decorator:

```python
@shared_task(name="notifications.events.process_invoice_created", acks_late=True)
```

`acks_late=True` ensures the message is not acknowledged until the task completes. Combined with the idempotency check, redelivery on worker crash is safe — the `ProcessedEvent` insert will raise `IntegrityError` on the retry and the handler will be skipped.

**Acceptance Criteria**

- The `process_invoice_created` task has `acks_late=True` in its decorator.
- No other changes to the task body.

---

### M45: Set `acks_late=True` on `process_plan_changed` in `billing/events/consumers.py`

In `billing/events/consumers.py`, update the task decorator:

```python
@shared_task(name="billing.events.process_plan_changed", acks_late=True)
```

**Acceptance Criteria**

- `process_plan_changed` has `acks_late=True`.
- No other changes to the task body.

---

### M46: Add `ValidationError` handling to `notifications/events/consumers.py`

In `notifications/events/consumers.py`, wrap the envelope and payload construction with `pydantic.ValidationError` catching. A malformed message must not crash the worker — it must be rejected to the DLQ:

```python
from pydantic import ValidationError

@shared_task(name="notifications.events.process_invoice_created", acks_late=True)
def process_invoice_created(raw_envelope: dict) -> None:
    try:
        envelope = EventEnvelope(**raw_envelope)
        payload = InvoiceCreatedPayload(**envelope.payload)
    except ValidationError:
        _log.exception(
            "process_invoice_created: invalid envelope, routing to DLQ: %s",
            raw_envelope,
        )
        raise  # re-raise so Celery routes to DLQ after max_retries exhausted
    with transaction.atomic():
        ...  # existing idempotency + handler logic unchanged
```

Add `import logging; _log = logging.getLogger(__name__)` at the top of the file.

**Acceptance Criteria**

- Given a raw dict missing required `EventEnvelope` fields, `process_invoice_created` logs the error and re-raises `ValidationError`.
- The task body after the `try/except` block is unchanged.
- Valid envelopes are processed normally.

---

### M47: Add `ValidationError` handling to `billing/events/consumers.py`

In `billing/events/consumers.py`, apply the same pattern as M46 to `process_plan_changed`:

```python
from pydantic import ValidationError
import logging
_log = logging.getLogger(__name__)

@shared_task(name="billing.events.process_plan_changed", acks_late=True)
def process_plan_changed(raw_envelope: dict) -> None:
    try:
        envelope = EventEnvelope(**raw_envelope)
        payload = PlanChangedPayload(**envelope.payload)
    except ValidationError:
        _log.exception(
            "process_plan_changed: invalid envelope, routing to DLQ: %s",
            raw_envelope,
        )
        raise
    with transaction.atomic():
        ...  # existing idempotency + handler logic unchanged
```

**Acceptance Criteria**

- Given a raw dict missing required `PlanChangedPayload` fields, `process_plan_changed` logs and re-raises `ValidationError`.
- Valid envelopes are processed normally.

---

### M48: Add DLQ config to `notifications/celery.py` queue declarations

In `notifications/celery.py`, update `app.conf.task_queues` to include dead-letter exchange and message TTL:

```python
app.conf.task_queues = [
    {
        "name": "notif.invoice.created",
        "exchange": "domain.events",
        "exchange_type": "topic",
        "routing_key": "billing.invoice.created",
        "queue_arguments": {
            "x-dead-letter-exchange": "domain.events.dlq",
            "x-message-ttl": 86_400_000,  # 24 hours in ms
        },
    }
]
```

**Acceptance Criteria**

- The queue declaration includes `"x-dead-letter-exchange": "domain.events.dlq"`.
- The queue declaration includes `"x-message-ttl": 86400000`.
- Queue name and routing key are unchanged from M20.

---

### M49: Add DLQ config to `billing/celery.py` queue declarations

In `billing/celery.py`, update `app.conf.task_queues` to include DLQ config on the `billing.plan.changed` queue:

```python
app.conf.task_queues = [
    {
        "name": "billing.plan.changed",
        "exchange": "domain.events",
        "exchange_type": "topic",
        "routing_key": "user_management.plan.changed",
        "queue_arguments": {
            "x-dead-letter-exchange": "domain.events.dlq",
            "x-message-ttl": 86_400_000,
        },
    }
]
```

**Acceptance Criteria**

- Queue declaration includes `"x-dead-letter-exchange": "domain.events.dlq"` and `"x-message-ttl": 86400000`.
- Queue name and routing key unchanged from M22.

---

### M50: Add structured divergence logging to `DualWriteDispatcher` in `billing/adapters/notification_adapter.py`

In `billing/adapters/notification_adapter.py`, update `DualWriteDispatcher.send_receipt` to emit a structured log entry comparing sync and event path outcomes. Replace the bare `except Exception` block:

```python
def send_receipt(self, invoice_id: UUID, user_id: UUID) -> None:
    self._sync.send_receipt(invoice_id=invoice_id, user_id=user_id)
    try:
        self._event.send_receipt(invoice_id=invoice_id, user_id=user_id)
        _log.info(
            "DualWriteDispatcher: both paths succeeded invoice_id=%s user_id=%s",
            invoice_id,
            user_id,
            extra={"dual_write_outcome": "match", "invoice_id": str(invoice_id)},
        )
    except Exception:
        _log.exception(
            "DualWriteDispatcher: event path failed invoice_id=%s user_id=%s",
            invoice_id,
            user_id,
            extra={"dual_write_outcome": "diverged", "invoice_id": str(invoice_id)},
        )
```

**Acceptance Criteria**

- On success of both paths, logs at `INFO` with `extra={"dual_write_outcome": "match", ...}`.
- On event path failure, logs at `ERROR`/`EXCEPTION` with `extra={"dual_write_outcome": "diverged", ...}`.
- Behavior (propagation of sync errors, swallowing of event errors) is unchanged from M12.

---

### M51: Add structured divergence logging to `DualWriteAdapter` in `user_management/adapters/billing_adapter.py`

In `user_management/adapters/billing_adapter.py`, update `DualWriteAdapter.recalculate` to emit the same structured log fields as M50:

```python
def recalculate(self, user_id: UUID, old_plan: str, new_plan: str) -> None:
    self._sync.recalculate(user_id=user_id, old_plan=old_plan, new_plan=new_plan)
    try:
        self._event.recalculate(user_id=user_id, old_plan=old_plan, new_plan=new_plan)
        _log.info(
            "DualWriteAdapter: both paths succeeded user_id=%s",
            user_id,
            extra={"dual_write_outcome": "match", "user_id": str(user_id)},
        )
    except Exception:
        _log.exception(
            "DualWriteAdapter: event path failed user_id=%s",
            user_id,
            extra={"dual_write_outcome": "diverged", "user_id": str(user_id)},
        )
```

**Acceptance Criteria**

- On success of both paths, logs `INFO` with `extra={"dual_write_outcome": "match"}`.
- On event path failure, logs `EXCEPTION` with `extra={"dual_write_outcome": "diverged"}`.
- Error propagation behavior unchanged from M31.

---

## Phase 3 — Polish

### M52: Log active dispatch mode at startup in `billing/apps.py`

In `billing/apps.py`, immediately after the dispatcher is assigned in `BillingConfig.ready()`, add:

```python
import logging
_log = logging.getLogger(__name__)
_log.info(
    "billing: NOTIFICATION_DISPATCH_MODE=%s dispatcher=%s",
    mode,
    type(_state.notification_dispatcher).__name__,
)
```

**Acceptance Criteria**

- Server startup log contains a line with `"NOTIFICATION_DISPATCH_MODE="` showing the active mode value.
- The log line also includes the dispatcher class name (e.g., `"SynchronousDispatcher"`).

---

### M53: Log active dispatch mode at startup in `user_management/apps.py`

In `user_management/apps.py`, immediately after the adapter is assigned in `UserManagementConfig.ready()`, add:

```python
import logging
_log = logging.getLogger(__name__)
_log.info(
    "user_management: PLAN_RECALC_DISPATCH_MODE=%s adapter=%s",
    mode,
    type(_state.plan_recalc_adapter).__name__,
)
```

**Acceptance Criteria**

- Startup log contains `"PLAN_RECALC_DISPATCH_MODE="` showing the active mode value.
- Log line includes adapter class name.

---

### M54: Update C4 container diagram notes to reference RFC-005

In the C4 container diagram file (typically `docs/architecture/c4-container.md` or equivalent), locate the notes section for the three extracted services (`billing_svc`, `notif_svc`, `user_svc`) and the RabbitMQ broker. Add a note referencing this RFC:

```
> Migration implemented via RFC-005 (strangler fig, transactional outbox, idempotent consumers).
> Cut-over criterion: <0.1% event divergence over 5 consecutive business days; tech lead sign-off required.
```

No structural changes to the diagram itself — notes only.

**Acceptance Criteria**

- The C4 container diagram notes section contains `"RFC-005"`.
- The cut-over criterion (`<0.1%`, `5 consecutive business days`, `tech lead sign-off`) appears in the notes.
- No containers, relationships, or diagram structure are changed.

---

### M55: Amend ADR-002 to record transactional outbox and idempotent consumer patterns

In the ADR-002 file (`docs/adr/ADR-002-*.md` or equivalent), add an **Amendment** section after the existing decision record:

```markdown
## Amendment — 2026-04-19 (RFC-005)

**Transactional Outbox** is the mandated delivery implementation for all RabbitMQ publishes in this platform. Direct publish inside a transaction is prohibited — the outbox row acts as the durable record. Relay task runs every 5 seconds via Celery beat using `SELECT FOR UPDATE SKIP LOCKED`.

**Idempotent Consumer** using a `ProcessedEvent` table (UUID PK) is mandatory for all consumer services. Consumers must insert a `ProcessedEvent` row inside the same `transaction.atomic()` block as the handler. An `IntegrityError` on duplicate PK means the event was already processed — handler must be skipped silently.

See RFC-005 for implementation details.
```

**Acceptance Criteria**

- ADR-002 contains an Amendment section dated 2026-04-19.
- The amendment mentions transactional outbox as mandatory and prohibits direct publish.
- The amendment mentions idempotent consumer as mandatory with `ProcessedEvent` pattern.
- `"RFC-005"` appears in the amendment text.

---

## RFC Goal Coverage

| RFC Goal | Milestone(s) |
|---|---|
| Replace sync coupling points with RabbitMQ domain events | M4–M13 (billing→notif), M23–M32 (user_mgmt→billing) |
| Extract notifications into independently deployable service | M14–M20 (notif_svc scaffold + consumer) |
| Extract billing into independently deployable service | M21–M22 (billing_svc scaffold + Celery) |
| Extract user management into independently deployable service | M33–M34 (user_svc scaffold + Celery) |
| Zero customer-visible downtime via strangler fig + dual-write | M10–M13 (SynchronousDispatcher→DualWrite→EventBased), M24/M30–M32 |
| Transactional outbox pattern | M4–M8 (billing), M25–M29 (user_management), M41–M43 |
| Idempotent consumer pattern | M15–M18 (notifications), M35–M38 (billing) |
| Validate each extraction independently before cut-over | M50–M51 (divergence logging), M48–M49 (DLQ config) |
| Shared event schema package | M1–M3 |
| ADR-002 amendment (outbox + idempotency) | M55 |
| C4 notes updated | M54 |

---

## Change Log

- 2026-04-19: Initial plan — 55 milestones across 3 phases
