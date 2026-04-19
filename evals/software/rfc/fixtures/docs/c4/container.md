# C4 Level 2: Container Diagram

```mermaid
C4Container
    title Container Diagram — SaaS Platform

    Person(customer, "Customer")
    Person(admin, "Admin")
    Person(partner, "Partner")

    System_Boundary(platform, "SaaS Platform") {
        Container(spa, "Web App", "React / TypeScript", "Single-page application. Project management UI, dashboards, settings.")
        Container(api, "API Server", "Express.js / Node.js", "REST API. Business logic, auth middleware, request validation. Versioned endpoints (v1).")
        Container(worker, "Background Worker", "Node.js / Bull", "Async job processing. Report generation, data exports, webhook delivery.")
        Container(db, "Primary Database", "PostgreSQL 15", "Users, projects, billing, configurations. Row-level security for future multi-tenancy.")
        Container(cache, "Cache / Sessions", "Redis 7", "Session storage, API response caching, rate limiting counters, job queues (Bull).")
        Container(broker, "Message Broker", "RabbitMQ", "Inter-service domain events. Billing, notification, and user management event routing.")
        Container(billing_svc, "Billing Service", "Django / Python", "Subscription management, invoice generation, Stripe integration.")
        Container(notif_svc, "Notification Service", "Django / Python", "Email dispatch via SendGrid, in-app notifications, notification preferences.")
        Container(user_svc, "User Management Service", "Django / Python", "User profiles, team management, plan assignments, Auth0 integration.")
    }

    System_Ext(stripe, "Stripe")
    System_Ext(sendgrid, "SendGrid")
    System_Ext(auth0, "Auth0")
    System_Ext(s3, "AWS S3")

    Rel(customer, spa, "Uses", "HTTPS")
    Rel(admin, spa, "Uses", "HTTPS")
    Rel(partner, api, "Calls", "REST API / HTTPS")
    Rel(spa, api, "Calls", "JSON / HTTPS")
    Rel(api, db, "Reads/Writes", "SQL / TCP")
    Rel(api, cache, "Reads/Writes", "Redis protocol")
    Rel(api, broker, "Publishes events", "AMQP")
    Rel(worker, db, "Reads/Writes", "SQL / TCP")
    Rel(worker, cache, "Reads job queue", "Redis protocol")
    Rel(worker, s3, "Stores files", "HTTPS/SDK")
    Rel(billing_svc, broker, "Publishes/Consumes", "AMQP")
    Rel(billing_svc, db, "Reads/Writes", "SQL / TCP")
    Rel(billing_svc, stripe, "Processes payments", "HTTPS")
    Rel(notif_svc, broker, "Consumes", "AMQP")
    Rel(notif_svc, sendgrid, "Sends emails", "HTTPS")
    Rel(user_svc, broker, "Publishes/Consumes", "AMQP")
    Rel(user_svc, db, "Reads/Writes", "SQL / TCP")
    Rel(user_svc, auth0, "Manages identity", "HTTPS")
```

## Notes

- **API Server** is the main entry point for all client requests — handles versioning (ADR-001), rate limiting, auth middleware
- **RabbitMQ** added per ADR-002 for billing/notification/user management decoupling
- **Redis** serves triple duty: session store, cache, and Bull job queue backing store
- **Django services** (billing, notifications, user management) extracted from the original monolith — each has its own schema in the shared PostgreSQL instance
- **Background Worker** handles long-running tasks: report generation, CSV exports, webhook retries
