# Diagram Type Reference

Type-specific Mermaid syntax. Read the section for the diagram type you are generating.

---

## Flowchart

```mermaid
flowchart TD
    A([Start]) --> B[Process step]
    B --> C{Decision?}
    C -->|yes| D[Action]
    C -->|no| E([End])
```

- Orientations: `TD` (top-down), `LR` (left-right), `BT`, `RL`
- Shapes: `[rect]`, `(round)`, `([stadium])`, `{diamond}`, `[(cylinder)]`, `[[subroutine]]`, `{{hexagon}}`, `>asymmetric]`, `[/parallelogram/]`
- Subgraphs: `subgraph id [title] ... end`
- Links: `-->`, `---`, `-.->`, `==>`, `--text-->`, `-->|text|`

---

## Sequence Diagram

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server
    participant D as Database
    C->>S: POST /login
    activate S
    S->>D: SELECT user
    D-->>S: user row
    S-->>C: 200 OK + token
    deactivate S
```

- Use short aliases: `participant C as Client`
- Sync: `->>`, response: `-->>`, open: `->`
- `activate`/`deactivate` for lifelines
- `rect rgb(...)` for grouping
- `Note over A,B: text` for annotations
- `alt`/`else`/`end` for conditionals, `loop`/`end` for loops
- Max 6 participants before splitting

---

## State Diagram

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Running : start()
    Running --> Idle : stop()
    Running --> Error : fail()
    Error --> Idle : reset()
    Error --> [*] : shutdown()
```

- `state "Label" as id` for readable names
- Composite: `state "Group" as g { inner1 --> inner2 }`
- Terminals: `[*] -->` (start), `--> [*]` (end)
- `<<fork>>` and `<<join>>` for parallel states

---

## ER Diagram

```mermaid
erDiagram
    USER ||--o{ ORDER : "places"
    ORDER ||--|{ LINE_ITEM : "contains"
    PRODUCT ||--o{ LINE_ITEM : "appears in"
    USER {
        int id PK
        string email UK
        string name
    }
```

- Cardinality: `||` exactly one, `o|` zero or one, `|{` one+, `o{` zero+
- Show PK/FK/UK only — omit low-value attributes
- Relationship labels in quotes

---

## Class Diagram

```mermaid
classDiagram
    class Animal {
        +String name
        +int age
        +makeSound() Sound
    }
    Animal <|-- Dog
    Animal <|-- Cat
```

- Visibility: `+` public, `-` private, `#` protected, `~` package
- Relationships: `<|--` inheritance, `*--` composition, `o--` aggregation, `-->` association, `..>` dependency, `..|>` realization
- Annotations: `<<interface>>`, `<<abstract>>`, `<<enumeration>>`
- **`classDef` application must be inline** — use `class ClassName:::classDefName { ... }`, not standalone `ClassName:::classDefName` lines (those cause parse errors)

---

## Gantt Chart

```mermaid
gantt
    dateFormat YYYY-MM-DD
    title Project Timeline
    section Phase 1
    Design           :a1, 2025-01-01, 30d
    Prototype        :a2, after a1, 20d
    section Phase 2
    Implementation   :b1, after a2, 60d
    Testing          :b2, after b1, 30d
    Launch           :milestone, after b2, 0d
```

- `dateFormat` must be first
- Group with `section`
- Dependencies: `after taskId`
- Milestones: `:milestone, after X, 0d`
- Status modifiers: `done`, `active`, `crit`

---

## Pie Chart

```mermaid
pie title Distribution
    "Category A" : 40
    "Category B" : 30
    "Category C" : 20
    "Other" : 10
```

- Values are proportional, not required to sum to 100
- Keep to 6–8 slices; group small ones into "Other"

---

## Mindmap

```mermaid
mindmap
    root((Central Topic))
        Branch A
            Leaf A1
            Leaf A2
        Branch B
            Leaf B1
```

- Indentation defines hierarchy
- Root shapes: `((circle))`, `[square]`, `(rounded)`
- Keep to 3–4 levels deep; short labels

---

## Timeline

```mermaid
timeline
    title Project History
    2024-Q1 : Inception
            : Team formed
    2024-Q2 : Alpha release
    2024-Q3 : Beta release
    2024-Q4 : GA launch
```

- Time period on its own line; events indented with `:`
- Multiple events per period are allowed

---

## Quadrant Chart

```mermaid
quadrantChart
    title Priority Matrix
    x-axis Low Effort --> High Effort
    y-axis Low Impact --> High Impact
    quadrant-1 Do First
    quadrant-2 Schedule
    quadrant-3 Delegate
    quadrant-4 Eliminate
    Item A: [0.8, 0.9]
    Item B: [0.2, 0.7]
```

- Quadrants: 1=top-right, 2=top-left, 3=bottom-left, 4=bottom-right
- Points: `Label: [x, y]` with 0.0–1.0 coordinates

---

## Sankey Diagram (`sankey-beta`)

```mermaid
sankey-beta
    Source A,Target X,30
    Source A,Target Y,20
    Source B,Target X,15
    Source B,Target Z,25
```

- CSV format: `source,target,value`
- Values control flow width
- Keep to ~10–15 flows for readability

---

## Git Graph

