# PRD-001: Multi-Tenant Analytics Platform

- **ID**: PRD-001
- **Status**: Draft
- **Author**: —
- **Created**: 2026-04-19
- **Last Updated**: 2026-04-19

## Problem

Enterprise HR customers (200+) cannot build custom reports or dashboards on their employee data within our platform. They export CSVs and use Excel or Looker — a manual, error-prone workflow that creates uncontrolled copies of sensitive PII and compensation data outside our system. This is the #1 requested feature in lost-deal analyses for the past two quarters. Three competitors already offer basic reporting, and we're losing deals specifically on this gap. Customers need self-service analytics that respect strict compliance requirements (SOC 2, GDPR) and data residency rules, without requiring them to maintain external BI infrastructure. The opportunity is a new revenue line at $5/employee/month — significant given 500–50,000 employees per customer.

## Personas & Use Cases

- **HR Analyst** (builds reports, creates dashboards): Power user who currently exports CSVs weekly and builds pivot tables in Excel. Needs to create custom reports (headcount by department, attrition trends, compensation distribution) without leaving the platform. Wants to save, schedule, and share reports with colleagues.
- **HR Executive** (consumes dashboards, makes decisions): Views dashboards shared by analysts. Often doesn't have an account in the main HR product — accesses dashboards via shared links. Needs high-level summaries with drill-down capability. Cannot tolerate slow load times.
- **IT/Security Admin** (manages access, ensures compliance): Controls who can see what data, enforces data residency policies, and audits data access. Needs to restrict PII visibility (e.g., analysts see aggregate compensation, not individual salaries) and ensure EU tenant data stays in EU infrastructure.
- **Customer Success Manager** (internal, supports onboarding): Helps customers set up their first dashboards. Needs the platform to be self-service enough that CSMs aren't bottlenecked on every report request.

## Goals & Scope

- **Must have**: Self-service report builder — customers create reports using a visual interface by selecting dimensions, measures, and filters from their data. Dashboard builder — combine multiple reports into a shareable dashboard. Tenant data isolation — one customer never sees another's data, enforced at every layer. Role-based access within a tenant — admins control who can build reports, who can view, and which data fields are visible per role. Shareable dashboard links — executives without platform accounts can view dashboards via authenticated links. SOC 2 and GDPR compliance — audit logs for all data access, right-to-deletion support, consent-aware data handling.
- **Should have**: Scheduled reports — email a PDF/CSV of a report on a recurring schedule. Pre-built report templates for common HR metrics (headcount, attrition, compensation bands) so customers start quickly. Data residency controls — admin configures which region their data is stored and processed in (US, EU at launch).
- **Non-goals**: Real-time streaming analytics — reports run on data refreshed periodically (hourly or daily), not live. Custom data ingestion from external sources — analytics operates on data already in our HR platform, not arbitrary data uploads. Embedded analytics for our customers' customers — this is an internal analytics tool for HR teams, not a white-label BI product. Building a general-purpose BI tool — we optimize for HR data and use cases, not arbitrary data modeling.

## User Stories

- As an **HR Analyst**, I want to build a custom report showing attrition rate by department over the past 12 months so that I can identify retention problem areas and present them to leadership.
  - **Acceptance**: Analyst selects "Attrition Rate" measure, "Department" dimension, "Last 12 Months" time filter using a visual report builder. Report generates in < 10 seconds. Report can be saved, named, and added to a dashboard.
  - **Scenario**: Analyst opens the analytics module, clicks "New Report." Selects measure "Attrition Rate," groups by "Department," filters to "Last 12 Months." Clicks "Run." A bar chart and data table appear in 6 seconds showing attrition by department. Analyst saves as "Q1 Attrition by Dept" and adds it to the "Leadership Dashboard."

- As an **HR Executive**, I want to view a shared dashboard without creating a platform account so that I can review workforce metrics before the board meeting.
  - **Acceptance**: Executive receives a link, authenticates via email verification or SSO, and sees the dashboard. Dashboard loads in < 5 seconds. Executive can drill down (click a department to see team-level data) but cannot modify the dashboard or export raw data.
  - **Scenario**: CHRO receives a link to "Q3 Workforce Dashboard" from the HR analyst. Clicks it, verifies via email code, sees four charts: headcount trend, attrition by department, open requisitions, and average tenure. Clicks the "Engineering" bar in the attrition chart to drill down into engineering sub-teams. All data loads interactively.

