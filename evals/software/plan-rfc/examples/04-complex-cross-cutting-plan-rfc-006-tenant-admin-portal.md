# PLAN-RFC-006: Tenant Admin Portal

**RFC**: RFC-006 — Tenant Admin Portal: Self-Service Member and Configuration Management
**Status**: Ready
**Created**: 2026-04-19
**Last Updated**: 2026-04-19

## Context

- **PRD**: none
- **ADRs**: none — RFC-006 Impact: "no new architectural decisions; builds on existing patterns"
- **C4**: Web App container (update description), API Server container (update description). No new containers.
- **Related RFCs**: RFC-004 (Multi-Tenancy Foundation) — provides `tenantMiddleware`, `tenantStorage` AsyncLocalStorage, `withTenantConnection`, JWT auth middleware. RFC-005 (Tenant Operations) — provides `tenant_feature_flags` table, `GLOBAL_FEATURE_DEFAULTS` pattern, Redis cache invalidation, `usage_records` table in `billing_svc`.

## Open Question Resolutions

1. **Q1 — Auth0 Organization roles**: Assumed supported. Plan includes Auth0 Action (M28). **Implementation of M28 blocked until confirmed — verify Auth0 plan tier before deploying.**
2. **Q2 — billing_svc internal auth**: Network-level isolation (VPC) in Phase 1. Service-to-service JWT deferred.
3. **Q3 — PLAN_FEATURE_GATES**: Static TypeScript map in `src/config/plan-feature-gates.ts`. Requires deploy for plan changes. DB table deferred.
4. **Q4 — Audit log retention**: Deferred to ops — no code change needed. Configure DB-level partition or `DELETE WHERE occurred_at < now() - interval '1 year'` cron.

## File Structure Map

| File | Action | Responsibility |
|---|---|---|
| `src/middleware/tenant-admin-guard.ts` | Create | `tenantAdminGuard(req, res, next)` — reads `req.auth['https://yourapp.com/roles']`, 403 if `tenant_admin` absent |
| `src/config/plan-feature-gates.ts` | Create | `GLOBAL_FEATURE_DEFAULTS` map, `PLAN_FEATURE_GATES` map, `planAllowsFeature(tenantPlan, flagKey): boolean` |
| `src/lib/auth0-management.ts` | Create | Auth0 `ManagementClient` singleton; `listOrgMembers()`, `inviteOrgMember()`, `removeOrgMember()` typed wrappers |
| `src/routes/admin/usage.ts` | Create | `getUsage()` — HTTP proxy to `billing_svc` internal endpoint |
| `src/routes/admin/members.ts` | Create | `listMembers`, `inviteMember`, `removeMember` route handlers |
| `src/routes/admin/features.ts` | Create | `listFeatures`, `updateFeatureFlag` route handlers |
| `src/routes/admin/billing.ts` | Create | `createBillingPortalSession` — Stripe Customer Portal session creation |
| `src/routes/admin/index.ts` | Create | Admin Express router: `tenantMiddleware` → `tenantAdminGuard` → all sub-routes |
| `src/app.ts` | Modify | Mount admin router at `/v1/admin/tenant` after existing versioned routes |
| `src/components/auth/RequireRole.tsx` | Create | Reads `roles` from JWT auth context, redirects to `/` if specified role absent |
| `src/admin/UsageDashboard.tsx` | Create | Fetches GET /v1/admin/tenant/usage, renders metrics table |
| `src/admin/MemberList.tsx` | Create | Members table with remove button per row; GET + DELETE /v1/admin/tenant/members |
| `src/admin/InviteForm.tsx` | Create | Email + role form; POST /v1/admin/tenant/members; shows 202 confirmation |
| `src/admin/FeatureFlagList.tsx` | Create | Flag table with toggle checkboxes; PATCH /v1/admin/tenant/features/:key |
| `src/admin/BillingPortalRedirect.tsx` | Create | Button POSTs to /v1/admin/tenant/billing/portal-session; `window.location` redirect |
| `src/admin/AdminPortal.tsx` | Create | Lazy-loaded root with nested React Router routes for all four admin sections |
| `src/routes/index.tsx` | Modify | Add lazy `/admin/*` route with `<RequireRole role="tenant_admin">` + `<Suspense>` |
| `billing_svc/views/internal.py` | Create | `InternalUsageView` — GET /internal/usage/\<tenant_id\>; aggregates `usage_records` by metric |
| `billing_svc/urls.py` | Modify | Register `internal/usage/<uuid:tenant_id>` → `InternalUsageView` |
| `shared/migrations/0004_add_admin_audit_log.py` | Create | Alembic migration: `admin_audit_log` table — no RLS, cross-tenant, tracks member invite/remove |
| `auth0/actions/inject-roles.js` | Create | Auth0 post-login Action: inject `roles` array claim from Auth0 Organization member roles |

---

## Phase 1 — Core

### M1: Create `src/middleware/tenant-admin-guard.ts`

Create `src/middleware/tenant-admin-guard.ts`:

```typescript
// src/middleware/tenant-admin-guard.ts
import { NextFunction, Request, Response } from 'express';

const ROLES_CLAIM = 'https://yourapp.com/roles';

export function tenantAdminGuard(req: Request, res: Response, next: NextFunction): void {
  const roles: string[] = (req as any).auth?.[ROLES_CLAIM] ?? [];
  if (!roles.includes('tenant_admin')) {
    res.status(403).json({ error: 'Tenant admin role required' });
    return;
  }
  next();
}
```

`req.auth` is set by the JWT middleware (RFC-004) that runs before this guard. Cast to `any` if the JWT middleware does not augment Express `Request` type.

**AC:**

- When `req.auth['https://yourapp.com/roles']` is `['tenant_admin']`, `next()` is called and no response is sent.
- When the claim is absent, an empty array, or does not contain `'tenant_admin'`, response status is `403` with body `{ "error": "Tenant admin role required" }` and `next()` is not called.
- `tsc --noEmit` passes with no type errors.

---

### M2: Create `src/config/plan-feature-gates.ts`

Create `src/config/plan-feature-gates.ts`:

