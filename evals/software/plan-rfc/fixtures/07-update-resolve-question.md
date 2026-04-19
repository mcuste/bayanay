# RFC-001: API Versioning Strategy

**ID**: RFC-001
**Status**: Accepted
**Proposed by**: Engineering Team
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

URL-path versioning (`/v1/users`, `/v2/users`). Each major version gets its own route namespace. Controllers are version-specific but share service layer logic. A version sunset policy: deprecated versions get 6 months notice, minimum 3 months overlap.

Version routing handled by Express middleware that maps `/v{N}/...` to the correct controller set. Shared validation and business logic stays in the service layer — only request/response shapes are version-specific.

## Alternatives

### Header-based versioning (Accept header)

Use `Accept: application/vnd.api+json; version=2` header. Keeps URLs clean, follows content negotiation standards. **Rejected**: harder to test (can't just change URL in browser/curl), API gateway routing becomes more complex, and our CDN can't cache different versions of the same URL path without custom VCL rules.

### Query parameter versioning (?version=2)

Append `?version=2` to requests. Simple to implement, easy to test. **Rejected**: query parameters are semantically for filtering/pagination, not resource representation. Breaks caching assumptions — CDNs and proxies may strip or ignore unknown query params. Also looks unprofessional in API documentation.

## Impact

- **Files / Modules**: `src/routes/`, `src/controllers/`, `src/middleware/versioning.ts`
- **C4**: Container diagram — no new containers, but API Gateway container description needs updating to reflect version routing
- **ADRs**: ADR to record the URL-path versioning decision
- **Breaking changes**: No — additive only. Existing unversioned endpoints continue working as v1.

## Open Questions

- [x] Should unversioned endpoints (`/users`) be treated as v1 or rejected? → **Treated as v1 with deprecation warning header**
- [x] What's the maximum number of concurrent versions we'll support? Lean toward 2 but ops wants 3. → **2. Ops agreed after reviewing maintenance burden data showing cost of supporting a third active version.**
- [x] Should we version the OpenAPI spec per version, or maintain one spec with version annotations? → **Separate OpenAPI specs per version. Annotation approach was too confusing during review and increases risk of spec drift.**

---

## Change Log

- 2026-03-01: Initial draft
- 2026-03-10: Status → In Review, added sunset policy details
- 2026-03-15: Status → Accepted, resolved unversioned endpoint question
- 2026-04-19: Resolved open questions — max concurrent versions (2) and OpenAPI spec strategy (separate specs per version)
