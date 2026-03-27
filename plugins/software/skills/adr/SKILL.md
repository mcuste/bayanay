---
name: adr
description: "Draft or update Architecture Decision Records (ADRs) — record architectural decisions with context, alternatives, and trade-offs. Trigger phrases: 'create an ADR', 'write an ADR', 'record this decision', 'ADR for', 'document the decision to use X', 'we decided to use', 'update ADR'."
argument-hint: "<the decision to record e.g. 'use sqlx over diesel', or path to existing ADR to update>"
effort: high
version: 1.1.0
allowed-tools: "Bash(mkdir*), Read, Glob, Grep, Write, Edit, WebSearch"
---

# ADR — Architecture Decision Record

**Output style:** Short and concise — lead with actions, skip preamble and filler.

ADRs = permanent decision log. One decision per ADR. **Immutable once accepted.** Reverse by writing new superseding ADR.

## Draft New ADR

### Step 0: Locate ADR directory

1. Glob `**/ADR-*.md` and `**/adr/**/*.md`.
2. Matches found → use containing directory.
3. No matches → ask user (suggest `docs/adr/`).
4. Directory missing → create it, copy `template.md` there.

Store resolved path for all subsequent steps.

### Step 1: Research

Read before writing:

- Existing ADRs — prior decisions, conflicts, potential supersessions
- C4 diagrams (`**/c4/**/*.md`) — affected containers/components
- RFCs (`**/rfc*/**/*.md`) — if ADR implements an RFC decision
- Relevant source files — what code does today

**Conflict check:** Flag any accepted ADR that contradicts or overlaps. Present conflicts before continuing — user decides: supersede or coexist.

### Step 2: Evaluate scope

Gate checks — reject if any true:

- **No genuine alternative?** → suggest code comment or RFC instead
- **Implementation-level?** (folder structure, naming, code style) → no ADR
- **Existing ADR covers this?** → point user to it
- **Conflicts with accepted ADR?** → frame as supersession

If decision doesn't warrant ADR, say why and suggest alternative. Don't draft just because asked.

### Step 3: Clarify (if needed)

If alternatives, constraints, or consequences unclear — ask all questions together:

- What alternatives were considered?
- Driving constraints? (performance, team skills, timeline, integration)
- Already implemented or still proposed?
- Reverses or refines existing ADR?
- Deciders? (default: user's name if known, else TBD)
- Verification method? (CI check, design review, fitness test — "not applicable" OK if stated explicitly)

Never invent alternatives or guess consequences.

### Step 4: Draft

1. **Assign number** — next sequential after highest existing (ADR-001 if none).
2. **Write** — use [`template.md`](template.md) for structure, [`references/generation-guidelines.md`](references/generation-guidelines.md) for section guidance. Fill every section. No placeholders.
3. **Supersession** — if reversing prior ADR: update old status to `Superseded by ADR-{NNN}`, cross-link both.
4. **Self-review** — check every rule in [`references/rules.md`](references/rules.md). Fix all violations before presenting.

Present complete draft for approval. **Do not write to disk until user approves.**

### Step 5: Write

Save to `{adr-directory}/ADR-{NNN}-{slug}.md`. Update superseded ADR if applicable.

### Step 6: Confirm

User approves → set status `Accepted`, date to today. User wants changes → revise and re-present.

---

## Key Constraints

Full guidance: [`references/generation-guidelines.md`](references/generation-guidelines.md).

- One decision per ADR — split if multiple
- Active voice — "We will use X" not "X was selected"
- Context = forces and constraints, not meeting history
- At least one negative consequence — look harder if you can't find one
- Specific rejection reasons — not "too complex" or "not idiomatic"
- Name affected modules, crates, or patterns

## Success Criteria

- All sections filled; no placeholders or template commentary
- Decision active-voice, unambiguous
- ≥1 alternative with specific rejection reasoning
- Negative consequences named
- Confirmation section filled ("not applicable" OK, omission not)
- All [`references/rules.md`](references/rules.md) rules pass
- ADR number sequential and unique
- Superseded ADR updated if applicable
- File at `{adr-directory}/ADR-{NNN}-{slug}.md` with status and date set
