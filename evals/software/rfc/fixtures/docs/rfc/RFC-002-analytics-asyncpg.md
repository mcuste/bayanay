# RFC-002: Raw asyncpg for Analytics Pipeline Queries

**ID**: RFC-002
**Status**: In Review
**Proposed by**: Jamie Torres
**Created**: 2026-04-01
**Last Updated**: 2026-04-10
**Targets**: Implementation, ADR

## Problem / Motivation

Analytics dashboard endpoints aggregate millions of rows with complex joins and window functions. SQLAlchemy ORM adds 25-40x overhead per query: object hydration (~30ms), relationship loading, and the synchronous psycopg2 driver. P95 latency is 4 seconds against a target of <500ms. The ORM's value (object mapping, relationship management) is wasted on read-only aggregate queries returning flat result sets.

**ADR-003 conflict**: ADR-003 mandates SQLAlchemy for all database access. This RFC proposes a scoped exception for analytics queries, not a blanket override.

## Goals and Non-Goals

### Goals

- Analytics dashboard P95 latency under 500ms
- Use asyncpg for ~8-10 analytics pipeline queries
- Amend ADR-003 with scoped exception for read-only analytics aggregations
- Parameterized queries only — maintain SQL injection protection

### Non-Goals

- Replacing SQLAlchemy for CRUD operations
- Rewriting all read queries in raw SQL
- Adding a separate analytics database or read replica
- Async conversion of the entire application

## Proposed Solution

Analytics query layer using asyncpg directly, scoped to `src/analytics/` only. Raw SQL files with `$1, $2` parameterized placeholders. asyncpg connection pool initialized at startup, independent from SQLAlchemy's pool. Results returned as plain dicts. Linter rule restricts asyncpg imports to `src/analytics/`.

## Alternatives

### SQLAlchemy Core with async driver

Switch analytics queries to SQLAlchemy Core (SQL expression language, no ORM hydration). Use `sqlalchemy[asyncio]` with asyncpg driver.

**Rejected**: Benchmarks show Core is still 2-5x slower than raw asyncpg for complex aggregations. Heaviest query: 1.2s via Core vs 180ms via asyncpg. Doesn't hit <500ms P95 for worst-case queries.

### Full migration to asyncpg

Replace SQLAlchemy entirely across all services.

**Rejected**: Disproportionate effort (~50+ models). Lose Alembic migrations, relationship loading, session management. 2-3 month migration with high regression risk for a problem scoped to ~10 queries.

## Impact

- **Files / Modules**: `src/analytics/queries/` (new), `src/analytics/db.py` (new), `src/analytics/views.py` (modify)
- **C4**: None — no architectural changes
- **ADRs**: Amend ADR-003 with scoped exception
- **Breaking changes**: No — analytics API response shapes unchanged

## Open Questions

- [ ] Benchmark SQLAlchemy Core first to validate rejection with hard numbers? — **must resolve**
- [ ] Connection pool sizing — share limit with SQLAlchemy or independent? — **must resolve**
- [x] Scope creep prevention? → **Linter rule restricting asyncpg imports to `src/analytics/`**

---

## Change Log

- 2026-04-01: Initial draft
- 2026-04-10: Status → In Review, added benchmark data to alternatives
