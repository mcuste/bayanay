# ADR-003: Use SQLAlchemy for All Database Access

- **Status**: Accepted
- **Date**: 2025-11-15
- **Deciders**: Backend team
- **Affects**: All services with database access

## Context

We need a consistent approach to database access across all Python services. The team has mixed experience — some prefer raw SQL, others want an ORM. Without a standard, each service uses a different approach, making code reviews harder and increasing SQL injection risk.

## Decision

Use SQLAlchemy ORM for all database access. Raw SQL is only permitted inside SQLAlchemy `text()` calls with bound parameters.

## Consequences

### Positive
- Consistent database access patterns across all services
- Built-in protection against SQL injection via parameterized queries
- Easier to write and review — Python objects instead of SQL strings

### Negative
- ORM overhead for read-heavy analytics queries
- Learning curve for developers unfamiliar with SQLAlchemy
- Complex queries sometimes harder to express than raw SQL
