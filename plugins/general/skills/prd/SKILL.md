---
name: prd
description: "Draft or update a PRD (product requirements document) or feature spec for any feature, initiative, or system. Trigger phrases: 'write a PRD', 'draft requirements', 'product requirements for', 'create a spec', 'requirements doc', 'update PRD'. Produces a complete structured document: problem statement, goals, user stories, functional and non-functional requirements, risks, and success metrics."
argument-hint: "<feature description, problem statement, or initiative>"
version: 1.1.0
allowed-tools: "Bash(mkdir*), Read, Glob, Grep, Write, Edit, WebSearch, WebFetch, Skill"
---

# PRD

A PRD defines the **problem space and success criteria** — *what* and *why*, not *how*. Architecture, tech stack, and implementation details belong in technical docs (C4, ADR, RFC). Plan mode shows the full draft for user review before writing to disk.

This is the **entry point** for the product documentation workflow. Downstream documents (C4 diagrams, RFCs, ADRs) all read from the PRD — capture product details with enough clarity and precision that technical authors can derive architecture and proposals without ambiguity.

## Step 1: Gather Context

Start from what you already know — the conversation history likely contains ideation output, problem framing, or user research. Extract everything relevant before asking for more.

- Review the current conversation for decisions, personas, goals, and constraints already discussed
- Read existing PRDs in `docs/prd/`, related RFCs, ADRs, and C4 diagrams
- Web-search for competitive landscape and market context when relevant

**If genuinely uncertain** about scope, target users, or key constraints, ask the user directly. Ask open-ended questions that draw out the user's thinking — never present multi-choice options or suggest answers. Let the user articulate intent in their own words.

Good questions sound like:

- "What problem are your users facing today, and how do they work around it?"
- "Who are the distinct types of users — and what does each care about most?"
- "What would make you confident this succeeded six months from now?"
- "What is explicitly not part of this initiative?"

Bad questions sound like:

- "Should the target be (a) developers, (b) designers, or (c) both?" — don't constrain the answer
- "Would you prefer option A or option B?" — don't frame as choices

Present related questions together. Challenge vague or untestable requirements before drafting — don't assume intent.

## Step 2: Draft

Write a complete PRD using [`template.md`](template.md). Cover every section in order:

1. **Problem Statement** — who is affected, what the problem is, cost of inaction; ground in evidence (user feedback, data, observed workarounds), not assertions
2. **Context & Motivation** — why now, what alternatives exist, why this approach
3. **User Personas & Use Cases** — who the users are and their key workflows; never assume a single user type
4. **Objective & Goals** — strategic alignment; must-have / should-have / non-goals
5. **Scope** — what's explicitly in and explicitly out
6. **User Stories & Requirements** — behavior-level statements ("user can filter by date range"), testable, no architecture or implementation detail
7. **Non-Functional Requirements** — ground in existing system constraints; use numbers ("p99 < 100ms at 10k req/s"), never vague terms ("handle high traffic")
8. **Assumptions & Dependencies** — known constraints and external dependencies
9. **Risks & Open Questions** — honest unknowns; likelihood + mitigation for risks
10. **Success Metrics** — measurable outcomes with targets
11. **References** — relative paths to related PRDs, RFCs, ADRs, C4 diagrams

Guard rails (full list in [`references/generation-guidelines.md`](references/generation-guidelines.md)):

- **No technical detail** — no schemas, API designs, framework choices, or system-level decisions
- **Behavior level only** — if a requirement reads like a design decision, reframe it as observable behavior
- **Use the user's own language and domain terms**
- **Don't over-structure** — a small tool doesn't need all 11 sections; omit what doesn't apply

When a section benefits from a visual (user journey, system context), `Skill("general:diagram")` and embed the resulting Mermaid block inline.

Validate against all rules in [`references/quality-rules.md`](references/quality-rules.md) before presenting.

## Step 3: Write

After user approves in Plan mode:

1. Scan `docs/prd/` for the highest existing PRD ID; use the next sequential number (PRD-001 if none exist)
2. Fill metadata: ID, Status: Draft, Author, Created/Last Updated dates
3. Save to `docs/prd/PRD-{NNN}-{slug}.md`

## Success Criteria

- All sections present with no placeholder text
- Requirements are behavior-level and testable — no implementation or architecture detail
- NFRs have numeric targets
- User Personas identified; never a single generic "user"
- Goals and non-goals are clearly separated
- All rules in [`references/quality-rules.md`](references/quality-rules.md) pass
- File saved to the correct path with metadata filled in
