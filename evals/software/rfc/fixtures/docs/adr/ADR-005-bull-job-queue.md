# ADR-005: Use Bull for Background Job Processing

- **Status**: Accepted
- **Date**: 2025-10-05
- **Deciders**: Backend team
- **Affects**: Background Worker container, Redis

## Context

Need reliable background job processing for report generation, CSV exports, webhook delivery, and scheduled tasks. Jobs must survive worker restarts, support retries with backoff, and provide visibility into queue state.

## Decision

Use Bull (Node.js) backed by Redis for all background job processing. Job queues per task type (reports, exports, webhooks). Retry policy: 3 attempts with exponential backoff. Jobs persisted in Redis until completion or max retries exhausted.

## Consequences

### Positive
- Redis already in stack — no new infrastructure
- Bull is mature, well-maintained, good TypeScript support
- Built-in retry, backoff, rate limiting, and job prioritization

### Negative
- Redis is not a durable store — job data lost if Redis restarts without persistence (mitigated by Redis AOF)
- Bull's Redis usage can be memory-intensive with large job payloads
- Monitoring requires additional tooling (Bull Board or custom)

## Alternatives Considered

- **Celery (Python)** — rejected: would require Python runtime alongside Node.js worker, adds language complexity
- **AWS SQS** — rejected: vendor lock-in, no built-in job scheduling, retry logic more complex
- **pg-boss (PostgreSQL)** — rejected: adds load to primary database, less mature than Bull
