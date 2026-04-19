# C4 Level 1: System Context

```mermaid
C4Context
    title System Context — SaaS Platform

    Person(customer, "Customer", "End user of the platform. Manages projects, views dashboards, configures settings.")
    Person(admin, "Admin", "Internal staff. Manages tenants, monitors system health, handles support escalations.")
    Person(partner, "Partner", "External integrator. Consumes public API for data sync and automation.")

    System(platform, "SaaS Platform", "Core product. Project management, analytics dashboards, team collaboration, billing.")

    System_Ext(stripe, "Stripe", "Payment processing. Subscriptions, invoices, refunds.")
    System_Ext(sendgrid, "SendGrid", "Transactional email delivery. Receipts, notifications, password resets.")
    System_Ext(auth0, "Auth0", "Identity provider. SSO, MFA, social login.")
    System_Ext(s3, "AWS S3", "File storage. User uploads, generated reports, backups.")
    System_Ext(datadog, "Datadog", "Observability. Metrics, logs, traces, alerting.")

    Rel(customer, platform, "Uses", "HTTPS")
    Rel(admin, platform, "Manages", "HTTPS")
    Rel(partner, platform, "Integrates via", "REST API")
    Rel(platform, stripe, "Processes payments", "HTTPS/Webhooks")
    Rel(platform, sendgrid, "Sends emails", "HTTPS")
    Rel(platform, auth0, "Authenticates users", "OIDC/HTTPS")
    Rel(platform, s3, "Stores files", "HTTPS/SDK")
    Rel(platform, datadog, "Sends telemetry", "HTTPS/Agent")
```

## Notes

- **Customers** interact via web browser (React SPA) and mobile apps
- **Partners** use the public REST API (v1, versioned per ADR-001)
- **Auth0** handles all authentication — platform never stores passwords
- **Stripe** is the single payment provider — no direct credit card handling
