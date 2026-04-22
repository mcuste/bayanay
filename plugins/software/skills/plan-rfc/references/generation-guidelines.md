# Plan Generation Guidelines

## Milestones

### Size

One milestone = one cohesive code change (~30 min). A meaningful feature chunk — multiple related fns, a module slice, a test suite for a component, a complete config layer. Not a PR — PR may contain several milestones. Needs "and" joining two unrelated concerns → split it.

### Three Phases (strict order)

**Phase 1 — Core:** Walking skeleton + happy-path defaults. Simplest correct input, default path. No error handling, edge cases, config, or validation beyond compiler requirements.

**Phase 2 — Details:** Production-ready non-happy-path. Error handling, validation, edge cases, config, permissions, timeouts, retries.

**Phase 3 — Polish:** User-facing: messages, formatting, help text, progress, logging, docs. Skippable if appetite runs out.

### Phase Ordering

- M1 always = walking skeleton (thinnest end-to-end path).
- Front-load risk and uncertainty within each phase.
- Every milestone leaves system compilable/runnable.
- Every milestone independently valuable — cancellation after any milestone leaves useful work.

### File Structure Map

Map all created/modified files before defining milestones. Each milestone references this map — no surprise files mid-plan. Existing codebases → explore current structure, follow existing patterns.

### Zero-Context Executor

Every milestone self-contained — implementable reading that milestone alone. Never "similar to M3" or "same approach as above". Repeat details every time. References other milestone context → underspecified.

### Specificity

Name concrete artifacts: file paths, fn names, type names, module names. Not "add rate limiting middleware" but "create `createRateLimiter()` in `src/middleware/rate-limit.ts` returning express-rate-limit middleware with Redis store".

### Context Sources

- **RFC** — proposal being implemented. Goals, non-goals, solution, alternatives.
- **PRD** — product requirements. User stories, ACs, personas, behavioral boundaries.
- **C4** — current architecture. Boundaries, deployment topology.
- **ADRs** — active constraints. Tech choices, required patterns.
- **Related RFCs** — overlapping/dependent proposals. Avoid conflicts, find shared infra.
- **Codebase** — existing patterns, naming, test structure.

## Acceptance Criteria

ACs answer: "How do we know this milestone is done?"

- 1-3 per milestone. More than 3 → milestone too big, split.
- Unambiguous pass/fail.
- Measurable: "returns 429 status" not "handles rate limits".
- Behavior not implementation — "what" not "how".
- Format: Given-When-Then (workflows), Rules-Based (constraints), Example-Based (business logic). Mix freely.

### LLM-Agent ACs

LLM executor → more explicit: concrete input/output mappings, pre/postconditions, invariants, enumerated edge cases, negative requirements (agents add unrequested features). Tests before impl. Tautological tests (asserting what code does, not what it should do) = #1 LLM testing failure.

## Pitfalls

- **Too big** — can't impl in ~30 min → split.
- **Phase leakage** — error handling in Phase 1, happy-path in Phase 2. Keep phases clean.
- **Vague** — "add middleware" → which file? fn? signature?
- **Cross-references** — "similar to M3" → repeat details, executor reads milestones in isolation.
- **Missing file map** — surprise files mid-plan → map upfront.
- **Stale RFCs** — flag Draft/In Review >60 days, In Progress no updates >30 days.
- **Missing traceability** — ADRs must reference RFC ID.
- **Sycophantic planning** — surface risks and conflicts, don't agree.
- **Scope creep** — fixed appetites + explicit Non-Goals.
- **Back-loaded risk** — risky/uncertain work → early milestones.
