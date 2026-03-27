# ADR Generation Guidelines

## DO

- Create ADR when choosing between meaningful alternatives: libraries, data stores, protocols, frameworks, architectural patterns
- Create ADR when C4 diagrams change — diagram changes = architectural decisions
- Active voice: "We will use X for Y" not "X was chosen"
- Surface both pros and cons — no bias toward chosen option
- Name specific affected codebase elements: modules, crates, services, patterns
- Status `Proposed` until user confirms → `Accepted` once confirmed
- Reference related ADRs, RFCs, PRDs, C4 diagrams by relative path
- Fill `Affects` metadata with C4 containers/components impacted
- Supersession: update old ADR status to `Superseded by ADR-{NNN}`, cross-link both
- `WebSearch` when comparing external technologies — check deprecation, compatibility, benchmarks

## DON'T

- Multiple decisions in one ADR — one ADR, one decision
- Edit accepted ADRs — supersede with new ADR
- Narrate discussion in Context — describe forces, not meeting minutes
- ADR for trivial choices with no real alternative
- ADR for implementation-level choices (variable naming, folder structure, code style)
- Invent alternatives — if only one option considered, state that
- Hedging language ("could", "might", "was considered") — decision is made, state it
- Template commentary or placeholders in output

## Section Guidance

Each section has specific purpose — don't blend.

- **Context**: Forces and constraints — technical limitations, business requirements, team constraints, integration needs. Not meeting minutes.
- **Decision Drivers**: Specific, measurable. "Sub-millisecond query latency for read path" not "improve performance." Concrete constraints that influenced choice.
- **Decision**: Active voice. One clear sentence, then detail if needed. "We will use X for Y because Z."
- **Consequences / Positive**: What becomes easier or possible? Name specific improvement.
- **Consequences / Negative**: What becomes harder or impossible? What trade-offs accepted? Every decision has ≥1. Look harder if you can't find one.
- **Consequences / Neutral**: Side effects neither good nor bad — migrations, learning curve, ecosystem changes.
- **Alternatives Considered**: Each gets description, pros, cons, specific rejection reason tied to decision drivers. "Too complex" not a reason — explain what complexity means here.
- **Confirmation**: How team verifies correct implementation — CI checks, design reviews, fitness tests, monitoring. If no automated verification, state explicitly. Never omit.
- **References**: Related ADRs, RFCs, PRDs, external resources. Relative paths for internal docs.

## ADR Lifecycle

Written at moment of decision. Immutable once accepted — record stands even if decision proves wrong.

Reversing a decision:

1. Create new superseding ADR
2. Update original status to `Superseded by ADR-{NNN}`
3. Cross-link both

Original ADR stays as context for why initial decision was made.

**Status flow:** `Proposed` → `Accepted` → (`Deprecated` | `Superseded by ADR-{NNN}`)
