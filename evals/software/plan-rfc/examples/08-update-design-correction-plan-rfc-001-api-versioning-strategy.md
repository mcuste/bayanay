# PLAN-RFC-001: API Versioning Strategy

**RFC**: RFC-001
**Status**: Ready
**Created**: 2026-04-19
**Last Updated**: 2026-04-19

> **Note**: RFC-001 header field says `Status: Accepted`, but the 2026-04-19 change log entry records `status → In Review` after the design correction. The plan proceeds on the header value. RFC author should reconcile the status field before implementation begins.

## File Structure Map

| File | Action | Responsibility |
|---|---|---|
| `src/routes/v1.ts` | Create | Express Router for v1 endpoints; `GET /users` returns v1 response shape at path `/users` (no version prefix) |
| `src/routes/v2.ts` | Create | Express Router for v2 endpoints; `GET /users` returns v2 response shape at path `/users` (no version prefix) |
| `src/app.ts` | Modify | Remove `createVersionRouter` wiring; mount `v1Router` at `/` directly — v1 app entry point |
| `kong/config.yml` | Create | Kong declarative config: services for `api-v1` and `api-v2` upstreams, Route by Header routes matching `X-API-Version` values, global Response Transformer for `Vary` header, default fallback route with deprecation headers, pre-function plugin for invalid version rejection |
| `test/api-versioning.test.ts` | Create | Integration tests asserting header routing behaviour: version dispatch, deprecation fallback, invalid version rejection |
| `docs/adr/ADR-001-url-path-versioning.md` | Create | Record original URL-path decision; status `Superseded by ADR-002` |
| `docs/adr/ADR-002-header-based-api-versioning.md` | Create | Record header-based decision; explains why original rejection reasons no longer apply; status `Accepted` |
| `openapi/v1.yaml` | Create | OpenAPI 3.1 spec; `servers[0].url` is `/`; includes `X-API-Version: "1"` as required request header |
| `openapi/v2.yaml` | Create | OpenAPI 3.1 spec; `servers[0].url` is `/`; includes `X-API-Version: "2"` as required request header |

---

## Phase 1 — Core

### M1: Create `src/routes/v1.ts` — `v1Router` with `GET /users` stub

Create `src/routes/v1.ts`:

```ts
import express from 'express';

export const v1Router = express.Router();

v1Router.get('/users', (_req, res) => {
  res.json({ version: 'v1', users: [] });
});
```

Route is mounted at `/users`, not `/v1/users`. No authentication, no DB access, no pagination — placeholder response only.

**Acceptance Criteria**

- `GET /users` on `v1Router` responds with HTTP 200 and JSON body `{ "version": "v1", "users": [] }`.
- Importing `v1Router` from `./routes/v1` compiles without TypeScript errors.

---

### M2: Create `src/routes/v2.ts` — `v2Router` with `GET /users` stub

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
- Importing `v2Router` from `./routes/v2` compiles without TypeScript errors.

---

### M3: Update `src/app.ts` to mount `v1Router` directly at `/`

In `src/app.ts`:

1. Remove the `import { createVersionRouter } from './middleware/versioning'` line.
2. Remove the `createVersionRouter(new Map([...]))` call.
3. Add `import { v1Router } from './routes/v1'`.
4. Add `app.use('/', v1Router)`.

No `/v1` prefix. The v1 app instance answers `GET /users` directly. Kong is responsible for routing versioned traffic to this process — the app itself does not inspect `X-API-Version`.

**Acceptance Criteria**

- `GET /users` on the Express app returns HTTP 200 with body `{ "version": "v1", "users": [] }`.
- `src/app.ts` contains no import or reference to `createVersionRouter` or `./middleware/versioning`.
- `tsc --noEmit` exits 0.

---

### M4: Create `kong/config.yml` — `api-v1` service and `X-API-Version: 1` route

Create `kong/config.yml` as a Kong deck declarative config file:

```yaml
_format_version: "3.0"

services:
  - name: api-v1
    url: http://api-v1:3000
    routes:
      - name: api-v1-header-route
        headers:
          X-API-Version:
            - "1"
```

Service `api-v1` points to the v1 Express upstream. Route `api-v1-header-route` matches only requests where `X-API-Version` equals `"1"`. No catch-all, no default route, no plugins yet.

**Acceptance Criteria**

- `kong/config.yml` parses as valid YAML without errors.
- The file contains a service named `api-v1` with a URL field.
- Route `api-v1-header-route` has `headers.X-API-Version` set to `["1"]`.

---

### M5: Add `api-v2` service and `X-API-Version: 2` route to `kong/config.yml`

In `kong/config.yml`, add a second service and route under the `services` list:

```yaml
  - name: api-v2
    url: http://api-v2:3000
    routes:
      - name: api-v2-header-route
        headers:
          X-API-Version:
            - "2"
```

**Acceptance Criteria**

- `kong/config.yml` contains a service named `api-v2` with a distinct `url` from `api-v1`.
- Route `api-v2-header-route` has `headers.X-API-Version` set to `["2"]`.
- `deck validate kong/config.yml` exits 0 with no errors.

