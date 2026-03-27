# RFC-{NNN}: {Title}

**ID**: RFC-{NNN}
**Status**: Draft | In Review | Accepted | Rejected | In Progress | Implemented | Superseded | On Hold
**Proposed by**: {name — human stakeholder accountable for the decision}
**Created**: {YYYY-MM-DD}
**Last Updated**: {YYYY-MM-DD}
**Targets**: {C4 | Implementation | ADR — list all that apply}

## Problem / Motivation

Why needed? What breaks without it? Expected outcome?

## Goals and Non-Goals

### Goals

- {Each goal maps to ≥1 milestone}

### Non-Goals

- {Explicitly out of scope — prevents creep}

## Proposed Solution

Concrete design. Enough detail for someone unfamiliar with codebase — not full implementation detail.

## Alternatives

### {Alternative 1}

Description, pros, cons, rejection reason.

### {Alternative 2}

Description, pros, cons, rejection reason.

## Impact

- **Files / Modules**: {specific paths or modules}
- **C4**: {diagrams needing update, or "none"}
- **ADRs**: {decisions to record, or "none"}
- **Breaking changes**: {yes/no — if yes, what breaks}

## Open Questions

- [ ] {Must resolve before acceptance}
- [ ] {Can defer to implementation}

Resolved questions stay with resolution recorded:

- [x] {Resolved question} → **{Answer, e.g. "per ADR-005"}**

---

<!-- Added after acceptance -->

## Implementation Plan

Vertical slices — each cuts all layers, delivers complete thin functionality. One stacked PR per milestone. Front-load risk.

- **Milestone 1:** {Walking skeleton — thinnest end-to-end path} — **Open**
- **Milestone 2:** {Single-concern reviewable change} — **Open**
- **Milestone 3:** {Single-concern reviewable change} — **Open**
- **Milestone N:** {Split until each is PR-sized} — **Open**
- **Milestone N+1:** {Rollout/migration — feature flags, monitoring} — **Open**

## Acceptance Criteria

Best-fit format per milestone. Mix freely.

### Milestone 1

**Given-When-Then** — user interactions and workflows:

```gherkin
Scenario: {description}
  Given {precondition}
  When {action}
  Then {observable outcome}
```

**Rules-Based** — UI constraints and system specs:

- {Concrete, measurable — "loads within 200ms", not "loads quickly"}

**Example-Based** — complex business logic:

```text
{input condition} --> {expected output}
```

Each criterion: independently testable, unambiguous pass/fail. Include edge cases, error states, negative requirements. 3–7 per milestone.

### Milestone 2

- {criterion}

## Change Log

- {YYYY-MM-DD}: Initial draft
