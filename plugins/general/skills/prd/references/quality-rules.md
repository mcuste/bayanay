# PRD Quality Rules

Apply per-section during drafting and as final pass before presenting.

## Completeness

- `prd-problem-missing` — Problem Statement missing or only placeholders
- `prd-goals-missing` — Goals missing; must include primary goals and non-goals
- `prd-requirements-vague` — Requirements use vague language, no measurable criteria
- `prd-nfr-missing` — NFRs missing; must cover performance, reliability, security, scalability
- `prd-metrics-missing` — Success Metrics missing or not measurable
- `prd-stories-missing` — User Stories missing or empty
- `prd-stories-no-acceptance` — User Stories lack acceptance criteria

## Clarity

- `prd-ambiguous-scope` — Goals/non-goals not separated or non-goals empty
- `prd-undefined-terms` — Domain terms used without definition
- `prd-conflicting-requirements` — Requirements contradict each other

## Feasibility

- `prd-infeasible-requirement` — Requirement infeasible given current architecture
- `prd-missing-dependency` — Assumes capabilities that don't exist without acknowledging dependency
- `prd-uncosted-nfr` — NFRs imply significant infra changes without acknowledging cost

## Consistency

- `prd-stale-references` — References point to nonexistent files
- `prd-overlapping-scope` — Scope overlaps another PRD without acknowledging relationship
- `prd-status-stale` — Status "Draft" but created >30 days ago
