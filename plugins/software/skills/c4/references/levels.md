# C4 Level Guidelines

Include/exclude guidance per level. Referenced from SKILL.md.

## Level 1 — System Context

Stakeholder whiteboard — what system does, who uses it, what it connects to.

**Include:**
- System as single center box
- All human actors by role/persona (not individuals)
- All external systems (APIs, SSO, email, payment, data feeds)
- One-line relationship labels ("sends notifications via", "authenticates with")

**Exclude:**
- Technology labels — level is tech-agnostic
- Internal structure — no DBs, services, modules
- Deployment details — no servers, regions, infra
- Protocol labels (belong at Level 2)

**Mermaid type:** `C4Context`

---

## Level 2 — Container

Major technical building blocks and communication. Technology visible. Audience: technical team.

**Include:**
- Each deployable unit as container: apps, services, DBs, queues, storage, caches
- Tech label on every container ("React SPA", "Rust/Axum", "PostgreSQL 16", "NATS JetStream", "S3")
- Relationships labeled with protocol ("REST/HTTPS", "SQL/TCP", "async via NATS", "gRPC")
- External systems and users from Level 1, showing which containers they reach

**Exclude:**
- Internal code structure — no classes, modules, functions
- Deployment details — no servers, load balancers, regions
- Minor utility scripts — only significant containers
- \>15 elements — split into sub-diagrams

**Mermaid type:** `C4Container`

---

## Level 3 — Component

Zooms into single container. **Only if user explicitly requests** — LLM reads code directly, usually redundant.

**Include:**
- Major components within one container (controllers, services, repositories, domain models)
- One-line responsibility per component
- Relationships and what they exchange
- External containers/systems connecting to these components

**Exclude:**
- Individual classes/functions — structural groupings only
- Multiple containers — one container per diagram
- Framework boilerplate with no architectural insight (middleware, router extractors)

**Mermaid type:** `C4Component`

---

## Level 4 — Code

Never generate. Code is source of truth.
