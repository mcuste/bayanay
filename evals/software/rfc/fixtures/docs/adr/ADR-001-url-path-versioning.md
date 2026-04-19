# ADR-001: URL-Path API Versioning

- **Status**: Accepted
- **Date**: 2026-03-15
- **Deciders**: Backend team, API consumers
- **Affects**: API Gateway, all REST endpoints
- **Implements**: RFC-001

## Context

Our REST API had no versioning strategy. Breaking changes deployed directly caused three client-breaking incidents in Q4 2025. Mobile apps and partner integrations broke after backend deploys with no migration path.

## Decision Drivers

- Must support at least two concurrent API versions
- Must be testable without special tooling (browser, curl)
- Must work with existing CDN caching (Cloudflare)
- Team familiarity — most developers have used URL-path versioning before

## Decision

Use URL-path versioning: `/v1/users`, `/v2/users`. Each major version gets its own route namespace with version-specific controllers sharing the service layer. Deprecated versions get 6 months notice, minimum 3 months overlap. Maximum 2 concurrent versions.

## Consequences

### Positive
- Clear, visible versioning — easy to test and document
- CDN caches different versions at different paths naturally
- API gateway routing is straightforward path matching

### Negative
- URL pollution — version prefix on every endpoint
- Route duplication across version namespaces
- Clients must update base URLs on version migration

### Neutral
- Unversioned endpoints (`/users`) treated as v1 with deprecation warning header

## Alternatives Considered

- **Header-based versioning** — rejected: harder to test, CDN caching requires custom Vary rules, API gateway routing more complex
- **Query parameter versioning** — rejected: semantically wrong (params are for filtering), breaks caching assumptions
