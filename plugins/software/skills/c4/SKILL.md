---
name: c4
description: "Draft or update C4 architecture diagrams (System Context, Container, Component). Generates Mermaid diagrams from codebase analysis. Trigger phrases: 'create C4', 'C4 diagrams', 'system context diagram', 'container diagram', 'document the architecture', 'architecture diagram', 'update C4', 'continue C4'."
argument-hint: "<'update [path]' | 'continue' | system name/scope>"
model: opusplan
effort: high
version: 2.0.0
allowed-tools: "Bash(mkdir*), Read, Glob, Grep, Write, Edit, Skill"
---

# C4 Architecture Diagrams

**Output style:** Short and concise — lead with actions, skip preamble and filler.

Generate/update C4 diagrams. **Start at Level 1, work down. Confirm with user before advancing each level.**

Codebase = source of truth. Derive from actual code. Never invent components.

## Mode

- **`$ARGUMENTS` starts with "update"** → [Update Diagrams](#update-diagrams)
- **`$ARGUMENTS` starts with "continue"** → [Continue C4](#continue-c4)
- **WIP exists in `docs/c4/WIP-*.md`** → [Continue C4](#continue-c4)
- **Else** → [Draft New Diagrams](#draft-new-diagrams)

---

## Draft New Diagrams

### Step 1: Research

Read first, draw later:

- Existing docs: PRDs (`docs/prd/`), ADRs, RFCs, existing C4 diagrams
- Codebase: entry points, deployable units, infrastructure (Dockerfile, docker-compose, k8s, terraform), integrations (HTTP clients, DBs, queues, caches)
- Rust: `Cargo.toml` workspace members, `[[bin]]` targets, key deps

### Step 2: Scope & Questions

Present findings and all questions together. Write WIP:

1. Write `docs/c4/WIP-{slug}.md` with:
   - Research findings: identified actors, containers, external systems
   - Technology stack summary
   - Questions:
     - **Level 1:** Which external systems? (SSO, email, payment, third-party APIs)
     - **Level 2:** Technology choices per container? (language, framework, DB version, queue)
     - **Scope/actors unclear:** Ask — wrong Level 1 actors invalidate everything downstream
2. Add `## Pending Input` — answer questions, confirm scope.
3. Tell user: `/c4 continue` with answers.

**ALWAYS wait for user answers — NEVER proceed without them.**

### Step 3: Level 1 — System Context

Always first. Technology-agnostic — see [references/levels.md](references/levels.md).

Use [templates/context.md](templates/context.md). Update WIP with Level 1 diagram.

1. Update `docs/c4/WIP-{slug}.md` — add Level 1 diagram.
2. Add `## Pending Input` — approve Level 1 or request changes.
3. Tell user: `/c4 continue` with feedback.

**ALWAYS wait for approval — no Level 2 without it.**

### Step 4: Level 2 — Container

Only if multiple deployable units exist. Technology visible here — see [references/levels.md](references/levels.md).

Use [templates/container.md](templates/container.md). Update WIP with Level 2 diagram.

1. Update `docs/c4/WIP-{slug}.md` — add Level 2 diagram.
2. Add `## Pending Input` — approve Level 2 or request changes. Level 3 only on explicit request.
3. Tell user: `/c4 continue` with feedback.

**ALWAYS wait for approval — no Level 3 without explicit request.**

### Step 5: Level 3 — Component (explicit request only)

Only when user asks. LLM reads code directly — Level 3 redundant in most cases. One diagram per container.

Use [templates/component.md](templates/component.md). Update WIP with Level 3 diagram.

1. Update `docs/c4/WIP-{slug}.md` — add Level 3 diagram.
2. Add `## Pending Input` — approve or request changes.
3. Tell user: `/c4 continue` with feedback.

**Never generate Level 4 — code is source of truth.**

### Step 6: Self-Review

Check every diagram against [references/rules.md](references/rules.md). Fix all violations before output.

### Step 7: Finalize

On approval of final level:

1. Split WIP into individual files:
   - `docs/c4/{slug}-context.md`
   - `docs/c4/{slug}-container.md` (if Level 2)
   - `docs/c4/{slug}/{slug}-component.md` (if Level 3)
2. Delete WIP.

### Step 8: ADR Reminder

C4 changes = architectural decisions. After writing, remind user to create corresponding ADR.

---

## Continue C4

Resume WIP from last pause point.

### Step 1: Load WIP

1. Find WIP: `$ARGUMENTS` path, or glob `docs/c4/WIP-*.md`. Multiple → ask which.
2. Read WIP. `## Pending Input` = pause point.
3. `$ARGUMENTS` (after "continue") or user msg = answer to pending question.

### Step 2: Apply and Resume

1. Remove `## Pending Input`.
2. Incorporate answer into WIP.
3. Resume next step in [Draft New Diagrams](#draft-new-diagrams):
   - Scope/questions answered → Step 3 (Level 1)
   - Level 1 approved → Step 4 (Level 2)
   - Level 1 changes requested → revise, re-run Step 3
   - Level 2 approved → Step 7 (Finalize) or Step 5 (Level 3 if requested)
   - Level 2 changes requested → revise, re-run Step 4
   - Level 3 approved → Step 7 (Finalize)
   - Level 3 changes requested → revise, re-run Step 5

---

## Update Diagrams

User provides path or diagram slug; otherwise glob `docs/c4/*.md` and ask.

**Updating:** Read current version first. Preserve manual annotations and notes.

### Step 1: Load Context

1. Read existing diagram(s).
2. Read related ADRs, RFCs, PRDs.
3. Read relevant source — what changed since diagram written.
4. Ask user what needs updating if not obvious.

### Step 2: Apply Changes

Update affected diagrams. Present changes for approval before writing.

### Step 3: Side-Effects

Architecture changes may need:

- Decisions → `Skill("software:adr")`
- RFC update → `Skill("software:rfc", "update")`

---

## Diagram Conventions

**Naming:** Aliases — lowercase `snake_case`. Labels — human-readable. Technology — specific ("Rust/Axum", "PostgreSQL 16"). Descriptions — *what* not *how*.

**Level 1:** No tech labels. All human actors, system boundary, all external systems.

**Level 2:** Tech on every container. All deployable units. Every relationship labeled with protocol ("REST/HTTPS", "SQL/TCP", "async via NATS").

**Level 3:** Architecturally significant modules only. Derive from module structure, trait boundaries, handler/router organization.

**Exclude all levels:** Implementation details, minor modules, hypothetical components, deployment infra (servers, regions, load balancers).

## Success Criteria

- Level 1 before Level 2; Level 3 only if requested; Level 4 never
- External systems and tech confirmed with user — never invented
- User approved each level before advancing
- Every diagram: Notes present, relationships labeled, no phantom components
- All [references/rules.md](references/rules.md) rules pass
- Files at correct paths with metadata filled
- ADR reminder after creation/update
