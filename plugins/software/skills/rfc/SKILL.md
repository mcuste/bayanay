---
name: rfc
description: "Draft or update an RFC (Request for Change) — async technical proposal for C4 architecture changes, implementation decisions, or revisiting ADRs. Trigger phrases: 'propose an RFC', 'write an RFC', 'create an RFC', 'draft an RFC for', 'update RFC'. Manages RFC lifecycle only — implementation is done by language-specific generators."
argument-hint: "<'update [RFC path]' | proposal title or problem>"
model: opusplan
effort: high
version: 2.0.0
allowed-tools: "Bash(mkdir*), Read, Glob, Grep, Write, Edit, WebSearch, WebFetch, Skill"
---

# RFC — Request for Change

**Output style:** Short and concise — lead with actions, skip preamble and filler.

Async proposal for changes needing review before implementation. Propose → review → refine → implement. Never skip ahead.

**Can target:** C4 docs, implementation decisions, ADRs
**Cannot target:** PRDs — update those directly

## Mode

- **`$ARGUMENTS` starts with "update"** → [Update RFC](#update-rfc)
- **Anything else** → [Draft New RFC](#draft-new-rfc)

---

## Draft New RFC

### Step 1: Research

Read before proposing:

- RFCs in `docs/rfc/` — avoid duplication, flag related proposals
- ADRs in `docs/adr/` — constraints and conflicts
- C4 diagrams in `docs/c4/` — affected architecture
- PRDs in `docs/prd/` — driving product decisions
- Relevant source files — current state

External systems: use language-specific research skills (e.g., `Skill("rust:rust-researcher")`, `Skill("python:python-researcher")`) or web-search to verify current state.

Architecture/model design: use generator skills (e.g., `Skill("rust:rust-generator")`, `Skill("python:python-generator")`) to propose idiomatic structures before committing.

### Step 2: Clarify (if needed)

If problem, scope, or constraints unclear — ask all together:

- What problem? What breaks without it?
- Which targets: C4 changes, implementation decisions, ADR updates?
- Known alternatives or constraints ruling out approaches?
- Appetite?

Never draft with invented constraints or assumed scope.

### Step 3: Draft

1. Read [`template.md`](template.md). Fill every section. No placeholders.
2. Assign next sequential ID from `docs/rfc/`.
3. Status: **Draft**.
4. **Goals and Non-Goals**: mandatory. Non-Goals prevent scope creep — can't articulate out-of-scope = don't understand scope.
5. **Alternatives**: ≥2 with specific rejection reasoning. No "too complex" hand-waving.
6. **Milestones** (draft-quality, refined after acceptance): per [`references/generation-guidelines.md`](references/generation-guidelines.md). M1 = walking skeleton; subsequent = single-PR vertical slices; nice-to-haves last; final = rollout/migration.
7. Proposed Solution affects >3 unrelated modules → split into separate RFCs.

Output full RFC for review. **Do not write to disk without user approval.**

### Step 4: Write

Save to `docs/rfc/RFC-{NNN}-{slug}.md`. Status → **In Review**.

---

## After Acceptance (same session as approval)

1. Create ADR(s) → `Skill("software:adr")`
2. Update C4 if architecture changes → `Skill("software:c4")`
3. Refine milestones and ACs per [`references/generation-guidelines.md`](references/generation-guidelines.md):
   - Each milestone: single-PR-sized, vertical slice, walking skeleton first, risk front-loaded
   - ACs: independently testable, unambiguous pass/fail, 3–7 per milestone, include edge cases and negative requirements
   - Format: Given-When-Then, Rules-Based, or Example-Based as appropriate
4. Add Change Log entry
5. Status → **Accepted**

Substantial side-effects → confirm scope with user first.

---

## After Rejection

1. Add `## Rejection Reason` section with reason
2. Status → **Rejected**
3. Add Change Log entry
4. Flag RFCs or ADRs referencing this one

---

## Update RFC

Update existing RFC for implementation learnings, design corrections, or milestone progress. User provides path or RFC ID; otherwise glob `docs/rfc/*.md` and ask.

### Step 1: Load Context

1. Read RFC file.
2. Read related ADRs and C4 diagrams from Impact section.
3. Read relevant source files — what changed since RFC was written.
4. Ask user what needs updating if not obvious.

### Step 2: Apply Changes

- **Milestone completed** → mark **Done**; status → **In Progress** or **Implemented** if all done.
- **Design correction** → update Proposed Solution, status → **In Review**, explain change and reason.
- **Scope change** → update Implementation Plan and Acceptance Criteria.
- **Open Question resolved** → check box, add resolution after `→`.

Always add Change Log entry.

### Step 3: Side-Effects

Update changes architecture or decisions:

- Architecture → `Skill("software:c4")`
- Decisions → `Skill("software:adr")`

---

## Superseding

1. Old RFC status → **Superseded**, add `**Superseded by**: RFC-{NNN}`
2. New RFC: add `**Supersedes**: RFC-{NNN}`
3. Change Log entries on both