---

### M6: Add `Vary: X-API-Version` global response header via Kong `response-transformer` plugin

In `kong/config.yml`, add a top-level `plugins` section with a global `response-transformer` plugin:

```yaml
plugins:
  - name: response-transformer
    config:
      add:
        headers:
          - "Vary: X-API-Version"
```

Applying globally ensures every response — regardless of which version route matched — includes the `Vary` header, enabling correct CDN caching.

**Acceptance Criteria**

- `kong/config.yml` contains a top-level `plugins` list with a `response-transformer` entry.
- The plugin's `config.add.headers` includes `"Vary: X-API-Version"`.
- `deck validate kong/config.yml` exits 0.

---

## Phase 2 — Details

### M7: Add default route (no `X-API-Version` header) to `api-v1` service in `kong/config.yml`

In `kong/config.yml`, add a second route to the `api-v1` service:

```yaml
      - name: api-v1-default-route
        paths:
          - /
        strip_path: false
```

This route has no `headers` matcher, so it catches all requests that did not match `api-v1-header-route` or `api-v2-header-route`. Kong evaluates more-specific routes (with header matchers) first, so this acts as a fallback to v1.

**Acceptance Criteria**

- `kong/config.yml` contains route `api-v1-default-route` on service `api-v1` with no `headers` field.
- A request carrying no `X-API-Version` header is routed to the `api-v1` upstream (not `api-v2`).
- A request with `X-API-Version: 2` still routes to `api-v2` (default route does not intercept it).

---

### M8: Add deprecation response headers to `api-v1-default-route` via scoped plugin

In `kong/config.yml`, add a route-scoped `response-transformer` plugin on `api-v1-default-route`:

```yaml
      - name: api-v1-default-route
        paths:
          - /
        strip_path: false
        plugins:
          - name: response-transformer
            config:
              add:
                headers:
                  - "Deprecation: true"
                  - "Sunset: Sun, 19 Oct 2026 00:00:00 GMT"
                  - "Link: </v1{path}>; rel=\"deprecation\""
```

The `Sunset` value is a static RFC 7231 HTTP-date 6 months from the RFC correction date (2026-04-19). The `Link` header uses Kong's templating to inject the request path.

**Acceptance Criteria**

- A request with no `X-API-Version` header receives `Deprecation: true` in the response.
- A request with no `X-API-Version` header receives a `Sunset` header with a date value.
- A request with `X-API-Version: 1` to route `api-v1-header-route` does NOT receive a `Deprecation` header.

---

### M9: Add `pre-function` plugin to reject invalid `X-API-Version` values with HTTP 400

In `kong/config.yml`, add a global `pre-function` plugin that rejects requests where `X-API-Version` is present but not in `{"1", "2"}`:

```yaml
  - name: pre-function
    config:
      access:
        - |
          local version = kong.request.get_header("X-API-Version")
          if version ~= nil and version ~= "1" and version ~= "2" then
            return kong.response.exit(400, {
              error = "Unsupported API version",
              supported = {"1", "2"}
            })
          end
```

Place this plugin before the `response-transformer` plugin in the `plugins` list (top-level). Runs on every request before routing.

**Acceptance Criteria**

- A request with `X-API-Version: 99` receives HTTP 400 with JSON body `{ "error": "Unsupported API version", "supported": ["1", "2"] }`.
- A request with `X-API-Version: 1` proceeds normally (no 400).
- A request with `X-API-Version: 2` proceeds normally (no 400).
- A request with no `X-API-Version` header proceeds normally (no 400; reaches default route).

---

### M10: Write integration tests in `test/api-versioning.test.ts`

Create `test/api-versioning.test.ts` using `supertest` against a Kong-proxied test environment. Each test sends a real HTTP request through Kong and asserts on the response.

Four test cases:

1. **v1 header routing**: `GET /users` with `X-API-Version: 1` → HTTP 200, body `{ "version": "v1" }`, response header `Vary: X-API-Version` present, no `Deprecation` header.
2. **v2 header routing**: `GET /users` with `X-API-Version: 2` → HTTP 200, body `{ "version": "v2" }`, response header `Vary: X-API-Version` present.
3. **Default fallback**: `GET /users` with no `X-API-Version` header → HTTP 200, body `{ "version": "v1" }`, response headers include `Deprecation: true` and `Sunset`.
4. **Invalid version**: `GET /users` with `X-API-Version: 99` → HTTP 400, body contains `{ "error": "Unsupported API version" }`.

**Acceptance Criteria**

- All 4 test cases pass (`npm test` exits 0).
- No test asserts on Kong internal state — all assertions are on HTTP response status, headers, or body.
- Each test case is independent; no shared mutable request state between cases.

---

### M11: Create `docs/adr/ADR-001-url-path-versioning.md` as Superseded

Create `docs/adr/ADR-001-url-path-versioning.md`:

