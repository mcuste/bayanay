# ADR-002: Use RabbitMQ for Inter-Service Messaging

- **Status**: Accepted
- **Date**: 2026-02-20
- **Deciders**: Backend team, DevOps
- **Affects**: Billing service, Notifications service, User Management service

## Context

The Django monolith's three bounded contexts (billing, notifications, user management) communicate via synchronous function calls. A slow email provider blocks the billing response path. Services can't be deployed or scaled independently. We need asynchronous, reliable messaging between these contexts.

## Decision Drivers

- At-least-once delivery semantics required for billing events
- Dead letter queue support for failed message handling
- Team has Celery experience (RabbitMQ-backed)
- Must support topic-based routing (events go to multiple consumers)

## Decision

Use RabbitMQ as the message broker for inter-service communication. Domain events published to topic exchanges; consumers bind queues with routing keys. Dead letter queues with 3-retry exponential backoff policy. Celery as the client library for publisher/consumer implementation.

## Consequences

### Positive
- True decoupling — services communicate only via events
- Independent deployment and scaling per service
- Reliable delivery with dead letter handling and retry

### Negative
- Eventual consistency — billing may process plan changes with seconds of delay
- New infrastructure to operate (RabbitMQ cluster)
- Message ordering not guaranteed across consumers

### Neutral
- Event schemas stored as JSON Schema files in shared repo
- Idempotent consumers required — every handler must safely process duplicate events

## Alternatives Considered

- **Redis Streams** — rejected: less mature, no built-in dead letter queues, weaker routing (no topic exchanges)
- **Kafka** — rejected: overkill for our event volume (~1k events/hour), operational complexity too high for team size
- **Synchronous HTTP** — rejected: creates distributed monolith, cascading failures, doesn't solve coupling
