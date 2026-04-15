---
name: prd
description: "Draft or update a PRD (product requirements document) or feature spec for any feature, initiative, or system. Trigger phrases: 'write a PRD', 'draft requirements', 'product requirements for', 'create a spec', 'requirements doc', 'update PRD'. Produces a complete structured document: problem statement, goals, user stories, functional and non-functional requirements, risks, and success metrics."
argument-hint: "<feature description, problem statement, or initiative>"
version: 1.2.0
allowed-tools: "Bash(mkdir*), Read, Glob, Grep, Write, Edit, WebSearch, WebFetch, Skill"
---

# PRD

PRD defines **what** and **why** — never *how*. Architecture, tech stack, implementation belong in C4/ADR/RFC. Present full draft in Plan mode before writing to disk.

Entry point for product doc workflow. Downstream docs (C4, RFC, ADR) read from PRD — capture product details precisely enough that technical authors need no clarification.

## Step 1: Gather Context

Extract decisions, personas, goals, constraints from conversation history first. Then:

- Read existing PRDs in `docs/prd/`, related RFCs, ADRs, C4 diagrams
- Web-search competitive landscape when relevant

**Only if genuinely uncertain** about scope, users, or constraints — ask open-ended questions (never multi-choice, never suggest answers). Group related questions. Challenge vague/untestable inputs before drafting.

## Step 2: Draft

Use [`template.md`](template.md) for structure. Follow [`references/generation-guidelines.md`](references/generation-guidelines.md) during drafting. Skip sections that don't apply — small tool ≠ all 11 sections.

Use `Skill("general:diagram")` for visuals (user journeys, system context) and embed inline.

Validate against [`references/quality-rules.md`](references/quality-rules.md) before presenting.

## Step 3: Write

After user approves in Plan mode:

1. Next sequential ID from `docs/prd/` (PRD-001 if none exist)
2. Fill metadata: ID, Status: Draft, Author, dates
3. Save to `docs/prd/PRD-{NNN}-{slug}.md`
