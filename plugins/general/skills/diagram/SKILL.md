---
name: diagram
description: "Draw, visualize, diagram, chart, sketch, or map out any system, process, workflow, data model, architecture, relationship, hierarchy, timeline, or concept as a Mermaid diagram. Trigger phrases: 'draw me a', 'can you sketch', 'show me how X flows', 'visualize the', 'diagram this', 'chart the', 'make a flowchart', 'create a sequence diagram'. Supports flowcharts, sequence diagrams, state machines, ER diagrams, class diagrams, Gantt charts, pie charts, mindmaps, timelines, quadrant charts, sankey diagrams, git graphs, C4 models, block diagrams, architecture diagrams, packet diagrams, kanban boards, XY charts, requirement diagrams, and journey maps."
argument-hint: "<what to diagram — a process, system, data model, workflow, or concept>"
effort: high
version: 1.0.0
---

Generate Mermaid diagram with Material Design styling.

## 1 — Theme (Do First)

Read [`assets/material-theme.txt`](assets/material-theme.txt). Paste contents verbatim as first line of Mermaid block. Never reconstruct from memory.

**Renderer compatibility**: beta types have version requirements and varying platform support — check [references/diagram-types.md](references/diagram-types.md) headers. All types support `%%{init}%%` since Mermaid 10.5.

### Semantic Colors

Apply only to nodes with clear semantic role. Leave neutral nodes unstyled.

| Color  | Fill / Border         | Meaning                          |
|--------|-----------------------|----------------------------------|
| Blue   | `#BBDEFB` / `#1565C0` | Default (applied by theme)       |
| Green  | `#C8E6C9` / `#2E7D32` | Success, completion, approval    |
| Pink   | `#F8BBD0` / `#AD1457` | Error, failure, rejection        |
| Purple | `#E1BEE7` / `#6A1B9A` | External system, third-party     |
| Yellow | `#FFF9C4` / `#F9A825` | Pending, caution, note           |
| Grey   | `#F5F5F5` / `#616161` | Disabled, deprecated             |

Per-type coloring syntax (e.g. sequence diagrams use `rect rgb(...)` not `classDef`) in [references/diagram-types.md](references/diagram-types.md).

### Example

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

## 2 — Understand Subject

Read relevant code/docs. If user references code, explore before drawing. Clarify ambiguity with one focused question — don't guess.

## 3 — Choose Diagram Type

Honor explicit requests. Otherwise pick best fit, state why.

| Subject                                    | Mermaid Type         |
|--------------------------------------------|----------------------|
| Process, workflow, decision tree           | `flowchart TD`       |
| Request/response, API calls, async         | `sequenceDiagram`    |
| Lifecycle, modes, state transitions        | `stateDiagram-v2`    |
| Data model, schema, entities               | `erDiagram`          |
| Class hierarchy, type relationships        | `classDiagram`       |
| Schedule, phases, dependencies             | `gantt`              |
| Proportional data, distribution            | `pie`                |
| Hierarchical brainstorm, topic map         | `mindmap`            |
| Chronological events, milestones           | `timeline`           |
| 2×2 matrix, priority/effort grid           | `quadrantChart`      |
| Flow volumes between nodes                 | `sankey-beta`        |
| Git branching strategy                     | `gitGraph`           |
| System context, containers, components     | `C4Context`          |
| Block layout, **no connections**           | `block-beta`         |
| Cloud/infra with service icons             | `architecture-beta`  |
| Network packet structure, binary layout    | `packet-beta`        |
| Board-style task tracking                  | `kanban`             |
| Bar/line charts with numeric axes          | `xychart-beta`       |
| Requirements traceability                  | `requirementDiagram` |
| User experience journey                    | `journey`            |

**Connected nodes with boundaries → `flowchart` + `subgraph`, never `block-beta`** (block-beta arrows pass through nodes).

Type-specific syntax in [references/diagram-types.md](references/diagram-types.md).

## 4 — Generate

**Layout:**

- Default `TD`. Use `LR` only for horizontal flows (pipelines, data streams).
- Max ~100 chars rendered width. Use `<br/>` for long labels. Max 3–4 side-by-side nodes.
- Short IDs (`req`, `auth`, `db`), descriptive labels.
- One relationship per line — never chain arrows.
- `subgraph` when 8+ nodes.
- Split at ~15 nodes or when audiences differ.

**Labels:**

- Node labels: Title case, max ~30 chars. Use `<br/>` to wrap.
- Edge labels: lowercase, max ~15 chars (1–3 words). Omit when self-evident.
- Dense cross-edges → switch to `LR` for more label space.

**Flowchart shapes:** see [references/diagram-types.md](references/diagram-types.md) Flowchart section. Use semantic shapes: `([…])` start/end, `{…?}` decision, `[(…)]` storage.

## 5 — Validate

Re-check bolded warnings in [references/diagram-types.md](references/diagram-types.md) for your type. Fix issues before output.

## 6 — Output

```markdown
### {Diagram Title}

```mermaid
%%{init: ...}%%   ← verbatim from assets/material-theme.txt

{diagramType}
    ...
```

Brief explanation and any simplifications made.

```

Save to file only if user specifies path. Note beta types (`sankey-beta`, `xychart-beta`, `architecture-beta`, `packet-beta`, `block-beta`) have varying renderer support.
