# ADR Review Rules

Used during self-review (Step 4: Draft) and review mode. Fix violations in self-review before presenting. In review mode, report as: `ADR: {filename} — [rule-id] **severity** — description of issue → suggested fix`.

## Completeness

`adr-context-missing` **blocker** — Context section is missing or contains only template placeholders.

`adr-decision-missing` **blocker** — Decision section is missing or doesn't contain a clear, active-voice statement.

`adr-decision-passive` **blocker** — Decision uses passive voice or hedging language ("it was decided", "we might use", "X could be used"). Must be active: "We will use X."

`adr-consequences-missing` **blocker** — Consequences section is missing.

`adr-no-negatives` **blocker** — Consequences section has no negative consequences listed. Every decision has trade-offs.

`adr-alternatives-missing` **blocker** — Alternatives Considered section is missing or lists fewer than one alternative.

`adr-alternative-weak-rejection` **gap** — An alternative is rejected with vague reasoning ("too complex", "not a good fit", "not idiomatic") without explaining specifically why.

`adr-drivers-missing` **gap** — Decision Drivers section is missing or contains only generic drivers ("improve performance", "better DX") without specific, measurable constraints.

`adr-confirmation-missing` **gap** — Confirmation section is missing or empty. Every ADR should state how the decision will be verified, or explicitly state that no automated verification applies.

## Clarity

`adr-context-narrates` **gap** — Context section narrates discussion history ("we discussed...", "in the meeting...") instead of describing forces and constraints.

`adr-vague-consequences` **gap** — Consequences are vague ("this will be better", "easier to maintain") without specifying what concretely improves or degrades.

`adr-scope-unclear` **gap** — It's not clear which parts of the codebase this decision affects. ADRs should name specific modules, crates, or patterns.

## Consistency

`adr-contradicts-adr` **blocker** — This ADR contradicts another accepted ADR without superseding it.

`adr-contradicts-code` **blocker** — The decision described doesn't match what the code actually does. Either the ADR is stale or the code diverged.

`adr-supersession-broken` **blocker** — ADR claims to supersede another ADR, but the superseded ADR's status hasn't been updated.

`adr-stale-references` **gap** — References point to files that don't exist.

`adr-missing-number` **gap** — ADR doesn't follow the `ADR-{NNN}` numbering convention.

`adr-status-stale` **gap** — Status is "Proposed" but the date is more than 30 days ago.