```typescript
// src/config/plan-feature-gates.ts

export type TenantPlan = 'starter' | 'business' | 'enterprise';

/** Global defaults when no per-tenant override exists — mirrors shared/tenancy/flags.py */
export const GLOBAL_FEATURE_DEFAULTS: Record<string, boolean> = {
  sso_enabled: false,
  advanced_analytics: false,
  api_rate_limit_override: false,
  data_export: true,
};

/**
 * Plan-gated flags. true = tenant on this plan may toggle the flag.
 * Flags absent from a plan's map cannot be overridden by tenant admins on that plan.
 */
export const PLAN_FEATURE_GATES: Record<TenantPlan, Record<string, boolean>> = {
  starter: {
    data_export: true,
  },
  business: {
    data_export: true,
    advanced_analytics: true,
    api_rate_limit_override: true,
  },
  enterprise: {
    data_export: true,
    advanced_analytics: true,
    api_rate_limit_override: true,
    sso_enabled: true,
  },
};

export function planAllowsFeature(tenantPlan: TenantPlan, flagKey: string): boolean {
  return PLAN_FEATURE_GATES[tenantPlan]?.[flagKey] === true;
}
```

**AC:**

- `planAllowsFeature('starter', 'advanced_analytics')` returns `false`.
- `planAllowsFeature('enterprise', 'sso_enabled')` returns `true`.
- `planAllowsFeature('business', 'unknown_flag')` returns `false`.
- `tsc --noEmit` passes with no type errors.

---

### M3: Create `src/lib/auth0-management.ts`

Create `src/lib/auth0-management.ts`:

```typescript
// src/lib/auth0-management.ts
import { ManagementClient } from 'auth0';

const auth0 = new ManagementClient({
  domain: process.env.AUTH0_DOMAIN!,
  clientId: process.env.AUTH0_MGMT_CLIENT_ID!,
  clientSecret: process.env.AUTH0_MGMT_CLIENT_SECRET!,
});

export interface OrgMember {
  userId: string;
  email: string;
  name: string;
  roles: string[];
}

export async function listOrgMembers(orgId: string): Promise<OrgMember[]> {
  const members = await auth0.organizations.getMembers({ id: orgId });
  return (members.data ?? []).map((m) => ({
    userId: m.user_id!,
    email: m.email ?? '',
    name: m.name ?? '',
    roles: ((m as any).roles ?? []).map((r: any) => r.name as string),
  }));
}

export async function inviteOrgMember(
  orgId: string,
  email: string,
  role: string,
  inviterName: string,
): Promise<void> {
  await auth0.organizations.createInvitation(
    { id: orgId },
    { invitee: { email }, inviter: { name: inviterName }, roles: [role] },
  );
}

export async function removeOrgMember(orgId: string, userId: string): Promise<void> {
  await auth0.organizations.deleteMember({ id: orgId }, { members: [userId] });
}
```

Required env vars: `AUTH0_DOMAIN`, `AUTH0_MGMT_CLIENT_ID`, `AUTH0_MGMT_CLIENT_SECRET`. The `ManagementClient` is instantiated once at module load — all imports share the singleton.

**AC:**

- `import { listOrgMembers } from './lib/auth0-management'` resolves without TypeScript error.
- `ManagementClient` is constructed with `domain`, `clientId`, `clientSecret` from `process.env` — no hardcoded values.
- `tsc --noEmit` passes with no type errors.

---

### M4: Create `billing_svc/views/internal.py` and register URL

Create `billing_svc/views/internal.py`:

```python
# billing_svc/views/internal.py
import uuid

from django.http import JsonResponse
from django.views import View
from sqlalchemy import func, select

from billing_svc.db import Session
from billing_svc.models import UsageRecord
from shared.tenancy.context import admin_context


class InternalUsageView(View):
    def get(self, request, tenant_id: uuid.UUID):
        with admin_context():
            session = Session()
            try:
                rows = session.execute(
                    select(
                        UsageRecord.metric,
                        func.sum(UsageRecord.quantity).label("used"),
                    )
                    .where(UsageRecord.tenant_id == tenant_id)
                    .group_by(UsageRecord.metric)
                ).all()
            finally:
                session.close()

        usage = [{"metric": row.metric, "used": int(row.used)} for row in rows]
        return JsonResponse({"period": "current", "usage": usage})
```

In `billing_svc/urls.py`, add after existing patterns:

```python
from billing_svc.views.internal import InternalUsageView
from django.urls import path

urlpatterns = [
    # ... existing patterns ...
    path('internal/usage/<uuid:tenant_id>', InternalUsageView.as_view(), name='internal-usage'),
]
```

`admin_context()` bypasses RLS — appropriate for this network-isolated internal endpoint. No public routing. Phase 1 returns only `"current"` period; `?period=YYYY-MM` support added in Phase 2 (M27).

**AC:**

- `GET /internal/usage/<valid-tenant-uuid>` returns `{ "period": "current", "usage": [{ "metric": "api_calls", "used": 150 }] }` when `usage_records` contains rows for that tenant.
- `GET /internal/usage/<tenant-uuid-with-no-records>` returns `{ "period": "current", "usage": [] }`.
- `python manage.py check` (in `billing_svc`) exits 0.

---

### M5: Create `src/routes/admin/usage.ts` with getUsage()

Create `src/routes/admin/usage.ts`:

```typescript
// src/routes/admin/usage.ts
import axios from 'axios';
import { Request, Response } from 'express';
import { tenantStorage } from '../../middleware/tenant';

const BILLING_SVC_INTERNAL_URL = process.env.BILLING_SVC_INTERNAL_URL!;

export async function getUsage(req: Request, res: Response): Promise<void> {
  const { tenantId } = tenantStorage.getStore()!;
  const response = await axios.get(
    `${BILLING_SVC_INTERNAL_URL}/internal/usage/${tenantId}`,
    { headers: { 'X-Tenant-ID': tenantId } },
  );
  res.json(response.data);
}
```

