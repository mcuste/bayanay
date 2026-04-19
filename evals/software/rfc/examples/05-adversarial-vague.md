# WIP RFC: System Performance Improvement

**Status**: WIP — Pending Clarification
**Created**: 2026-04-19

---

## Research Findings

Current system (from C4 and existing RFCs):

- **API Server** (Express/Node.js): main entry point for all client traffic. Handles auth middleware, rate limiting, versioning.
- **Background Worker** (Node.js/Bull): report generation, CSV exports, webhook retries. RFC-003 (Draft) notes jobs fail silently — monitoring gap but no latency data.
- **Primary DB** (PostgreSQL 15): shared by API and all three Django services.
- **Cache** (Redis 7): sessions, response cache, rate limiting, Bull queue.
- **Django services** (billing, notifications, user management): extracted from monolith, each with its own schema.

**RFC-002 (In Review)** already targets analytics dashboard P95 latency (currently 4s, target <500ms) via asyncpg. Any performance RFC must not overlap or conflict with this.

**No existing ADRs** restrict performance optimization approaches (ADR-003 scoped exception already in motion via RFC-002).

---

## What Is Known

- The request is to "make the system faster"
- No component, endpoint, or metric is specified
- No SLO or baseline measurement is provided
- Could target multiple unrelated areas → may need to split into separate RFCs

---

## Pending Input

**Cannot draft this RFC without answers to the following:**

1. **What is slow?** Which component or user-facing operation is the problem?
   - API response latency (which endpoints)?
   - Background job processing time or throughput?
   - A specific Django service (billing, notifications, user management)?
   - Frontend load time / asset delivery?
   - Database queries outside the analytics pipeline (already covered by RFC-002)?

2. **What metric is being violated?** Is there a measured baseline and a target SLO?
   - Example: "P95 API latency is 1.8s, target <300ms"
   - Example: "Report generation jobs take 45s, target <10s"
   - Without a metric, success is unmeasurable.

3. **Is this distinct from RFC-002?** RFC-002 (In Review) addresses analytics query latency. Does this RFC cover a different area, or should it supersede/extend RFC-002?

4. **What is the appetite?** Quick wins (caching, query tuning) or architectural changes (read replicas, service extraction)?

5. **Is there a specific incident or customer complaint driving this?** Context helps scope the problem.

---

Reply with answers and run `/rfc continue` to proceed to approach proposals.
