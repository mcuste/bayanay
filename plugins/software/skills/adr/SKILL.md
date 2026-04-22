---
name: adr
description: "Draft or update Architecture Decision Records (ADRs) — record architectural decisions with context, alternatives, and trade-offs. Trigger phrases: 'create an ADR', 'write an ADR', 'record this decision', 'ADR for', 'document the decision to use X', 'we decided to use', 'update ADR', 'continue ADR'."
argument-hint: "<'update [ADR path]' | 'continue' | the decision to record>"
effort: high
version: 2.0.0
allowed-tools: "Bash(mkdir*), Read, Glob, Grep, Write, Edit, WebSearch"
---

# ADR — Architecture Decision Record

**Output style:** Short and concise — lead with actions, skip preamble and filler.

ADRs = permanent decision log. One decision per ADR. **Immutable once accepted.** Reverse by writing new superseding ADR.

## Mode

- **`$ARGUMENTS` starts with "update"** → [Update ADR](#update-adr)
- **`$ARGUMENTS` starts with "continue"** → [Continue ADR](#continue-adr)
- **WIP exists in `{adr-directory}/WIP-*.md`** → [Continue ADR](#continue-adr)
- **Else** → [Draft New ADR](#draft-new-adr)

---

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

### Step 3: Clarify & Write WIP

If alternatives, constraints, or consequences unclear — ask all questions together.

1. Write `{adr-directory}/WIP-{slug}.md` with:
   - Research findings: related ADRs, affected components, RFC references
   - Decision context as understood so far
   - Questions (if needed):
     - What alternatives were considered?
     - Driving constraints? (performance, team skills, timeline, integration)
     - Already implemented or still proposed?
     - Reverses or refines existing ADR?
     - Deciders? (default: user's name if known, else TBD)
     - Verification method? (CI check, design review, fitness test — "not applicable" OK if stated explicitly)
2. Add `## Pending Input` — answer questions, confirm context.
3. Tell user: `/adr continue` with answers.

Never invent alternatives or guess consequences.

**ALWAYS wait for user answers — NEVER proceed without them.**

### Step 4: Draft

1. **Assign number** — next sequential after highest existing (ADR-001 if none).
2. **Write** — use [`template.md`](template.md) for structure, [`references/generation-guidelines.md`](references/generation-guidelines.md) for section guidance. Fill every section. No placeholders.
3. **Supersession** — if reversing prior ADR: update old status to `Superseded by ADR-{NNN}`, cross-link both.
4. **Self-review** — check every rule in [`references/rules.md`](references/rules.md). Fix all violations before presenting.

Update WIP with complete draft:

1. Update `{adr-directory}/WIP-{slug}.md` — full ADR content.
2. Add `## Pending Input` — approve, request changes, or reject.
3. Tell user: `/adr continue` with feedback.

**ALWAYS wait for approval — NEVER write final ADR without it.**

### Step 5: Finalize

On approval:

1. Rename WIP → `{adr-directory}/ADR-{NNN}-{slug}.md`. Status → `Accepted`, date → today.
2. Delete WIP if separate from final.
3. Update superseded ADR if applicable.

---

## Continue ADR

Resume WIP from last pause point.

### Step 1: Load WIP

1. Find WIP: `$ARGUMENTS` path, or glob `{adr-directory}/WIP-*.md` (or `**/WIP-*.md` if adr-directory unknown). Multiple → ask which.
2. Read WIP. `## Pending Input` = pause point.
3. `$ARGUMENTS` (after "continue") or user msg = answer to pending question.

### Step 2: Apply and Resume

1. Remove `## Pending Input`.
2. Incorporate answer into ADR.
3. Resume next step in [Draft New ADR](#draft-new-adr):
   - Clarification answered → Step 4 (Draft)
   - Draft approved → Step 5 (Finalize)
   - Change requests → revise, re-run Step 4

---

## Update ADR

Design corrections or resolved questions. User provides path or ADR ID; otherwise glob `{adr-directory}/ADR-*.md` and ask.

### Step 1: Load Context

1. Read ADR.
2. Read related C4, RFCs, PRDs.
3. Read relevant source — what changed since ADR written.
4. Ask user what needs updating if not obvious.

### Step 2: Apply Changes

- **Correction** → update content, add Change Log entry.
- **Supersession** → write new ADR via [Draft New ADR](#draft-new-adr), update old status.

### Step 3: Side-Effects

ADR changes may affect:

- Architecture → `Skill("software:c4")`
- RFC → `Skill("software:rfc", "update")`

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