`BILLING_SVC_INTERNAL_URL` env var must be set (e.g., `http://billing-svc:8000`). `axios` is assumed already used in the project; add as dependency if absent. `tenantStorage` is the `AsyncLocalStorage` from RFC-004 (`src/middleware/tenant.ts`).

**AC:**

- When `billing_svc` returns `{ "period": "current", "usage": [{ "metric": "api_calls", "used": 150 }] }`, `getUsage()` returns the same payload with status 200.
- The proxy URL uses `tenantStorage.getStore()!.tenantId` as the path param — a request for tenant `abc-123` proxies to `/internal/usage/abc-123`.
- `tsc --noEmit` passes with no type errors.

---

### M6: Create `src/routes/admin/members.ts` with listMembers()

Create `src/routes/admin/members.ts` with `listMembers()` only — `inviteMember` and `removeMember` added in M7 and M8:

```typescript
// src/routes/admin/members.ts
import { Request, Response } from 'express';
import { getTenantById } from '../../db/tenants';
import { listOrgMembers } from '../../lib/auth0-management';
import { tenantStorage } from '../../middleware/tenant';

export async function listMembers(req: Request, res: Response): Promise<void> {
  const { tenantId } = tenantStorage.getStore()!;
  const tenant = await getTenantById(tenantId);
  const members = await listOrgMembers(tenant.auth0_org_id);
  res.json(members);
}
```

`getTenantById` is the existing lookup function from RFC-004/005 at `src/db/tenants.ts`. `listOrgMembers` is from M3.

**AC:**

- When Auth0 returns two organization members, `listMembers()` responds with a JSON array of two objects, each containing `userId`, `email`, `name`, `roles`.
- The Auth0 org ID is fetched from the DB using `tenantId` from `tenantStorage` — not from request params.
- `tsc --noEmit` passes with no type errors.

---

### M7: Add inviteMember() to `src/routes/admin/members.ts`

In `src/routes/admin/members.ts`, add `inviteOrgMember` to the import from `auth0-management` and append `inviteMember()` after `listMembers()`:

```typescript
import { listOrgMembers, inviteOrgMember } from '../../lib/auth0-management';

export async function inviteMember(req: Request, res: Response): Promise<void> {
  const { email, role } = req.body as { email: string; role: string };
  const { tenantId } = tenantStorage.getStore()!;
  const tenant = await getTenantById(tenantId);
  await inviteOrgMember(tenant.auth0_org_id, email, role, (req as any).auth.name);
  res.status(202).json({ message: 'Invitation sent' });
}
```

`(req as any).auth.name` reads the inviter's display name from the JWT — set by Auth0. No body validation in Phase 1.

**AC:**

- When called with body `{ "email": "user@acme.com", "role": "tenant_member" }`, `inviteOrgMember()` is called with the tenant's `auth0_org_id`, the email, role, and the JWT `name` claim as inviter name.
- Response status is `202` with body `{ "message": "Invitation sent" }`.
- `tsc --noEmit` passes with no type errors.

---

### M8: Add removeMember() to `src/routes/admin/members.ts`

In `src/routes/admin/members.ts`, add `removeOrgMember` to the import and append `removeMember()` after `inviteMember()`:

```typescript
import { listOrgMembers, inviteOrgMember, removeOrgMember } from '../../lib/auth0-management';

export async function removeMember(req: Request, res: Response): Promise<void> {
  const { userId } = req.params;
  const { tenantId } = tenantStorage.getStore()!;
  const tenant = await getTenantById(tenantId);
  await removeOrgMember(tenant.auth0_org_id, userId);
  res.status(204).send();
}
```

**AC:**

- When called with `userId` path param `"auth0|abc123"`, `removeOrgMember()` is called with the tenant's `auth0_org_id` and `"auth0|abc123"`.
- Response status is `204` with no body.
- `tsc --noEmit` passes with no type errors.

---

### M9: Create `src/routes/admin/features.ts` with listFeatures()

Create `src/routes/admin/features.ts` with `listFeatures()` only — `updateFeatureFlag` added in M10:

```typescript
// src/routes/admin/features.ts
import { Request, Response } from 'express';
import { withTenantConnection } from '../../db/tenant-client';
import { GLOBAL_FEATURE_DEFAULTS } from '../../config/plan-feature-gates';
import { tenantStorage } from '../../middleware/tenant';

export async function listFeatures(req: Request, res: Response): Promise<void> {
  const { tenantId } = tenantStorage.getStore()!;

  const overrides = await withTenantConnection(async (client) => {
    const result = await client.query<{ flag_key: string; enabled: boolean }>(
      `SELECT flag_key, enabled FROM shared.tenant_feature_flags WHERE tenant_id = $1`,
      [tenantId],
    );
    return result.rows;
  });

  const overrideMap = new Map(overrides.map((r) => [r.flag_key, r.enabled]));

  const flags = Object.entries(GLOBAL_FEATURE_DEFAULTS).map(([key, defaultVal]) => ({
    flag_key: key,
    enabled: overrideMap.has(key) ? overrideMap.get(key)! : defaultVal,
    source: overrideMap.has(key) ? 'override' : 'global',
  }));

  res.json(flags);
}
```

`tenant_feature_flags` is in the `shared` schema with no RLS policy (per RFC-005 design). Reading with an explicit `WHERE tenant_id = $1` is correct; `withTenantConnection` is used for consistency with RFC-004 patterns.

**AC:**

- When `tenant_feature_flags` has a row `(tenant_id=X, flag_key="sso_enabled", enabled=true)`, the response includes `{ "flag_key": "sso_enabled", "enabled": true, "source": "override" }`.
- When no override row exists for `"data_export"`, the response includes `{ "flag_key": "data_export", "enabled": true, "source": "global" }`.
- `tsc --noEmit` passes with no type errors.

---

### M10: Add updateFeatureFlag() to `src/routes/admin/features.ts`

In `src/routes/admin/features.ts`, add the additional imports and append `updateFeatureFlag()` after `listFeatures()`:

