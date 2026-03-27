---
name: diagram
description: "Draw, visualize, diagram, chart, sketch, or map out any system, process, workflow, data model, architecture, relationship, hierarchy, timeline, or concept as a Mermaid diagram. Trigger phrases: 'draw me a', 'can you sketch', 'show me how X flows', 'visualize the', 'diagram this', 'chart the', 'make a flowchart', 'create a sequence diagram'. Supports flowcharts, sequence diagrams, state machines, ER diagrams, class diagrams, Gantt charts, pie charts, mindmaps, timelines, quadrant charts, sankey diagrams, git graphs, C4 models, block diagrams, architecture diagrams, packet diagrams, kanban boards, XY charts, requirement diagrams, and journey maps."
argument-hint: "<what to diagram — a process, system, data model, workflow, or concept>"
effort: high
version: 1.0.0
---

Generate a Mermaid diagram for the user's request with Material Design styling.

## Material Design Theme — Read First

**Before writing any diagram code**, read [`assets/material-theme.txt`](assets/material-theme.txt) and paste its entire contents verbatim as the first line of the Mermaid block. Never reconstruct this string from memory — always read the file.

After the init block, apply semantic colors to make the diagram self-documenting:

| Color  | Fill / Border         | Semantic use                                |
|--------|-----------------------|---------------------------------------------|
| Blue   | `#BBDEFB` / `#1565C0` | Default nodes, main path (applied by theme) |
| Green  | `#C8E6C9` / `#2E7D32` | Success states, completions, approvals      |
| Pink   | `#F8BBD0` / `#AD1457` | Errors, failures, warnings, rejections      |
| Purple | `#E1BEE7` / `#6A1B9A` | External systems, third-party services      |
| Yellow | `#FFF9C4` / `#F9A825` | Notes, pending states, caution              |
| Grey   | `#F5F5F5` / `#616161` | Disabled, deprecated, background elements   |

Apply colors only to nodes with a clear semantic role. Leave neutral/default nodes unstyled. Coloring syntax and per-type instructions (sequence diagrams use `rect rgb(...)`, not `classDef`) are in [references/styling-guide.md](references/styling-guide.md).

### Example

**User:** "Draw a flowchart for user login with password check and MFA"

```mermaid
%%{init: ...}%%   ← verbatim from assets/material-theme.txt

flowchart TD
    classDef ok fill:#C8E6C9,stroke:#2E7D32,color:#212121
    classDef err fill:#F8BBD0,stroke:#AD1457,color:#212121
    classDef ext fill:#E1BEE7,stroke:#6A1B9A,color:#212121

    start([Enter Credentials]) --> check{Valid Password?}
    check -->|no| fail[Auth Failed]:::err
    check -->|yes| mfa{MFA Enabled?}
    mfa -->|no| dash([Dashboard]):::ok
    mfa -->|yes| otp[Enter OTP] --> verify{OTP Valid?}
    verify -->|yes| dash
    verify -->|no| fail
```

## Step 1: Understand the Subject

Read relevant code, docs, or the user's description. If the user references code or a system, explore it before drawing. Clarify ambiguity with one focused question rather than guessing wrong.

## Step 2: Choose Diagram Type

Pick the best type from this table. Honor explicit user requests. Otherwise select the best fit and briefly mention why.

| Subject                                         | Mermaid Type         |
|-------------------------------------------------|----------------------|
| Process, workflow, decision tree, algorithm     | `flowchart TD`       |
| Request/response, API calls, async messaging    | `sequenceDiagram`    |
| Lifecycle, modes, state transitions             | `stateDiagram-v2`    |
| Data model, schema, entity relationships        | `erDiagram`          |
| Class hierarchy, type relationships             | `classDiagram`       |
| Project schedule, phases, dependencies          | `gantt`              |
| Proportional data, distribution                 | `pie`                |
| Hierarchical brainstorming, topic map           | `mindmap`            |
| Chronological events, milestones                | `timeline`           |
| 2×2 matrix, priority/effort grid                | `quadrantChart`      |
| Flow volumes between nodes                      | `sankey-beta`        |
| Git branching strategy                          | `gitGraph`           |
| System context, containers, components (C4)     | `C4Context`          |
| Block layout, **no connections between blocks** | `block-beta`         |
| Cloud/infrastructure with service icons         | `architecture-beta`  |
| Network packet structure, binary layout         | `packet-beta`        |
| Board-style task tracking, columns              | `kanban`             |
| Bar/line charts with numeric axes               | `xychart-beta`       |
| Requirements traceability, verification         | `requirementDiagram` |
| User experience, satisfaction journey           | `journey`            |

> **Note:** For layouts with connections between nodes, always use `flowchart TD/LR` with `subgraph` boundaries — never `block-beta`. Block-beta has poor edge routing; arrows pass through other nodes.

For type-specific syntax details, read the relevant section of [references/diagram-types.md](references/diagram-types.md).

## Step 3: Generate the Diagram

**Layout:**

- Prefer `TD` (top-down). Use `LR` only for naturally horizontal flows (pipelines, data streams) with 4–5 nodes wide.
- Keep rendered width under ~100 characters. Use `<br/>` for long labels. Limit side-by-side nodes to 3–4.
- Short IDs (`req`, `auth`, `db`), descriptive labels in definitions.
- One relationship per line — never chain arrows.
- Group related nodes with `subgraph` when there are 8+ nodes.
- Split into multiple diagrams at ~15 nodes or when subjects serve different audiences.

**Labels:**

- Title case for node labels, lowercase for edge labels.
- Node labels: max ~30 characters. Use `<br/>` to break long labels across two lines.
- Edge labels: max ~15 characters — shorter is better. Prefer 1–3 words (`validates`, `returns 200`, `on failure`). Omit when the relationship is self-evident.
- When a diagram has dense cross-edges, switch to `LR` — it gives edge labels more horizontal space.

**Flowchart node shapes:** start/end `([Start])`, process `[Step]`, decision `{Decision?}`, storage `[(Database)]`, external `[[External]]`.

## Step 4: Validate Before Output

Read [references/common-pitfalls.md](references/common-pitfalls.md) and check the section for the diagram type you used. Fix any issues found before continuing.

## Step 5: Output

Output a fenced Mermaid code block with a heading and brief explanation:

```markdown
### {Diagram Title}

```mermaid
%%{init: ...}%%   ← verbatim from assets/material-theme.txt

{diagramType}
    ...
```

Brief explanation of what the diagram shows and any simplifications made.
```

Save to a file only if the user specifies a path. Note when using beta diagram types (`sankey-beta`, `xychart-beta`, `architecture-beta`, `packet-beta`, `block-beta`) that rendering support varies by Mermaid renderer version.

## Success Criteria

- `%%{init}%%` Material Design theme block is present and copied verbatim from [`assets/material-theme.txt`](assets/material-theme.txt).
- Semantic colors applied to distinguish success/error/external nodes.
- Diagram renders without syntax errors.
- Diagram type matches the subject.
- Node count stays under 15 per diagram; split if needed.
- Labels are concise (≤30 chars) and readable.
- Common pitfalls for the chosen diagram type have been checked.
