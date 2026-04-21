---
name: prd
description: "Draft or update a PRD (product requirements document) or feature spec for any feature, initiative, or system. Trigger phrases: 'write a PRD', 'draft requirements', 'product requirements for', 'create a spec', 'requirements doc', 'update PRD', 'continue PRD'. Produces a complete structured document: problem statement, goals, user stories, functional and non-functional requirements, risks, and success metrics."
argument-hint: "<'continue' | feature description, problem statement, or initiative>"
model: opusplan
effort: high
version: 2.0.0
allowed-tools: "Bash(mkdir*), Read, Glob, Grep, Write, Edit, WebSearch, WebFetch, Skill"
---

# PRD

PRD defines **what** and **why** — never *how*. Architecture, tech stack, implementation belong in C4/ADR/RFC. Entry point for product doc workflow. Downstream docs (C4, RFC, ADR) read from PRD — capture product details precisely enough that technical authors need no clarification.

## Mode

- `$ARGUMENTS` starts with "continue" → [Continue PRD](#continue-prd)
- WIP exists in `docs/prd/WIP-*.md` → [Continue PRD](#continue-prd)
- Otherwise → [Draft New PRD](#draft-new-prd)

---

## Draft New PRD

### Step 1: Research

Extract decisions, personas, goals, constraints from conversation history first. Then:

- Read existing PRDs in `docs/prd/`, related RFCs, ADRs, C4 diagrams
- Read relevant source code (entry points, models, existing features) to ground requirements in current capabilities — flag where requirements extend vs. conflict with existing behavior
- Web-search competitive landscape when relevant

**Scope check**: if the request spans multiple independent subsystems, decompose into separate PRDs. Each should be deliverable independently. Draft a scope map first, then write the first PRD.

### Step 2: Clarify (if needed)

Unclear about scope, users, or constraints → write WIP and ask:

1. Write `docs/prd/WIP-{slug}.md` with research findings and what's known.
2. Add `## Pending Input` with open-ended questions (never multi-choice, never suggest answers):
   - What problem? Who experiences it? What's the impact?
   - Who are distinct user types?
   - What signals success?
   - Known constraints or dependencies?
3. Tell user: `/prd continue` with answers.

NEVER draft with invented constraints or assumed scope.

### Step 3: Draft

Use [`template.md`](template.md) for structure. Follow [`references/generation-guidelines.md`](references/generation-guidelines.md) during drafting. Skip sections that don't apply — small tool ≠ all 11 sections. Scale each section to its complexity: 1-2 sentences for simple/obvious aspects, full paragraphs only where ambiguity exists. If a section needs >300 words, it likely contains scope for a separate PRD or belongs in a technical doc.

Use `Skill("general:diagram")` for visuals (user journeys, system context) and embed inline.

Validate against [`references/quality-rules.md`](references/quality-rules.md).

**Self-review — all must pass:**

- [ ] No placeholders, TBDs, TODOs
- [ ] Ambiguity check — could any requirement be read two ways? pick one
- [ ] Contradiction scan — do any requirements conflict?
- [ ] Scope check — still one cohesive feature?

Write to `docs/prd/WIP-{slug}.md` (overwrite WIP if exists). Add `## Pending Input` — approve or request changes. Tell user: `/prd continue`.

**NEVER write final PRD without user approval.**

### Step 4: Finalize

On approval:

1. Next sequential ID from `docs/prd/` (PRD-001 if none exist).
2. Fill metadata: ID, Status: Draft, Author, dates.
3. Rename WIP → `docs/prd/PRD-{NNN}-{slug}.md`. Delete WIP if separate from final.

---

## Continue PRD

Resume WIP from last pause point.

### Step 1: Load WIP

1. Find WIP: `$ARGUMENTS` path, or glob `docs/prd/WIP-*.md`. Multiple → ask which.
2. Read WIP. `## Pending Input` = pause point.
3. `$ARGUMENTS` (after "continue") or user msg = answer to pending question.

### Step 2: Apply and Resume

1. Remove `## Pending Input`.
2. Incorporate answer into PRD.
3. Resume next step in [Draft New PRD](#draft-new-prd):
   - Clarification → Step 3 (Draft)
   - Draft approval → Step 4 (Finalize)
   - Change requests → revise, re-run Step 3