```typescript
import { getTenantById } from '../../db/tenants';
import { planAllowsFeature, TenantPlan } from '../../config/plan-feature-gates';
import { redis } from '../../config/redis';

export async function updateFeatureFlag(req: Request, res: Response): Promise<void> {
  const { flagKey } = req.params;
  const { enabled } = req.body as { enabled: boolean };
  const { tenantId } = tenantStorage.getStore()!;

  const tenant = await getTenantById(tenantId);
  if (!planAllowsFeature(tenant.plan as TenantPlan, flagKey)) {
    res.status(403).json({ error: `Feature '${flagKey}' requires plan upgrade` });
    return;
  }

  await withTenantConnection(async (client) => {
    await client.query(
      `INSERT INTO shared.tenant_feature_flags (tenant_id, flag_key, enabled)
       VALUES ($1, $2, $3)
       ON CONFLICT (tenant_id, flag_key) DO UPDATE SET enabled = $3, updated_at = now()`,
      [tenantId, flagKey, enabled],
    );
  });

  await redis.del(`tenant:${tenantId}:flag:${flagKey}`);

  res.json({ flag_key: flagKey, enabled });
}
```

`redis` is the existing Redis client exported from `src/config/redis.ts` (established in RFC-005). `tenant.plan` comes from `getTenantById()`.

**AC:**

- When `planAllowsFeature(tenant.plan, flagKey)` returns `true` and `enabled=true`, a row is upserted in `shared.tenant_feature_flags` and `redis.del("tenant:<id>:flag:<key>")` is called. Response is `{ "flag_key": "<key>", "enabled": true }` with status 200.
- When `planAllowsFeature(tenant.plan, flagKey)` returns `false`, response is `403` with `{ "error": "Feature '<key>' requires plan upgrade" }`. No DB write, no Redis del.
- `tsc --noEmit` passes with no type errors.

---

### M11: Create `src/routes/admin/billing.ts` with createBillingPortalSession()

Create `src/routes/admin/billing.ts`:

```typescript
// src/routes/admin/billing.ts
import { Request, Response } from 'express';
import Stripe from 'stripe';
import { getTenantById } from '../../db/tenants';
import { tenantStorage } from '../../middleware/tenant';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: '2024-04-10' });

export async function createBillingPortalSession(req: Request, res: Response): Promise<void> {
  const { tenantId } = tenantStorage.getStore()!;
  const tenant = await getTenantById(tenantId);

  const session = await stripe.billingPortal.sessions.create({
    customer: tenant.stripe_customer_id!,
    return_url: `${process.env.APP_BASE_URL}/admin/billing`,
  });

  res.json({ url: session.url });
}
```

`stripe_customer_id` null check is Phase 2 (M26). `STRIPE_SECRET_KEY` and `APP_BASE_URL` must be set in environment.

**AC:**

- When `tenant.stripe_customer_id` is `"cus_abc123"` and `APP_BASE_URL` is `"https://app.example.com"`, `stripe.billingPortal.sessions.create` is called with `{ customer: "cus_abc123", return_url: "https://app.example.com/admin/billing" }`.
- Response is `{ "url": "<stripe-portal-url>" }` with status 200.
- `tsc --noEmit` passes with no type errors.

---

### M12: Create `src/routes/admin/index.ts` and mount in `src/app.ts`

Create `src/routes/admin/index.ts`:

```typescript
// src/routes/admin/index.ts
import { Router } from 'express';
import { tenantMiddleware } from '../../middleware/tenant';
import { tenantAdminGuard } from '../../middleware/tenant-admin-guard';
import { listMembers, inviteMember, removeMember } from './members';
import { listFeatures, updateFeatureFlag } from './features';
import { getUsage } from './usage';
import { createBillingPortalSession } from './billing';

const adminRouter = Router();

adminRouter.use(tenantMiddleware);    // RFC-004: extracts tenant_id from JWT into AsyncLocalStorage
adminRouter.use(tenantAdminGuard);   // RFC-006: enforces tenant_admin role

adminRouter.get('/members', listMembers);
adminRouter.post('/members', inviteMember);
adminRouter.delete('/members/:userId', removeMember);
adminRouter.get('/features', listFeatures);
adminRouter.patch('/features/:flagKey', updateFeatureFlag);
adminRouter.get('/usage', getUsage);
adminRouter.post('/billing/portal-session', createBillingPortalSession);

export { adminRouter };
```

In `src/app.ts`, add after the existing versioned route mounts:

```typescript
import { adminRouter } from './routes/admin';
// ...
app.use('/v1/admin/tenant', adminRouter);
```

**AC:**

- `GET /v1/admin/tenant/members` with a JWT lacking `tenant_admin` role returns `403`.
- `GET /v1/admin/tenant/members` with a valid JWT containing `tenant_admin` role reaches the `listMembers` handler.
- `tsc --noEmit` passes on both files with no type errors.

---

### M13: Create `src/components/auth/RequireRole.tsx`

Create `src/components/auth/RequireRole.tsx`:

```typescript
// src/components/auth/RequireRole.tsx
import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';

const ROLES_CLAIM = 'https://yourapp.com/roles';

interface RequireRoleProps {
  role: string;
  children: React.ReactNode;
}

export function RequireRole({ role, children }: RequireRoleProps): JSX.Element {
  const { user } = useAuth();
  const roles: string[] = (user as any)?.[ROLES_CLAIM] ?? [];

  if (!roles.includes(role)) {
    return <Navigate to="/" replace />;
  }

  return <>{children}</>;
}
```

`useAuth()` is the existing auth hook that returns the decoded JWT payload as `user`. Adapt the hook import path and `user` property access to match the project's auth pattern (e.g., Auth0 React SDK's `useUser()`). If `RequireRole` already exists in the project, skip this milestone.

**AC:**

- When `user[ROLES_CLAIM]` includes the `role` prop value, `children` is rendered.
- When `user[ROLES_CLAIM]` does not include `role` (or is absent), `<Navigate to="/" replace />` is rendered.
- `tsc --noEmit` passes with no type errors.

---

### M14: Create `src/admin/UsageDashboard.tsx`

Create `src/admin/UsageDashboard.tsx`:

