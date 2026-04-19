# PLAN-RFC-001: API Versioning Strategy

**RFC**: RFC-001
**Status**: Ready
**Created**: 2026-04-19
**Last Updated**: 2026-04-19

## File Structure Map

| File | Action | Responsibility |
|---|---|---|
| `src/middleware/versioning.ts` | Create | Export `ApiVersion` type, `VersionRouteMap` type, `createVersionRouter()` factory |
| `src/routes/v1.ts` | Create | Express Router for v1 endpoints; `GET /users` returns v1 shape |
| `src/routes/v2.ts` | Create | Express Router for v2 endpoints; `GET /users` returns v2 shape |
| `src/app.ts` | Modify | Wire `createVersionRouter` into Express app; mount versioned + unversioned routes |
| `src/middleware/versioning.test.ts` | Create | Unit tests: v1 routing, v2 routing, unversioned fallback, unsupported version rejection |
| `docs/adr/ADR-001-url-path-versioning.md` | Create | Record URL-path versioning decision with rejected alternatives |
| `openapi/v1.yaml` | Create | OpenAPI 3.1 spec scoped to `/v1` |
| `openapi/v2.yaml` | Create | OpenAPI 3.1 spec scoped to `/v2` |

---

## Phase 1 — Core

### M1: Define `ApiVersion` and `VersionRouteMap` types; export `createVersionRouter` stub in `src/middleware/versioning.ts`

Create `src/middleware/versioning.ts`. Define and export:

```ts
import express from 'express';

export type ApiVersion = `v${number}`;
export type VersionRouteMap = Map<ApiVersion, express.Router>;

export function createVersionRouter(routes: VersionRouteMap): express.Router {
  return express.Router();
}
```

Function body returns an empty Router — actual routing logic is added in M4. This milestone establishes the exported API shape so downstream files can import without compilation errors.

**Acceptance Criteria**

- Importing `{ createVersionRouter, ApiVersion, VersionRouteMap }` from `./middleware/versioning` in a TypeScript file compiles without errors.
- `createVersionRouter(new Map())` returns an Express Router instance (has `.use`, `.get`, `.handle` properties).

---

### M2: Create `src/routes/v1.ts` — `v1Router` with `GET /users` stub

Create `src/routes/v1.ts`:

```ts
import express from 'express';

export const v1Router = express.Router();

v1Router.get('/users', (_req, res) => {
  res.json({ version: 'v1', users: [] });
});
```

No authentication, no DB access, no pagination — placeholder response only.

**Acceptance Criteria**

- `GET /users` on `v1Router` responds with HTTP 200 and JSON body `{ "version": "v1", "users": [] }`.
- Importing `v1Router` from `./routes/v1` compiles without errors.

---

### M3: Create `src/routes/v2.ts` — `v2Router` with `GET /users` stub

Create `src/routes/v2.ts`:

```ts
import express from 'express';

export const v2Router = express.Router();

v2Router.get('/users', (_req, res) => {
  res.json({ version: 'v2', users: [] });
});
```

Response differs from v1 only in the `version` field — v2 production shape changes are outside RFC-001 scope.

**Acceptance Criteria**

- `GET /users` on `v2Router` responds with HTTP 200 and JSON body `{ "version": "v2", "users": [] }`.
- Importing `v2Router` from `./routes/v2` compiles without errors.

---

### M4: Implement version prefix mounting in `createVersionRouter`

Replace the stub body in `src/middleware/versioning.ts` with the real implementation:

```ts
export function createVersionRouter(routes: VersionRouteMap): express.Router {
  const router = express.Router();
  for (const [version, subRouter] of routes) {
    router.use(`/${version}`, subRouter);
  }
  return router;
}
```

No header injection, no fallback handling, no validation — happy path only.

**Acceptance Criteria**

- A request to `/v1/users` via the returned router is handled by the v1 sub-router, not v2.
- A request to `/v2/users` via the returned router is handled by the v2 sub-router, not v1.

---

### M5: Wire `createVersionRouter` in `src/app.ts`

In `src/app.ts`, import `createVersionRouter` from `./middleware/versioning`, `v1Router` from `./routes/v1`, and `v2Router` from `./routes/v2`. Mount the version router on the Express app:

