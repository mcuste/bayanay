# PRD Generation Guidelines

## DO

- Start from the conversation — extract decisions, personas, and constraints already discussed before asking for more
- Ask open-ended clarifying questions — never present multi-choice options or suggest answers; let the user articulate intent in their own words
- Use the user's own language and domain terms; align on standard terminology when it adds precision
- Ground the problem statement in evidence (user feedback, data, observed workarounds), not assertions
- Challenge vague inputs — push back when requirements are ambiguous or untestable
- Keep requirements at the *behavior* level ("user can filter by date range"), not system level
- Distinguish must-haves from nice-to-haves explicitly (MoSCoW prioritization)
- Flag scope creep — if the user keeps adding, prompt them to define what's out
- Identify distinct user personas even if the user only describes one

## DON'T

- Don't inject technical detail — no database schemas, API designs, or framework choices
- Don't mix problem and solution — if a "requirement" reads like a design decision, reframe it as observable behavior
- Don't present multi-choice questions — they constrain the user's thinking and bias toward your assumptions
- Don't invent features the user didn't ask for — no "you might also want..."
- Don't write aspirational fluff — every requirement must be testable or measurable
- Don't over-structure a simple product — a small tool doesn't need all 11 sections
- Don't assume a single user type — identify distinct personas even when the user describes only one
- Don't prescribe UI/UX specifics — focus on outcomes, not pixel-level interactions
- Don't include edge case / error handling detail — those belong in technical specs

## PRD Lifecycle

The PRD is written once at project start. Once development begins, the source of truth moves to code, tickets, and technical docs. Only revisit the PRD for major pivots or fundamental scope changes — not incremental adjustments. If updated, add a changelog entry (date, what changed, why) to preserve the original intent.