```typescript
// src/admin/UsageDashboard.tsx
import React, { useEffect, useState } from 'react';

interface UsageEntry { metric: string; used: number; }
interface UsageResponse { period: string; usage: UsageEntry[]; }

export function UsageDashboard(): JSX.Element {
  const [data, setData] = useState<UsageResponse | null>(null);

  useEffect(() => {
    fetch('/v1/admin/tenant/usage', {
      headers: { Authorization: `Bearer ${localStorage.getItem('access_token')}` },
    })
      .then((r) => r.json())
      .then(setData);
  }, []);

  if (!data) return <div>Loading...</div>;

  return (
    <div>
      <h2>Usage — {data.period}</h2>
      <table>
        <thead><tr><th>Metric</th><th>Used</th></tr></thead>
        <tbody>
          {data.usage.map((u) => (
            <tr key={u.metric}><td>{u.metric}</td><td>{u.used}</td></tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

Token retrieval from `localStorage` is a placeholder — adapt to the project's auth token access pattern.

**AC:**

- On mount, fetches `GET /v1/admin/tenant/usage` and renders each metric as a table row with `metric` and `used` columns.
- Before the fetch resolves, renders `<div>Loading...</div>`.
- `tsc --noEmit` passes with no type errors.

---

### M15: Create `src/admin/MemberList.tsx`

Create `src/admin/MemberList.tsx`:

```typescript
// src/admin/MemberList.tsx
import React, { useEffect, useState } from 'react';

interface Member { userId: string; email: string; name: string; roles: string[]; }

