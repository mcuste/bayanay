# RFC-004: Per-IP Rate Limiting for REST API Endpoint Groups

**ID**: RFC-004
**Status**: In Review
**Proposed by**: Engineering Team
**Created**: 2026-04-19
**Last Updated**: 2026-04-19
**Targets**: Implementation

## Problem / Motivation

Public API endpoints are receiving sustained abuse from scrapers: single IPs hitting ~200 requests/second. This degrades response times for legitimate users, increases Redis and database load, and risks exhausting connection pools. There is currently no rate limiting on any endpoint. Without it, a single bad actor can monopolize server resources indefinitely.

## Goals and Non-Goals

### Goals

- Block sustained high-volume scraping (hundreds of requests/second from a single IP)
- Apply per-IP rate limits with different thresholds for three endpoint groups: public (unauthenticated), authenticated, and admin
- Make thresholds configurable per group without a code deploy (environment variables)
- Return standard `429 Too Many Requests` responses with `Retry-After` and `RateLimit-*` headers
- Use the existing Redis instance — no new infrastructure
- Exclude health check endpoints (`/health`, `/ready`) from rate limiting

### Non-Goals

- Per-user-ID rate limiting (IP-based only for this RFC)
- Allowlisting specific IPs or CIDR ranges
- Geographic blocking or bot detection beyond rate limiting
- Distributed rate limiting across multiple data centers
- Rate limiting internal service-to-service traffic

## Proposed Solution

Add `express-rate-limit` (v7) with `rate-limit-redis` store to the Express.js API Server. Create three middleware instances with independent thresholds and apply each to the corresponding router group before route handlers.

### Packages

```
npm install express-rate-limit rate-limit-redis
```

`express-rate-limit` is the de facto standard Express rate limiting middleware (8M+ weekly npm downloads). `rate-limit-redis` is its officially supported Redis store adapter, using atomic `INCR`/`EXPIRE` operations — the same pattern the existing Redis instance already handles per the C4 container notes.

### Configuration

New file `src/config/rateLimits.ts` reads thresholds from environment variables with safe defaults:

| Group         | Env var prefix          | Default max | Default window |
|---------------|-------------------------|-------------|----------------|
| Public        | `RATE_LIMIT_PUBLIC_*`   | 60 req      | 1 minute       |
| Authenticated | `RATE_LIMIT_AUTH_*`     | 300 req     | 1 minute       |
| Admin         | `RATE_LIMIT_ADMIN_*`    | 60 req      | 1 minute       |

Full env vars: `RATE_LIMIT_PUBLIC_MAX`, `RATE_LIMIT_PUBLIC_WINDOW_MS`, `RATE_LIMIT_AUTH_MAX`, `RATE_LIMIT_AUTH_WINDOW_MS`, `RATE_LIMIT_ADMIN_MAX`, `RATE_LIMIT_ADMIN_WINDOW_MS`.

### Middleware

New file `src/middleware/rateLimiter.ts` exports three named limiters:

```ts
import rateLimit from 'express-rate-limit';
import RedisStore from 'rate-limit-redis';
import { redisClient } from '../lib/redis';
import { rateLimitConfig } from '../config/rateLimits';

const store = (prefix: string) =>
  new RedisStore({ sendCommand: (...args) => redisClient.sendCommand(args), prefix });

export const publicLimiter = rateLimit({
  windowMs: rateLimitConfig.public.windowMs,
  max: rateLimitConfig.public.max,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  store: store('rl:public:'),
});

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

Key generator defaults to `req.ip`. `standardHeaders: 'draft-7'` emits `RateLimit-*` headers per the IETF draft standard. Legacy `X-RateLimit-*` headers are disabled to avoid duplication.

### Trust Proxy

Set `app.set('trust proxy', 1)` in `src/app.ts`. The deployment sits behind a single reverse proxy (one hop), so Express reads `req.ip` from the first `X-Forwarded-For` entry — the actual client IP. Setting this to the correct hop count prevents IP spoofing: a higher value would allow clients to inject arbitrary IPs into `X-Forwarded-For`.

### Router Application

In `src/app.ts`, health check routes are mounted before rate-limited routers so they are never subject to limiting. Rate limiting runs before authentication middleware within each group — this prevents scrapers from consuming auth overhead before being rejected on public routes.

```ts
import { publicLimiter, authLimiter, adminLimiter } from './middleware/rateLimiter';

app.set('trust proxy', 1);

// Health checks — no rate limiting
app.use('/health', healthRouter);
app.use('/ready', readyRouter);

// Rate-limited endpoint groups
app.use('/v1/public', publicLimiter, publicRouter);
app.use('/v1', authLimiter, v1Router);         // authenticated endpoints
app.use('/admin', adminLimiter, adminRouter);
```

### Failure Behavior

On Redis unavailability, `rate-limit-redis` throws and `express-rate-limit` defaults to **fail-open** (allows the request). This is intentional: rate limiting is a hardening measure, not an access control gate. Degraded Redis should not take down the API for legitimate users. The Redis instance is already a hard dependency for sessions — if Redis is down, session auth fails first anyway.

## Alternatives

### `rate-limiter-flexible`

A more powerful package supporting multiple algorithms natively (sliding window, token bucket, leaky bucket) with built-in automatic failover to in-memory when Redis is unavailable.

**Rejected**: The automatic in-memory failover is a liability in a multi-instance deployment — each instance maintains an independent counter, meaning a scraper can hit up to `max * instance_count` requests before being limited, and this bypass is silent (no alerts, no logs). Requires explicit operator action to disable failover, which runs counter to the goal of safe defaults. `express-rate-limit` is also better integrated with the Express ecosystem (typed middleware, standard header support).

### Custom middleware with raw Redis `INCR`/`EXPIRE`

Implement rate limiting directly using `ioredis`/`redis` client calls — `INCR key`, `EXPIRE key windowSeconds` — wrapped in Express middleware, without any rate limiting package.

**Rejected**: `express-rate-limit` already handles the non-trivial details correctly: race-free counter initialization (the first `INCR` sets expiry atomically via the Redis store), proper `Retry-After` calculation, `RateLimit-*` header emission per IETF draft-7, and test utilities (mock store for unit tests). Reimplementing this is maintenance burden with high probability of subtle bugs (e.g., race between `INCR` and `EXPIRE` on first request, off-by-one on remaining count).

## Impact

- **Files / Modules**:
  - `src/middleware/rateLimiter.ts` — new, exports three limiter middleware instances
  - `src/config/rateLimits.ts` — new, reads and validates env vars
  - `src/app.ts` — modify, set `trust proxy 1`, apply limiters to router groups, mount health routes before limiters
- **C4**: None — rate limiting is already noted as an API Server responsibility in the container diagram. No new containers or relationships.
- **ADRs**: None — this is a library selection with no architectural implications warranting a permanent decision record.
- **Breaking changes**: No — adds `429` responses and `RateLimit-*` headers. Existing clients that respect HTTP status codes handle `429` gracefully. Clients ignoring rate limit headers continue to work until they exceed thresholds.

## Open Questions

- [x] What is the load balancer hop count in production? → **Single reverse proxy; `app.set('trust proxy', 1)`**
- [x] Are the proposed default thresholds acceptable? → **Approved: 60/min public, 300/min auth, 60/min admin**
- [x] Should health check endpoints be excluded from rate limiting? → **Yes; mount `/health` and `/ready` before rate-limited routers**

---

## Change Log

- 2026-04-19: Initial draft
- 2026-04-19: Status → In Review; resolved all open questions (trust proxy, thresholds, health check exclusion)