```ts
import { createVersionRouter } from './middleware/versioning';
import { v1Router } from './routes/v1';
import { v2Router } from './routes/v2';

app.use(
  createVersionRouter(
    new Map([
      ['v1', v1Router],
      ['v2', v2Router],
    ])
  )
);
```

**Acceptance Criteria**

- `GET /v1/users` returns HTTP 200 with body `{ "version": "v1", "users": [] }`.
- `GET /v2/users` returns HTTP 200 with body `{ "version": "v2", "users": [] }`.

---

## Phase 2 — Details

### M6: Add unversioned-to-v1 fallback with `Deprecation` header in `createVersionRouter`

In `src/middleware/versioning.ts`, extend `createVersionRouter` to detect requests that don't match any `/v{N}` prefix and proxy them to the v1 sub-router. Add the fallback **after** the per-version `for` loop:

```ts
const v1SubRouter = routes.get('v1');
if (v1SubRouter) {
  router.use((req, res, next) => {
    res.setHeader('Deprecation', 'true');
    res.setHeader('Link', `</v1${req.path}>; rel="deprecation"`);
    v1SubRouter(req, res, next);
  });
}
```

This middleware runs only when no earlier `/v{N}` handler matched (i.e., requests like `/users` with no version prefix).

**Acceptance Criteria**

- `GET /users` returns the same HTTP status and body as `GET /v1/users`.
- `GET /users` response includes header `Deprecation: true`.
- `GET /users` response includes header `Link: </v1/users>; rel="deprecation"`.
- `GET /v1/users` response does NOT include a `Deprecation` header.

---

### M7: Add `X-API-Version` response header per version in `createVersionRouter`

In `src/middleware/versioning.ts`, inside the `for` loop in `createVersionRouter`, wrap each sub-router with a response-header middleware that runs before the sub-router:

```ts
for (const [version, subRouter] of routes) {
  router.use(`/${version}`, (_req, res, next) => {
    res.setHeader('X-API-Version', version);
    next();
  }, subRouter);
}
```

**Acceptance Criteria**

- `GET /v1/users` response includes header `X-API-Version: v1`.
- `GET /v2/users` response includes header `X-API-Version: v2`.
- `GET /users` (unversioned fallback) does NOT include an `X-API-Version` header.

---

### M8: Reject unsupported version numbers with 404 in `createVersionRouter`

In `src/middleware/versioning.ts`, add a middleware **before** the per-version `for` loop that intercepts requests to `/v{N}/...` where `N` is not in the routes map:

```ts
const supportedVersions = Array.from(routes.keys());
router.use(/^\/v\d+/, (req, res, next) => {
  const match = req.path.match(/^\/(v\d+)/);
  const requestedVersion = match?.[1] as ApiVersion | undefined;
  if (requestedVersion && !routes.has(requestedVersion)) {
    res.status(404).json({
      error: 'API version not supported',
      supported: supportedVersions,
    });
    return;
  }
  next();
});
```

Place this block before the `for` loop so the 404 fires before any sub-router can run.

**Acceptance Criteria**

- `GET /v3/users` returns HTTP 404 with JSON body `{ "error": "API version not supported", "supported": ["v1", "v2"] }`.
- `GET /v99/anything` returns HTTP 404 with `supported` array matching the registered versions.
- `GET /v1/users` continues to return HTTP 200.
- `GET /v2/users` continues to return HTTP 200.

---

### M9: Write unit tests for `createVersionRouter` in `src/middleware/versioning.test.ts`

Create `src/middleware/versioning.test.ts` using `supertest` and `express`. Each test constructs a fresh Express app, calls `createVersionRouter` with stub routers, and asserts HTTP response properties.

Four test cases:

1. **v1 routing**: `GET /v1/users` → HTTP 200, body `{ version: 'v1' }`, header `X-API-Version: v1`
2. **v2 routing**: `GET /v2/users` → HTTP 200, body `{ version: 'v2' }`, header `X-API-Version: v2`
3. **Unversioned fallback**: `GET /users` → same status and body as `GET /v1/users`; response headers include `Deprecation: true` and `Link` containing `/v1/users`; no `X-API-Version` header
4. **Unsupported version**: `GET /v3/users` → HTTP 404, body contains `{ error: 'API version not supported' }`

**Acceptance Criteria**

- All 4 test cases pass (`npm test` exits 0).
- No test asserts on internal state (router stack, middleware count) — all assertions are on HTTP response status, headers, or body.
- Each test creates its own Express app instance (no shared mutable state between tests).