export function MemberList(): JSX.Element {
  const [members, setMembers] = useState<Member[]>([]);

  const fetchMembers = () =>
    fetch('/v1/admin/tenant/members', {
      headers: { Authorization: `Bearer ${localStorage.getItem('access_token')}` },
    })
      .then((r) => r.json())
      .then(setMembers);

  useEffect(() => { void fetchMembers(); }, []);

  const handleRemove = async (userId: string) => {
    await fetch(`/v1/admin/tenant/members/${encodeURIComponent(userId)}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${localStorage.getItem('access_token')}` },
    });
    void fetchMembers();
  };

  return (
    <table>
      <thead><tr><th>Email</th><th>Name</th><th>Role</th><th /></tr></thead>
      <tbody>
        {members.map((m) => (
          <tr key={m.userId}>
            <td>{m.email}</td>
            <td>{m.name}</td>
            <td>{m.roles.join(', ')}</td>
            <td><button onClick={() => handleRemove(m.userId)}>Remove</button></td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
```

**AC:**

- On mount, fetches `GET /v1/admin/tenant/members` and renders each member as a table row.
- Clicking Remove calls `DELETE /v1/admin/tenant/members/:userId` then refetches the member list.
- `tsc --noEmit` passes with no type errors.

---

### M16: Create `src/admin/InviteForm.tsx`

Create `src/admin/InviteForm.tsx`:

```typescript
// src/admin/InviteForm.tsx
import React, { useState } from 'react';

export function InviteForm(): JSX.Element {
  const [email, setEmail] = useState('');
  const [role, setRole] = useState('tenant_member');
  const [status, setStatus] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const res = await fetch('/v1/admin/tenant/members', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${localStorage.getItem('access_token')}`,
      },
      body: JSON.stringify({ email, role }),
    });
    if (res.status === 202) {
      setStatus('Invitation sent');
      setEmail('');
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input type="email" value={email} onChange={(e) => setEmail(e.target.value)}
        placeholder="Email address" required />
      <select value={role} onChange={(e) => setRole(e.target.value)}>
        <option value="tenant_member">Member</option>
        <option value="tenant_admin">Admin</option>
      </select>
      <button type="submit">Invite</button>
      {status && <span>{status}</span>}
    </form>
  );
}
```

**AC:**

- Submitting the form POSTs `{ "email": "<value>", "role": "<value>" }` to `/v1/admin/tenant/members`.
- On a 202 response, displays `"Invitation sent"` and clears the email field.
- `tsc --noEmit` passes with no type errors.

---

### M17: Create `src/admin/FeatureFlagList.tsx`

Create `src/admin/FeatureFlagList.tsx`:

```typescript
// src/admin/FeatureFlagList.tsx
import React, { useEffect, useState } from 'react';

interface FlagEntry { flag_key: string; enabled: boolean; source: 'global' | 'override'; }

export function FeatureFlagList(): JSX.Element {
  const [flags, setFlags] = useState<FlagEntry[]>([]);

  const fetchFlags = () =>
    fetch('/v1/admin/tenant/features', {
      headers: { Authorization: `Bearer ${localStorage.getItem('access_token')}` },
    })
      .then((r) => r.json())
      .then(setFlags);

  useEffect(() => { void fetchFlags(); }, []);

  const handleToggle = async (flagKey: string, enabled: boolean) => {
    await fetch(`/v1/admin/tenant/features/${encodeURIComponent(flagKey)}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${localStorage.getItem('access_token')}`,
      },
      body: JSON.stringify({ enabled }),
    });
    void fetchFlags();
  };

  return (
    <table>
      <thead><tr><th>Flag</th><th>Enabled</th><th>Source</th></tr></thead>
      <tbody>
        {flags.map((f) => (
          <tr key={f.flag_key}>
            <td>{f.flag_key}</td>
            <td>
              <input type="checkbox" checked={f.enabled}
                onChange={(e) => handleToggle(f.flag_key, e.target.checked)} />
            </td>
            <td>{f.source}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
```

**AC:**

- On mount, fetches `GET /v1/admin/tenant/features` and renders each flag as a row with a checkbox reflecting `enabled`.
- Toggling a checkbox calls `PATCH /v1/admin/tenant/features/:flagKey` with `{ "enabled": <bool> }` then refetches the list.
- `tsc --noEmit` passes with no type errors.

---

### M18: Create `src/admin/BillingPortalRedirect.tsx`

Create `src/admin/BillingPortalRedirect.tsx`:

```typescript
// src/admin/BillingPortalRedirect.tsx
import React from 'react';

export function BillingPortalRedirect(): JSX.Element {
  const handleClick = async () => {
    const res = await fetch('/v1/admin/tenant/billing/portal-session', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${localStorage.getItem('access_token')}`,
      },
    });
    const { url } = (await res.json()) as { url: string };
    window.location.href = url;
  };

  return (
    <div>
      <p>Manage payment methods, download invoices, and review subscription history.</p>
      <button onClick={handleClick}>Open Billing Portal</button>
    </div>
  );
}
```

**AC:**

- Clicking "Open Billing Portal" POSTs to `/v1/admin/tenant/billing/portal-session`.
- On success, sets `window.location.href` to the `url` from the response — redirecting the browser to Stripe's hosted portal.
- `tsc --noEmit` passes with no type errors.

---

### M19: Create `src/admin/AdminPortal.tsx`

Create `src/admin/AdminPortal.tsx`. All sub-components (M14–M18) exist at this point:

```typescript
// src/admin/AdminPortal.tsx
import React from 'react';
import { Navigate, NavLink, Route, Routes } from 'react-router-dom';
import { BillingPortalRedirect } from './BillingPortalRedirect';
import { FeatureFlagList } from './FeatureFlagList';
import { InviteForm } from './InviteForm';
import { MemberList } from './MemberList';
import { UsageDashboard } from './UsageDashboard';

export default function AdminPortal(): JSX.Element {
  return (
    <div>
      <nav>
        <NavLink to="/admin/members">Members</NavLink>
        <NavLink to="/admin/features">Features</NavLink>
        <NavLink to="/admin/usage">Usage</NavLink>
        <NavLink to="/admin/billing">Billing</NavLink>
      </nav>
      <main>
        <Routes>
          <Route path="members" element={<><MemberList /><InviteForm /></>} />
          <Route path="features" element={<FeatureFlagList />} />
          <Route path="usage" element={<UsageDashboard />} />
          <Route path="billing" element={<BillingPortalRedirect />} />
          <Route index element={<Navigate to="members" replace />} />
        </Routes>
      </main>
    </div>
  );
}
```

Default export required for `React.lazy()`. All sub-components are eagerly imported here — they're part of the same lazy admin chunk.

**AC:**

- `AdminPortal` renders a nav with links to `/admin/members`, `/admin/features`, `/admin/usage`, `/admin/billing`.
- Navigating to `/admin/` (index) redirects to `/admin/members`.
- `tsc --noEmit` passes with no type errors.

---

### M20: Add lazy /admin/* route to `src/routes/index.tsx`

In `src/routes/index.tsx`, add the lazy import and admin route. Add to or alongside existing lazy imports at the top:

```typescript
import React, { lazy, Suspense } from 'react';
import { RequireRole } from '../components/auth/RequireRole';

const AdminPortal = lazy(() => import('../admin/AdminPortal'));
```

Inside the `<Routes>` element, add before the catch-all route:

```typescript
<Route
  path="/admin/*"
  element={
    <RequireRole role="tenant_admin">
      <Suspense fallback={<div>Loading admin...</div>}>
        <AdminPortal />
      </Suspense>
    </RequireRole>
  }
/>
```

`AdminPortal` is only downloaded when a `tenant_admin` user navigates to `/admin/`. The `<div>Loading admin...</div>` Suspense fallback is replaced by `AdminSkeleton` in Phase 3 (M30).

**AC:**

- Navigating to `/admin/members` as a user with `tenant_admin` in their JWT roles claim renders `AdminPortal` after the lazy bundle loads.
- Navigating to `/admin/` as a user without `tenant_admin` renders `<Navigate to="/" replace />` from `RequireRole`.
- `tsc --noEmit` passes on this file with no type errors.

---

## Phase 2 — Details

### M21: Create `shared/migrations/0004_add_admin_audit_log.py`

Create `shared/migrations/0004_add_admin_audit_log.py`. Set `depends_on` to the most recent revision in `shared/migrations/` (e.g., `0003_add_tenant_config_tables`).

```python
# shared/migrations/0004_add_admin_audit_log.py
import sqlalchemy as sa
from alembic import op


def upgrade() -> None:
    op.create_table(
        "admin_audit_log",
        sa.Column(
            "id", sa.UUID(as_uuid=True), primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("tenant_id", sa.UUID(as_uuid=True), nullable=False),
        sa.Column("actor_user_id", sa.String(128), nullable=False),
        sa.Column("action", sa.String(64), nullable=False),
        sa.Column("target_user_id", sa.String(128), nullable=True),
        sa.Column("metadata", sa.JSON, nullable=True),
        sa.Column(
            "occurred_at", sa.DateTime(timezone=True),
            server_default=sa.text("now()"), nullable=False,
        ),
        schema="shared",
    )
    op.create_index(
        "ix_admin_audit_log_tenant_id", "admin_audit_log", ["tenant_id"], schema="shared"
    )
    op.create_index(
        "ix_admin_audit_log_occurred_at", "admin_audit_log", ["occurred_at"], schema="shared"
    )
    # No RLS — cross-tenant by design (RFC-006). Internal ops tool reads all rows.
    # Application writes use app_admin role (BYPASSRLS).


def downgrade() -> None:
    op.drop_index("ix_admin_audit_log_occurred_at", table_name="admin_audit_log", schema="shared")
    op.drop_index("ix_admin_audit_log_tenant_id", table_name="admin_audit_log", schema="shared")
    op.drop_table("admin_audit_log", schema="shared")
```

**AC:**

- `alembic upgrade head` (as `app_admin`) creates `shared.admin_audit_log` with columns: `id`, `tenant_id`, `actor_user_id`, `action`, `target_user_id`, `metadata`, `occurred_at`.
- Indexes exist on `tenant_id` and `occurred_at`. No RLS policy exists on the table.
- `alembic downgrade -1` drops the table and both indexes cleanly.

---

### M22: Add audit log INSERT to inviteMember() in `src/routes/admin/members.ts`

In `src/routes/admin/members.ts`, add `pool` import and audit log INSERT inside `inviteMember()`, after the successful `inviteOrgMember()` call:

```typescript
import { pool } from '../../db/pool';  // raw pool — audit_log has no RLS

// Inside inviteMember(), after await inviteOrgMember(...):
await pool.query(
  `INSERT INTO shared.admin_audit_log
     (tenant_id, actor_user_id, action, target_user_id, metadata)
   VALUES ($1, $2, 'member_invite', $3, $4)`,
  [tenantId, (req as any).auth.sub, email, JSON.stringify({ role })],
);
```

The raw `pool` is used intentionally — `admin_audit_log` has no RLS policy and the INSERT must succeed regardless of tenant context. The ESLint `no-restricted-syntax` rule from RFC-004 bans `pool.query()` to prevent bypassing RLS; add an inline `// eslint-disable-next-line no-restricted-syntax` comment here since the bypass is deliberate.

**AC:**

- After a successful invite, a row is inserted into `shared.admin_audit_log` with `tenant_id=<tenantId>`, `actor_user_id=<auth.sub>`, `action="member_invite"`, `target_user_id=<email>`, `metadata={"role":"<role>"}`.
- `tsc --noEmit` passes with no type errors.

---

### M23: Add audit log INSERT to removeMember() in `src/routes/admin/members.ts`

In `src/routes/admin/members.ts`, add audit log INSERT inside `removeMember()`, after the successful `removeOrgMember()` call (`pool` import is already present from M22):

```typescript
// Inside removeMember(), after await removeOrgMember(...):
// eslint-disable-next-line no-restricted-syntax
await pool.query(
  `INSERT INTO shared.admin_audit_log
     (tenant_id, actor_user_id, action, target_user_id)
   VALUES ($1, $2, 'member_remove', $3)`,
  [tenantId, (req as any).auth.sub, userId],
);
```

**AC:**

- After a successful removal, a row is inserted into `shared.admin_audit_log` with `tenant_id=<tenantId>`, `actor_user_id=<auth.sub>`, `action="member_remove"`, `target_user_id=<userId>`.
- `tsc --noEmit` passes with no type errors.

---

### M24: Add Auth0 API error handling to inviteMember()

In `src/routes/admin/members.ts`, wrap the `inviteOrgMember()` call in `inviteMember()` with a try/catch:

```typescript
try {
  await inviteOrgMember(tenant.auth0_org_id, email, role, (req as any).auth.name);
} catch (err: any) {
  if (err?.statusCode === 409) {
    res.status(409).json({ error: 'User is already a member or has a pending invitation' });
    return;
  }
  res.status(502).json({ error: 'Failed to send invitation. Please try again.' });
  return;
}
```

Move the audit log INSERT (M22) to after the try/catch block so it only runs on success.

**AC:**

- When Auth0 returns 409, response is `409` with `{ "error": "User is already a member or has a pending invitation" }`. No audit log row inserted.
- When Auth0 returns any other non-2xx status, response is `502` with `{ "error": "Failed to send invitation. Please try again." }`.
- When Auth0 succeeds, behavior is unchanged from M7 (202 + audit log).

---

### M25: Add self-removal guard and Auth0 error handling to removeMember()

In `src/routes/admin/members.ts`, update `removeMember()` to add self-removal check before the Auth0 call, and wrap `removeOrgMember()` in try/catch:

```typescript
export async function removeMember(req: Request, res: Response): Promise<void> {
  const { userId } = req.params;
  const actorSub: string = (req as any).auth.sub;

  if (userId === actorSub) {
    res.status(400).json({ error: 'Cannot remove yourself from the organization' });
    return;
  }

  const { tenantId } = tenantStorage.getStore()!;
  const tenant = await getTenantById(tenantId);

  try {
    await removeOrgMember(tenant.auth0_org_id, userId);
  } catch (err: any) {
    res.status(502).json({ error: 'Failed to remove member. Please try again.' });
    return;
  }

  // audit log INSERT from M23 here
  // eslint-disable-next-line no-restricted-syntax
  await pool.query(...);
  res.status(204).send();
}
```

**AC:**

- When `req.params.userId === req.auth.sub`, response is `400` with `{ "error": "Cannot remove yourself from the organization" }`. No Auth0 call, no audit log.
- When Auth0 returns non-2xx, response is `502` with `{ "error": "Failed to remove member. Please try again." }`. No audit log.
- When Auth0 succeeds, audit log is inserted and response is `204`.

---

### M26: Add missing stripe_customer_id guard and Stripe error handling to createBillingPortalSession()

In `src/routes/admin/billing.ts`, add null check after tenant lookup and wrap the Stripe call in try/catch:

```typescript
export async function createBillingPortalSession(req: Request, res: Response): Promise<void> {
  const { tenantId } = tenantStorage.getStore()!;
  const tenant = await getTenantById(tenantId);

  if (!tenant.stripe_customer_id) {
    res.status(400).json({ error: 'No Stripe subscription found. Contact support to set up billing.' });
    return;
  }

  try {
    const session = await stripe.billingPortal.sessions.create({
      customer: tenant.stripe_customer_id,
      return_url: `${process.env.APP_BASE_URL}/admin/billing`,
    });
    res.json({ url: session.url });
  } catch (err: any) {
    res.status(502).json({ error: 'Failed to create billing portal session. Please try again.' });
  }
}
```

**AC:**

- When `tenant.stripe_customer_id` is `null` or `undefined`, response is `400` with `{ "error": "No Stripe subscription found. Contact support to set up billing." }`.
- When Stripe API throws, response is `502` with `{ "error": "Failed to create billing portal session. Please try again." }`.

---

### M27: Add period parameter support to billing_svc internal endpoint and usage proxy

In `billing_svc/views/internal.py`, add period parsing and update the query to filter by date range:

```python
import calendar
from datetime import date


def _get_period_range(period: str) -> tuple[date, date]:
    if period == 'current':
        today = date.today()
        start = today.replace(day=1)
        _, last_day = calendar.monthrange(today.year, today.month)
        return start, today.replace(day=last_day)
    try:
        year, month = int(period[:4]), int(period[5:7])
        _, last_day = calendar.monthrange(year, month)
        return date(year, month, 1), date(year, month, last_day)
    except (ValueError, IndexError):
        raise ValueError(f"Invalid period: {period!r}")


class InternalUsageView(View):
    def get(self, request, tenant_id: uuid.UUID):
        period_str = request.GET.get('period', 'current')
        try:
            start, end = _get_period_range(period_str)
        except ValueError:
            return JsonResponse({"error": "Invalid period. Use 'current' or 'YYYY-MM'."}, status=400)

        with admin_context():
            session = Session()
            try:
                rows = session.execute(
                    select(UsageRecord.metric, func.sum(UsageRecord.quantity).label("used"))
                    .where(
                        UsageRecord.tenant_id == tenant_id,
                        func.date(UsageRecord.occurred_at) >= start,
                        func.date(UsageRecord.occurred_at) <= end,
                    )
                    .group_by(UsageRecord.metric)
                ).all()
            finally:
                session.close()

        usage = [{"metric": row.metric, "used": int(row.used)} for row in rows]
        return JsonResponse({"period": period_str, "usage": usage})
```

In `src/routes/admin/usage.ts`, forward the `period` query param:

```typescript
export async function getUsage(req: Request, res: Response): Promise<void> {
  const { tenantId } = tenantStorage.getStore()!;
  const period = (req.query.period as string) ?? 'current';
  const response = await axios.get(
    `${BILLING_SVC_INTERNAL_URL}/internal/usage/${tenantId}?period=${encodeURIComponent(period)}`,
    { headers: { 'X-Tenant-ID': tenantId } },
  );
  res.json(response.data);
}
```

**AC:**

- `GET /internal/usage/<tenant-id>?period=2026-01` returns usage aggregated for January 2026 only, with `"period": "2026-01"` in the response.
- `GET /internal/usage/<tenant-id>?period=invalid` returns `400` with `{ "error": "Invalid period. Use 'current' or 'YYYY-MM'." }`.
- `GET /v1/admin/tenant/usage` (no period) defaults to `"current"` — behavior unchanged from M5.

---

### M28: Create `auth0/actions/inject-roles.js`

Create `auth0/actions/inject-roles.js` (versioned in repo; deployed via Auth0 Deploy CLI or dashboard):

```javascript
/**
 * Auth0 Post-Login Action: inject-roles
 * Trigger: Post Login
 *
 * Injects the user's Auth0 Organization member roles as a custom claim.
 * Claim namespace must match ROLES_CLAIM constant in:
 *   - src/middleware/tenant-admin-guard.ts  (Express API guard)
 *   - src/components/auth/RequireRole.tsx   (React route guard)
 *
 * Auth0 Organization roles "tenant_admin" and "tenant_member" must be created
 * in the Auth0 dashboard before this Action is deployed.
 *
 * PREREQUISITE: Resolve RFC-006 Q1 (confirm Auth0 plan supports custom
 * Organization member roles) before deploying this Action.
 */

const ROLES_CLAIM = 'https://yourapp.com/roles';

exports.onExecutePostLogin = async (event, api) => {
  const roles = event.authorization?.roles ?? [];
  api.idToken.setCustomClaim(ROLES_CLAIM, roles);
  api.accessToken.setCustomClaim(ROLES_CLAIM, roles);
};
```

Uses `event.authorization.roles` — the roles assigned to the user in the Auth0 Organization they are currently logging into. No Action secrets required.

**AC:**

- When `event.authorization.roles` is `["tenant_admin"]`, both `api.idToken.setCustomClaim` and `api.accessToken.setCustomClaim` are called with `'https://yourapp.com/roles'` and `["tenant_admin"]`.
- When `event.authorization.roles` is `undefined` or `null`, both claims are set to `[]` (empty array — never `null` or `undefined`).
- The Action file contains a comment identifying the two files that must use the same `ROLES_CLAIM` constant value.

---

## Phase 3 — Polish

### M29: Update C4 container diagrams for RFC-006

Locate the C4 container diagram (glob `docs/c4/*.md` or `docs/architecture/c4*.md`). Apply targeted updates — no new containers (RFC-006 adds no new infrastructure):

**Container description updates:**

- **Web App (React SPA)**: append `"; includes lazy-loaded tenant admin portal at /admin/ — code-split, only downloaded by tenant_admin users"`
- **API Server (Express.js)**: append `"; /v1/admin/tenant/ namespace for tenant self-service: member management, feature flags, usage, Stripe billing portal"`

**Rel() additions:**

- API Server → Auth0: add `"Auth0 Management API (invite/remove org members via /v1/admin/tenant/members)"`
- API Server → billing_svc: add `"GET /internal/usage/:tenant_id (usage dashboard proxy)"`
- API Server → Stripe: add `"billingPortal.sessions.create (admin billing portal redirect)"`

Add Change Log entry: `2026-04-19: Updated for RFC-006 — lazy admin SPA route at /admin/ and /v1/admin/tenant/ API namespace`.

**AC:**

- The C4 diagram file renders without Mermaid syntax errors.
- Web App container description references `"/admin/"` and `"tenant_admin"`.
- API Server container description references `"/v1/admin/tenant/"`.

---

### M30: Create AdminSkeleton and replace Suspense fallback placeholder

Create `src/admin/AdminSkeleton.tsx`:

```typescript
// src/admin/AdminSkeleton.tsx
import React from 'react';

export function AdminSkeleton(): JSX.Element {
  return (
    <div aria-label="Loading admin portal">
      <div style={{ height: 40, background: '#eee', marginBottom: 8 }} />
      <div style={{ height: 200, background: '#f5f5f5' }} />
    </div>
  );
}
```

In `src/routes/index.tsx`, replace `<div>Loading admin...</div>` with `<AdminSkeleton />`:

```typescript
import { AdminSkeleton } from '../admin/AdminSkeleton';

<Suspense fallback={<AdminSkeleton />}>
  <AdminPortal />
</Suspense>
```

**AC:**

- While the admin bundle is loading (Suspense suspended), `<AdminSkeleton>` is rendered with `aria-label="Loading admin portal"`.
- `tsc --noEmit` passes on both files with no type errors.

---

## Change Log

- 2026-04-19: Initial plan created from RFC-006
