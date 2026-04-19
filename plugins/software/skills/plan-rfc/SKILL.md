---
name: plan-rfc
description: "Create or update implementation plan for accepted RFC. Decompose RFC goals into ultra-granular milestones (~5 min each), grouped by phase: core first, then details, then polish. References PRDs, C4, ADRs, related RFCs. Trigger phrases: 'plan RFC', 'create plan for RFC', 'implementation plan for', 'update plan'. Planning only — implementation done by language-specific generators."
argument-hint: "<'update [plan path]' | RFC path or ID>"
model: opusplan
effort: high
version: 2.1.0
allowed-tools: "Bash(mkdir*), Read, Glob, Grep, Write, Edit, WebSearch, WebFetch, Skill"
---

# Plan RFC

Short, direct output. Lead with actions, skip filler. **Every step mandatory — no skip, combine, or reorder.**

**Input:** Accepted RFC (path or ID)
**Output:** Plan in `docs/plans/`

## Mode

- **`$ARGUMENTS` starts with "update"** → [Update Plan](#update-plan)
- **Else** → [Create Plan](#create-plan)

---

## Create Plan

### Step 1: Load Context

1. Read RFC. No path/ID → glob `docs/rfc/*.md`, ask.
2. Status must be **Accepted**. Other → refuse, say get RFC accepted first.
3. Read ADRs + C4 diagrams from RFC Impact section.
4. Read PRDs from `docs/prd/`.
5. Read related RFCs from `docs/rfc/` — referenced, superseded, overlapping.
6. Read relevant source files — current code state.

Unknown deps/APIs/libs → `Skill("{lang}:{lang}-researcher")` or web-search. Verify current APIs, version constraints, integration patterns.

### Step 2: Map File Structure

RFC gives architecture direction — use `Skill("{lang}:{lang}-generator")` to refine: fn signatures, type defs, module boundaries, file layout. Not generating code — enough detail for precise milestones.

Map all files to create/modify + what each does. Milestones reference this map. Existing codebases → follow existing patterns and naming.

### Step 3: Decompose into Milestones

Per [`references/generation-guidelines.md`](references/generation-guidelines.md):

Milestones target zero-context executor — no project knowledge, no taste, no judgment. Each self-contained: never "similar to M3" or "same as above" — repeat all details. If executor can't implement from milestone alone → underspecified.

Each milestone = one atomic change, ~5 min. Single fn, test file, config change, or wiring step. PR may contain many milestones.

Three phases, strictly ordered:

**Phase 1 — Core:** Walking skeleton + happy-path defaults. No error handling, edge cases, or config. System works for simplest correct input on default path.

**Phase 2 — Details:** Error handling, validation, edge cases, config, non-default paths. Production-ready minus polish.

**Phase 3 — Polish:** User-facing messages, formatting, help text, progress indicators, logging. Skippable if appetite runs out.

Within each phase:

- Front-load risk and uncertainty.
- **Every milestone must leave project buildable, runnable, lint-clean.** Build/compile/check/lint pass after each. This constrains ordering:
  - Define types and interfaces before code referencing them.
  - New modules need compilable skeleton (exported types + placeholder impls) before other code imports them.
  - Refactors split across milestones → each intermediate state must compile. Use temporary re-exports, adapter fns, or lint-suppression annotations (later milestone removes).
  - Never add import, type ref, or fn call whose target doesn't exist yet. Milestone N calls `foo()` → `foo()` must exist (even as stub) by end of milestone N or earlier.
  - Stubs and no-op impls OK if they compile and aren't hit at runtime on current happy path.
- "and" joining two concerns → split into two milestones.

Descriptions must be implementation-specific. Not "add rate limiting" → "create `createRateLimiter()` factory in `src/middleware/rate-limit.ts` returning express-rate-limit middleware with Redis store". Name files, fns, types, modules.

Every RFC goal → >=1 milestone. Flag any uncovered goal.

### Step 4: Acceptance Criteria

Per [`references/generation-guidelines.md`](references/generation-guidelines.md):

- **1-3 per milestone** — small milestones need fewer ACs
- Independently testable, unambiguous pass/fail
- Behavior not implementation — "what" not "how"
- Measurable — "returns 429 status" not "handles rate limits"
- Format: Given-When-Then, Rules-Based, or Example-Based

LLM-agent implementers → concrete input/output mappings, pre/postconditions, invariants, enumerated edge cases. Tests before impl. Tautological tests (asserting what code does, not what it should do) = #1 LLM testing failure.

### Step 5: Self-Review

Do NOT present until all pass:

- [ ] File map covers all created/modified files
- [ ] Every RFC goal → >=1 milestone
- [ ] Grouped: Core → Details → Polish
- [ ] Each milestone ~5-min-sized (one atomic change)
- [ ] Phase 1 starts with walking skeleton (thinnest end-to-end)
- [ ] Phase 1 = happy-path only — no error handling, config, edge cases
- [ ] Risk front-loaded within each phase
- [ ] Each milestone leaves project buildable + lint-clean — no dangling refs, missing imports, unresolved types
- [ ] 1-3 ACs per milestone, independently testable
- [ ] Descriptions name specific files, fns, types
- [ ] Each milestone self-contained — no "similar to M3"
- [ ] No placeholders, TBDs, TODOs
- [ ] No unrequested features (YAGNI)

Present for review. **Do not write to disk without user approval.**

### Step 6: Write

Save to `docs/plans/PLAN-RFC-{NNN}-{slug}.md`.

---

## Update Plan

Update plan for impl learnings, milestone progress, or scope changes. User gives path or plan ID; else glob `docs/plans/*.md`, ask.

### Step 1: Load Context

1. Read plan.
2. Read source RFC.
3. Read related ADRs, C4, PRDs.
4. Read related RFCs — referenced or overlapping.
5. Read relevant source — what changed since plan written.
6. Ask user what needs updating if not obvious.

### Step 2: Apply Changes

- **Completed** → mark **Done**. All done → RFC status → **Implemented**.
- **Scope change** → update milestones + ACs. RFC scope changed too → tell user: `Skill("software:rfc", "update")` first.
- **Needs splitting** → split, keep same phase.
- **Impl learning** → adjust remaining milestones, explain what changed + why.

Always add Change Log entry.

### Step 3: Side-Effects

Plan changes affect architecture or decisions:

- Architecture → `Skill("software:c4")`
- Decisions → `Skill("software:adr")`
- RFC correction needed → `Skill("software:rfc", "update")`