- **Status**: Superseded by ADR-002
- **Context**: REST API had no versioning; breaking changes deployed directly caused three mobile-app incidents in Q1 2026.
- **Decision**: URL-path versioning (`/v{N}/resource`); version-specific route namespaces; shared service layer; Express middleware routes `/v{N}/...` to correct controller set.
- **Consequences**: Routes multiply per major version; stable URLs; CDN-cacheable without custom config; easy to test by changing URL in browser/curl.
- **Rejected alternatives**:
  - *Header-based* (`X-API-Version` header) — CDN cannot differentiate versions at the same URL without Vary support; Kong header routing plugins add operational complexity (original assessment).
  - *Query parameter* (`?version=2`) — semantically incorrect; CDNs and proxies may strip unknown query params.
- **Superseded**: Kong header routing plugins and Cloudflare `Vary: X-API-Version` support became available, removing the two rejection reasons. See ADR-002.

**Acceptance Criteria**

- File exists at `docs/adr/ADR-001-url-path-versioning.md` with `Status: Superseded by ADR-002`.
- Document includes both original rejected alternatives (header-based and query parameter) each with explicit rationale matching RFC-001.
- Document references ADR-002 in the supersession note.

---

### M12: Create `docs/adr/ADR-002-header-based-api-versioning.md`

Create `docs/adr/ADR-002-header-based-api-versioning.md`:

- **Status**: Accepted
- **Supersedes**: ADR-001
- **Context**: ADR-001 rejected header-based versioning due to CDN caching and Kong routing complexity. Both objections were resolved: Cloudflare supports `Vary: X-API-Version` for cache differentiation; Kong's Route by Header and Request Transformer plugins handle routing without custom middleware.
- **Decision**: Header-based versioning using `X-API-Version` request header. Kong routes to version-specific upstreams. Absent header defaults to v1 with `Deprecation: true` + `Sunset` response headers. `Vary: X-API-Version` response header on all responses.
- **Consequences**: URLs are clean (no `/v{N}` prefix); clients send one extra header; CDN caches version-differentiated responses correctly; Kong config becomes the single source of versioning routing truth; Express apps are version-unaware.
- **Rejected alternatives** (from ADR-001): URL-path versioning — pollutes URLs; forces clients to update base URL on each migration; was superseded when original objections to header-based were resolved. Query parameter versioning — semantically incorrect; caching unreliable; still rejected.

**Acceptance Criteria**

- File exists at `docs/adr/ADR-002-header-based-api-versioning.md` with `Status: Accepted`.
- Document cites Cloudflare `Vary` support and Kong Route by Header plugin as the resolution of the original ADR-001 rejection reasons.
- Document references ADR-001 in the Supersedes field.

---

## Phase 3 — Polish

### M13: Create `openapi/v1.yaml` — OpenAPI 3.1 spec for v1 with `X-API-Version` header

Create `openapi/v1.yaml`:

```yaml
openapi: 3.1.0
info:
  title: API v1
  version: "1.0.0"
  description: "Version 1 — deprecated. Migrate to v2 by sending X-API-Version: 2."
servers:
  - url: /
    description: Version 1 (deprecated; omit X-API-Version or send X-API-Version: 1)
paths:
  /users:
    get:
      summary: List users
      parameters:
        - in: header
          name: X-API-Version
          required: false
          schema:
            type: string
            enum: ["1"]
          description: "API version. Omitting defaults to v1 with deprecation warning."
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
- `servers[0].url` equals `/` (not `/v1`).
- `paths./users.get.parameters` contains an entry for `X-API-Version` header with enum `["1"]`.
- File parses as valid YAML without errors.

---

### M14: Create `openapi/v2.yaml` — OpenAPI 3.1 spec for v2 with `X-API-Version` header

Create `openapi/v2.yaml`:

```yaml
openapi: 3.1.0
info:
  title: API v2
  version: "2.0.0"
servers:
  - url: /
    description: Version 2 (current; send X-API-Version: 2)
paths:
  /users:
    get:
      summary: List users
      parameters:
        - in: header
          name: X-API-Version
          required: true
          schema:
            type: string
            enum: ["2"]
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
- `servers[0].url` equals `/` (not `/v2`).
- `paths./users.get.parameters` contains an entry for `X-API-Version` header with enum `["2"]` and `required: true`.
- File contains no `$ref` pointing to `v1.yaml` — specs are structurally independent.

---

## Change Log

- 2026-04-19: Initial plan — 14 milestones across 3 phases, based on URL-path versioning (RFC-001 original)
- 2026-04-19: Design correction update — switched to header-based versioning per RFC-001 2026-04-19 correction; removed `src/middleware/versioning.ts` from file map; replaced M1/M4/M5/M6 (Express version router) with `kong/config.yml` milestones M4–M9; updated `src/app.ts` mounting (M3) to remove version prefix; updated OpenAPI server URLs from `/v1`/`/v2` to `/` with `X-API-Version` header parameter (M13–M14); split ADR milestone into ADR-001 (Superseded) + ADR-002 (Accepted) (M11–M12)
