# PRD-{NNN}: {Title}

- **ID**: PRD-{NNN}
- **Status**: Draft
- **Author**: {name}
- **Created**: {YYYY-MM-DD}
- **Last Updated**: {YYYY-MM-DD}

## Problem

What problem, who experiences it, impact of not solving it. Why now? What alternatives exist today? Ground in evidence — feedback, workarounds, data.

## Personas & Use Cases

Distinct personas and key workflows — never single generic "user".

- **Persona A** ({role/context}): {workflow or pain point}
- **Persona B** ({role/context}): {workflow or pain point}

## Goals & Scope

- **Must have**: Required for success.
- **Should have**: Important, not blocking launch.
- **Non-goals**: Explicitly out of scope and why.

## User Stories

Behavior-level only — no architecture or implementation.

- As a {persona}, I want {action} so that {benefit}.
  - **Acceptance**: {measurable condition}
  - **Scenario**: {concrete walkthrough — user does X → sees Y → result Z}

## Behavioral Boundaries

User-visible limits and what happens when reached. Not error handling — observable behavior.

- {capability}: limit {value}. Beyond limit: {what user sees}.

## Non-Functional Requirements

Skip if not applicable. Numeric targets only — no vague qualifiers.

- **Performance**: {e.g., p99 < 100ms at 10k req/s}
- **Reliability**: {uptime, failure modes, recovery}
- **Security**: {auth, authorization, data protection}
- **Scalability**: {expected load, growth projections}

## Risks & Open Questions

Include dependencies (external systems, teams, APIs) and assumptions (expected true, not guaranteed).

- **Risk**: {description} — likelihood: {L/M/H} — mitigation: {plan}
- **Dependency**: {system/team} — {what happens if unavailable}
- [ ] Open question 1

## Success Metrics

Measurable outcomes only.

- {metric}: target {value}

## References

- Related PRDs, RFCs, ADRs, C4 diagrams (relative paths)
- Web sources researched (URLs)