```mermaid
gitGraph
    commit id: "init"
    branch develop
    checkout develop
    commit id: "feat-1"
    checkout main
    merge develop id: "merge-1"
    commit id: "hotfix"
```

- `branch name`, `checkout name`, `merge name`
- Tags: `commit id: "v1.0" tag: "v1.0"`
- `cherry-pick id: "id"`

---

## C4 Diagrams

```mermaid
C4Context
    title System Context
    Person(user, "User", "End user")
    System(app, "Application", "The main system")
    System_Ext(email, "Email Service", "External provider")
    Rel(user, app, "Uses", "HTTPS")
    Rel(app, email, "Sends mail", "SMTP")
```

- Types: `C4Context`, `C4Container`, `C4Component`, `C4Dynamic`
- Elements: `Person()`, `System()`, `System_Ext()`, `Container()`, `Component()`
- Boundaries: `Boundary(id, "Label") { ... }`
- One C4 level per diagram
- **Arrow routing**: C4 uses a grid layout. On hub-and-spoke patterns arrows often route through other nodes. Add `UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")` right after the `title` line to control elements per row — tuning this value spreads nodes out and gives arrows cleaner paths. If crossings persist, split into two diagrams (users→system, system→external services).

---

## Block Diagram (`block-beta`)

```mermaid
block-beta
    columns 3
    A["Service A"] B["Service B"] C["Service C"]
    space D["Database"]:2
    block:group
        E["Worker 1"]
        F["Worker 2"]
    end
    A --> D
```

- `columns N` sets grid width; `:N` spans N columns
- `space` for empty cells
- `block:id ... end` for nested containers
- **Styling nodes**: `classDef`/`:::` is not supported inside nested `block:...:end` containers. Use `style nodeId fill:...,stroke:...,color:...` statements after all `end` keywords instead.
- **When to avoid `block-beta`**: it uses a fixed grid layout — blocks size unpredictably and edge routing is poor (arrows pass through nodes). If the diagram has connections between nodes, use `flowchart TD/LR` with `subgraph` boundaries instead, which gives proper edge routing and predictable sizing. Reserve `block-beta` for static layout diagrams with no or very few arrows.

---

## Architecture Diagram (`architecture-beta`)

```mermaid
architecture-beta
    group cloud(cloud)[Cloud]
    service api(server)[API] in cloud
    service db(database)[Database] in cloud
    service client(internet)[Client]
    client:R --> L:api
    api:R --> L:db
```

- `group id(icon)[Label]` for boundaries
- `service id(icon)[Label] in group`
- Icons: `cloud`, `server`, `database`, `internet`, `disk`
- Connections use edge anchors: T, B, L, R
- **Label restriction:** Labels must contain only alphanumeric characters and spaces — no `.`, `-`, `/`, `[`, `]`, or other punctuation. `Node.js` → `NodeJS`, `ECS - API` → `ECS API`. If labels require special characters, use `flowchart TD` with `subgraph` for the boundary instead.

---

## Packet Diagram (`packet-beta`)

```mermaid
packet-beta
    0-15: "Source Port"
    16-31: "Destination Port"
    32-63: "Sequence Number"
    64-95: "Acknowledgment Number"
```

- `start-end: "Label"` for each field
- Rows wrap at 32 bits by default

---

## Kanban Board

```mermaid
kanban
    Todo
        Task A
        Task B
    In Progress
        Task C
    Done
        Task D
```

- Column names as top-level items, tasks indented under columns

---

## XY Chart (`xychart-beta`)

```mermaid
xychart-beta
    title "Monthly Revenue"
    x-axis [Jan, Feb, Mar, Apr, May]
    y-axis "Revenue ($K)" 0 --> 100
    bar [30, 45, 60, 55, 80]
    line [30, 45, 60, 55, 80]
```

- `bar [values]` and/or `line [values]`
- Keep data points under ~15

---

## Requirement Diagram

```mermaid
requirementDiagram
    requirement high_perf {
        id: REQ_001
        text: Handle 1000 req/s
        risk: high
        verifymethod: test
    }
    element api_server {
        type: service
    }
    api_server - satisfies -> high_perf
```

- Types: `requirement`, `functionalRequirement`, `performanceRequirement`, `interfaceRequirement`, `designConstraint`, `physicalRequirement`
- Risk: `low`, `medium`, `high`
- Verify: `analysis`, `inspection`, `test`, `demonstration`
- Relations: `satisfies`, `traces`, `contains`, `derives`, `refines`, `copies`
- **`text:` field is plain text only** — no `<br/>`, HTML, or special characters. Keep it to one concise sentence.
- **Avoid hyphens everywhere** — hyphens in identifiers, `id:` values, or node names are parsed as relation arrow tokens and cause parse errors. Use underscores instead (`REQ_001`, `auth_service`, not `REQ-001`, `auth-service`).

---

## Journey Diagram

```mermaid
journey
    title User Onboarding
    section Sign Up
        Visit landing page: 5: User
        Fill registration form: 3: User
        Verify email: 2: User
    section First Use
        Complete tutorial: 4: User
        Create first project: 5: User
```

- Format: `Task name: satisfaction(1–5): actor`
- Higher number = better satisfaction
- Group with `section`
