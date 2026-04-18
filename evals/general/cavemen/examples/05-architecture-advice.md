Use msg queue. Direct calls from API handlers = fragile, slow, coupled.

**Why queue wins:**

- API handler sends notification req to queue → returns fast to client. No waiting on email/SMS/push providers
- Provider down → msgs stay in queue, retry later. Direct call → user gets 500 or lost notification
- Spike in traffic → queue buffers. Direct call → overwhelms downstream services → cascading failure
- Add new channel (Slack, webhook) → add new consumer. No touching API handler code

**Architecture:**

```
API Handler → Message Queue → Consumer(s) → Email / SMS / Push
```

Each consumer handles one channel. Failed delivery → back to queue w/ retry + exponential backoff.

**Queue choice:**

- **RabbitMQ** — simple setup, routing flexible, good for most cases
- **SQS** — managed, no ops overhead, pairs w/ Lambda for consumers
- **Kafka** — overkill unless need event replay, ordering guarantees, or massive throughput

**When direct calls OK:**

- Single notification type, low volume, provider highly reliable
- Prototype / MVP where speed-to-ship matters more than resilience

Start w/ queue + separate consumer per channel. Keep API handlers thin — accept req, validate, enqueue, respond. Consumer handles retry logic, rate limiting, provider failover.
