# RFC-001: API Versioning Strategy

**ID**: RFC-001
**Status**: In Review
**Proposed by**: Sarah Chen
**Created**: 2026-03-01
**Last Updated**: 2026-04-19
**Targets**: Implementation, ADR

## Problem / Motivation

Our REST API has no versioning strategy. Breaking changes are deployed directly, causing client failures. Three incidents in the last quarter where mobile apps broke after backend deploys. We need a versioning scheme that lets us evolve the API without breaking existing consumers.

## Goals and Non-Goals

### Goals

- Establish a versioning scheme for all public API endpoints
- Allow at least two API versions to coexist in production
- Provide a deprecation timeline and migration path for consumers

### Non-Goals

- Versioning internal service-to-service communication (gRPC contracts handle this)
- Automatic client migration tooling
- GraphQL — REST only for now

## Proposed Solution

Header-based versioning using a custom `X-API-Version` request header (e.g., `X-API-Version: 2`). Clients send the version header; absent header defaults to v1 with a deprecation warning response header. Kong API Gateway handles version routing via its built-in Request Transformer and Route by Header plugins — no custom middleware required. Cloudflare caches version-differentiated responses correctly using the `Vary: X-API-Version` response header, which resolves the original CDN objection.

Controllers remain version-specific while sharing the service layer for validation and business logic — only request/response shapes are version-specific. The same sunset policy applies: deprecated versions get 6 months notice, minimum 3 months overlap.

**Design correction (2026-04-19)**: Original proposal used URL-path versioning. After prototyping, Kong's header routing plugins and Cloudflare's Vary header support make header-based versioning straightforward. The two rejection reasons from the original proposal no longer apply.

## Alternatives

### URL-path versioning (/v1/users, /v2/users)

Route namespaced by version prefix. Each version gets its own controller set; service layer is shared. **Rejected**: pollutes URLs with version prefix on every endpoint; forces all clients to update their base URL on each version migration. Was the original chosen approach — superseded when Kong header routing and Cloudflare Vary support became available, removing the advantage URL-path had on operability.

### Query parameter versioning (?version=2)

Append `?version=2` to requests. Simple to implement, easy to test. **Rejected**: query parameters are semantically for filtering/pagination, not resource representation. Breaks caching assumptions — CDNs and proxies may strip or ignore unknown query params. Also looks unprofessional in API documentation.

## Impact

- **Files / Modules**: `src/middleware/versioning.ts` (remove Express version-routing middleware — replaced by Kong plugin config), `src/controllers/` (unchanged), `src/routes/` (remove `/v{N}` path prefixes)
- **C4**: Container diagram — API Gateway (Kong) description needs updating to reflect header-based routing instead of path-based routing
- **ADRs**: ADR-001 (URL-Path API Versioning) must be superseded by a new ADR recording the header-based decision and the reasons the original objections were resolved
- **Breaking changes**: Yes — URL paths change. `/v1/users` → `/users` with `X-API-Version: 1`. Requires coordinated client migration with deprecation period for old URL-path style.

## Open Questions

- [x] Should unversioned endpoints (`/users`) be treated as v1 or rejected? → **Treated as v1 with deprecation warning header**
- [ ] What's the maximum number of concurrent versions we'll support? Lean toward 2 but ops wants 3.
- [ ] Should we version the OpenAPI spec per version, or maintain one spec with version annotations?
- [ ] Migration timeline for existing clients using URL-path style (`/v1/...`) — need to define deprecation window before switching.

---

## Change Log

- 2026-03-01: Initial draft
- 2026-03-10: Status → In Review, added sunset policy details
- 2026-03-15: Status → Accepted, resolved unversioned endpoint question
- 2026-04-19: Design correction — switched Proposed Solution from URL-path to header-based versioning; Kong header routing plugins and Cloudflare Vary support resolve original rejection reasons; status → In Review; ADR-001 supersession required