- As an **IT/Security Admin**, I want to restrict which data fields are visible to specific roles so that analysts can build reports without seeing individual compensation data.
  - **Acceptance**: Admin configures field-level permissions — e.g., "Analyst" role can see aggregated compensation (averages, bands) but not individual salary. Permissions are enforced in the report builder (restricted fields don't appear as selectable) and in query execution (even raw API calls return redacted data).
  - **Scenario**: IT admin opens analytics settings, selects the "Analyst" role, and removes access to "Individual Salary" and "SSN" fields. An analyst who previously had a report with individual salaries now sees those columns replaced with "Restricted." Creating a new report, the analyst doesn't see these fields in the dimension/measure picker.

- As an **IT/Security Admin**, I want to configure data residency so that our EU employees' data is stored and processed only in the EU region.
  - **Acceptance**: Admin selects "EU" as the data residency region. All analytics queries for that tenant execute in EU infrastructure. Audit log confirms no cross-region data transfer.
  - **Scenario**: German customer's IT admin sets data residency to "EU" during onboarding. When an HR analyst runs a report, the query executes against the EU data store. Admin reviews the audit log and confirms all queries show "Region: EU."

## Behavioral Boundaries

- **Report complexity**: Maximum 5 dimensions and 10 measures per report. Beyond that, the report builder shows "Split this into multiple reports for better performance and readability." Maximum 20 reports per dashboard.
- **Query timeout**: Reports that take > 30 seconds to generate show "This report is too complex. Try reducing the time range or number of dimensions." No partial results displayed.
- **Data freshness**: Analytics data refreshes from the main HR database on a configurable schedule (hourly or daily). Dashboard shows "Data as of [timestamp]" — never implies real-time.
- **Shared link expiry**: Dashboard share links expire after 30 days by default. Admin can configure 7, 30, or 90 days. Expired links show "This link has expired — contact the dashboard owner for a new link."
- **Tenant data volume**: Designed for up to 50,000 employees per tenant. Tenants approaching this scale may experience longer report generation times; proactive notification at 80% of capacity.

## Non-Functional Requirements

- **Performance**: Report generation < 10 seconds for 95th percentile of queries across tenants with up to 50,000 employees. Dashboard load (with up to 20 reports) < 5 seconds. Report builder UI interaction (adding dimensions, applying filters) < 200ms.
- **Reliability**: Analytics platform availability ≥ 99.9%. Data refresh jobs complete within the scheduled window ≥ 99.5% of the time. If refresh fails, analytics serves stale data with a visible "Data refresh delayed" warning — never shows an error page.
- **Security**: Tenant data isolation enforced at the query layer — no configuration error or API manipulation can return cross-tenant data. All data access logged with user, timestamp, query, and result set size. Field-level access control enforced at query execution, not just UI.
- **Scalability**: Support 200 tenants at launch, scaling to 1,000 tenants. 2 TB total data at launch, growing 30% YoY. Concurrent analytics sessions: up to 500 across all tenants.
- **Compliance**: SOC 2 Type II audit-ready — access logs retained 7 years. GDPR right-to-deletion: when an employee is deleted from the HR system, their data is purged from analytics within 24 hours. Data residency: US and EU regions at launch, architecture supports adding regions.

## Risks & Open Questions

- **Risk**: Self-service report builder UX is hard — users may create poorly performing reports that frustrate them — likelihood: H — mitigation: pre-built templates for common HR metrics; guardrails on query complexity; progressive disclosure in the builder (simple mode by default, advanced mode opt-in).
- **Risk**: Data residency adds operational complexity — separate infrastructure per region — likelihood: H — mitigation: start with two regions (US, EU); design for region-as-config from the start.
- **Risk**: Pricing at $5/employee/month may face pushback from customers with large employee counts (50k × $5 = $250k/yr) — likelihood: M — mitigation: volume tiers; validate pricing with 5–10 design partners before GA.
- **Dependency**: Data refresh pipeline from the main HR database — requires a reliable change-data-capture or ETL process. If the main database schema changes, analytics refresh must adapt.
- **Dependency**: EU infrastructure for data residency — requires provisioning compute and storage in an EU region if not already available.
- [ ] Should customers be able to create calculated fields (e.g., "cost per hire = total recruiting spend / hires")? Significant scope but high value.
- [ ] How should analytics handle historical data — is it retroactive (analytics on employees who left before the feature launched) or forward-only?
- [ ] Should we offer an API for customers to programmatically query their analytics data (for embedding in their own tools)?
- [ ] What's the migration path for customers currently using Looker on exported CSVs? Can we import their existing report definitions?

## Success Metrics

- Revenue: 30% of existing enterprise customers adopt the analytics add-on within 6 months of GA
- Win rate: Analytics-related lost-deal rate drops by 50% within two quarters
- Engagement: Active analytics users (ran at least one report in the past month) ≥ 60% of licensed users
- Self-service: 80% of reports created by customers without CSM assistance after onboarding
- Compliance: Zero data isolation incidents (cross-tenant data exposure) — ever
- Performance: 95th percentile report generation < 10 seconds, sustained across all tenants

## References

- Competitive analysis: [competitors offering basic reporting — research needed]
- SOC 2 compliance requirements
- GDPR data residency and right-to-deletion requirements
