---
name: rfc
description: "Draft or update an RFC (Request for Change) — async technical proposal for C4 architecture changes, implementation decisions, or revisiting ADRs. Trigger phrases: 'propose an RFC', 'write an RFC', 'create an RFC', 'draft an RFC for', 'update RFC', 'continue RFC'. Manages RFC lifecycle only — implementation is done by language-specific generators."
argument-hint: "<'update [RFC path]' | 'continue' | proposal title or problem>"
model: opusplan
effort: high
version: 2.4.0
allowed-tools: "Bash(mkdir*), Read, Glob, Grep, Write, Edit, WebSearch, WebFetch, Skill"
---

# RFC — Request for Change

Proposal → review → refine → implement. **ALWAYS follow every step. NEVER skip, combine, or reorder.**

Targets: C4 docs, implementation decisions, ADRs. NEVER target PRDs — update those directly.

## Mode

- `$ARGUMENTS` starts with "update" → [Update RFC](#update-rfc)
- `$ARGUMENTS` starts with "continue" → [Continue RFC](#continue-rfc)
- WIP exists in `docs/rfc/WIP-*.md` → [Continue RFC](#continue-rfc)
- Otherwise → [Draft New RFC](#draft-new-rfc)

---

## Draft New RFC

### Step 1: Research

Read before proposing:

- `docs/rfc/` — avoid duplication, flag related
- `docs/adr/` — constraints, conflicts
- `docs/c4/` — affected architecture
- `docs/prd/` — driving product decisions
- Relevant source — current state

`Skill("{lang}:{lang}-researcher")` or web-search when external research needed.
`Skill("{lang}:{lang}-generator")` to design architecture: modules, services, data models, interfaces, error handling. Detect lang first. Call even with no existing source — generator designs new architecture, not just reviews.
NEVER invent lang-specific architecture without generator input.

### Step 2: Scope Check

- \>3 unrelated modules → split RFCs. Present decomposition, get approval.
- Related RFC in Draft/In Review → flag, ask: supersede, amend, or abandon.
- Contradicts ADR → address explicitly (supersede or explain exemption).

### Step 3: Clarify (if needed)

Unclear problem, scope, or constraints → write WIP and ask:

1. Write `docs/rfc/WIP-{slug}.md` with research findings and what's known.
2. Add `## Pending Input` with specific questions:
   - What problem? What breaks without it?
   - Targets: C4, implementation, ADR?
   - Known alternatives or constraints?
   - Appetite?
3. Tell user: `/rfc continue` with answers.

NEVER draft with invented constraints or assumed scope.

### Step 4: Propose Approaches

`Skill("{lang}:{lang}-generator")` if not called in Step 1 — design architecture for each candidate. When in doubt, call it.

Present 2-3 candidates, write to WIP. Every candidate MUST be viable production choice. NEVER include straw-man or obviously inferior options. One approach valid → present one, explain why alternatives don't apply.

1. Update `docs/rfc/WIP-{slug}.md` — approaches section:
   - Each: 2-3 sentence description, key tradeoff, biggest risk
   - Reference generator output; note divergence from idiomatic defaults and why
   - Recommendation with reasoning
   - Data flows / component relationships / state transitions → `Skill("general:diagram")`
2. Add `## Pending Input` — pick approach.
3. Tell user: `/rfc continue` with selection.

**ALWAYS wait for user pick — NEVER proceed without selection.**

### Step 5: Draft

1. Read [`template.md`](template.md). Fill every section. No placeholders.
2. Next sequential ID from `docs/rfc/`.
3. Status: **Draft**.
4. **Goals and Non-Goals** mandatory. Can't articulate out-of-scope = don't understand scope.
5. **Alternatives** ≥2 with specific rejection reasoning. Every alternative MUST be credible production option. NEVER pad with straw-man. NEVER hand-wave "too complex".
6. Architecture changes → `Skill("general:diagram")` for before/after in Proposed Solution.

**Self-review — all must pass:**

- [ ] No placeholders, TBDs, TODOs
- [ ] Goals and Non-Goals consistent
- [ ] Each alternative has specific rejection reasoning
- [ ] Scope fits single RFC (re-check Step 2)
- [ ] No unrequested features (YAGNI)
- [ ] Open Questions marked must-resolve vs can-defer

Write to `docs/rfc/WIP-{slug}.md` (overwrite WIP). Add `## Pending Input` — approve or request changes. Tell user: `/rfc continue`.

**NEVER write final RFC without user approval.**

### Step 6: Finalize

On approval:

1. Rename WIP → `docs/rfc/RFC-{NNN}-{slug}.md`. Status → **In Review**.
2. Delete WIP if separate from final.

---

## Continue RFC

Resume WIP from last pause point.

### Step 1: Load WIP

1. Find WIP: `$ARGUMENTS` path, or glob `docs/rfc/WIP-*.md`. Multiple → ask which.
2. Read WIP. `## Pending Input` = pause point.
3. `$ARGUMENTS` (after "continue") or user msg = answer to pending question.

### Step 2: Apply and Resume

1. Remove `## Pending Input`.
2. Incorporate answer into RFC.
3. Resume next step in [Draft New RFC](#draft-new-rfc):
   - Clarification → Step 4 (Propose Approaches)
   - Approach selection → Step 5 (Draft)
   - Draft approval → Step 6 (Finalize)
   - Change requests → revise, re-run Step 5

---

## After Acceptance (same session)

1. ADR(s) → `Skill("software:adr")`
2. C4 if architecture changes → `Skill("software:c4")`
3. Implementation plan → `Skill("software:plan-rfc")`
4. Change Log entry
5. Status → **Accepted**

Substantial side-effects → confirm scope with user first.

---

## After Rejection

1. Add `## Rejection Reason` section
2. Status → **Rejected**
3. Change Log entry
4. Flag RFCs/ADRs referencing this one

---

## Update RFC

Design corrections or resolved questions. User provides path or RFC ID; otherwise glob `docs/rfc/*.md` and ask.

Milestone progress or scope changes → `Skill("software:plan-rfc", "update")`.

### Step 1: Load Context

1. Read RFC.
2. Read related ADRs, C4 from Impact section.
3. Read relevant source — what changed since RFC written.
4. Ask user what needs updating if not obvious.

### Step 2: Apply Changes

- **Design correction** → update Proposed Solution, status → **In Review**, explain change.
- **Open Question resolved** → check box, add resolution after `→`.

Add Change Log entry.

### Step 3: Side-Effects

Update changes architecture or decisions:

- Architecture → `Skill("software:c4")`
- Decisions → `Skill("software:adr")`

---

## Superseding

1. Old RFC → **Superseded**, add `**Superseded by**: RFC-{NNN}`
2. New RFC → add `**Supersedes**: RFC-{NNN}`
3. Change Log entries on both
