# PLAN-RFC-004: Per-IP Rate Limiting for REST API Endpoint Groups

**RFC**: RFC-004
**Status**: Ready
**Created**: 2026-04-19
**Last Updated**: 2026-04-19

## File Structure Map

| File | Action | Responsibility |
|---|---|---|
| `src/config/rateLimits.ts` | Create | Export `rateLimitConfig` — per-group `max` and `windowMs` values, initially hardcoded, then env-var-backed |
| `src/middleware/rateLimiter.ts` | Create | Export `publicLimiter`, `authLimiter`, `adminLimiter` — express-rate-limit instances with Redis store |
| `src/app.ts` | Modify | Set `trust proxy 1`, mount health routes before rate limiters, wire limiters to router groups |
| `package.json` | Modify | Add `express-rate-limit@7` and `rate-limit-redis` dependencies |

---

## Phase 1 — Core

### M1: Install `express-rate-limit@7` and `rate-limit-redis`

Run `npm install express-rate-limit@7 rate-limit-redis` in the project root. No source files change in this milestone — package installation only.

**Acceptance Criteria**

- Both packages appear in `package.json` `dependencies` with pinned or range versions.
- `node_modules/express-rate-limit` and `node_modules/rate-limit-redis` directories exist after install.

---

### M2: Create `src/config/rateLimits.ts` with hardcoded defaults

Create the file `src/config/rateLimits.ts`. Export a single `const rateLimitConfig` object with three sub-objects:

```ts
export const rateLimitConfig = {
  public: { max: 60, windowMs: 60_000 },
  auth:   { max: 300, windowMs: 60_000 },
  admin:  { max: 60, windowMs: 60_000 },
};
```

No env var reading, no validation, no dynamic logic — hardcoded values only. This milestone is Phase 1; env var support is added in M9.

**Acceptance Criteria**

- Importing `rateLimitConfig` from `../config/rateLimits` in a TypeScript file compiles without errors.
- `rateLimitConfig.public.max === 60`, `rateLimitConfig.public.windowMs === 60000`.
- `rateLimitConfig.auth.max === 300`, `rateLimitConfig.auth.windowMs === 60000`.
- `rateLimitConfig.admin.max === 60`, `rateLimitConfig.admin.windowMs === 60000`.

---

### M3: Create `src/middleware/rateLimiter.ts` — export `publicLimiter`

Create the file `src/middleware/rateLimiter.ts`. Import and wire:

```ts
import rateLimit from 'express-rate-limit';
import RedisStore from 'rate-limit-redis';
import { redisClient } from '../lib/redis';
import { rateLimitConfig } from '../config/rateLimits';

const store = (prefix: string) =>
  new RedisStore({ sendCommand: (...args: string[]) => redisClient.sendCommand(args), prefix });

export const publicLimiter = rateLimit({
  windowMs: rateLimitConfig.public.windowMs,
  max: rateLimitConfig.public.max,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  store: store('rl:public:'),
});
```

Do not add `authLimiter` or `adminLimiter` yet — that is M6. `standardHeaders: 'draft-7'` emits `RateLimit-*` headers per IETF draft-7 and sets `Retry-After` automatically; no extra header logic needed.

**Acceptance Criteria**

- `publicLimiter` is a function with arity 3 (Express `(req, res, next)` signature).
- Constructing `store('rl:public:')` does not throw at import time.
- `publicLimiter`'s internal config has `standardHeaders` set to `'draft-7'` and `legacyHeaders` set to `false`.

---

### M4: Set `app.set('trust proxy', 1)` in `src/app.ts`

In `src/app.ts`, add `app.set('trust proxy', 1)` as the first statement after `const app = express()` (or equivalent app creation), before any `app.use` or route registration. Single-line insertion only — no other changes in this milestone.

The value `1` means Express reads `req.ip` from the first entry of `X-Forwarded-For`, which corresponds to the actual client IP behind one reverse-proxy hop. Do not use `true` (would trust all `X-Forwarded-For` entries, enabling IP spoofing).

**Acceptance Criteria**

