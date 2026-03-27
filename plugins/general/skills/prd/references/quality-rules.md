# PRD Quality Rules

Apply per-section during drafting and as a final pass before presenting the draft.

## Completeness

- `prd-problem-missing` — Problem Statement missing or only template placeholders.
- `prd-goals-missing` — Goals missing; must include primary goals and non-goals.
- `prd-requirements-vague` — Functional requirements use vague language without measurable criteria.
- `prd-nfr-missing` — Non-functional requirements missing; must address performance, reliability, security, and scalability.
- `prd-metrics-missing` — Success Metrics missing or no measurable outcomes.
- `prd-stories-missing` — User Stories missing or empty.
- `prd-stories-no-acceptance` — User Stories lack acceptance criteria (measurable conditions for "done").

## Clarity

- `prd-ambiguous-scope` — Goals/non-goals not clearly separated or non-goals empty.
- `prd-undefined-terms` — Domain terms used without definition.
- `prd-conflicting-requirements` — Two or more requirements contradict each other.

## Feasibility

- `prd-infeasible-requirement` — Requirement is infeasible given current architecture.
- `prd-missing-dependency` — Assumes capabilities that don't exist without acknowledging the dependency.
- `prd-uncosted-nfr` — NFRs imply significant infra/architecture changes without acknowledging cost.

## Consistency

- `prd-stale-references` — References point to files that don't exist.
- `prd-overlapping-scope` — Scope overlaps another PRD without acknowledging the relationship.
- `prd-status-stale` — Status is "Draft" but created date is >30 days ago.
