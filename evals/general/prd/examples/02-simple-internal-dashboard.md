# PRD-001: Unified Uptime Dashboard

- **ID**: PRD-001
- **Status**: Draft
- **Author**: —
- **Created**: 2026-04-19
- **Last Updated**: 2026-04-19

## Problem

The SRE team checks three separate tools (Datadog, PagerDuty, custom healthcheck endpoints) every time they need to assess service health. Context-switching between tools wastes time during incidents when speed matters most, and creates risk of missing a degraded service that only shows in one tool. With 15 engineers doing this daily, the cumulative cost is significant — and during incidents, the lack of a single source of truth slows down triage.

## Personas & Use Cases

- **On-call SRE** (incident responder): Needs to assess overall system health in seconds when paged. Currently opens three tabs and mentally correlates status across tools. Needs a single view that shows which services are degraded and which source reported the issue.
- **SRE Team Lead** (daily standup, capacity planning): Reviews service health trends to identify recurring problem areas. Currently asks team members to summarize because no single view exists.

## Goals & Scope

- **Must have**: Single-page dashboard aggregating health status from Datadog, PagerDuty, and custom healthcheck endpoints. Per-service health indicator combining all three sources. Auto-refresh without manual reload. Clear indication of data source and last-updated time per service.
- **Should have**: Visual distinction between "down," "degraded," and "healthy" states. Clickable links to the source tool for each status entry (deep-link to Datadog monitor, PagerDuty incident, healthcheck detail).
- **Non-goals**: Alerting — PagerDuty already handles this; the dashboard is read-only. Historical trend analysis — this is a live status view, not a metrics platform. Public-facing status page — this is internal only, no external branding or access control concerns beyond SSO.

## User Stories

- As an **On-call SRE**, I want to open one page and see the health of all services so that I can assess blast radius within 10 seconds of being paged.
  - **Acceptance**: Dashboard loads in < 3 seconds. All monitored services visible without scrolling on a standard laptop screen. Each service shows aggregate status from all three sources.
  - **Scenario**: SRE gets paged at 2 AM, opens the dashboard. Sees "payments-api" showing red with source "Datadog: monitor triggered" and "Healthcheck: /health returning 503." PagerDuty shows an active incident. SRE clicks the Datadog link, goes directly to the triggered monitor.

- As an **SRE Team Lead**, I want to see at a glance how many services are healthy vs. degraded so that I can prioritize team focus during daily standup.
  - **Acceptance**: Summary counts (e.g., "18 healthy, 2 degraded, 1 down") visible at the top of the page.
  - **Scenario**: Lead opens dashboard before standup, sees 2 services degraded. Notes the service names and source details, brings them up in standup without needing to check each tool individually.

## Behavioral Boundaries

- **Data freshness**: Dashboard auto-refreshes every 30 seconds. If a source hasn't responded in > 60 seconds, that source's status shows "stale" with the last-known timestamp — never silently shows outdated data as current.
- **Source unavailability**: If Datadog API is unreachable, dashboard shows "Datadog: unavailable" for affected services rather than hiding the source or showing false-healthy. Other sources continue to display normally.
- **Service count**: Designed for up to 50 services. Beyond 50, the single-page layout may require grouping or filtering (out of scope for v1).

## Non-Functional Requirements

- **Performance**: Page load < 3 seconds. Status refresh cycle completes < 5 seconds for all sources.
- **Reliability**: Dashboard should be available 99.9% of the time (internal SLA). If the dashboard itself is down during an incident, engineers fall back to individual tools — so the dashboard must not become a single point of failure for incident response.
- **Security**: Internal access only, authenticated via existing SSO. No public endpoints. API keys for Datadog/PagerDuty stored in existing secrets management, never exposed to the browser.

## Risks & Open Questions

- **Risk**: Datadog and PagerDuty API rate limits could throttle refresh cycles — likelihood: L — mitigation: cache responses server-side with 30-second TTL; 15 users viewing the dashboard hit the cache, not the APIs directly.
- **Dependency**: Datadog API and PagerDuty API — if either changes authentication or deprecates endpoints, dashboard breaks for that source.
- **Dependency**: Custom healthcheck endpoints — assumes all services expose a consistent healthcheck contract (e.g., `/health` returning HTTP 200/503).
- [ ] How should the dashboard handle services monitored by only one or two of the three sources? Show blank cells or "not monitored"?
- [ ] Should services be grouped (by team, by tier, by environment) or shown as a flat list?

## Success Metrics

- Adoption: All 15 SRE engineers use the dashboard as their first stop during incidents within 2 weeks of launch
- Efficiency: Mean time from page to "blast radius assessed" decreases by 50% (baseline from incident retros)
- Trust: Zero incidents where the dashboard showed healthy while a service was actually degraded, in the first 3 months
