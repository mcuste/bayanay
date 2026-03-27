# PRD-{NNN}: {Title}

| ID        | Status | Author | Created      | Last Updated |
|-----------|--------|--------|--------------|--------------|
| PRD-{NNN} | Draft  | {name} | {YYYY-MM-DD} | {YYYY-MM-DD} |

## Problem Statement

What problem are we solving? Who experiences it? What is the impact of not solving it?

Ground this in evidence — user feedback, observed workarounds, data, or research. State what you know and how you know it.

## Context & Motivation

Why now? What alternatives or workarounds exist today? Why is this the right approach?

## User Personas & Use Cases

Who are the users? Identify distinct personas and their key workflows — don't assume a single user type.

- **Persona A** ({role/context}): {key workflow or pain point}
- **Persona B** ({role/context}): {key workflow or pain point}

## Objective & Goals

Strategic alignment — how does this serve business goals?

- **Must have**: What this must deliver to be considered successful.
- **Should have**: Important but not blocking launch.
- **Non-goals**: What is explicitly out of scope and why.

## Scope

**In scope**: {what this initiative covers}

**Out of scope**: {what is explicitly excluded}

## User Stories & Requirements

Behavior-level statements only — no architecture or implementation detail. Each story includes acceptance criteria.

- As a {persona}, I want {action} so that {benefit}.
  - **Acceptance**: {measurable condition that must be true}

## Non-Functional Requirements

- **Performance**: Specific targets (e.g., p99 < 100ms at 10k req/s)
- **Reliability**: Uptime targets, failure modes, recovery expectations
- **Security**: Auth, authorization, data protection requirements
- **Scalability**: Expected load, growth projections

## Assumptions & Dependencies

- **Assumptions**: Things expected to be true but not guaranteed.
- **Constraints**: Limits on time, budget, technology, or team capacity.
- **Dependencies**: External systems, teams, or APIs this relies on.

## Risks & Open Questions

- **Risk**: {description} — likelihood: {low/medium/high} — mitigation: {plan}
- [ ] Open question 1
- [ ] Open question 2

## Success Metrics

How will we know this succeeded? Measurable outcomes only.

- {metric}: target {value}

## References

- Related PRDs, RFCs, ADRs, C4 diagrams (relative paths)
