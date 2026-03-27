# RFC Generation Guidelines

## Milestone Rules

- **M1 = walking skeleton**: thinnest end-to-end path. Always first. Front-load risk.
- **Vertical slices, not layers**: each milestone cuts all layers. Never "M1: schema, M2: API, M3: UI."
- **Single-PR-sized**: one diff per milestone. Split if description has "and" joining two concerns.
- **Independently valuable**: if cancelled after any milestone, completed work still useful.
- **Must-haves first, nice-to-haves last**: cut if appetite runs out.
- **Final milestone = rollout**: feature flags, gradual rollout, monitoring.

### Appetite (Shape Up)

Fixed appetite, scope to fit. Well-shaped milestones: **rough** (room for judgment), **solved** (main elements present, rabbit holes identified), **bounded** (clear appetite, explicit Non-Goals).

## Acceptance Criteria Rules

ACs answer: "How do we know this milestone is done?"

- **Independently testable** — unambiguous pass/fail
- **Measurable** — "loads within 2s" not "loads quickly"
- **Behavior, not implementation** — "what" not "how"
- **3–7 per milestone** — fewer = underspecified, more = split
- **Edge cases** — empty states, errors, permissions, timeouts, boundaries
- **Negative requirements** — what system must NOT do

### LLM-Agent ACs

LLM implementer → more explicit: concrete input/output mappings, pre/postconditions, invariants, enumerated edge cases, negative requirements (agents frequently add unrequested features). Tests before implementation — tautological tests (asserting what code does, not what it should do) = #1 LLM testing failure mode.

## Pitfalls

- **Stale RFCs**: flag Draft/In Review >60 days, In Progress no updates >30 days
- **Missing traceability**: ADRs must reference RFC ID
- **Over-specification**: define problem and approach, not implementation details
- **Sycophantic planning**: surface risks and conflicts, don't just agree
- **Scope creep**: fixed appetites + explicit Non-Goals
- **Back-loaded risk**: risky/uncertain work → M1