- `app.get('trust proxy')` returns `1`.
- The `app.set('trust proxy', 1)` line appears before all `app.use` calls in `src/app.ts`.

---

### M5: Wire `publicLimiter` to `/v1/public` in `src/app.ts`

In `src/app.ts`, import `publicLimiter` from `./middleware/rateLimiter` and add:

```ts
app.use('/v1/public', publicLimiter, publicRouter);
```

Replace (or augment) the existing `app.use('/v1/public', publicRouter)` line with this form so `publicLimiter` runs before `publicRouter`. Do not modify other routes in this milestone.

**Acceptance Criteria**

- In the Express router stack, the `publicLimiter` layer appears before the `publicRouter` layer on the `/v1/public` path.
- A `GET /v1/public/anything` request passes through `publicLimiter` before reaching `publicRouter`.

---

### M6: Add `authLimiter` and `adminLimiter` exports to `src/middleware/rateLimiter.ts`

In `src/middleware/rateLimiter.ts`, append two additional exports after `publicLimiter`. The `store` helper and imports already exist from M3 — reuse them:

```ts
export const authLimiter = rateLimit({
  windowMs: rateLimitConfig.auth.windowMs,
  max: rateLimitConfig.auth.max,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  store: store('rl:auth:'),
});

export const adminLimiter = rateLimit({
  windowMs: rateLimitConfig.admin.windowMs,
  max: rateLimitConfig.admin.max,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  store: store('rl:admin:'),
});
```

Each limiter uses a distinct Redis key prefix (`'rl:auth:'` and `'rl:admin:'`) so counters are independent. No changes to `src/app.ts` in this milestone.

**Acceptance Criteria**

- `authLimiter` and `adminLimiter` are exported functions with arity 3.
- `authLimiter`'s store uses prefix `'rl:auth:'`; `adminLimiter`'s store uses prefix `'rl:admin:'`.
- `authLimiter` is configured with `max: 300`; `adminLimiter` with `max: 60`.

---

### M7: Wire `authLimiter` and `adminLimiter` in `src/app.ts`

In `src/app.ts`, add `authLimiter` and `adminLimiter` to the import from `./middleware/rateLimiter`. Replace (or augment) the existing `/v1` and `/admin` `app.use` calls:

```ts
app.use('/v1', authLimiter, v1Router);
app.use('/admin', adminLimiter, adminRouter);
```

`publicLimiter` wiring from M5 remains unchanged.

**Acceptance Criteria**

- `v1Router` is preceded by `authLimiter` in the `/v1` route stack.
- `adminRouter` is preceded by `adminLimiter` in the `/admin` route stack.
- All three rate-limited router registrations exist in `src/app.ts`.

---

### M8: Mount `/health` and `/ready` before rate-limited routers in `src/app.ts`

In `src/app.ts`, ensure `app.use('/health', healthRouter)` and `app.use('/ready', readyRouter)` appear before all `app.use` calls that include a rate limiter (`publicLimiter`, `authLimiter`, `adminLimiter`). Move these two lines if they are not already in the correct position. No other changes.

**Acceptance Criteria**

- In `app._router.stack`, the index of the `/health` layer is less than the index of the `/v1/public` (publicLimiter) layer.
- In `app._router.stack`, the index of the `/ready` layer is less than the index of the `/v1/public` (publicLimiter) layer.
- A `GET /health` request reaches `healthRouter` without passing through `publicLimiter`, `authLimiter`, or `adminLimiter`.

---

## Phase 2 — Details

### M9: Add env var reading to `src/config/rateLimits.ts`

Replace the hardcoded values in `src/config/rateLimits.ts` with env var reads. Use `parseInt` with a fallback for each of the six fields:

```ts
export const rateLimitConfig = {
  public: {
    max:      parseInt(process.env.RATE_LIMIT_PUBLIC_MAX       ?? '60',    10),
    windowMs: parseInt(process.env.RATE_LIMIT_PUBLIC_WINDOW_MS ?? '60000', 10),
  },
  auth: {
    max:      parseInt(process.env.RATE_LIMIT_AUTH_MAX          ?? '300',   10),
    windowMs: parseInt(process.env.RATE_LIMIT_AUTH_WINDOW_MS    ?? '60000', 10),
  },
  admin: {
    max:      parseInt(process.env.RATE_LIMIT_ADMIN_MAX          ?? '60',    10),
    windowMs: parseInt(process.env.RATE_LIMIT_ADMIN_WINDOW_MS    ?? '60000', 10),
  },
};
```

