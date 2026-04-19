# RFC-003: Background Job Monitoring Dashboard

**ID**: RFC-003
**Status**: Draft
**Proposed by**: Alex Kim
**Created**: 2026-04-15
**Last Updated**: 2026-04-15
**Targets**: Implementation

## Problem / Motivation

Background jobs (Bull workers) fail silently. We only discover failures when customers report missing exports or stale reports. No visibility into job queue depth, failure rates, or processing latency. Datadog shows container-level metrics but nothing job-specific. On-call engineers spend 30+ minutes per incident just finding which job failed and why.

## Goals and Non-Goals

### Goals

- Real-time dashboard showing job queue status: pending, active, completed, failed per queue
- Job failure alerting with structured error context (job ID, payload summary, stack trace)
- Historical metrics: throughput, latency percentiles, failure rate per queue over 7/30 days
- Retry and manual re-enqueue from the dashboard for failed jobs

### Non-Goals

- Job scheduling or cron management — Bull handles this
- Replacing Datadog for infrastructure monitoring
- Custom job types or workflow orchestration
- Public-facing status page

## Proposed Solution

Deploy Bull Board (open-source Bull dashboard) as an internal admin route behind auth middleware. Augment with custom Datadog metrics emitted from Bull event listeners for alerting and historical trends.

1. Mount Bull Board at `/admin/jobs` behind admin auth middleware
2. Add Bull event listeners (`completed`, `failed`, `stalled`) that emit custom Datadog metrics
3. Datadog monitors for: failure rate > 5% over 5 minutes, queue depth > 1000, stalled jobs > 0
4. Failed job detail view with payload inspection and one-click retry

## Alternatives

### Custom React dashboard with Bull API

Build a custom monitoring UI consuming Bull's Redis-backed queue API directly.

**Rejected**: Significant frontend development effort for a tool only admins use. Bull Board provides 80% of the needed functionality out of the box. Custom dashboard would require ongoing maintenance as Bull's internals evolve.

### Grafana + Prometheus with Bull exporter

Export Bull metrics to Prometheus, visualize in Grafana. Use Grafana alerting for failures.

**Rejected**: Adds two infrastructure components (Prometheus, Grafana) we don't run. Datadog already handles metrics and alerting. Duplicating observability infrastructure for one use case is wasteful. If we ever adopt Grafana broadly, can migrate then.

## Impact

- **Files / Modules**: `src/admin/jobs/` (new route), `src/workers/metrics.ts` (new event listeners), `package.json` (bull-board dependency)
- **C4**: Container diagram — no new containers. API Server description updated to mention admin dashboard.
- **ADRs**: None
- **Breaking changes**: No

## Open Questions

- [ ] Should Bull Board be a separate admin service or mounted in the main API server? Security vs simplicity — **can defer**
- [ ] Retention period for failed job payloads in Redis? Large payloads could consume memory — **must resolve**

---

## Change Log

- 2026-04-15: Initial draft
