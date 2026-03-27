---
name: c4
description: "Draft or update C4 architecture diagrams (System Context, Container, Component). Generates Mermaid diagrams from codebase analysis. Trigger phrases: 'create C4', 'C4 diagrams', 'system context diagram', 'container diagram', 'document the architecture', 'architecture diagram', 'update C4'."
argument-hint: "<system name/scope to draft or update diagrams>"
model: opusplan
effort: high
version: 1.0.0
allowed-tools: "Bash(mkdir*), Read, Glob, Grep, Write, Edit, Skill"
---

# C4 Architecture Diagrams

**Output style:** Short and concise — lead with actions, skip preamble and filler.

Generate/update C4 diagrams. **Start at Level 1, work down. Confirm with user before advancing each level.**

Codebase = source of truth. Derive from actual code. Never invent components.

## Draft New Diagrams

### Step 1: Research

Read first, draw later:

- Existing docs: PRDs (`docs/prd/`), ADRs, RFCs, existing C4 diagrams
- Codebase: entry points, deployable units, infrastructure (Dockerfile, docker-compose, k8s, terraform), integrations (HTTP clients, DBs, queues, caches)
- Rust: `Cargo.toml` workspace members, `[[bin]]` targets, key deps

### Step 2: Ask Before Drawing

Present all questions together:

- **Level 1:** Which external systems? (SSO, email, payment, third-party APIs)
- **Level 2:** Technology choices per container? (language, framework, DB version, queue)
- **Scope/actors unclear:** Ask — wrong Level 1 actors invalidate everything downstream

### Step 3: Level 1 — System Context

Always first. Technology-agnostic — see [references/levels.md](references/levels.md).

Use [templates/context.md](templates/context.md). Save to `docs/c4/{slug}-context.md`.

**Present to user. No Level 2 without explicit approval.**

### Step 4: Level 2 — Container

Only if multiple deployable units exist. Technology visible here — see [references/levels.md](references/levels.md).

Use [templates/container.md](templates/container.md). Save to `docs/c4/{slug}-container.md`.

**Present to user. No Level 3 without explicit request.**

### Step 5: Level 3 — Component (explicit request only)

Only when user asks. LLM reads code directly — Level 3 redundant in most cases. One diagram per container.

Use [templates/component.md](templates/component.md). Save to `docs/c4/{container-slug}/{container-slug}-component.md`.

**Never generate Level 4 — code is source of truth.**

### Step 6: Self-Review

Check every diagram against [references/rules.md](references/rules.md). Fix all violations before output.

### Step 7: ADR Reminder

C4 changes = architectural decisions. After writing, remind user to create corresponding ADR.

## Diagram Conventions

**Naming:** Aliases — lowercase `snake_case`. Labels — human-readable. Technology — specific ("Rust/Axum", "PostgreSQL 16"). Descriptions — *what* not *how*.

**Level 1:** No tech labels. All human actors, system boundary, all external systems.

**Level 2:** Tech on every container. All deployable units. Every relationship labeled with protocol ("REST/HTTPS", "SQL/TCP", "async via NATS").

**Level 3:** Architecturally significant modules only. Derive from module structure, trait boundaries, handler/router organization.

**Exclude all levels:** Implementation details, minor modules, hypothetical components, deployment infra (servers, regions, load balancers).

**Updating:** Read current version first. Preserve manual annotations and notes.

## Success Criteria

- Level 1 before Level 2; Level 3 only if requested; Level 4 never
- External systems and tech confirmed with user — never invented
- User approved each level before advancing
- Every diagram: Notes present, relationships labeled, no phantom components
- All [references/rules.md](references/rules.md) rules pass
- Files at correct paths with metadata filled
- ADR reminder after creation/update