Validation is added in M10. This milestone only introduces the reads.

**Acceptance Criteria**

- Given `RATE_LIMIT_AUTH_MAX=500` in `process.env`, `rateLimitConfig.auth.max === 500`.
- Given no env vars set, all values equal the original hardcoded defaults: public max 60, auth max 300, admin max 60, all windows 60000.

---

### M10: Validate env var values at startup in `src/config/rateLimits.ts`

After parsing each value, validate it. If `isNaN(value) || value <= 0`, throw an `Error` with a message that names the env var and shows the raw value. Add validation immediately after the `rateLimitConfig` declaration, covering all six fields. Example pattern:

```ts
const entries: Array<[string, number, string]> = [
  ['RATE_LIMIT_PUBLIC_MAX',       rateLimitConfig.public.max,      process.env.RATE_LIMIT_PUBLIC_MAX       ?? ''],
  ['RATE_LIMIT_PUBLIC_WINDOW_MS', rateLimitConfig.public.windowMs, process.env.RATE_LIMIT_PUBLIC_WINDOW_MS ?? ''],
  ['RATE_LIMIT_AUTH_MAX',         rateLimitConfig.auth.max,        process.env.RATE_LIMIT_AUTH_MAX         ?? ''],
  ['RATE_LIMIT_AUTH_WINDOW_MS',   rateLimitConfig.auth.windowMs,   process.env.RATE_LIMIT_AUTH_WINDOW_MS   ?? ''],
  ['RATE_LIMIT_ADMIN_MAX',        rateLimitConfig.admin.max,       process.env.RATE_LIMIT_ADMIN_MAX        ?? ''],
  ['RATE_LIMIT_ADMIN_WINDOW_MS',  rateLimitConfig.admin.windowMs,  process.env.RATE_LIMIT_ADMIN_WINDOW_MS  ?? ''],
];
for (const [name, value, raw] of entries) {
  if (isNaN(value) || value <= 0) {
    throw new Error(
      `Invalid rate limit config: ${name} must be a positive integer, got "${raw || '(default)'}"`
    );
  }
}
```

Only validate env-var-set fields that fail — defaults are always valid so they never trigger the throw.

**Acceptance Criteria**

- Given `RATE_LIMIT_PUBLIC_MAX=abc` in `process.env`, importing `rateLimitConfig` throws `Error` with message containing `'RATE_LIMIT_PUBLIC_MAX'` and `'abc'`.
- Given `RATE_LIMIT_AUTH_MAX=0` in `process.env`, throws `Error` with message containing `'RATE_LIMIT_AUTH_MAX'` and `'0'`.
- Given all env vars unset, no error is thrown and defaults apply.
- Given all env vars set to valid positive integers, no error is thrown.

---

## Phase 3 — Polish

### M11: Log effective rate limit config at server startup

In `src/app.ts` (or the file that calls `app.listen`), add a `console.log` immediately after `rateLimitConfig` is available — either at module level after the import, or inside the `listen` callback. Log all three groups:

```ts
console.log(
  '[rate-limit] public: %d req / %d ms | auth: %d req / %d ms | admin: %d req / %d ms',
  rateLimitConfig.public.max,  rateLimitConfig.public.windowMs,
  rateLimitConfig.auth.max,    rateLimitConfig.auth.windowMs,
  rateLimitConfig.admin.max,   rateLimitConfig.admin.windowMs,
);
```

**Acceptance Criteria**

- Server startup output contains a line beginning with `[rate-limit]` that includes all three groups' `max` and `windowMs` values matching the resolved config.
- When env vars override defaults, the logged values reflect the overrides, not the hardcoded defaults.

---

## Change Log

- 2026-04-19: Initial plan — 11 milestones across 3 phases
