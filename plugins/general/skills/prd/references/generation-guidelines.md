# PRD Generation Guidelines

## DO

- Extract decisions, personas, constraints from conversation before asking more
- Ask open-ended clarifying questions — never multi-choice or suggested answers
  - Good: "What problem are users facing?" / "Who are distinct user types?" / "What signals success in six months?"
  - Bad: "Should target be (a) devs (b) designers (c) both?" — constrains answer
- Use user's language and domain terms; align on standard terminology when it adds precision
- Ground problem statement in evidence (feedback, data, workarounds), not assertions
- Challenge vague or untestable inputs
- Keep requirements at behavior level ("user can filter by date range"), not system level
- Add one concrete scenario per user story — exposes hidden assumptions abstract stories hide
- State behavioral boundaries for each requirement — what user sees at limits (not error handling)
- Distinguish must-haves from nice-to-haves (MoSCoW)
- Flag scope creep — prompt user to define what's out
- If request spans multiple independent subsystems, decompose into separate PRDs first
- Identify distinct personas even if user describes only one

## DON'T

- Inject technical detail — no schemas, API designs, framework choices
- Mix problem and solution — reframe design decisions as observable behavior
- Present multi-choice questions — they constrain thinking and bias toward your assumptions
- Invent features user didn't ask for
- Write aspirational fluff — every requirement must be testable or measurable
- Over-structure simple products — small tool ≠ all 11 sections; scale sections to complexity
- Write >300 words per section — split scope or move to technical doc
- Assume single user type
- Prescribe UI/UX specifics — focus on outcomes
- Include edge case / error handling detail — belongs in technical specs (behavioral boundaries are OK)

## PRD Lifecycle

PRD written once at project start. Once development begins, source of truth moves to code, tickets, technical docs. Only revisit for major pivots or fundamental scope changes. If updated, add changelog entry (date, what changed, why).
