# Styling Guide

Per-type coloring syntax. Colors and semantics defined in SKILL.md.

## No Styling Support

`erDiagram`, `gantt`, `pie`, `mindmap`, `timeline`, `quadrant`, `sankey-beta`, `gitGraph`, `xychart-beta`, `packet-beta`, `kanban`, `journey`, `requirementDiagram` — leave unstyled. Theme `%%{init}%%` block handles colors and fonts.

## `flowchart`, `stateDiagram-v2` — `classDef` + `:::`

Use `classDef` declarations + `:::` on nodes (see SKILL.md example).

## `sequenceDiagram` — `rect rgb(...)` blocks

`classDef` not supported. Use colored `rect` blocks:

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server

    rect rgb(200,230,201)
        Note over C,S: Happy path
        C->>S: POST /login
        S-->>C: 200 OK + token
    end

    rect rgb(248,187,208)
        Note over C,S: Error path
        C->>S: POST /login (bad password)
        S-->>C: 401 Unauthorized
    end
```

RGB values: green `rgb(200,230,201)`, pink `rgb(248,187,208)`, purple `rgb(225,190,231)`, yellow `rgb(255,249,196)`

### `classDiagram` — inline only

```mermaid
classDiagram
    class PaymentProvider:::ext {
        <<abstract>>
        +charge() bool
    }
```

Standalone `ClassName:::classDefName` outside class body → parse error.

### `block-beta` — `style` after `end`

`classDef`/`:::` not supported inside nested `block:...:end`. Use `style` after all `end` keywords:

```mermaid
block-beta
    columns 2
    A["Service A"] B["Service B"]
    block:group
        C["Worker"]
    end
    style A fill:#C8E6C9,stroke:#2E7D32,color:#212121
    style C fill:#E1BEE7,stroke:#6A1B9A,color:#212121
```

### `architecture-beta`

No `classDef`. Use `style` if needed (renderer support varies).

### `C4Context` / `C4Container` / `C4Component`

`System_Ext` auto-styled by C4. No additional coloring needed.