---

### M10: Create `docs/adr/ADR-001-url-path-versioning.md`

Create the file `docs/adr/ADR-001-url-path-versioning.md` with the following sections:

- **Status**: Accepted
- **Context**: REST API had no versioning; breaking changes deployed directly caused three mobile-app incidents in Q1 2026
- **Decision**: URL-path versioning (`/v{N}/resource`); each major version gets its own route namespace; shared service layer, version-specific controllers
- **Consequences**: Routes multiply per major version; URLs are stable and CDN-cacheable without custom config; easy to test by changing URL in browser or curl
- **Rejected alternatives**:
  - *Header-based* (`Accept: application/vnd.api+json; version=2`) — CDN cannot cache different versions at the same URL path without custom VCL; harder to test interactively
  - *Query parameter* (`?version=2`) — semantically incorrect (parameters are for filtering/pagination, not resource representation); CDNs and proxies may strip or mishandle unknown query params

**Acceptance Criteria**

- File exists at `docs/adr/ADR-001-url-path-versioning.md` with `Status: Accepted`.
- Document includes both rejected alternatives (header-based and query parameter) each with explicit rationale matching the RFC.

---

### M11: Create `openapi/v1.yaml` — OpenAPI 3.1 spec for v1

Create `openapi/v1.yaml`:

```yaml
openapi: 3.1.0
info:
  title: API v1
  version: "1.0.0"
  description: "Version 1 — deprecated. Migrate to /v2."
servers:
  - url: /v1
    description: Version 1 (deprecated)
paths:
  /users:
    get:
      summary: List users
      responses:
        "200":
          description: User list
          content:
            application/json:
              schema:
                type: object
                properties:
                  version:
                    type: string
                    example: v1
                  users:
                    type: array
                    items: {}
```

**Acceptance Criteria**

- File exists at `openapi/v1.yaml`.
- `servers[0].url` equals `/v1`.
- File parses as valid YAML without errors.

---

### M12: Create `openapi/v2.yaml` — OpenAPI 3.1 spec for v2

Create `openapi/v2.yaml`:

```yaml
openapi: 3.1.0
info:
  title: API v2
  version: "2.0.0"
servers:
  - url: /v2
    description: Version 2 (current)
paths:
  /users:
    get:
      summary: List users
      responses:
        "200":
          description: User list
          content:
            application/json:
              schema:
                type: object
                properties:
                  version:
                    type: string
                    example: v2
                  users:
                    type: array
                    items: {}
```

**Acceptance Criteria**

- File exists at `openapi/v2.yaml`.
- `servers[0].url` equals `/v2`.
- File parses as valid YAML without errors.
- File contains no `$ref` pointing to `v1.yaml` — specs are structurally independent.

---

## Phase 3 — Polish

### M13: Add `Sunset` header to unversioned endpoint responses

In `src/middleware/versioning.ts`, extend the unversioned fallback middleware (added in M6) to set a `Sunset` header per RFC 8594. Compute the sunset date as 6 months from the current date at request time:

```ts
router.use((req, res, next) => {
  const sunsetDate = new Date();
  sunsetDate.setMonth(sunsetDate.getMonth() + 6);
  res.setHeader('Deprecation', 'true');
  res.setHeader('Sunset', sunsetDate.toUTCString());
  res.setHeader('Link', `</v1${req.path}>; rel="deprecation"`);
  v1SubRouter(req, res, next);
});
```

**Acceptance Criteria**

- `GET /users` response includes a `Sunset` header.
- The `Sunset` header value parses as a valid date at least 6 months after the current date.
- `GET /v1/users` response does NOT include a `Sunset` header.

---

### M14: Log deprecation warning on unversioned endpoint access

In `src/middleware/versioning.ts`, inside the unversioned fallback middleware, add a `console.warn` call before delegating to `v1SubRouter`:

```ts
console.warn(`[DEPRECATION] Unversioned request to ${req.method} ${req.path} — use /v1${req.path} instead`);
```

**Acceptance Criteria**

- When `GET /users` is called, stderr output contains the string `[DEPRECATION]` and the request path `/users`.
- When `GET /v1/users` is called, no line containing `[DEPRECATION]` is written to stderr.

---

## Change Log

- 2026-04-19: Initial plan — 14 milestones across 3 phases
